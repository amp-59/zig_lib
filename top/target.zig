pub const Range = struct {
    min: struct {
        major: usize,
        minor: usize,
        patch: usize,
        pre: ?[]const u8 = null,
        build: ?[]const u8 = null,
    },
    max: struct {
        major: usize,
        minor: usize,
        patch: usize,
        pre: ?[]const u8 = null,
        build: ?[]const u8 = null,
    },
};
pub const Version = struct {
    major: usize,
    minor: usize,
    patch: usize,
    pre: ?[]const u8 = null,
    build: ?[]const u8 = null,
};
pub const LinuxVersionRange = struct {
    range: Range,
    glibc: struct {
        major: usize,
        minor: usize,
        patch: usize,
        pre: ?[]const u8 = null,
        build: ?[]const u8 = null,
    },
};
pub const WindowsVersion = enum(u32) {
    nt4 = 67108864,
    win2k = 83886080,
    xp = 83951616,
    ws2003 = 84017152,
    vista = 100663296,
    win7 = 100728832,
    win8 = 100794368,
    win8_1 = 100859904,
    win10 = 167772160,
    win10_th2 = 167772161,
    win10_rs1 = 167772162,
    win10_rs2 = 167772163,
    win10_rs3 = 167772164,
    win10_rs4 = 167772165,
    win10_rs5 = 167772166,
    win10_19h1 = 167772167,
    win10_vb = 167772168,
    win10_mn = 167772169,
    win10_fe = 167772170,
};
pub const Target = struct {
    cpu: Cpu,
    os: Os,
    abi: Abi,
    ofmt: ObjectFormat,
    pub const Cpu = struct {
        arch: enum(u6) {
            arm = 0,
            armeb = 1,
            aarch64 = 2,
            aarch64_be = 3,
            aarch64_32 = 4,
            arc = 5,
            avr = 6,
            bpfel = 7,
            bpfeb = 8,
            csky = 9,
            dxil = 10,
            hexagon = 11,
            loongarch32 = 12,
            loongarch64 = 13,
            m68k = 14,
            mips = 15,
            mipsel = 16,
            mips64 = 17,
            mips64el = 18,
            msp430 = 19,
            powerpc = 20,
            powerpcle = 21,
            powerpc64 = 22,
            powerpc64le = 23,
            r600 = 24,
            amdgcn = 25,
            riscv32 = 26,
            riscv64 = 27,
            sparc = 28,
            sparc64 = 29,
            sparcel = 30,
            s390x = 31,
            tce = 32,
            tcele = 33,
            thumb = 34,
            thumbeb = 35,
            x86 = 36,
            x86_64 = 37,
            xcore = 38,
            xtensa = 39,
            nvptx = 40,
            nvptx64 = 41,
            le32 = 42,
            le64 = 43,
            amdil = 44,
            amdil64 = 45,
            hsail = 46,
            hsail64 = 47,
            spir = 48,
            spir64 = 49,
            spirv32 = 50,
            spirv64 = 51,
            kalimba = 52,
            shave = 53,
            lanai = 54,
            wasm32 = 55,
            wasm64 = 56,
            renderscript32 = 57,
            renderscript64 = 58,
            ve = 59,
            spu_2 = 60,
        },
        model: *const struct {
            name: []const u8,
            llvm_name: ?[:0]const u8,
            features: struct {
                ints: [5]usize,
            },
        },
        features: struct {
            ints: [5]usize,
        },
        pub const Feature = struct {
            index: u9 = 0,
            name: []const u8 = "",
            llvm_name: ?[:0]const u8,
            description: []const u8,
            dependencies: struct {
                ints: [5]usize,
            },
        };
        pub const Set = struct {
            ints: [5]usize,
        };
    };
    pub const Os = struct {
        tag: enum(u6) {
            freestanding = 0,
            ananas = 1,
            cloudabi = 2,
            dragonfly = 3,
            freebsd = 4,
            fuchsia = 5,
            ios = 6,
            kfreebsd = 7,
            linux = 8,
            lv2 = 9,
            macos = 10,
            netbsd = 11,
            openbsd = 12,
            solaris = 13,
            windows = 14,
            zos = 15,
            haiku = 16,
            minix = 17,
            rtems = 18,
            nacl = 19,
            aix = 20,
            cuda = 21,
            nvcl = 22,
            amdhsa = 23,
            ps4 = 24,
            ps5 = 25,
            elfiamcu = 26,
            tvos = 27,
            watchos = 28,
            driverkit = 29,
            mesa3d = 30,
            contiki = 31,
            amdpal = 32,
            hermit = 33,
            hurd = 34,
            wasi = 35,
            emscripten = 36,
            shadermodel = 37,
            uefi = 38,
            opencl = 39,
            glsl450 = 40,
            vulkan = 41,
            plan9 = 42,
            other = 43,
        },
        version_range: union {
            none: void,
            semver: Range,
            linux: LinuxVersionRange,
            windows: struct {
                min: WindowsVersion,
                max: WindowsVersion,
            },
        },
    };
    pub const Abi = enum(u6) {
        none = 0,
        gnu = 1,
        gnuabin32 = 2,
        gnuabi64 = 3,
        gnueabi = 4,
        gnueabihf = 5,
        gnuf32 = 6,
        gnuf64 = 7,
        gnusf = 8,
        gnux32 = 9,
        gnuilp32 = 10,
        code16 = 11,
        eabi = 12,
        eabihf = 13,
        android = 14,
        musl = 15,
        musleabi = 16,
        musleabihf = 17,
        muslx32 = 18,
        msvc = 19,
        itanium = 20,
        cygnus = 21,
        coreclr = 22,
        simulator = 23,
        macabi = 24,
        pixel = 25,
        vertex = 26,
        geometry = 27,
        hull = 28,
        domain = 29,
        compute = 30,
        library = 31,
        raygeneration = 32,
        intersection = 33,
        anyhit = 34,
        closesthit = 35,
        miss = 36,
        callable = 37,
        mesh = 38,
        amplification = 39,
    };
    pub const ObjectFormat = enum(u4) {
        coff = 0,
        dxcontainer = 1,
        elf = 2,
        macho = 3,
        spirv = 4,
        wasm = 5,
        c = 6,
        hex = 7,
        raw = 8,
        plan9 = 9,
        nvptx = 10,
    };
    pub const aarch64 = struct {
        pub const Feature = enum(u8) {
            a510 = 0,
            a65 = 1,
            a710 = 2,
            a76 = 3,
            a78 = 4,
            a78c = 5,
            aes = 6,
            aggressive_fma = 7,
            alternate_sextload_cvt_f32_pattern = 8,
            altnzcv = 9,
            am = 10,
            amvs = 11,
            arith_bcc_fusion = 12,
            arith_cbz_fusion = 13,
            ascend_store_address = 14,
            b16b16 = 15,
            balance_fp_ops = 16,
            bf16 = 17,
            brbe = 18,
            bti = 19,
            call_saved_x10 = 20,
            call_saved_x11 = 21,
            call_saved_x12 = 22,
            call_saved_x13 = 23,
            call_saved_x14 = 24,
            call_saved_x15 = 25,
            call_saved_x18 = 26,
            call_saved_x8 = 27,
            call_saved_x9 = 28,
            ccdp = 29,
            ccidx = 30,
            ccpp = 31,
            clrbhb = 32,
            cmp_bcc_fusion = 33,
            complxnum = 34,
            contextidr_el2 = 35,
            cortex_r82 = 36,
            crc = 37,
            crypto = 38,
            cssc = 39,
            custom_cheap_as_move = 40,
            d128 = 41,
            disable_latency_sched_heuristic = 42,
            dit = 43,
            dotprod = 44,
            ecv = 45,
            el2vmsa = 46,
            el3 = 47,
            enable_select_opt = 48,
            ete = 49,
            exynos_cheap_as_move = 50,
            f32mm = 51,
            f64mm = 52,
            fgt = 53,
            fix_cortex_a53_835769 = 54,
            flagm = 55,
            fmv = 56,
            force_32bit_jump_tables = 57,
            fp16fml = 58,
            fp_armv8 = 59,
            fptoint = 60,
            fullfp16 = 61,
            fuse_address = 62,
            fuse_adrp_add = 63,
            fuse_aes = 64,
            fuse_arith_logic = 65,
            fuse_crypto_eor = 66,
            fuse_csel = 67,
            fuse_literals = 68,
            harden_sls_blr = 69,
            harden_sls_nocomdat = 70,
            harden_sls_retbr = 71,
            hbc = 72,
            hcx = 73,
            i8mm = 74,
            ite = 75,
            jsconv = 76,
            lor = 77,
            ls64 = 78,
            lse = 79,
            lse128 = 80,
            lse2 = 81,
            lsl_fast = 82,
            mec = 83,
            mops = 84,
            mpam = 85,
            mte = 86,
            neon = 87,
            nmi = 88,
            no_bti_at_return_twice = 89,
            no_neg_immediates = 90,
            no_zcz_fp = 91,
            nv = 92,
            outline_atomics = 93,
            pan = 94,
            pan_rwv = 95,
            pauth = 96,
            perfmon = 97,
            predictable_select_expensive = 98,
            predres = 99,
            prfm_slc_target = 100,
            rand = 101,
            ras = 102,
            rasv2 = 103,
            rcpc = 104,
            rcpc3 = 105,
            rcpc_immo = 106,
            rdm = 107,
            reserve_x1 = 108,
            reserve_x10 = 109,
            reserve_x11 = 110,
            reserve_x12 = 111,
            reserve_x13 = 112,
            reserve_x14 = 113,
            reserve_x15 = 114,
            reserve_x18 = 115,
            reserve_x2 = 116,
            reserve_x20 = 117,
            reserve_x21 = 118,
            reserve_x22 = 119,
            reserve_x23 = 120,
            reserve_x24 = 121,
            reserve_x25 = 122,
            reserve_x26 = 123,
            reserve_x27 = 124,
            reserve_x28 = 125,
            reserve_x3 = 126,
            reserve_x30 = 127,
            reserve_x4 = 128,
            reserve_x5 = 129,
            reserve_x6 = 130,
            reserve_x7 = 131,
            reserve_x9 = 132,
            rme = 133,
            sb = 134,
            sel2 = 135,
            sha2 = 136,
            sha3 = 137,
            slow_misaligned_128store = 138,
            slow_paired_128 = 139,
            slow_strqro_store = 140,
            sm4 = 141,
            sme = 142,
            sme2 = 143,
            sme2p1 = 144,
            sme_f16f16 = 145,
            sme_f64f64 = 146,
            sme_i16i64 = 147,
            spe = 148,
            spe_eef = 149,
            specres2 = 150,
            specrestrict = 151,
            ssbs = 152,
            strict_align = 153,
            sve = 154,
            sve2 = 155,
            sve2_aes = 156,
            sve2_bitperm = 157,
            sve2_sha3 = 158,
            sve2_sm4 = 159,
            sve2p1 = 160,
            tagged_globals = 161,
            the = 162,
            tlb_rmi = 163,
            tme = 164,
            tpidr_el1 = 165,
            tpidr_el2 = 166,
            tpidr_el3 = 167,
            tracev8_4 = 168,
            trbe = 169,
            uaops = 170,
            use_experimental_zeroing_pseudos = 171,
            use_postra_scheduler = 172,
            use_reciprocal_square_root = 173,
            use_scalar_inc_vl = 174,
            v8_1a = 175,
            v8_2a = 176,
            v8_3a = 177,
            v8_4a = 178,
            v8_5a = 179,
            v8_6a = 180,
            v8_7a = 181,
            v8_8a = 182,
            v8_9a = 183,
            v8a = 184,
            v8r = 185,
            v9_1a = 186,
            v9_2a = 187,
            v9_3a = 188,
            v9_4a = 189,
            v9a = 190,
            vh = 191,
            wfxt = 192,
            xs = 193,
            zcm = 194,
            zcz = 195,
            zcz_fp_workaround = 196,
            zcz_gp = 197,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "a510", .llvm_name = "a510", .description = "Cortex-A510 ARM processors", .dependencies = .{ .ints = .{ 9223372036854775808, 1, 17592186044416, 0, 0 } } },
            .{ .index = 1, .name = "a65", .llvm_name = "a65", .description = "Cortex-A65 ARM processors", .dependencies = .{ .ints = .{ 13835339530258874368, 17, 0, 0, 0 } } },
            .{ .index = 2, .name = "a710", .llvm_name = "a710", .description = "Cortex-A710 ARM processors", .dependencies = .{ .ints = .{ 9223653520421421056, 262145, 17592186044416, 0, 0 } } },
            .{ .index = 3, .name = "a76", .llvm_name = "a76", .description = "Cortex-A76 ARM processors", .dependencies = .{ .ints = .{ 9223653511831486464, 262145, 0, 0, 0 } } },
            .{ .index = 4, .name = "a78", .llvm_name = "a78", .description = "Cortex-A78 ARM processors", .dependencies = .{ .ints = .{ 9223653520421421056, 262145, 17592186044416, 0, 0 } } },
            .{ .index = 5, .name = "a78c", .llvm_name = "a78c", .description = "Cortex-A78C ARM processors", .dependencies = .{ .ints = .{ 9223653520421421056, 262145, 17592186044416, 0, 0 } } },
            .{ .index = 6, .name = "aes", .llvm_name = "aes", .description = "Enable AES support (FEAT_AES, FEAT_PMULL)", .dependencies = .{ .ints = .{ 0, 8388608, 0, 0, 0 } } },
            .{ .index = 7, .name = "aggressive_fma", .llvm_name = "aggressive-fma", .description = "Enable Aggressive FMA for floating-point.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "alternate_sextload_cvt_f32_pattern", .llvm_name = "alternate-sextload-cvt-f32-pattern", .description = "Use alternative pattern for sextload convert to f32", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "altnzcv", .llvm_name = "altnzcv", .description = "Enable alternative NZCV format for floating point comparisons (FEAT_FlagM2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "am", .llvm_name = "am", .description = "Enable v8.4-A Activity Monitors extension (FEAT_AMUv1)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "amvs", .llvm_name = "amvs", .description = "Enable v8.6-A Activity Monitors Virtualization support (FEAT_AMUv1p1)", .dependencies = .{ .ints = .{ 1024, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "arith_bcc_fusion", .llvm_name = "arith-bcc-fusion", .description = "CPU fuses arithmetic+bcc operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "arith_cbz_fusion", .llvm_name = "arith-cbz-fusion", .description = "CPU fuses arithmetic + cbz/cbnz operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "ascend_store_address", .llvm_name = "ascend-store-address", .description = "Schedule vector stores by ascending address", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "b16b16", .llvm_name = "b16b16", .description = "Enable SVE2.1 or SME2.1 non-widening BFloat16 to BFloat16 instructions (FEAT_B16B16)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "balance_fp_ops", .llvm_name = "balance-fp-ops", .description = "balance mix of odd and even D-registers for fp multiply(-accumulate) ops", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "bf16", .llvm_name = "bf16", .description = "Enable BFloat16 Extension (FEAT_BF16)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "brbe", .llvm_name = "brbe", .description = "Enable Branch Record Buffer Extension (FEAT_BRBE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "bti", .llvm_name = "bti", .description = "Enable Branch Target Identification (FEAT_BTI)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "call_saved_x10", .llvm_name = "call-saved-x10", .description = "Make X10 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "call_saved_x11", .llvm_name = "call-saved-x11", .description = "Make X11 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "call_saved_x12", .llvm_name = "call-saved-x12", .description = "Make X12 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "call_saved_x13", .llvm_name = "call-saved-x13", .description = "Make X13 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "call_saved_x14", .llvm_name = "call-saved-x14", .description = "Make X14 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "call_saved_x15", .llvm_name = "call-saved-x15", .description = "Make X15 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "call_saved_x18", .llvm_name = "call-saved-x18", .description = "Make X18 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "call_saved_x8", .llvm_name = "call-saved-x8", .description = "Make X8 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "call_saved_x9", .llvm_name = "call-saved-x9", .description = "Make X9 callee saved.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "ccdp", .llvm_name = "ccdp", .description = "Enable v8.5 Cache Clean to Point of Deep Persistence (FEAT_DPB2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "ccidx", .llvm_name = "ccidx", .description = "Enable v8.3-A Extend of the CCSIDR number of sets (FEAT_CCIDX)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "ccpp", .llvm_name = "ccpp", .description = "Enable v8.2 data Cache Clean to Point of Persistence (FEAT_DPB)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "clrbhb", .llvm_name = "clrbhb", .description = "Enable Clear BHB instruction (FEAT_CLRBHB)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "cmp_bcc_fusion", .llvm_name = "cmp-bcc-fusion", .description = "CPU fuses cmp+bcc operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "complxnum", .llvm_name = "complxnum", .description = "Enable v8.3-A Floating-point complex number support (FEAT_FCMA)", .dependencies = .{ .ints = .{ 0, 8388608, 0, 0, 0 } } },
            .{ .index = 35, .name = "contextidr_el2", .llvm_name = "CONTEXTIDREL2", .description = "Enable RW operand Context ID Register (EL2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "cortex_r82", .llvm_name = "cortex-r82", .description = "Cortex-R82 ARM processors", .dependencies = .{ .ints = .{ 0, 0, 17592186044416, 0, 0 } } },
            .{ .index = 37, .name = "crc", .llvm_name = "crc", .description = "Enable ARMv8 CRC-32 checksum instructions (FEAT_CRC32)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "crypto", .llvm_name = "crypto", .description = "Enable cryptographic instructions", .dependencies = .{ .ints = .{ 64, 0, 256, 0, 0 } } },
            .{ .index = 39, .name = "cssc", .llvm_name = "cssc", .description = "Enable Common Short Sequence Compression (CSSC) instructions (FEAT_CSSC)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "custom_cheap_as_move", .llvm_name = "custom-cheap-as-move", .description = "Use custom handling of cheap instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "d128", .llvm_name = "d128", .description = "Enable Armv9.4-A 128-bit Page Table Descriptors, System Registers and Instructions (FEAT_D128, FEAT_LVA3, FEAT_SYSREG128, FEAT_SYSINSTR128)", .dependencies = .{ .ints = .{ 0, 65536, 0, 0, 0 } } },
            .{ .index = 42, .name = "disable_latency_sched_heuristic", .llvm_name = "disable-latency-sched-heuristic", .description = "Disable latency scheduling heuristic", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "dit", .llvm_name = "dit", .description = "Enable v8.4-A Data Independent Timing instructions (FEAT_DIT)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "dotprod", .llvm_name = "dotprod", .description = "Enable dot product support (FEAT_DotProd)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "ecv", .llvm_name = "ecv", .description = "Enable enhanced counter virtualization extension (FEAT_ECV)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "el2vmsa", .llvm_name = "el2vmsa", .description = "Enable Exception Level 2 Virtual Memory System Architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "el3", .llvm_name = "el3", .description = "Enable Exception Level 3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "enable_select_opt", .llvm_name = "enable-select-opt", .description = "Enable the select optimize pass for select loop heuristics", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "ete", .llvm_name = "ete", .description = "Enable Embedded Trace Extension (FEAT_ETE)", .dependencies = .{ .ints = .{ 0, 0, 2199023255552, 0, 0 } } },
            .{ .index = 50, .name = "exynos_cheap_as_move", .llvm_name = "exynos-cheap-as-move", .description = "Use Exynos specific handling of cheap instructions", .dependencies = .{ .ints = .{ 1099511627776, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "f32mm", .llvm_name = "f32mm", .description = "Enable Matrix Multiply FP32 Extension (FEAT_F32MM)", .dependencies = .{ .ints = .{ 0, 0, 67108864, 0, 0 } } },
            .{ .index = 52, .name = "f64mm", .llvm_name = "f64mm", .description = "Enable Matrix Multiply FP64 Extension (FEAT_F64MM)", .dependencies = .{ .ints = .{ 0, 0, 67108864, 0, 0 } } },
            .{ .index = 53, .name = "fgt", .llvm_name = "fgt", .description = "Enable fine grained virtualization traps extension (FEAT_FGT)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "fix_cortex_a53_835769", .llvm_name = "fix-cortex-a53-835769", .description = "Mitigate Cortex-A53 Erratum 835769", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "flagm", .llvm_name = "flagm", .description = "Enable v8.4-A Flag Manipulation Instructions (FEAT_FlagM)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "fmv", .llvm_name = "fmv", .description = "Enable Function Multi Versioning support.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "force_32bit_jump_tables", .llvm_name = "force-32bit-jump-tables", .description = "Force jump table entries to be 32-bits wide except at MinSize", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 58, .name = "fp16fml", .llvm_name = "fp16fml", .description = "Enable FP16 FML instructions (FEAT_FHM)", .dependencies = .{ .ints = .{ 2305843009213693952, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "fp_armv8", .llvm_name = "fp-armv8", .description = "Enable ARMv8 FP (FEAT_FP)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "fptoint", .llvm_name = "fptoint", .description = "Enable FRInt[32|64][Z|X] instructions that round a floating-point number to an integer (in FP format) forcing it to fit into a 32- or 64-bit int (FEAT_FRINTTS)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "fullfp16", .llvm_name = "fullfp16", .description = "Full FP16 (FEAT_FP16)", .dependencies = .{ .ints = .{ 576460752303423488, 0, 0, 0, 0 } } },
            .{ .index = 62, .name = "fuse_address", .llvm_name = "fuse-address", .description = "CPU fuses address generation and memory operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "fuse_adrp_add", .llvm_name = "fuse-adrp-add", .description = "CPU fuses adrp+add operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "fuse_aes", .llvm_name = "fuse-aes", .description = "CPU fuses AES crypto operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 65, .name = "fuse_arith_logic", .llvm_name = "fuse-arith-logic", .description = "CPU fuses arithmetic and logic operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 66, .name = "fuse_crypto_eor", .llvm_name = "fuse-crypto-eor", .description = "CPU fuses AES/PMULL and EOR operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 67, .name = "fuse_csel", .llvm_name = "fuse-csel", .description = "CPU fuses conditional select operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 68, .name = "fuse_literals", .llvm_name = "fuse-literals", .description = "CPU fuses literal generation operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 69, .name = "harden_sls_blr", .llvm_name = "harden-sls-blr", .description = "Harden against straight line speculation across BLR instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 70, .name = "harden_sls_nocomdat", .llvm_name = "harden-sls-nocomdat", .description = "Generate thunk code for SLS mitigation in the normal text section", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 71, .name = "harden_sls_retbr", .llvm_name = "harden-sls-retbr", .description = "Harden against straight line speculation across RET and BR instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 72, .name = "hbc", .llvm_name = "hbc", .description = "Enable Armv8.8-A Hinted Conditional Branches Extension (FEAT_HBC)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 73, .name = "hcx", .llvm_name = "hcx", .description = "Enable Armv8.7-A HCRX_EL2 system register (FEAT_HCX)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 74, .name = "i8mm", .llvm_name = "i8mm", .description = "Enable Matrix Multiply Int8 Extension (FEAT_I8MM)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 75, .name = "ite", .llvm_name = "ite", .description = "Enable Armv9.4-A Instrumentation Extension FEAT_ITE", .dependencies = .{ .ints = .{ 562949953421312, 0, 0, 0, 0 } } },
            .{ .index = 76, .name = "jsconv", .llvm_name = "jsconv", .description = "Enable v8.3-A JavaScript FP conversion instructions (FEAT_JSCVT)", .dependencies = .{ .ints = .{ 576460752303423488, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "lor", .llvm_name = "lor", .description = "Enables ARM v8.1 Limited Ordering Regions extension (FEAT_LOR)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 78, .name = "ls64", .llvm_name = "ls64", .description = "Enable Armv8.7-A LD64B/ST64B Accelerator Extension (FEAT_LS64, FEAT_LS64_V, FEAT_LS64_ACCDATA)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 79, .name = "lse", .llvm_name = "lse", .description = "Enable ARMv8.1 Large System Extension (LSE) atomic instructions (FEAT_LSE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 80, .name = "lse128", .llvm_name = "lse128", .description = "Enable Armv9.4-A 128-bit Atomic Instructions (FEAT_LSE128)", .dependencies = .{ .ints = .{ 0, 32768, 0, 0, 0 } } },
            .{ .index = 81, .name = "lse2", .llvm_name = "lse2", .description = "Enable ARMv8.4 Large System Extension 2 (LSE2) atomicity rules (FEAT_LSE2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 82, .name = "lsl_fast", .llvm_name = "lsl-fast", .description = "CPU has a fastpath logical shift of up to 3 places", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 83, .name = "mec", .llvm_name = "mec", .description = "Enable Memory Encryption Contexts Extension", .dependencies = .{ .ints = .{ 0, 0, 32, 0, 0 } } },
            .{ .index = 84, .name = "mops", .llvm_name = "mops", .description = "Enable Armv8.8-A memcpy and memset acceleration instructions (FEAT_MOPS)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 85, .name = "mpam", .llvm_name = "mpam", .description = "Enable v8.4-A Memory system Partitioning and Monitoring extension (FEAT_MPAM)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 86, .name = "mte", .llvm_name = "mte", .description = "Enable Memory Tagging Extension (FEAT_MTE, FEAT_MTE2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 87, .name = "neon", .llvm_name = "neon", .description = "Enable Advanced SIMD instructions (FEAT_AdvSIMD)", .dependencies = .{ .ints = .{ 576460752303423488, 0, 0, 0, 0 } } },
            .{ .index = 88, .name = "nmi", .llvm_name = "nmi", .description = "Enable Armv8.8-A Non-maskable Interrupts (FEAT_NMI, FEAT_GICv3_NMI)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 89, .name = "no_bti_at_return_twice", .llvm_name = "no-bti-at-return-twice", .description = "Don't place a BTI instruction after a return-twice", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 90, .name = "no_neg_immediates", .llvm_name = "no-neg-immediates", .description = "Convert immediates and instructions to their negated or complemented equivalent when the immediate does not fit in the encoding.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 91, .name = "no_zcz_fp", .llvm_name = "no-zcz-fp", .description = "Has no zero-cycle zeroing instructions for FP registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 92, .name = "nv", .llvm_name = "nv", .description = "Enable v8.4-A Nested Virtualization Enchancement (FEAT_NV, FEAT_NV2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 93, .name = "outline_atomics", .llvm_name = "outline-atomics", .description = "Enable out of line atomics to support LSE instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 94, .name = "pan", .llvm_name = "pan", .description = "Enables ARM v8.1 Privileged Access-Never extension (FEAT_PAN)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 95, .name = "pan_rwv", .llvm_name = "pan-rwv", .description = "Enable v8.2 PAN s1e1R and s1e1W Variants (FEAT_PAN2)", .dependencies = .{ .ints = .{ 0, 1073741824, 0, 0, 0 } } },
            .{ .index = 96, .name = "pauth", .llvm_name = "pauth", .description = "Enable v8.3-A Pointer Authentication extension (FEAT_PAuth)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 97, .name = "perfmon", .llvm_name = "perfmon", .description = "Enable Code Generation for ARMv8 PMUv3 Performance Monitors extension (FEAT_PMUv3)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 98, .name = "predictable_select_expensive", .llvm_name = "predictable-select-expensive", .description = "Prefer likely predicted branches over selects", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 99, .name = "predres", .llvm_name = "predres", .description = "Enable v8.5a execution and data prediction invalidation instructions (FEAT_SPECRES)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 100, .name = "prfm_slc_target", .llvm_name = "prfm-slc-target", .description = "Enable SLC target for PRFM instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 101, .name = "rand", .llvm_name = "rand", .description = "Enable Random Number generation instructions (FEAT_RNG)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 102, .name = "ras", .llvm_name = "ras", .description = "Enable ARMv8 Reliability, Availability and Serviceability Extensions (FEAT_RAS, FEAT_RASv1p1)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 103, .name = "rasv2", .llvm_name = "rasv2", .description = "Enable ARMv8.9-A Reliability, Availability and Serviceability Extensions (FEAT_RASv2)", .dependencies = .{ .ints = .{ 0, 274877906944, 0, 0, 0 } } },
            .{ .index = 104, .name = "rcpc", .llvm_name = "rcpc", .description = "Enable support for RCPC extension (FEAT_LRCPC)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 105, .name = "rcpc3", .llvm_name = "rcpc3", .description = "Enable Armv8.9-A RCPC instructions for A64 and Advanced SIMD and floating-point instruction set (FEAT_LRCPC3)", .dependencies = .{ .ints = .{ 0, 4398046511104, 0, 0, 0 } } },
            .{ .index = 106, .name = "rcpc_immo", .llvm_name = "rcpc-immo", .description = "Enable v8.4-A RCPC instructions with Immediate Offsets (FEAT_LRCPC2)", .dependencies = .{ .ints = .{ 0, 1099511627776, 0, 0, 0 } } },
            .{ .index = 107, .name = "rdm", .llvm_name = "rdm", .description = "Enable ARMv8.1 Rounding Double Multiply Add/Subtract instructions (FEAT_RDM)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 108, .name = "reserve_x1", .llvm_name = "reserve-x1", .description = "Reserve X1, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 109, .name = "reserve_x10", .llvm_name = "reserve-x10", .description = "Reserve X10, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 110, .name = "reserve_x11", .llvm_name = "reserve-x11", .description = "Reserve X11, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 111, .name = "reserve_x12", .llvm_name = "reserve-x12", .description = "Reserve X12, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 112, .name = "reserve_x13", .llvm_name = "reserve-x13", .description = "Reserve X13, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 113, .name = "reserve_x14", .llvm_name = "reserve-x14", .description = "Reserve X14, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 114, .name = "reserve_x15", .llvm_name = "reserve-x15", .description = "Reserve X15, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 115, .name = "reserve_x18", .llvm_name = "reserve-x18", .description = "Reserve X18, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 116, .name = "reserve_x2", .llvm_name = "reserve-x2", .description = "Reserve X2, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 117, .name = "reserve_x20", .llvm_name = "reserve-x20", .description = "Reserve X20, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 118, .name = "reserve_x21", .llvm_name = "reserve-x21", .description = "Reserve X21, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 119, .name = "reserve_x22", .llvm_name = "reserve-x22", .description = "Reserve X22, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 120, .name = "reserve_x23", .llvm_name = "reserve-x23", .description = "Reserve X23, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 121, .name = "reserve_x24", .llvm_name = "reserve-x24", .description = "Reserve X24, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 122, .name = "reserve_x25", .llvm_name = "reserve-x25", .description = "Reserve X25, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 123, .name = "reserve_x26", .llvm_name = "reserve-x26", .description = "Reserve X26, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 124, .name = "reserve_x27", .llvm_name = "reserve-x27", .description = "Reserve X27, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 125, .name = "reserve_x28", .llvm_name = "reserve-x28", .description = "Reserve X28, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 126, .name = "reserve_x3", .llvm_name = "reserve-x3", .description = "Reserve X3, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 127, .name = "reserve_x30", .llvm_name = "reserve-x30", .description = "Reserve X30, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 128, .name = "reserve_x4", .llvm_name = "reserve-x4", .description = "Reserve X4, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 129, .name = "reserve_x5", .llvm_name = "reserve-x5", .description = "Reserve X5, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 130, .name = "reserve_x6", .llvm_name = "reserve-x6", .description = "Reserve X6, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 131, .name = "reserve_x7", .llvm_name = "reserve-x7", .description = "Reserve X7, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 132, .name = "reserve_x9", .llvm_name = "reserve-x9", .description = "Reserve X9, making it unavailable as a GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 133, .name = "rme", .llvm_name = "rme", .description = "Enable Realm Management Extension (FEAT_RME)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 134, .name = "sb", .llvm_name = "sb", .description = "Enable v8.5 Speculation Barrier (FEAT_SB)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 135, .name = "sel2", .llvm_name = "sel2", .description = "Enable v8.4-A Secure Exception Level 2 extension (FEAT_SEL2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 136, .name = "sha2", .llvm_name = "sha2", .description = "Enable SHA1 and SHA256 support (FEAT_SHA1, FEAT_SHA256)", .dependencies = .{ .ints = .{ 0, 8388608, 0, 0, 0 } } },
            .{ .index = 137, .name = "sha3", .llvm_name = "sha3", .description = "Enable SHA512 and SHA3 support (FEAT_SHA3, FEAT_SHA512)", .dependencies = .{ .ints = .{ 0, 0, 256, 0, 0 } } },
            .{ .index = 138, .name = "slow_misaligned_128store", .llvm_name = "slow-misaligned-128store", .description = "Misaligned 128 bit stores are slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 139, .name = "slow_paired_128", .llvm_name = "slow-paired-128", .description = "Paired 128 bit loads and stores are slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 140, .name = "slow_strqro_store", .llvm_name = "slow-strqro-store", .description = "STR of Q register with register offset is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 141, .name = "sm4", .llvm_name = "sm4", .description = "Enable SM3 and SM4 support (FEAT_SM4, FEAT_SM3)", .dependencies = .{ .ints = .{ 0, 8388608, 0, 0, 0 } } },
            .{ .index = 142, .name = "sme", .llvm_name = "sme", .description = "Enable Scalable Matrix Extension (SME) (FEAT_SME)", .dependencies = .{ .ints = .{ 131072, 0, 70368744177664, 0, 0 } } },
            .{ .index = 143, .name = "sme2", .llvm_name = "sme2", .description = "Enable Scalable Matrix Extension 2 (SME2) instructions", .dependencies = .{ .ints = .{ 0, 0, 16384, 0, 0 } } },
            .{ .index = 144, .name = "sme2p1", .llvm_name = "sme2p1", .description = "Enable Scalable Matrix Extension 2.1 (FEAT_SME2p1) instructions", .dependencies = .{ .ints = .{ 0, 0, 32768, 0, 0 } } },
            .{ .index = 145, .name = "sme_f16f16", .llvm_name = "sme-f16f16", .description = "Enable SME2.1 non-widening Float16 instructions (FEAT_SME_F16F16)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 146, .name = "sme_f64f64", .llvm_name = "sme-f64f64", .description = "Enable Scalable Matrix Extension (SME) F64F64 instructions (FEAT_SME_F64F64)", .dependencies = .{ .ints = .{ 0, 0, 16384, 0, 0 } } },
            .{ .index = 147, .name = "sme_i16i64", .llvm_name = "sme-i16i64", .description = "Enable Scalable Matrix Extension (SME) I16I64 instructions (FEAT_SME_I16I64)", .dependencies = .{ .ints = .{ 0, 0, 16384, 0, 0 } } },
            .{ .index = 148, .name = "spe", .llvm_name = "spe", .description = "Enable Statistical Profiling extension (FEAT_SPE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 149, .name = "spe_eef", .llvm_name = "spe-eef", .description = "Enable extra register in the Statistical Profiling Extension (FEAT_SPEv1p2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 150, .name = "specres2", .llvm_name = "specres2", .description = "Enable Speculation Restriction Instruction (FEAT_SPECRES2)", .dependencies = .{ .ints = .{ 0, 34359738368, 0, 0, 0 } } },
            .{ .index = 151, .name = "specrestrict", .llvm_name = "specrestrict", .description = "Enable architectural speculation restriction (FEAT_CSV2_2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 152, .name = "ssbs", .llvm_name = "ssbs", .description = "Enable Speculative Store Bypass Safe bit (FEAT_SSBS, FEAT_SSBS2)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 153, .name = "strict_align", .llvm_name = "strict-align", .description = "Disallow all unaligned memory access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 154, .name = "sve", .llvm_name = "sve", .description = "Enable Scalable Vector Extension (SVE) instructions (FEAT_SVE)", .dependencies = .{ .ints = .{ 2305843009213693952, 0, 0, 0, 0 } } },
            .{ .index = 155, .name = "sve2", .llvm_name = "sve2", .description = "Enable Scalable Vector Extension 2 (SVE2) instructions (FEAT_SVE2)", .dependencies = .{ .ints = .{ 0, 0, 70368811286528, 0, 0 } } },
            .{ .index = 156, .name = "sve2_aes", .llvm_name = "sve2-aes", .description = "Enable AES SVE2 instructions (FEAT_SVE_AES, FEAT_SVE_PMULL128)", .dependencies = .{ .ints = .{ 64, 0, 134217728, 0, 0 } } },
            .{ .index = 157, .name = "sve2_bitperm", .llvm_name = "sve2-bitperm", .description = "Enable bit permutation SVE2 instructions (FEAT_SVE_BitPerm)", .dependencies = .{ .ints = .{ 0, 0, 134217728, 0, 0 } } },
            .{ .index = 158, .name = "sve2_sha3", .llvm_name = "sve2-sha3", .description = "Enable SHA3 SVE2 instructions (FEAT_SVE_SHA3)", .dependencies = .{ .ints = .{ 0, 0, 134218240, 0, 0 } } },
            .{ .index = 159, .name = "sve2_sm4", .llvm_name = "sve2-sm4", .description = "Enable SM4 SVE2 instructions (FEAT_SVE_SM4)", .dependencies = .{ .ints = .{ 0, 0, 134225920, 0, 0 } } },
            .{ .index = 160, .name = "sve2p1", .llvm_name = "sve2p1", .description = "Enable Scalable Vector Extension 2.1 instructions", .dependencies = .{ .ints = .{ 0, 0, 134217728, 0, 0 } } },
            .{ .index = 161, .name = "tagged_globals", .llvm_name = "tagged-globals", .description = "Use an instruction sequence for taking the address of a global that allows a memory tag in the upper address bits", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 162, .name = "the", .llvm_name = "the", .description = "Enable Armv8.9-A Translation Hardening Extension (FEAT_THE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 163, .name = "tlb_rmi", .llvm_name = "tlb-rmi", .description = "Enable v8.4-A TLB Range and Maintenance Instructions (FEAT_TLBIOS, FEAT_TLBIRANGE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 164, .name = "tme", .llvm_name = "tme", .description = "Enable Transactional Memory Extension (FEAT_TME)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 165, .name = "tpidr_el1", .llvm_name = "tpidr-el1", .description = "Permit use of TPIDR_EL1 for the TLS base", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 166, .name = "tpidr_el2", .llvm_name = "tpidr-el2", .description = "Permit use of TPIDR_EL2 for the TLS base", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 167, .name = "tpidr_el3", .llvm_name = "tpidr-el3", .description = "Permit use of TPIDR_EL3 for the TLS base", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 168, .name = "tracev8_4", .llvm_name = "tracev8.4", .description = "Enable v8.4-A Trace extension (FEAT_TRF)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 169, .name = "trbe", .llvm_name = "trbe", .description = "Enable Trace Buffer Extension (FEAT_TRBE)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 170, .name = "uaops", .llvm_name = "uaops", .description = "Enable v8.2 UAO PState (FEAT_UAO)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 171, .name = "use_experimental_zeroing_pseudos", .llvm_name = "use-experimental-zeroing-pseudos", .description = "Hint to the compiler that the MOVPRFX instruction is merged with destructive operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 172, .name = "use_postra_scheduler", .llvm_name = "use-postra-scheduler", .description = "Schedule again after register allocation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 173, .name = "use_reciprocal_square_root", .llvm_name = "use-reciprocal-square-root", .description = "Use the reciprocal square root approximation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 174, .name = "use_scalar_inc_vl", .llvm_name = "use-scalar-inc-vl", .description = "Prefer inc/dec over add+cnt", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 175, .name = "v8_1a", .llvm_name = "v8.1a", .description = "Support ARM v8.1a instructions", .dependencies = .{ .ints = .{ 137438953472, 8797166804992, 9295429630892703744, 0, 0 } } },
            .{ .index = 176, .name = "v8_2a", .llvm_name = "v8.2a", .description = "Support ARM v8.2a instructions", .dependencies = .{ .ints = .{ 2147483648, 277025390592, 145135534866432, 0, 0 } } },
            .{ .index = 177, .name = "v8_3a", .llvm_name = "v8.3a", .description = "Support ARM v8.3a instructions", .dependencies = .{ .ints = .{ 18253611008, 1103806599168, 281474976710656, 0, 0 } } },
            .{ .index = 178, .name = "v8_4a", .llvm_name = "v8.4a", .description = "Support ARM v8.4a instructions", .dependencies = .{ .ints = .{ 36055185298031616, 4398317174784, 564083824787584, 0, 0 } } },
            .{ .index = 179, .name = "v8_5a", .llvm_name = "v8.5a", .description = "Support ARM v8.5a instructions", .dependencies = .{ .ints = .{ 1152921505144242688, 34359738368, 1125899932008512, 0, 0 } } },
            .{ .index = 180, .name = "v8_6a", .llvm_name = "v8.6a", .description = "Support ARM v8.6a instructions", .dependencies = .{ .ints = .{ 9042383626962944, 1024, 2251799813685248, 0, 0 } } },
            .{ .index = 181, .name = "v8_7a", .llvm_name = "v8.7a", .description = "Support ARM v8.7a instructions", .dependencies = .{ .ints = .{ 0, 512, 4503599627370496, 3, 0 } } },
            .{ .index = 182, .name = "v8_8a", .llvm_name = "v8.8a", .description = "Support ARM v8.8a instructions", .dependencies = .{ .ints = .{ 0, 17826048, 9007199254740992, 0, 0 } } },
            .{ .index = 183, .name = "v8_9a", .llvm_name = "v8.9a", .description = "Support ARM v8.9a instructions", .dependencies = .{ .ints = .{ 554050781184, 618475290624, 18014398513676288, 0, 0 } } },
            .{ .index = 184, .name = "v8a", .llvm_name = "v8a", .description = "Support ARM v8.0a instructions", .dependencies = .{ .ints = .{ 211106232532992, 8388608, 0, 0, 0 } } },
            .{ .index = 185, .name = "v8r", .llvm_name = "v8r", .description = "Support ARM v8r instructions", .dependencies = .{ .ints = .{ 36055377497817088, 13475459928064, 5531926265984, 0, 0 } } },
            .{ .index = 186, .name = "v9_1a", .llvm_name = "v9.1a", .description = "Support ARM v9.1a instructions", .dependencies = .{ .ints = .{ 0, 0, 4616189618054758400, 0, 0 } } },
            .{ .index = 187, .name = "v9_2a", .llvm_name = "v9.2a", .description = "Support ARM v9.2a instructions", .dependencies = .{ .ints = .{ 0, 0, 297237575406452736, 0, 0 } } },
            .{ .index = 188, .name = "v9_3a", .llvm_name = "v9.3a", .description = "Support ARM v9.3a instructions", .dependencies = .{ .ints = .{ 0, 0, 594475150812905472, 0, 0 } } },
            .{ .index = 189, .name = "v9_4a", .llvm_name = "v9.4a", .description = "Support ARM v9.4a instructions", .dependencies = .{ .ints = .{ 0, 0, 1188950301625810944, 0, 0 } } },
            .{ .index = 190, .name = "v9a", .llvm_name = "v9a", .description = "Support ARM v9a instructions", .dependencies = .{ .ints = .{ 0, 524288, 2251799947902976, 0, 0 } } },
            .{ .index = 191, .name = "vh", .llvm_name = "vh", .description = "Enables ARM v8.1 Virtual Host extension (FEAT_VHE)", .dependencies = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } },
            .{ .index = 192, .name = "wfxt", .llvm_name = "wfxt", .description = "Enable Armv8.7-A WFET and WFIT instruction (FEAT_WFxT)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 193, .name = "xs", .llvm_name = "xs", .description = "Enable Armv8.7-A limited-TLB-maintenance instruction (FEAT_XS)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 194, .name = "zcm", .llvm_name = "zcm", .description = "Has zero-cycle register moves", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 195, .name = "zcz", .llvm_name = "zcz", .description = "Has zero-cycle zeroing instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 32, 0 } } },
            .{ .index = 196, .name = "zcz_fp_workaround", .llvm_name = "zcz-fp-workaround", .description = "The zero-cycle floating-point zeroing instruction has a bug", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 197, .name = "zcz_gp", .llvm_name = "zcz-gp", .description = "Has zero-cycle zeroing instructions for generic registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const a64fx: Cpu = .{ .name = "a64fx", .llvm_name = "a64fx", .features = .{ .ints = .{ 17179873408, 25769803776, 299067229864192, 0, 0 } } };
            const ampere1: Cpu = .{ .name = "ampere1", .llvm_name = "ampere1", .features = .{ .ints = .{ 4611686027017326784, 146029150225, 4521191813415424, 0, 0 } } };
            const ampere1a: Cpu = .{ .name = "ampere1a", .llvm_name = "ampere1a", .features = .{ .ints = .{ 4611686027017326784, 146033344529, 4521191813423616, 0, 0 } } };
            const apple_a10: Cpu = .{ .name = "apple_a10", .llvm_name = "apple-a10", .features = .{ .ints = .{ 4810363384064, 8805756706821, 9295429630892703744, 12, 0 } } };
            const apple_a11: Cpu = .{ .name = "apple_a11", .llvm_name = "apple-a11", .features = .{ .ints = .{ 2305847682138124544, 8589934597, 281474976710656, 12, 0 } } };
            const apple_a12: Cpu = .{ .name = "apple_a12", .llvm_name = "apple-a12", .features = .{ .ints = .{ 2305847682138124544, 8589934597, 562949953421312, 12, 0 } } };
            const apple_a13: Cpu = .{ .name = "apple_a13", .llvm_name = "apple-a13", .features = .{ .ints = .{ 288235049076142336, 8589934597, 1125899906843136, 12, 0 } } };
            const apple_a14: Cpu = .{ .name = "apple_a14", .llvm_name = "apple-a14", .features = .{ .ints = .{ 15276214609502024576, 42949672991, 1125899932009024, 12, 0 } } };
            const apple_a15: Cpu = .{ .name = "apple_a15", .llvm_name = "apple-a15", .features = .{ .ints = .{ 4899921067503530240, 8589934623, 4503599627371008, 12, 0 } } };
            const apple_a16: Cpu = .{ .name = "apple_a16", .llvm_name = "apple-a16", .features = .{ .ints = .{ 4899921067503530240, 8589935135, 4503599627371008, 12, 0 } } };
            const apple_a7: Cpu = .{ .name = "apple_a7", .llvm_name = "apple-a7", .features = .{ .ints = .{ 4672924430592, 8589934597, 72057594037927936, 28, 0 } } };
            const apple_a8: Cpu = .{ .name = "apple_a8", .llvm_name = "apple-a8", .features = .{ .ints = .{ 4672924430592, 8589934597, 72057594037927936, 28, 0 } } };
            const apple_a9: Cpu = .{ .name = "apple_a9", .llvm_name = "apple-a9", .features = .{ .ints = .{ 4672924430592, 8589934597, 72057594037927936, 28, 0 } } };
            const apple_latest: Cpu = .{ .name = "apple_latest", .llvm_name = "apple-latest", .features = .{ .ints = .{ 4899921067503530240, 8589935135, 4503599627371008, 12, 0 } } };
            const apple_m1: Cpu = .{ .name = "apple_m1", .llvm_name = "apple-m1", .features = .{ .ints = .{ 15276214609502024576, 42949672991, 1125899932009024, 12, 0 } } };
            const apple_m2: Cpu = .{ .name = "apple_m2", .llvm_name = "apple-m2", .features = .{ .ints = .{ 4899921067503530240, 8589934623, 4503599627371008, 12, 0 } } };
            const apple_s4: Cpu = .{ .name = "apple_s4", .llvm_name = "apple-s4", .features = .{ .ints = .{ 2305847682138124544, 8589934597, 562949953421312, 12, 0 } } };
            const apple_s5: Cpu = .{ .name = "apple_s5", .llvm_name = "apple-s5", .features = .{ .ints = .{ 2305847682138124544, 8589934597, 562949953421312, 12, 0 } } };
            const carmel: Cpu = .{ .name = "carmel", .llvm_name = "carmel", .features = .{ .ints = .{ 2305843284091600896, 0, 281474976710656, 0, 0 } } };
            const cortex_a34: Cpu = .{ .name = "cortex_a34", .llvm_name = "cortex-a34", .features = .{ .ints = .{ 412316860416, 8589934592, 72057594037927936, 0, 0 } } };
            const cortex_a35: Cpu = .{ .name = "cortex_a35", .llvm_name = "cortex-a35", .features = .{ .ints = .{ 412316860416, 8589934592, 72057594037927936, 0, 0 } } };
            const cortex_a510: Cpu = .{ .name = "cortex_a510", .llvm_name = "cortex-a510", .features = .{ .ints = .{ 288793326105264129, 8594129920, 4611686018964258816, 0, 0 } } };
            const cortex_a53: Cpu = .{ .name = "cortex_a53", .llvm_name = "cortex-a53", .features = .{ .ints = .{ 9223373548683329536, 8589934593, 72075186223972352, 0, 0 } } };
            const cortex_a55: Cpu = .{ .name = "cortex_a55", .llvm_name = "cortex-a55", .features = .{ .ints = .{ 16140918931559809024, 1108101562369, 299067162755072, 0, 0 } } };
            const cortex_a57: Cpu = .{ .name = "cortex_a57", .llvm_name = "cortex-a57", .features = .{ .ints = .{ 9223655023660040192, 25769803793, 72075186223972352, 0, 0 } } };
            const cortex_a65: Cpu = .{ .name = "cortex_a65", .llvm_name = "cortex-a65", .features = .{ .ints = .{ 2305860876277645314, 1108101562368, 281474993487872, 0, 0 } } };
            const cortex_a65ae: Cpu = .{ .name = "cortex_a65ae", .llvm_name = "cortex-a65ae", .features = .{ .ints = .{ 2305860876277645314, 1108101562368, 281474993487872, 0, 0 } } };
            const cortex_a710: Cpu = .{ .name = "cortex_a710", .llvm_name = "cortex-a710", .features = .{ .ints = .{ 288793326105264132, 8594129920, 4611686018964258816, 0, 0 } } };
            const cortex_a715: Cpu = .{ .name = "cortex_a715", .llvm_name = "cortex-a715", .features = .{ .ints = .{ 9512446846526685184, 8594392065, 4611703611151351808, 0, 0 } } };
            const cortex_a72: Cpu = .{ .name = "cortex_a72", .llvm_name = "cortex-a72", .features = .{ .ints = .{ 9223653924148346880, 8589934609, 72057594037927936, 0, 0 } } };
            const cortex_a73: Cpu = .{ .name = "cortex_a73", .llvm_name = "cortex-a73", .features = .{ .ints = .{ 9223653924148346880, 8589934593, 72057594037927936, 0, 0 } } };
            const cortex_a75: Cpu = .{ .name = "cortex_a75", .llvm_name = "cortex-a75", .features = .{ .ints = .{ 11529514388109131776, 1108101562369, 281474976710656, 0, 0 } } };
            const cortex_a76: Cpu = .{ .name = "cortex_a76", .llvm_name = "cortex-a76", .features = .{ .ints = .{ 2305860876277645320, 1108101562368, 281474993487872, 0, 0 } } };
            const cortex_a76ae: Cpu = .{ .name = "cortex_a76ae", .llvm_name = "cortex-a76ae", .features = .{ .ints = .{ 2305860876277645320, 1108101562368, 281474993487872, 0, 0 } } };
            const cortex_a77: Cpu = .{ .name = "cortex_a77", .llvm_name = "cortex-a77", .features = .{ .ints = .{ 11529514396699066368, 1108101824513, 281474993487872, 0, 0 } } };
            const cortex_a78: Cpu = .{ .name = "cortex_a78", .llvm_name = "cortex-a78", .features = .{ .ints = .{ 2305860876277645328, 1108101562368, 281474994536448, 0, 0 } } };
            const cortex_a78c: Cpu = .{ .name = "cortex_a78c", .llvm_name = "cortex-a78c", .features = .{ .ints = .{ 324277040234627104, 1112396529664, 281474994536448, 0, 0 } } };
            const cortex_r82: Cpu = .{ .name = "cortex_r82", .llvm_name = "cortex-r82", .features = .{ .ints = .{ 288230444871188480, 42949672960, 144115188092633152, 0, 0 } } };
            const cortex_x1: Cpu = .{ .name = "cortex_x1", .llvm_name = "cortex-x1", .features = .{ .ints = .{ 11529514396699066368, 1108101824513, 299067180580864, 0, 0 } } };
            const cortex_x1c: Cpu = .{ .name = "cortex_x1c", .llvm_name = "cortex-x1c", .features = .{ .ints = .{ 11565543193718030336, 4410931806209, 299067180580864, 0, 0 } } };
            const cortex_x2: Cpu = .{ .name = "cortex_x2", .llvm_name = "cortex-x2", .features = .{ .ints = .{ 9512446846526685184, 8594392065, 4611703611150303232, 0, 0 } } };
            const cortex_x3: Cpu = .{ .name = "cortex_x3", .llvm_name = "cortex-x3", .features = .{ .ints = .{ 9512446837936750592, 8594392065, 4611703611151351808, 0, 0 } } };
            const cyclone: Cpu = .{ .name = "cyclone", .llvm_name = "cyclone", .features = .{ .ints = .{ 4672924430592, 8589934597, 72057594037927936, 28, 0 } } };
            const emag: Cpu = .{ .name = "emag", .llvm_name = null, .features = .{ .ints = .{ 412316860416, 8589934592, 72057594037927936, 0, 0 } } };
            const exynos_m1: Cpu = .{ .name = "exynos_m1", .llvm_name = null, .features = .{ .ints = .{ 145241500299558912, 8589934593, 72110370596064256, 0, 0 } } };
            const exynos_m2: Cpu = .{ .name = "exynos_m2", .llvm_name = null, .features = .{ .ints = .{ 145241500299558912, 8589934593, 72075186223975424, 0, 0 } } };
            const exynos_m3: Cpu = .{ .name = "exynos_m3", .llvm_name = "exynos-m3", .features = .{ .ints = .{ 13980299555581722624, 25770065945, 72075186223972352, 0, 0 } } };
            const exynos_m4: Cpu = .{ .name = "exynos_m4", .llvm_name = "exynos-m4", .features = .{ .ints = .{ 16286160019542519808, 8590196763, 299067162755072, 8, 0 } } };
            const exynos_m5: Cpu = .{ .name = "exynos_m5", .llvm_name = "exynos-m5", .features = .{ .ints = .{ 16286160019542519808, 8590196763, 299067162755072, 8, 0 } } };
            const falkor: Cpu = .{ .name = "falkor", .llvm_name = "falkor", .features = .{ .ints = .{ 1511828488192, 8821863088128, 72075186223976448, 8, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 9224216461784907776, 8388609, 17592186044416, 0, 0 } } };
            const kryo: Cpu = .{ .name = "kryo", .llvm_name = "kryo", .features = .{ .ints = .{ 1511828488192, 25770065920, 72075186223972352, 8, 0 } } };
            const neoverse_512tvb: Cpu = .{ .name = "neoverse_512tvb", .llvm_name = "neoverse-512tvb", .features = .{ .ints = .{ 9511884163398107136, 146029151233, 1143492177821696, 0, 0 } } };
            const neoverse_e1: Cpu = .{ .name = "neoverse_e1", .llvm_name = "neoverse-e1", .features = .{ .ints = .{ 11529232913132421120, 1108101562369, 299067179532288, 0, 0 } } };
            const neoverse_n1: Cpu = .{ .name = "neoverse_n1", .llvm_name = "neoverse-n1", .features = .{ .ints = .{ 11529514388109131776, 1108101824513, 299067180580864, 0, 0 } } };
            const neoverse_n2: Cpu = .{ .name = "neoverse_n2", .llvm_name = "neoverse-n2", .features = .{ .ints = .{ 9224216736662945792, 8594392065, 2269392536600576, 0, 0 } } };
            const neoverse_v1: Cpu = .{ .name = "neoverse_v1", .llvm_name = "neoverse-v1", .features = .{ .ints = .{ 9511884163398107136, 146029151233, 1143492177821696, 0, 0 } } };
            const neoverse_v2: Cpu = .{ .name = "neoverse_v2", .llvm_name = "neoverse-v2", .features = .{ .ints = .{ 289074801081974784, 146033345537, 4611703611151351808, 0, 0 } } };
            const saphira: Cpu = .{ .name = "saphira", .llvm_name = "saphira", .features = .{ .ints = .{ 1374389534720, 25770065920, 1143492093935616, 8, 0 } } };
            const thunderx: Cpu = .{ .name = "thunderx", .llvm_name = "thunderx", .features = .{ .ints = .{ 412316860416, 25769803776, 72075186223972352, 0, 0 } } };
            const thunderx2t99: Cpu = .{ .name = "thunderx2t99", .llvm_name = "thunderx2t99", .features = .{ .ints = .{ 274877911168, 17179869184, 158329674399744, 0, 0 } } };
            const thunderx3t110: Cpu = .{ .name = "thunderx3t110", .llvm_name = "thunderx3t110", .features = .{ .ints = .{ 274877976704, 25769803776, 580542173020160, 0, 0 } } };
            const thunderxt81: Cpu = .{ .name = "thunderxt81", .llvm_name = "thunderxt81", .features = .{ .ints = .{ 412316860416, 25769803776, 72075186223972352, 0, 0 } } };
            const thunderxt83: Cpu = .{ .name = "thunderxt83", .llvm_name = "thunderxt83", .features = .{ .ints = .{ 412316860416, 25769803776, 72075186223972352, 0, 0 } } };
            const thunderxt88: Cpu = .{ .name = "thunderxt88", .llvm_name = "thunderxt88", .features = .{ .ints = .{ 412316860416, 25769803776, 72075186223972352, 0, 0 } } };
            const tsv110: Cpu = .{ .name = "tsv110", .llvm_name = "tsv110", .features = .{ .ints = .{ 288249342727290880, 8589934593, 299067163803648, 0, 0 } } };
            const xgene1: Cpu = .{ .name = "xgene1", .llvm_name = null, .features = .{ .ints = .{ 0, 8589934592, 72057594037927936, 0, 0 } } };
        };
    };
    pub const arc = struct {
        pub const Feature = enum(u0) {
            norm = 0,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "norm", .llvm_name = "norm", .description = "Enable support for norm instruction.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
    pub const amdgpu = struct {
        pub const Feature = enum(u8) {
            @"16_bit_insts" = 0,
            a16 = 1,
            add_no_carry_insts = 2,
            aperture_regs = 3,
            architected_flat_scratch = 4,
            atomic_fadd_no_rtn_insts = 5,
            atomic_fadd_rtn_insts = 6,
            atomic_pk_fadd_no_rtn_insts = 7,
            auto_waitcnt_before_barrier = 8,
            back_off_barrier = 9,
            ci_insts = 10,
            cumode = 11,
            dl_insts = 12,
            dot1_insts = 13,
            dot2_insts = 14,
            dot3_insts = 15,
            dot4_insts = 16,
            dot5_insts = 17,
            dot6_insts = 18,
            dot7_insts = 19,
            dot8_insts = 20,
            dot9_insts = 21,
            dpp = 22,
            dpp8 = 23,
            dpp_64bit = 24,
            ds128 = 25,
            ds_src2_insts = 26,
            extended_image_insts = 27,
            fast_denormal_f32 = 28,
            fast_fmaf = 29,
            flat_address_space = 30,
            flat_atomic_fadd_f32_inst = 31,
            flat_for_global = 32,
            flat_global_insts = 33,
            flat_inst_offsets = 34,
            flat_scratch = 35,
            flat_scratch_insts = 36,
            flat_segment_offset_bug = 37,
            fma_mix_insts = 38,
            fmacf64_inst = 39,
            fmaf = 40,
            fp64 = 41,
            fp8_insts = 42,
            full_rate_64_ops = 43,
            g16 = 44,
            gcn3_encoding = 45,
            get_wave_id_inst = 46,
            gfx10 = 47,
            gfx10_3_insts = 48,
            gfx10_a_encoding = 49,
            gfx10_b_encoding = 50,
            gfx10_insts = 51,
            gfx11 = 52,
            gfx11_full_vgprs = 53,
            gfx11_insts = 54,
            gfx7_gfx8_gfx9_insts = 55,
            gfx8_insts = 56,
            gfx9 = 57,
            gfx90a_insts = 58,
            gfx940_insts = 59,
            gfx9_insts = 60,
            half_rate_64_ops = 61,
            image_gather4_d16_bug = 62,
            image_insts = 63,
            image_store_d16_bug = 64,
            inst_fwd_prefetch_bug = 65,
            int_clamp_insts = 66,
            inv_2pi_inline_imm = 67,
            lds_branch_vmem_war_hazard = 68,
            lds_misaligned_bug = 69,
            ldsbankcount16 = 70,
            ldsbankcount32 = 71,
            load_store_opt = 72,
            localmemorysize32768 = 73,
            localmemorysize65536 = 74,
            mad_intra_fwd_bug = 75,
            mad_mac_f32_insts = 76,
            mad_mix_insts = 77,
            mai_insts = 78,
            max_private_element_size_16 = 79,
            max_private_element_size_4 = 80,
            max_private_element_size_8 = 81,
            mfma_inline_literal_bug = 82,
            mimg_r128 = 83,
            movrel = 84,
            negative_scratch_offset_bug = 85,
            negative_unaligned_scratch_offset_bug = 86,
            no_data_dep_hazard = 87,
            no_sdst_cmpx = 88,
            nsa_clause_bug = 89,
            nsa_encoding = 90,
            nsa_max_size_13 = 91,
            nsa_max_size_5 = 92,
            nsa_to_vmem_bug = 93,
            offset_3f_bug = 94,
            packed_fp32_ops = 95,
            packed_tid = 96,
            pk_fmac_f16_inst = 97,
            promote_alloca = 98,
            prt_strict_null = 99,
            r128_a16 = 100,
            s_memrealtime = 101,
            s_memtime_inst = 102,
            scalar_atomics = 103,
            scalar_flat_scratch_insts = 104,
            scalar_stores = 105,
            sdwa = 106,
            sdwa_mav = 107,
            sdwa_omod = 108,
            sdwa_out_mods_vopc = 109,
            sdwa_scalar = 110,
            sdwa_sdst = 111,
            sea_islands = 112,
            sgpr_init_bug = 113,
            shader_cycles_register = 114,
            si_scheduler = 115,
            smem_to_vector_write_hazard = 116,
            southern_islands = 117,
            sramecc = 118,
            sramecc_support = 119,
            tgsplit = 120,
            trap_handler = 121,
            trig_reduced_range = 122,
            true16 = 123,
            unaligned_access_mode = 124,
            unaligned_buffer_access = 125,
            unaligned_ds_access = 126,
            unaligned_scratch_access = 127,
            unpacked_d16_vmem = 128,
            unsafe_ds_offset_folding = 129,
            user_sgpr_init16_bug = 130,
            valu_trans_use_hazard = 131,
            vcmpx_exec_war_hazard = 132,
            vcmpx_permlane_hazard = 133,
            vgpr_index_mode = 134,
            vmem_to_scalar_write_hazard = 135,
            volcanic_islands = 136,
            vop3_literal = 137,
            vop3p = 138,
            vopd = 139,
            vscnt = 140,
            wavefrontsize16 = 141,
            wavefrontsize32 = 142,
            wavefrontsize64 = 143,
            xnack = 144,
            xnack_support = 145,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "16_bit_insts", .llvm_name = "16-bit-insts", .description = "Has i16/f16 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "a16", .llvm_name = "a16", .description = "Support A16 for 16-bit coordinates/gradients/lod/clamp/mip image operands", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "add_no_carry_insts", .llvm_name = "add-no-carry-insts", .description = "Have VALU add/sub instructions without carry out", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "aperture_regs", .llvm_name = "aperture-regs", .description = "Has Memory Aperture Base and Size Registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "architected_flat_scratch", .llvm_name = "architected-flat-scratch", .description = "Flat Scratch register is a readonly SPI initialized architected register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "atomic_fadd_no_rtn_insts", .llvm_name = "atomic-fadd-no-rtn-insts", .description = "Has buffer_atomic_add_f32 and global_atomic_add_f32 instructions that don't return original value", .dependencies = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "atomic_fadd_rtn_insts", .llvm_name = "atomic-fadd-rtn-insts", .description = "Has buffer_atomic_add_f32 and global_atomic_add_f32 instructions that return original value", .dependencies = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "atomic_pk_fadd_no_rtn_insts", .llvm_name = "atomic-pk-fadd-no-rtn-insts", .description = "Has buffer_atomic_pk_add_f16 and global_atomic_pk_add_f16 instructions that don't return original value", .dependencies = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "auto_waitcnt_before_barrier", .llvm_name = "auto-waitcnt-before-barrier", .description = "Hardware automatically inserts waitcnt before barrier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "back_off_barrier", .llvm_name = "back-off-barrier", .description = "Hardware supports backing off s_barrier if an exception occurs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "ci_insts", .llvm_name = "ci-insts", .description = "Additional instructions for CI+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "cumode", .llvm_name = "cumode", .description = "Enable CU wavefront execution mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "dl_insts", .llvm_name = "dl-insts", .description = "Has v_fmac_f32 and v_xnor_b32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "dot1_insts", .llvm_name = "dot1-insts", .description = "Has v_dot4_i32_i8 and v_dot8_i32_i4 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "dot2_insts", .llvm_name = "dot2-insts", .description = "Has v_dot2_i32_i16, v_dot2_u32_u16 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "dot3_insts", .llvm_name = "dot3-insts", .description = "Has v_dot8c_i32_i4 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "dot4_insts", .llvm_name = "dot4-insts", .description = "Has v_dot2c_i32_i16 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "dot5_insts", .llvm_name = "dot5-insts", .description = "Has v_dot2c_f32_f16 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "dot6_insts", .llvm_name = "dot6-insts", .description = "Has v_dot4c_i32_i8 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "dot7_insts", .llvm_name = "dot7-insts", .description = "Has v_dot2_f32_f16, v_dot4_u32_u8, v_dot8_u32_u4 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "dot8_insts", .llvm_name = "dot8-insts", .description = "Has v_dot4_i32_iu8, v_dot8_i32_iu4 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "dot9_insts", .llvm_name = "dot9-insts", .description = "Has v_dot2_f16_f16, v_dot2_bf16_bf16, v_dot2_f32_bf16 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "dpp", .llvm_name = "dpp", .description = "Support DPP (Data Parallel Primitives) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "dpp8", .llvm_name = "dpp8", .description = "Support DPP8 (Data Parallel Primitives) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "dpp_64bit", .llvm_name = "dpp-64bit", .description = "Support DPP (Data Parallel Primitives) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "ds128", .llvm_name = "enable-ds128", .description = "Use ds_{read|write}_b128", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "ds_src2_insts", .llvm_name = "ds-src2-insts", .description = "Has ds_*_src2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "extended_image_insts", .llvm_name = "extended-image-insts", .description = "Support mips != 0, lod != 0, gather4, and get_lod", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "fast_denormal_f32", .llvm_name = "fast-denormal-f32", .description = "Enabling denormals does not cause f32 instructions to run at f64 rates", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "fast_fmaf", .llvm_name = "fast-fmaf", .description = "Assuming f32 fma is at least as fast as mul + add", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "flat_address_space", .llvm_name = "flat-address-space", .description = "Support flat address space", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "flat_atomic_fadd_f32_inst", .llvm_name = "flat-atomic-fadd-f32-inst", .description = "Has flat_atomic_add_f32 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "flat_for_global", .llvm_name = "flat-for-global", .description = "Force to generate flat instruction for global", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "flat_global_insts", .llvm_name = "flat-global-insts", .description = "Have global_* flat memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "flat_inst_offsets", .llvm_name = "flat-inst-offsets", .description = "Flat instructions have immediate offset addressing mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "flat_scratch", .llvm_name = "enable-flat-scratch", .description = "Use scratch_* flat memory instructions to access scratch", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "flat_scratch_insts", .llvm_name = "flat-scratch-insts", .description = "Have scratch_* flat memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "flat_segment_offset_bug", .llvm_name = "flat-segment-offset-bug", .description = "GFX10 bug where inst_offset is ignored when flat instructions access global memory", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "fma_mix_insts", .llvm_name = "fma-mix-insts", .description = "Has v_fma_mix_f32, v_fma_mixlo_f16, v_fma_mixhi_f16 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "fmacf64_inst", .llvm_name = "fmacf64-inst", .description = "Has v_fmac_f64 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "fmaf", .llvm_name = "fmaf", .description = "Enable single precision FMA (not as fast as mul+add, but fused)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "fp64", .llvm_name = "fp64", .description = "Enable double precision operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "fp8_insts", .llvm_name = "fp8-insts", .description = "Has fp8 and bf8 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "full_rate_64_ops", .llvm_name = "full-rate-64-ops", .description = "Most fp64 instructions are full rate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "g16", .llvm_name = "g16", .description = "Support G16 for 16-bit gradient image operands", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "gcn3_encoding", .llvm_name = "gcn3-encoding", .description = "Encoding format for VI", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "get_wave_id_inst", .llvm_name = "get-wave-id-inst", .description = "Has s_get_waveid_in_workgroup instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "gfx10", .llvm_name = "gfx10", .description = "GFX10 GPU generation", .dependencies = .{ .ints = .{ 10450623097915573263, 6917762545039705100, 5632, 0, 0 } } },
            .{ .index = 48, .name = "gfx10_3_insts", .llvm_name = "gfx10-3-insts", .description = "Additional instructions for GFX10.3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "gfx10_a_encoding", .llvm_name = "gfx10_a-encoding", .description = "Has BVH ray tracing instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "gfx10_b_encoding", .llvm_name = "gfx10_b-encoding", .description = "Encoding format GFX10_B", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "gfx10_insts", .llvm_name = "gfx10-insts", .description = "Additional instructions for GFX10+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "gfx11", .llvm_name = "gfx11", .description = "GFX11 GPU generation", .dependencies = .{ .ints = .{ 1247235784407254031, 7493989788561179660, 7680, 0, 0 } } },
            .{ .index = 53, .name = "gfx11_full_vgprs", .llvm_name = "gfx11-full-vgprs", .description = "GFX11 with 50% more physical VGPRs and 50% larger allocation granule than GFX10", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "gfx11_insts", .llvm_name = "gfx11-insts", .description = "Additional instructions for GFX11+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "gfx7_gfx8_gfx9_insts", .llvm_name = "gfx7-gfx8-gfx9-insts", .description = "Instructions shared in GFX7, GFX8, GFX9", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "gfx8_insts", .llvm_name = "gfx8-insts", .description = "Additional instructions for GFX8+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "gfx9", .llvm_name = "gfx9", .description = "GFX9 GPU generation", .dependencies = .{ .ints = .{ 1261045375431607311, 6917766453435302924, 164928, 0, 0 } } },
            .{ .index = 58, .name = "gfx90a_insts", .llvm_name = "gfx90a-insts", .description = "Additional instructions for GFX90A+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "gfx940_insts", .llvm_name = "gfx940-insts", .description = "Additional instructions for GFX940+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "gfx9_insts", .llvm_name = "gfx9-insts", .description = "Additional instructions for GFX9+", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "half_rate_64_ops", .llvm_name = "half-rate-64-ops", .description = "Most fp64 instructions are half rate instead of quarter", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 62, .name = "image_gather4_d16_bug", .llvm_name = "image-gather4-d16-bug", .description = "Image Gather4 D16 hardware bug", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "image_insts", .llvm_name = "image-insts", .description = "Support image instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "image_store_d16_bug", .llvm_name = "image-store-d16-bug", .description = "Image Store D16 hardware bug", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 65, .name = "inst_fwd_prefetch_bug", .llvm_name = "inst-fwd-prefetch-bug", .description = "S_INST_PREFETCH instruction causes shader to hang", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 66, .name = "int_clamp_insts", .llvm_name = "int-clamp-insts", .description = "Support clamp for integer destination", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 67, .name = "inv_2pi_inline_imm", .llvm_name = "inv-2pi-inline-imm", .description = "Has 1 / (2 * pi) as inline immediate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 68, .name = "lds_branch_vmem_war_hazard", .llvm_name = "lds-branch-vmem-war-hazard", .description = "Switching between LDS and VMEM-tex not waiting VM_VSRC=0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 69, .name = "lds_misaligned_bug", .llvm_name = "lds-misaligned-bug", .description = "Some GFX10 bug with multi-dword LDS and flat access that is not naturally aligned in WGP mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 70, .name = "ldsbankcount16", .llvm_name = "ldsbankcount16", .description = "The number of LDS banks per compute unit.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 71, .name = "ldsbankcount32", .llvm_name = "ldsbankcount32", .description = "The number of LDS banks per compute unit.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 72, .name = "load_store_opt", .llvm_name = "load-store-opt", .description = "Enable SI load/store optimizer pass", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 73, .name = "localmemorysize32768", .llvm_name = "localmemorysize32768", .description = "The size of local memory in bytes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 74, .name = "localmemorysize65536", .llvm_name = "localmemorysize65536", .description = "The size of local memory in bytes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 75, .name = "mad_intra_fwd_bug", .llvm_name = "mad-intra-fwd-bug", .description = "MAD_U64/I64 intra instruction forwarding bug", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 76, .name = "mad_mac_f32_insts", .llvm_name = "mad-mac-f32-insts", .description = "Has v_mad_f32/v_mac_f32/v_madak_f32/v_madmk_f32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "mad_mix_insts", .llvm_name = "mad-mix-insts", .description = "Has v_mad_mix_f32, v_mad_mixlo_f16, v_mad_mixhi_f16 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 78, .name = "mai_insts", .llvm_name = "mai-insts", .description = "Has mAI instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 79, .name = "max_private_element_size_16", .llvm_name = "max-private-element-size-16", .description = "Maximum private access size may be 16", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 80, .name = "max_private_element_size_4", .llvm_name = "max-private-element-size-4", .description = "Maximum private access size may be 4", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 81, .name = "max_private_element_size_8", .llvm_name = "max-private-element-size-8", .description = "Maximum private access size may be 8", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 82, .name = "mfma_inline_literal_bug", .llvm_name = "mfma-inline-literal-bug", .description = "MFMA cannot use inline literal as SrcC", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 83, .name = "mimg_r128", .llvm_name = "mimg-r128", .description = "Support 128-bit texture resources", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 84, .name = "movrel", .llvm_name = "movrel", .description = "Has v_movrel*_b32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 85, .name = "negative_scratch_offset_bug", .llvm_name = "negative-scratch-offset-bug", .description = "Negative immediate offsets in scratch instructions with an SGPR offset page fault on GFX9", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 86, .name = "negative_unaligned_scratch_offset_bug", .llvm_name = "negative-unaligned-scratch-offset-bug", .description = "Scratch instructions with a VGPR offset and a negative immediate offset that is not a multiple of 4 read wrong memory on GFX10", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 87, .name = "no_data_dep_hazard", .llvm_name = "no-data-dep-hazard", .description = "Does not need SW waitstates", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 88, .name = "no_sdst_cmpx", .llvm_name = "no-sdst-cmpx", .description = "V_CMPX does not write VCC/SGPR in addition to EXEC", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 89, .name = "nsa_clause_bug", .llvm_name = "nsa-clause-bug", .description = "MIMG-NSA in a hard clause has unpredictable results on GFX10.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 90, .name = "nsa_encoding", .llvm_name = "nsa-encoding", .description = "Support NSA encoding for image instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 91, .name = "nsa_max_size_13", .llvm_name = "nsa-max-size-13", .description = "The maximum non-sequential address size in VGPRs.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 92, .name = "nsa_max_size_5", .llvm_name = "nsa-max-size-5", .description = "The maximum non-sequential address size in VGPRs.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 93, .name = "nsa_to_vmem_bug", .llvm_name = "nsa-to-vmem-bug", .description = "MIMG-NSA followed by VMEM fail if EXEC_LO or EXEC_HI equals zero", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 94, .name = "offset_3f_bug", .llvm_name = "offset-3f-bug", .description = "Branch offset of 3f hardware bug", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 95, .name = "packed_fp32_ops", .llvm_name = "packed-fp32-ops", .description = "Support packed fp32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 96, .name = "packed_tid", .llvm_name = "packed-tid", .description = "Workitem IDs are packed into v0 at kernel launch", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 97, .name = "pk_fmac_f16_inst", .llvm_name = "pk-fmac-f16-inst", .description = "Has v_pk_fmac_f16 instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 98, .name = "promote_alloca", .llvm_name = "promote-alloca", .description = "Enable promote alloca pass", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 99, .name = "prt_strict_null", .llvm_name = "enable-prt-strict-null", .description = "Enable zeroing of result registers for sparse texture fetches", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 100, .name = "r128_a16", .llvm_name = "r128-a16", .description = "Support gfx9-style A16 for 16-bit coordinates/gradients/lod/clamp/mip image operands, where a16 is aliased with r128", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 101, .name = "s_memrealtime", .llvm_name = "s-memrealtime", .description = "Has s_memrealtime instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 102, .name = "s_memtime_inst", .llvm_name = "s-memtime-inst", .description = "Has s_memtime instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 103, .name = "scalar_atomics", .llvm_name = "scalar-atomics", .description = "Has atomic scalar memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 104, .name = "scalar_flat_scratch_insts", .llvm_name = "scalar-flat-scratch-insts", .description = "Have s_scratch_* flat memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 105, .name = "scalar_stores", .llvm_name = "scalar-stores", .description = "Has store scalar memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 106, .name = "sdwa", .llvm_name = "sdwa", .description = "Support SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 107, .name = "sdwa_mav", .llvm_name = "sdwa-mav", .description = "Support v_mac_f32/f16 with SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 108, .name = "sdwa_omod", .llvm_name = "sdwa-omod", .description = "Support OMod with SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 109, .name = "sdwa_out_mods_vopc", .llvm_name = "sdwa-out-mods-vopc", .description = "Support clamp for VOPC with SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 110, .name = "sdwa_scalar", .llvm_name = "sdwa-scalar", .description = "Support scalar register with SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 111, .name = "sdwa_sdst", .llvm_name = "sdwa-sdst", .description = "Support scalar dst for VOPC with SDWA (Sub-DWORD Addressing) extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 112, .name = "sea_islands", .llvm_name = "sea-islands", .description = "SEA_ISLANDS GPU generation", .dependencies = .{ .ints = .{ 9259403034172064768, 2594073660244890624, 32768, 0, 0 } } },
            .{ .index = 113, .name = "sgpr_init_bug", .llvm_name = "sgpr-init-bug", .description = "VI SGPR initialization bug requiring a fixed SGPR allocation size", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 114, .name = "shader_cycles_register", .llvm_name = "shader-cycles-register", .description = "Has SHADER_CYCLES hardware register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 115, .name = "si_scheduler", .llvm_name = "si-scheduler", .description = "Enable SI Machine Scheduler", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 116, .name = "smem_to_vector_write_hazard", .llvm_name = "smem-to-vector-write-hazard", .description = "s_load_dword followed by v_cmp page faults", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 117, .name = "southern_islands", .llvm_name = "southern-islands", .description = "SOUTHERN_ISLANDS GPU generation", .dependencies = .{ .ints = .{ 9223374236079357952, 288230651031196288, 32768, 0, 0 } } },
            .{ .index = 118, .name = "sramecc", .llvm_name = "sramecc", .description = "Enable SRAMECC", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 119, .name = "sramecc_support", .llvm_name = "sramecc-support", .description = "Hardware supports SRAMECC", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 120, .name = "tgsplit", .llvm_name = "tgsplit", .description = "Enable threadgroup split execution", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 121, .name = "trap_handler", .llvm_name = "trap-handler", .description = "Trap handler support", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 122, .name = "trig_reduced_range", .llvm_name = "trig-reduced-range", .description = "Requires use of fract on arguments to trig instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 123, .name = "true16", .llvm_name = "true16", .description = "True 16-bit operand instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 124, .name = "unaligned_access_mode", .llvm_name = "unaligned-access-mode", .description = "Enable unaligned global, local and region loads and stores if the hardware supports it", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 125, .name = "unaligned_buffer_access", .llvm_name = "unaligned-buffer-access", .description = "Hardware supports unaligned global loads and stores", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 126, .name = "unaligned_ds_access", .llvm_name = "unaligned-ds-access", .description = "Hardware supports unaligned local and region loads and stores", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 127, .name = "unaligned_scratch_access", .llvm_name = "unaligned-scratch-access", .description = "Support unaligned scratch loads and stores", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 128, .name = "unpacked_d16_vmem", .llvm_name = "unpacked-d16-vmem", .description = "Has unpacked d16 vmem instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 129, .name = "unsafe_ds_offset_folding", .llvm_name = "unsafe-ds-offset-folding", .description = "Force using DS instruction immediate offsets on SI", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 130, .name = "user_sgpr_init16_bug", .llvm_name = "user-sgpr-init16-bug", .description = "Bug requiring at least 16 user+system SGPRs to be enabled", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 131, .name = "valu_trans_use_hazard", .llvm_name = "valu-trans-use-hazard", .description = "Hazard when TRANS instructions are closely followed by a use of the result", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 132, .name = "vcmpx_exec_war_hazard", .llvm_name = "vcmpx-exec-war-hazard", .description = "V_CMPX WAR hazard on EXEC (V_CMPX issue ONLY)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 133, .name = "vcmpx_permlane_hazard", .llvm_name = "vcmpx-permlane-hazard", .description = "TODO: describe me", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 134, .name = "vgpr_index_mode", .llvm_name = "vgpr-index-mode", .description = "Has VGPR mode register indexing", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 135, .name = "vmem_to_scalar_write_hazard", .llvm_name = "vmem-to-scalar-write-hazard", .description = "VMEM instruction followed by scalar writing to EXEC mask, M0 or SGPR leads to incorrect execution.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 136, .name = "volcanic_islands", .llvm_name = "volcanic-islands", .description = "VOLCANIC_ISLANDS GPU generation", .dependencies = .{ .ints = .{ 9331495812854711297, 2594124375218721804, 32832, 0, 0 } } },
            .{ .index = 137, .name = "vop3_literal", .llvm_name = "vop3-literal", .description = "Can use one literal in VOP3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 138, .name = "vop3p", .llvm_name = "vop3p", .description = "Has VOP3P packed instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 139, .name = "vopd", .llvm_name = "vopd", .description = "Has VOPD dual issue wave32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 140, .name = "vscnt", .llvm_name = "vscnt", .description = "Has separate store vscnt counter", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 141, .name = "wavefrontsize16", .llvm_name = "wavefrontsize16", .description = "The number of threads per wavefront", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 142, .name = "wavefrontsize32", .llvm_name = "wavefrontsize32", .description = "The number of threads per wavefront", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 143, .name = "wavefrontsize64", .llvm_name = "wavefrontsize64", .description = "The number of threads per wavefront", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 144, .name = "xnack", .llvm_name = "xnack", .description = "Enable XNACK support", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 145, .name = "xnack_support", .llvm_name = "xnack-support", .description = "Hardware supports XNACK", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const bonaire: Cpu = .{ .name = "bonaire", .llvm_name = "bonaire", .features = .{ .ints = .{ 0, 281474976710784, 0, 0, 0 } } };
            const carrizo: Cpu = .{ .name = "carrizo", .llvm_name = "carrizo", .features = .{ .ints = .{ 2305843009750564864, 128, 131329, 0, 0 } } };
            const fiji: Cpu = .{ .name = "fiji", .llvm_name = "fiji", .features = .{ .ints = .{ 0, 128, 257, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const generic_hsa: Cpu = .{ .name = "generic_hsa", .llvm_name = "generic-hsa", .features = .{ .ints = .{ 1073741824, 0, 32768, 0, 0 } } };
            const gfx1010: Cpu = .{ .name = "gfx1010", .llvm_name = "gfx1010", .features = .{ .ints = .{ 211243738599936, 4507449901977778, 147632, 0, 0 } } };
            const gfx1011: Cpu = .{ .name = "gfx1011", .llvm_name = "gfx1011", .features = .{ .ints = .{ 211243739542016, 4507449901977778, 147632, 0, 0 } } };
            const gfx1012: Cpu = .{ .name = "gfx1012", .llvm_name = "gfx1012", .features = .{ .ints = .{ 211243739542016, 4507449901977778, 147632, 0, 0 } } };
            const gfx1013: Cpu = .{ .name = "gfx1013", .llvm_name = "gfx1013", .features = .{ .ints = .{ 774193692021248, 4507449901977778, 147632, 0, 0 } } };
            const gfx1030: Cpu = .{ .name = "gfx1030", .llvm_name = "gfx1030", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1031: Cpu = .{ .name = "gfx1031", .llvm_name = "gfx1031", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1032: Cpu = .{ .name = "gfx1032", .llvm_name = "gfx1032", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1033: Cpu = .{ .name = "gfx1033", .llvm_name = "gfx1033", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1034: Cpu = .{ .name = "gfx1034", .llvm_name = "gfx1034", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1035: Cpu = .{ .name = "gfx1035", .llvm_name = "gfx1035", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1036: Cpu = .{ .name = "gfx1036", .llvm_name = "gfx1036", .features = .{ .ints = .{ 2111062326276608, 1125900108169344, 16384, 0, 0 } } };
            const gfx1100: Cpu = .{ .name = "gfx1100", .llvm_name = "gfx1100", .features = .{ .ints = .{ 9236882837888176240, 1125904537356416, 16428, 0, 0 } } };
            const gfx1101: Cpu = .{ .name = "gfx1101", .llvm_name = "gfx1101", .features = .{ .ints = .{ 9236882837888176240, 1125904537356416, 16424, 0, 0 } } };
            const gfx1102: Cpu = .{ .name = "gfx1102", .llvm_name = "gfx1102", .features = .{ .ints = .{ 9227875638633435248, 1125904537356416, 16428, 0, 0 } } };
            const gfx1103: Cpu = .{ .name = "gfx1103", .llvm_name = "gfx1103", .features = .{ .ints = .{ 9227875638633435248, 1125904537356416, 16424, 0, 0 } } };
            const gfx600: Cpu = .{ .name = "gfx600", .llvm_name = "gfx600", .features = .{ .ints = .{ 2305843009750564864, 9007199254740992, 0, 0, 0 } } };
            const gfx601: Cpu = .{ .name = "gfx601", .llvm_name = "gfx601", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
            const gfx602: Cpu = .{ .name = "gfx602", .llvm_name = "gfx602", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
            const gfx700: Cpu = .{ .name = "gfx700", .llvm_name = "gfx700", .features = .{ .ints = .{ 0, 281474976710784, 0, 0, 0 } } };
            const gfx701: Cpu = .{ .name = "gfx701", .llvm_name = "gfx701", .features = .{ .ints = .{ 2305843009750564864, 281474976710784, 0, 0, 0 } } };
            const gfx702: Cpu = .{ .name = "gfx702", .llvm_name = "gfx702", .features = .{ .ints = .{ 536870912, 281474976710720, 0, 0, 0 } } };
            const gfx703: Cpu = .{ .name = "gfx703", .llvm_name = "gfx703", .features = .{ .ints = .{ 0, 281474976710720, 0, 0, 0 } } };
            const gfx704: Cpu = .{ .name = "gfx704", .llvm_name = "gfx704", .features = .{ .ints = .{ 0, 281474976710784, 0, 0, 0 } } };
            const gfx705: Cpu = .{ .name = "gfx705", .llvm_name = "gfx705", .features = .{ .ints = .{ 0, 281474976710720, 0, 0, 0 } } };
            const gfx801: Cpu = .{ .name = "gfx801", .llvm_name = "gfx801", .features = .{ .ints = .{ 2305843009750564864, 128, 131329, 0, 0 } } };
            const gfx802: Cpu = .{ .name = "gfx802", .llvm_name = "gfx802", .features = .{ .ints = .{ 0, 562949953421440, 257, 0, 0 } } };
            const gfx803: Cpu = .{ .name = "gfx803", .llvm_name = "gfx803", .features = .{ .ints = .{ 0, 128, 257, 0, 0 } } };
            const gfx805: Cpu = .{ .name = "gfx805", .llvm_name = "gfx805", .features = .{ .ints = .{ 0, 562949953421440, 257, 0, 0 } } };
            const gfx810: Cpu = .{ .name = "gfx810", .llvm_name = "gfx810", .features = .{ .ints = .{ 4611686018427387904, 65, 131328, 0, 0 } } };
            const gfx900: Cpu = .{ .name = "gfx900", .llvm_name = "gfx900", .features = .{ .ints = .{ 13979173243559346176, 12416, 0, 0, 0 } } };
            const gfx902: Cpu = .{ .name = "gfx902", .llvm_name = "gfx902", .features = .{ .ints = .{ 13979173243559346176, 12416, 0, 0, 0 } } };
            const gfx904: Cpu = .{ .name = "gfx904", .llvm_name = "gfx904", .features = .{ .ints = .{ 13979173518437253120, 4224, 0, 0, 0 } } };
            const gfx906: Cpu = .{ .name = "gfx906", .llvm_name = "gfx906", .features = .{ .ints = .{ 16285016527651500032, 36028797018968192, 0, 0, 0 } } };
            const gfx908: Cpu = .{ .name = "gfx908", .llvm_name = "gfx908", .features = .{ .ints = .{ 16285016527651991712, 36028805609181312, 0, 0, 0 } } };
            const gfx909: Cpu = .{ .name = "gfx909", .llvm_name = "gfx909", .features = .{ .ints = .{ 13979173243559346176, 12416, 0, 0, 0 } } };
            const gfx90a: Cpu = .{ .name = "gfx90a", .llvm_name = "gfx90a", .features = .{ .ints = .{ 9655727221826908896, 36028812051370112, 0, 0, 0 } } };
            const gfx90c: Cpu = .{ .name = "gfx90c", .llvm_name = "gfx90c", .features = .{ .ints = .{ 13979173243559346176, 12416, 0, 0, 0 } } };
            const gfx940: Cpu = .{ .name = "gfx940", .llvm_name = "gfx940", .features = .{ .ints = .{ 1008820337469551344, 36028812051366016, 0, 0, 0 } } };
            const hainan: Cpu = .{ .name = "hainan", .llvm_name = "hainan", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
            const hawaii: Cpu = .{ .name = "hawaii", .llvm_name = "hawaii", .features = .{ .ints = .{ 2305843009750564864, 281474976710784, 0, 0, 0 } } };
            const iceland: Cpu = .{ .name = "iceland", .llvm_name = "iceland", .features = .{ .ints = .{ 0, 562949953421440, 257, 0, 0 } } };
            const kabini: Cpu = .{ .name = "kabini", .llvm_name = "kabini", .features = .{ .ints = .{ 0, 281474976710720, 0, 0, 0 } } };
            const kaveri: Cpu = .{ .name = "kaveri", .llvm_name = "kaveri", .features = .{ .ints = .{ 0, 281474976710784, 0, 0, 0 } } };
            const mullins: Cpu = .{ .name = "mullins", .llvm_name = "mullins", .features = .{ .ints = .{ 0, 281474976710720, 0, 0, 0 } } };
            const oland: Cpu = .{ .name = "oland", .llvm_name = "oland", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
            const pitcairn: Cpu = .{ .name = "pitcairn", .llvm_name = "pitcairn", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
            const polaris10: Cpu = .{ .name = "polaris10", .llvm_name = "polaris10", .features = .{ .ints = .{ 0, 128, 257, 0, 0 } } };
            const polaris11: Cpu = .{ .name = "polaris11", .llvm_name = "polaris11", .features = .{ .ints = .{ 0, 128, 257, 0, 0 } } };
            const stoney: Cpu = .{ .name = "stoney", .llvm_name = "stoney", .features = .{ .ints = .{ 4611686018427387904, 65, 131328, 0, 0 } } };
            const tahiti: Cpu = .{ .name = "tahiti", .llvm_name = "tahiti", .features = .{ .ints = .{ 2305843009750564864, 9007199254740992, 0, 0, 0 } } };
            const tonga: Cpu = .{ .name = "tonga", .llvm_name = "tonga", .features = .{ .ints = .{ 0, 562949953421440, 257, 0, 0 } } };
            const tongapro: Cpu = .{ .name = "tongapro", .llvm_name = "tongapro", .features = .{ .ints = .{ 0, 562949953421440, 257, 0, 0 } } };
            const verde: Cpu = .{ .name = "verde", .llvm_name = "verde", .features = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } };
        };
    };
    pub const arm = struct {
        pub const Feature = enum(u8) {
            @"32bit" = 0,
            @"8msecext" = 1,
            a76 = 2,
            aapcs_frame_chain = 3,
            aapcs_frame_chain_leaf = 4,
            aclass = 5,
            acquire_release = 6,
            aes = 7,
            atomics_32 = 8,
            avoid_movs_shop = 9,
            avoid_partial_cpsr = 10,
            bf16 = 11,
            big_endian_instructions = 12,
            cde = 13,
            cdecp0 = 14,
            cdecp1 = 15,
            cdecp2 = 16,
            cdecp3 = 17,
            cdecp4 = 18,
            cdecp5 = 19,
            cdecp6 = 20,
            cdecp7 = 21,
            cheap_predicable_cpsr = 22,
            clrbhb = 23,
            crc = 24,
            crypto = 25,
            d32 = 26,
            db = 27,
            dfb = 28,
            disable_postra_scheduler = 29,
            dont_widen_vmovs = 30,
            dotprod = 31,
            dsp = 32,
            execute_only = 33,
            expand_fp_mlx = 34,
            exynos = 35,
            fix_cmse_cve_2021_35465 = 36,
            fix_cortex_a57_aes_1742098 = 37,
            fp16 = 38,
            fp16fml = 39,
            fp64 = 40,
            fp_armv8 = 41,
            fp_armv8d16 = 42,
            fp_armv8d16sp = 43,
            fp_armv8sp = 44,
            fpao = 45,
            fpregs = 46,
            fpregs16 = 47,
            fpregs64 = 48,
            fullfp16 = 49,
            fuse_aes = 50,
            fuse_literals = 51,
            harden_sls_blr = 52,
            harden_sls_nocomdat = 53,
            harden_sls_retbr = 54,
            has_v4t = 55,
            has_v5t = 56,
            has_v5te = 57,
            has_v6 = 58,
            has_v6k = 59,
            has_v6m = 60,
            has_v6t2 = 61,
            has_v7 = 62,
            has_v7clrex = 63,
            has_v8 = 64,
            has_v8_1a = 65,
            has_v8_1m_main = 66,
            has_v8_2a = 67,
            has_v8_3a = 68,
            has_v8_4a = 69,
            has_v8_5a = 70,
            has_v8_6a = 71,
            has_v8_7a = 72,
            has_v8_8a = 73,
            has_v8_9a = 74,
            has_v8m = 75,
            has_v8m_main = 76,
            has_v9_1a = 77,
            has_v9_2a = 78,
            has_v9_3a = 79,
            has_v9_4a = 80,
            has_v9a = 81,
            hwdiv = 82,
            hwdiv_arm = 83,
            i8mm = 84,
            iwmmxt = 85,
            iwmmxt2 = 86,
            lob = 87,
            long_calls = 88,
            loop_align = 89,
            m3 = 90,
            mclass = 91,
            mp = 92,
            muxed_units = 93,
            mve = 94,
            mve1beat = 95,
            mve2beat = 96,
            mve4beat = 97,
            mve_fp = 98,
            nacl_trap = 99,
            neon = 100,
            neon_fpmovs = 101,
            neonfp = 102,
            no_branch_predictor = 103,
            no_bti_at_return_twice = 104,
            no_movt = 105,
            no_neg_immediates = 106,
            noarm = 107,
            nonpipelined_vfp = 108,
            pacbti = 109,
            perfmon = 110,
            prefer_ishst = 111,
            prefer_vmovsr = 112,
            prof_unpr = 113,
            r4 = 114,
            ras = 115,
            rclass = 116,
            read_tp_hard = 117,
            reserve_r9 = 118,
            ret_addr_stack = 119,
            sb = 120,
            sha2 = 121,
            slow_fp_brcc = 122,
            slow_load_D_subreg = 123,
            slow_odd_reg = 124,
            slow_vdup32 = 125,
            slow_vgetlni32 = 126,
            slowfpvfmx = 127,
            slowfpvmlx = 128,
            soft_float = 129,
            splat_vfp_neon = 130,
            strict_align = 131,
            swift = 132,
            thumb2 = 133,
            thumb_mode = 134,
            trustzone = 135,
            use_mipipeliner = 136,
            use_misched = 137,
            v2 = 138,
            v2a = 139,
            v3 = 140,
            v3m = 141,
            v4 = 142,
            v4t = 143,
            v5t = 144,
            v5te = 145,
            v5tej = 146,
            v6 = 147,
            v6j = 148,
            v6k = 149,
            v6kz = 150,
            v6m = 151,
            v6sm = 152,
            v6t2 = 153,
            v7a = 154,
            v7em = 155,
            v7k = 156,
            v7m = 157,
            v7r = 158,
            v7s = 159,
            v7ve = 160,
            v8_1a = 161,
            v8_1m_main = 162,
            v8_2a = 163,
            v8_3a = 164,
            v8_4a = 165,
            v8_5a = 166,
            v8_6a = 167,
            v8_7a = 168,
            v8_8a = 169,
            v8_9a = 170,
            v8a = 171,
            v8m = 172,
            v8m_main = 173,
            v8r = 174,
            v9_1a = 175,
            v9_2a = 176,
            v9_3a = 177,
            v9_4a = 178,
            v9a = 179,
            vfp2 = 180,
            vfp2sp = 181,
            vfp3 = 182,
            vfp3d16 = 183,
            vfp3d16sp = 184,
            vfp3sp = 185,
            vfp4 = 186,
            vfp4d16 = 187,
            vfp4d16sp = 188,
            vfp4sp = 189,
            virtualization = 190,
            vldn_align = 191,
            vmlx_forwarding = 192,
            vmlx_hazards = 193,
            wide_stride_vfp = 194,
            xscale = 195,
            zcz = 196,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "32bit", .llvm_name = "32bit", .description = "Prefer 32-bit Thumb instrs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "8msecext", .llvm_name = "8msecext", .description = "Enable support for ARMv8-M Security Extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "a76", .llvm_name = "a76", .description = "Cortex-A76 ARM processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "aapcs_frame_chain", .llvm_name = "aapcs-frame-chain", .description = "Create an AAPCS compliant frame chain", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "aapcs_frame_chain_leaf", .llvm_name = "aapcs-frame-chain-leaf", .description = "Create an AAPCS compliant frame chain for leaf functions", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "aclass", .llvm_name = "aclass", .description = "Is application profile ('A' series)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "acquire_release", .llvm_name = "acquire-release", .description = "Has v8 acquire/release (lda/ldaex  etc) instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "aes", .llvm_name = "aes", .description = "Enable AES support", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 8, .name = "atomics_32", .llvm_name = "atomics-32", .description = "Assume that lock-free 32-bit atomics are available", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "avoid_movs_shop", .llvm_name = "avoid-movs-shop", .description = "Avoid movs instructions with shifter operand", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "avoid_partial_cpsr", .llvm_name = "avoid-partial-cpsr", .description = "Avoid CPSR partial update for OOO execution", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "bf16", .llvm_name = "bf16", .description = "Enable support for BFloat16 instructions", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 12, .name = "big_endian_instructions", .llvm_name = "big-endian-instructions", .description = "Expect instructions to be stored big-endian.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "cde", .llvm_name = "cde", .description = "Support CDE instructions", .dependencies = .{ .ints = .{ 0, 4096, 0, 0, 0 } } },
            .{ .index = 14, .name = "cdecp0", .llvm_name = "cdecp0", .description = "Coprocessor 0 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "cdecp1", .llvm_name = "cdecp1", .description = "Coprocessor 1 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "cdecp2", .llvm_name = "cdecp2", .description = "Coprocessor 2 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "cdecp3", .llvm_name = "cdecp3", .description = "Coprocessor 3 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "cdecp4", .llvm_name = "cdecp4", .description = "Coprocessor 4 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "cdecp5", .llvm_name = "cdecp5", .description = "Coprocessor 5 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "cdecp6", .llvm_name = "cdecp6", .description = "Coprocessor 6 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "cdecp7", .llvm_name = "cdecp7", .description = "Coprocessor 7 ISA is CDEv1", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "cheap_predicable_cpsr", .llvm_name = "cheap-predicable-cpsr", .description = "Disable +1 predication cost for instructions updating CPSR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "clrbhb", .llvm_name = "clrbhb", .description = "Enable Clear BHB instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "crc", .llvm_name = "crc", .description = "Enable support for CRC instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "crypto", .llvm_name = "crypto", .description = "Enable support for Cryptography extensions", .dependencies = .{ .ints = .{ 128, 144115188075855872, 0, 0, 0 } } },
            .{ .index = 26, .name = "d32", .llvm_name = "d32", .description = "Extend FP to 32 double registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "db", .llvm_name = "db", .description = "Has data barrier (dmb/dsb) instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "dfb", .llvm_name = "dfb", .description = "Has full data barrier (dfb) instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "disable_postra_scheduler", .llvm_name = "disable-postra-scheduler", .description = "Don't schedule again after register allocation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "dont_widen_vmovs", .llvm_name = "dont-widen-vmovs", .description = "Don't widen VMOVS to VMOVD", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "dotprod", .llvm_name = "dotprod", .description = "Enable support for dot product instructions", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 32, .name = "dsp", .llvm_name = "dsp", .description = "Supports DSP instructions in ARM and/or Thumb2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "execute_only", .llvm_name = "execute-only", .description = "Enable the generation of execute only code.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "expand_fp_mlx", .llvm_name = "expand-fp-mlx", .description = "Expand VFP/NEON MLA/MLS instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "exynos", .llvm_name = "exynos", .description = "Samsung Exynos processors", .dependencies = .{ .ints = .{ 3377716950728704, 16465723187620741120, 5, 20, 0 } } },
            .{ .index = 36, .name = "fix_cmse_cve_2021_35465", .llvm_name = "fix-cmse-cve-2021-35465", .description = "Mitigate against the cve-2021-35465 security vulnurability", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "fix_cortex_a57_aes_1742098", .llvm_name = "fix-cortex-a57-aes-1742098", .description = "Work around Cortex-A57 Erratum 1742098 / Cortex-A72 Erratum 1655431 (AES)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "fp16", .llvm_name = "fp16", .description = "Enable half-precision floating point", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "fp16fml", .llvm_name = "fp16fml", .description = "Enable full half-precision floating point fml instructions", .dependencies = .{ .ints = .{ 562949953421312, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "fp64", .llvm_name = "fp64", .description = "Floating point unit supports double precision", .dependencies = .{ .ints = .{ 281474976710656, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "fp_armv8", .llvm_name = "fp-armv8", .description = "Enable ARMv8 FP", .dependencies = .{ .ints = .{ 21990232555520, 0, 288230376151711744, 0, 0 } } },
            .{ .index = 42, .name = "fp_armv8d16", .llvm_name = "fp-armv8d16", .description = "Enable ARMv8 FP with only 16 d-registers", .dependencies = .{ .ints = .{ 8796093022208, 0, 576460752303423488, 0, 0 } } },
            .{ .index = 43, .name = "fp_armv8d16sp", .llvm_name = "fp-armv8d16sp", .description = "Enable ARMv8 FP with only 16 d-registers and no double precision", .dependencies = .{ .ints = .{ 0, 0, 1152921504606846976, 0, 0 } } },
            .{ .index = 44, .name = "fp_armv8sp", .llvm_name = "fp-armv8sp", .description = "Enable ARMv8 FP with no double precision", .dependencies = .{ .ints = .{ 8796093022208, 0, 2305843009213693952, 0, 0 } } },
            .{ .index = 45, .name = "fpao", .llvm_name = "fpao", .description = "Enable fast computation of positive address offsets", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "fpregs", .llvm_name = "fpregs", .description = "Enable FP registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "fpregs16", .llvm_name = "fpregs16", .description = "Enable 16-bit FP registers", .dependencies = .{ .ints = .{ 70368744177664, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "fpregs64", .llvm_name = "fpregs64", .description = "Enable 64-bit FP registers", .dependencies = .{ .ints = .{ 70368744177664, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "fullfp16", .llvm_name = "fullfp16", .description = "Enable full half-precision floating point", .dependencies = .{ .ints = .{ 149533581377536, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "fuse_aes", .llvm_name = "fuse-aes", .description = "CPU fuses AES crypto operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "fuse_literals", .llvm_name = "fuse-literals", .description = "CPU fuses literal generation operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "harden_sls_blr", .llvm_name = "harden-sls-blr", .description = "Harden against straight line speculation across indirect calls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 53, .name = "harden_sls_nocomdat", .llvm_name = "harden-sls-nocomdat", .description = "Generate thunk code for SLS mitigation in the normal text section", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "harden_sls_retbr", .llvm_name = "harden-sls-retbr", .description = "Harden against straight line speculation across RETurn and BranchRegister instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "has_v4t", .llvm_name = "v4t", .description = "Support ARM v4T instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "has_v5t", .llvm_name = "v5t", .description = "Support ARM v5T instructions", .dependencies = .{ .ints = .{ 36028797018963968, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "has_v5te", .llvm_name = "v5te", .description = "Support ARM v5TE, v5TEj, and v5TExp instructions", .dependencies = .{ .ints = .{ 72057594037927936, 0, 0, 0, 0 } } },
            .{ .index = 58, .name = "has_v6", .llvm_name = "v6", .description = "Support ARM v6 instructions", .dependencies = .{ .ints = .{ 144115188075855872, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "has_v6k", .llvm_name = "v6k", .description = "Support ARM v6k instructions", .dependencies = .{ .ints = .{ 288230376151711744, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "has_v6m", .llvm_name = "v6m", .description = "Support ARM v6M instructions", .dependencies = .{ .ints = .{ 288230376151711744, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "has_v6t2", .llvm_name = "v6t2", .description = "Support ARM v6t2 instructions", .dependencies = .{ .ints = .{ 576460752303423488, 2048, 32, 0, 0 } } },
            .{ .index = 62, .name = "has_v7", .llvm_name = "v7", .description = "Support ARM v7 instructions", .dependencies = .{ .ints = .{ 11529215046068469760, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "has_v7clrex", .llvm_name = "v7clrex", .description = "Has v7 clrex instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "has_v8", .llvm_name = "v8", .description = "Support ARM v8 instructions", .dependencies = .{ .ints = .{ 4611686018427387968, 70368744177664, 0, 0, 0 } } },
            .{ .index = 65, .name = "has_v8_1a", .llvm_name = "v8.1a", .description = "Support ARM v8.1a instructions", .dependencies = .{ .ints = .{ 0, 1, 0, 0, 0 } } },
            .{ .index = 66, .name = "has_v8_1m_main", .llvm_name = "v8.1m.main", .description = "Support ARM v8-1M Mainline instructions", .dependencies = .{ .ints = .{ 0, 4096, 0, 0, 0 } } },
            .{ .index = 67, .name = "has_v8_2a", .llvm_name = "v8.2a", .description = "Support ARM v8.2a instructions", .dependencies = .{ .ints = .{ 0, 2, 0, 0, 0 } } },
            .{ .index = 68, .name = "has_v8_3a", .llvm_name = "v8.3a", .description = "Support ARM v8.3a instructions", .dependencies = .{ .ints = .{ 0, 8, 0, 0, 0 } } },
            .{ .index = 69, .name = "has_v8_4a", .llvm_name = "v8.4a", .description = "Support ARM v8.4a instructions", .dependencies = .{ .ints = .{ 2147483648, 16, 0, 0, 0 } } },
            .{ .index = 70, .name = "has_v8_5a", .llvm_name = "v8.5a", .description = "Support ARM v8.5a instructions", .dependencies = .{ .ints = .{ 0, 72057594037927968, 0, 0, 0 } } },
            .{ .index = 71, .name = "has_v8_6a", .llvm_name = "v8.6a", .description = "Support ARM v8.6a instructions", .dependencies = .{ .ints = .{ 2048, 1048640, 0, 0, 0 } } },
            .{ .index = 72, .name = "has_v8_7a", .llvm_name = "v8.7a", .description = "Support ARM v8.7a instructions", .dependencies = .{ .ints = .{ 0, 128, 0, 0, 0 } } },
            .{ .index = 73, .name = "has_v8_8a", .llvm_name = "v8.8a", .description = "Support ARM v8.8a instructions", .dependencies = .{ .ints = .{ 0, 256, 0, 0, 0 } } },
            .{ .index = 74, .name = "has_v8_9a", .llvm_name = "v8.9a", .description = "Support ARM v8.9a instructions", .dependencies = .{ .ints = .{ 8388608, 512, 0, 0, 0 } } },
            .{ .index = 75, .name = "has_v8m", .llvm_name = "v8m", .description = "Support ARM v8M Baseline instructions", .dependencies = .{ .ints = .{ 1152921504606846976, 0, 0, 0, 0 } } },
            .{ .index = 76, .name = "has_v8m_main", .llvm_name = "v8m.main", .description = "Support ARM v8M Mainline instructions", .dependencies = .{ .ints = .{ 4611686018427387904, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "has_v9_1a", .llvm_name = "v9.1a", .description = "Support ARM v9.1a instructions", .dependencies = .{ .ints = .{ 0, 131200, 0, 0, 0 } } },
            .{ .index = 78, .name = "has_v9_2a", .llvm_name = "v9.2a", .description = "Support ARM v9.2a instructions", .dependencies = .{ .ints = .{ 0, 8448, 0, 0, 0 } } },
            .{ .index = 79, .name = "has_v9_3a", .llvm_name = "v9.3a", .description = "Support ARM v9.3a instructions", .dependencies = .{ .ints = .{ 0, 16896, 0, 0, 0 } } },
            .{ .index = 80, .name = "has_v9_4a", .llvm_name = "v9.4a", .description = "Support ARM v9.4a instructions", .dependencies = .{ .ints = .{ 0, 33792, 0, 0, 0 } } },
            .{ .index = 81, .name = "has_v9a", .llvm_name = "v9a", .description = "Support ARM v9a instructions", .dependencies = .{ .ints = .{ 0, 64, 0, 0, 0 } } },
            .{ .index = 82, .name = "hwdiv", .llvm_name = "hwdiv", .description = "Enable divide instructions in Thumb", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 83, .name = "hwdiv_arm", .llvm_name = "hwdiv-arm", .description = "Enable divide instructions in ARM mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 84, .name = "i8mm", .llvm_name = "i8mm", .description = "Enable Matrix Multiply Int8 Extension", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 85, .name = "iwmmxt", .llvm_name = "iwmmxt", .description = "ARMv5te architecture", .dependencies = .{ .ints = .{ 0, 0, 131072, 0, 0 } } },
            .{ .index = 86, .name = "iwmmxt2", .llvm_name = "iwmmxt2", .description = "ARMv5te architecture", .dependencies = .{ .ints = .{ 0, 0, 131072, 0, 0 } } },
            .{ .index = 87, .name = "lob", .llvm_name = "lob", .description = "Enable Low Overhead Branch extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 88, .name = "long_calls", .llvm_name = "long-calls", .description = "Generate calls via indirect call instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 89, .name = "loop_align", .llvm_name = "loop-align", .description = "Prefer 32-bit alignment for loops", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 90, .name = "m3", .llvm_name = "m3", .description = "Cortex-M3 ARM processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 91, .name = "mclass", .llvm_name = "mclass", .description = "Is microcontroller profile ('M' series)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 92, .name = "mp", .llvm_name = "mp", .description = "Supports Multiprocessing extension", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 93, .name = "muxed_units", .llvm_name = "muxed-units", .description = "Has muxed AGU and NEON/FPU", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 94, .name = "mve", .llvm_name = "mve", .description = "Support M-Class Vector Extension with integer ops", .dependencies = .{ .ints = .{ 422216760033280, 4, 0, 0, 0 } } },
            .{ .index = 95, .name = "mve1beat", .llvm_name = "mve1beat", .description = "Model MVE instructions as a 1 beat per tick architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 96, .name = "mve2beat", .llvm_name = "mve2beat", .description = "Model MVE instructions as a 2 beats per tick architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 97, .name = "mve4beat", .llvm_name = "mve4beat", .description = "Model MVE instructions as a 4 beats per tick architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 98, .name = "mve_fp", .llvm_name = "mve.fp", .description = "Support M-Class Vector Extension with integer and floating ops", .dependencies = .{ .ints = .{ 562949953421312, 1073741824, 0, 0, 0 } } },
            .{ .index = 99, .name = "nacl_trap", .llvm_name = "nacl-trap", .description = "NaCl trap", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 100, .name = "neon", .llvm_name = "neon", .description = "Enable NEON instructions", .dependencies = .{ .ints = .{ 0, 0, 18014398509481984, 0, 0 } } },
            .{ .index = 101, .name = "neon_fpmovs", .llvm_name = "neon-fpmovs", .description = "Convert VMOVSR, VMOVRS, VMOVS to NEON", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 102, .name = "neonfp", .llvm_name = "neonfp", .description = "Use NEON for single precision FP", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 103, .name = "no_branch_predictor", .llvm_name = "no-branch-predictor", .description = "Has no branch predictor", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 104, .name = "no_bti_at_return_twice", .llvm_name = "no-bti-at-return-twice", .description = "Don't place a BTI instruction after a return-twice", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 105, .name = "no_movt", .llvm_name = "no-movt", .description = "Don't use movt/movw pairs for 32-bit imms", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 106, .name = "no_neg_immediates", .llvm_name = "no-neg-immediates", .description = "Convert immediates and instructions to their negated or complemented equivalent when the immediate does not fit in the encoding.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 107, .name = "noarm", .llvm_name = "noarm", .description = "Does not support ARM mode execution", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 108, .name = "nonpipelined_vfp", .llvm_name = "nonpipelined-vfp", .description = "VFP instructions are not pipelined", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 109, .name = "pacbti", .llvm_name = "pacbti", .description = "Enable Pointer Authentication and Branch Target Identification", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 110, .name = "perfmon", .llvm_name = "perfmon", .description = "Enable support for Performance Monitor extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 111, .name = "prefer_ishst", .llvm_name = "prefer-ishst", .description = "Prefer ISHST barriers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 112, .name = "prefer_vmovsr", .llvm_name = "prefer-vmovsr", .description = "Prefer VMOVSR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 113, .name = "prof_unpr", .llvm_name = "prof-unpr", .description = "Is profitable to unpredicate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 114, .name = "r4", .llvm_name = "r4", .description = "Cortex-R4 ARM processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 115, .name = "ras", .llvm_name = "ras", .description = "Enable Reliability, Availability and Serviceability extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 116, .name = "rclass", .llvm_name = "rclass", .description = "Is realtime profile ('R' series)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 117, .name = "read_tp_hard", .llvm_name = "read-tp-hard", .description = "Reading thread pointer from register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 118, .name = "reserve_r9", .llvm_name = "reserve-r9", .description = "Reserve R9, making it unavailable as GPR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 119, .name = "ret_addr_stack", .llvm_name = "ret-addr-stack", .description = "Has return address stack", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 120, .name = "sb", .llvm_name = "sb", .description = "Enable v8.5a Speculation Barrier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 121, .name = "sha2", .llvm_name = "sha2", .description = "Enable SHA1 and SHA256 support", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 122, .name = "slow_fp_brcc", .llvm_name = "slow-fp-brcc", .description = "FP compare + branch is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 123, .name = "slow_load_D_subreg", .llvm_name = "slow-load-D-subreg", .description = "Loading into D subregs is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 124, .name = "slow_odd_reg", .llvm_name = "slow-odd-reg", .description = "VLDM/VSTM starting with an odd register is slow", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 125, .name = "slow_vdup32", .llvm_name = "slow-vdup32", .description = "Has slow VDUP32 - prefer VMOV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 126, .name = "slow_vgetlni32", .llvm_name = "slow-vgetlni32", .description = "Has slow VGETLNi32 - prefer VMOV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 127, .name = "slowfpvfmx", .llvm_name = "slowfpvfmx", .description = "Disable VFP / NEON FMA instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 128, .name = "slowfpvmlx", .llvm_name = "slowfpvmlx", .description = "Disable VFP / NEON MAC instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 129, .name = "soft_float", .llvm_name = "soft-float", .description = "Use software floating point features.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 130, .name = "splat_vfp_neon", .llvm_name = "splat-vfp-neon", .description = "Splat register from VFP to NEON", .dependencies = .{ .ints = .{ 1073741824, 0, 0, 0, 0 } } },
            .{ .index = 131, .name = "strict_align", .llvm_name = "strict-align", .description = "Disallow all unaligned memory access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 132, .name = "swift", .llvm_name = "swift", .description = "Swift ARM processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 133, .name = "thumb2", .llvm_name = "thumb2", .description = "Enable Thumb2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 134, .name = "thumb_mode", .llvm_name = "thumb-mode", .description = "Thumb mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 135, .name = "trustzone", .llvm_name = "trustzone", .description = "Enable support for TrustZone security extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 136, .name = "use_mipipeliner", .llvm_name = "use-mipipeliner", .description = "Use the MachinePipeliner", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 137, .name = "use_misched", .llvm_name = "use-misched", .description = "Use the MachineScheduler", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 138, .name = "v2", .llvm_name = null, .description = "ARMv2 architecture", .dependencies = .{ .ints = .{ 0, 0, 8, 0, 0 } } },
            .{ .index = 139, .name = "v2a", .llvm_name = null, .description = "ARMv2a architecture", .dependencies = .{ .ints = .{ 0, 0, 8, 0, 0 } } },
            .{ .index = 140, .name = "v3", .llvm_name = null, .description = "ARMv3 architecture", .dependencies = .{ .ints = .{ 0, 0, 8, 0, 0 } } },
            .{ .index = 141, .name = "v3m", .llvm_name = null, .description = "ARMv3m architecture", .dependencies = .{ .ints = .{ 0, 0, 8, 0, 0 } } },
            .{ .index = 142, .name = "v4", .llvm_name = "armv4", .description = "ARMv4 architecture", .dependencies = .{ .ints = .{ 0, 0, 8, 0, 0 } } },
            .{ .index = 143, .name = "v4t", .llvm_name = "armv4t", .description = "ARMv4t architecture", .dependencies = .{ .ints = .{ 36028797018963968, 0, 8, 0, 0 } } },
            .{ .index = 144, .name = "v5t", .llvm_name = "armv5t", .description = "ARMv5t architecture", .dependencies = .{ .ints = .{ 72057594037927936, 0, 8, 0, 0 } } },
            .{ .index = 145, .name = "v5te", .llvm_name = "armv5te", .description = "ARMv5te architecture", .dependencies = .{ .ints = .{ 144115188075855872, 0, 8, 0, 0 } } },
            .{ .index = 146, .name = "v5tej", .llvm_name = "armv5tej", .description = "ARMv5tej architecture", .dependencies = .{ .ints = .{ 144115188075855872, 0, 8, 0, 0 } } },
            .{ .index = 147, .name = "v6", .llvm_name = "armv6", .description = "ARMv6 architecture", .dependencies = .{ .ints = .{ 288230380446679040, 0, 0, 0, 0 } } },
            .{ .index = 148, .name = "v6j", .llvm_name = "armv6j", .description = "ARMv7a architecture", .dependencies = .{ .ints = .{ 0, 0, 524288, 0, 0 } } },
            .{ .index = 149, .name = "v6k", .llvm_name = "armv6k", .description = "ARMv6k architecture", .dependencies = .{ .ints = .{ 576460752303423488, 0, 0, 0, 0 } } },
            .{ .index = 150, .name = "v6kz", .llvm_name = "armv6kz", .description = "ARMv6kz architecture", .dependencies = .{ .ints = .{ 576460752303423488, 0, 128, 0, 0 } } },
            .{ .index = 151, .name = "v6m", .llvm_name = "armv6-m", .description = "ARMv6m architecture", .dependencies = .{ .ints = .{ 1152921504741064704, 8796227239936, 72, 0, 0 } } },
            .{ .index = 152, .name = "v6sm", .llvm_name = "armv6s-m", .description = "ARMv6sm architecture", .dependencies = .{ .ints = .{ 1152921504741064704, 8796227239936, 72, 0, 0 } } },
            .{ .index = 153, .name = "v6t2", .llvm_name = "armv6t2", .description = "ARMv6t2 architecture", .dependencies = .{ .ints = .{ 2305843013508661248, 0, 0, 0, 0 } } },
            .{ .index = 154, .name = "v7a", .llvm_name = "armv7-a", .description = "ARMv7a architecture", .dependencies = .{ .ints = .{ 4611686022856572960, 70437463654400, 0, 0, 0 } } },
            .{ .index = 155, .name = "v7em", .llvm_name = "armv7e-m", .description = "ARMv7em architecture", .dependencies = .{ .ints = .{ 4611686022856572928, 8796227502080, 64, 0, 0 } } },
            .{ .index = 156, .name = "v7k", .llvm_name = "armv7k", .description = "ARMv7a architecture", .dependencies = .{ .ints = .{ 0, 0, 67108864, 0, 0 } } },
            .{ .index = 157, .name = "v7m", .llvm_name = "armv7-m", .description = "ARMv7m architecture", .dependencies = .{ .ints = .{ 4611686018561605632, 8796227502080, 64, 0, 0 } } },
            .{ .index = 158, .name = "v7r", .llvm_name = "armv7-r", .description = "ARMv7r architecture", .dependencies = .{ .ints = .{ 4611686022856572928, 4573968371810304, 0, 0, 0 } } },
            .{ .index = 159, .name = "v7s", .llvm_name = "armv7s", .description = "ARMv7a architecture", .dependencies = .{ .ints = .{ 0, 0, 67108864, 0, 0 } } },
            .{ .index = 160, .name = "v7ve", .llvm_name = "armv7ve", .description = "ARMv7ve architecture", .dependencies = .{ .ints = .{ 4611686022856572960, 70437732089856, 4611686018427388032, 0, 0 } } },
            .{ .index = 161, .name = "v8_1a", .llvm_name = "armv8.1-a", .description = "ARMv81a architecture", .dependencies = .{ .ints = .{ 2203502772256, 268435458, 4611686018427388032, 0, 0 } } },
            .{ .index = 162, .name = "v8_1m_main", .llvm_name = "armv8.1-m.main", .description = "ARMv81mMainline architecture", .dependencies = .{ .ints = .{ 134217794, 2260596049575940, 64, 0, 0 } } },
            .{ .index = 163, .name = "v8_2a", .llvm_name = "armv8.2-a", .description = "ARMv82a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120712, 4611686018427388032, 0, 0 } } },
            .{ .index = 164, .name = "v8_3a", .llvm_name = "armv8.3-a", .description = "ARMv83a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120720, 4611686018427388032, 0, 0 } } },
            .{ .index = 165, .name = "v8_4a", .llvm_name = "armv8.4-a", .description = "ARMv84a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120736, 4611686018427388032, 0, 0 } } },
            .{ .index = 166, .name = "v8_5a", .llvm_name = "armv8.5-a", .description = "ARMv85a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120768, 4611686018427388032, 0, 0 } } },
            .{ .index = 167, .name = "v8_6a", .llvm_name = "armv8.6-a", .description = "ARMv86a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120832, 4611686018427388032, 0, 0 } } },
            .{ .index = 168, .name = "v8_7a", .llvm_name = "armv8.7-a", .description = "ARMv87a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082120960, 4611686018427388032, 0, 0 } } },
            .{ .index = 169, .name = "v8_8a", .llvm_name = "armv8.8-a", .description = "ARMv88a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082121216, 4611686018427388032, 0, 0 } } },
            .{ .index = 170, .name = "v8_9a", .llvm_name = "armv8.9-a", .description = "ARMv89a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082121728, 4611686018427388032, 0, 0 } } },
            .{ .index = 171, .name = "v8a", .llvm_name = "armv8-a", .description = "ARMv8a architecture", .dependencies = .{ .ints = .{ 2203502772256, 268435457, 4611686018427388032, 0, 0 } } },
            .{ .index = 172, .name = "v8m", .llvm_name = "armv8-m.base", .description = "ARMv8mBaseline architecture", .dependencies = .{ .ints = .{ 9223372036988993602, 8796227504128, 72, 0, 0 } } },
            .{ .index = 173, .name = "v8m_main", .llvm_name = "armv8-m.main", .description = "ARMv8mMainline architecture", .dependencies = .{ .ints = .{ 134217794, 8796227506176, 64, 0, 0 } } },
            .{ .index = 174, .name = "v8r", .llvm_name = "armv8-r", .description = "ARMv8r architecture", .dependencies = .{ .ints = .{ 2203737653248, 4503668615282689, 4611686018427387904, 0, 0 } } },
            .{ .index = 175, .name = "v9_1a", .llvm_name = "armv9.1-a", .description = "ARMv91a architecture", .dependencies = .{ .ints = .{ 2203469217824, 2251800082128896, 4611686018427388032, 0, 0 } } },
            .{ .index = 176, .name = "v9_2a", .llvm_name = "armv9.2-a", .description = "ARMv92a architecture", .dependencies = .{ .ints = .{ 2203469217824, 2251800082137088, 4611686018427388032, 0, 0 } } },
            .{ .index = 177, .name = "v9_3a", .llvm_name = "armv9.3-a", .description = "ARMv93a architecture", .dependencies = .{ .ints = .{ 2203502772256, 2251800082153472, 4611686018427388032, 0, 0 } } },
            .{ .index = 178, .name = "v9_4a", .llvm_name = "armv9.4-a", .description = "ARMv94a architecture", .dependencies = .{ .ints = .{ 2203469217824, 2251800082186240, 4611686018427388032, 0, 0 } } },
            .{ .index = 179, .name = "v9a", .llvm_name = "armv9-a", .description = "ARMv9a architecture", .dependencies = .{ .ints = .{ 2203469217824, 2251800082251776, 4611686018427388032, 0, 0 } } },
            .{ .index = 180, .name = "vfp2", .llvm_name = "vfp2", .description = "Enable VFP2 instructions", .dependencies = .{ .ints = .{ 1099511627776, 0, 9007199254740992, 0, 0 } } },
            .{ .index = 181, .name = "vfp2sp", .llvm_name = "vfp2sp", .description = "Enable VFP2 instructions with no double precision", .dependencies = .{ .ints = .{ 70368744177664, 0, 0, 0, 0 } } },
            .{ .index = 182, .name = "vfp3", .llvm_name = "vfp3", .description = "Enable VFP3 instructions", .dependencies = .{ .ints = .{ 0, 0, 180143985094819840, 0, 0 } } },
            .{ .index = 183, .name = "vfp3d16", .llvm_name = "vfp3d16", .description = "Enable VFP3 instructions with only 16 d-registers", .dependencies = .{ .ints = .{ 0, 0, 76561193665298432, 0, 0 } } },
            .{ .index = 184, .name = "vfp3d16sp", .llvm_name = "vfp3d16sp", .description = "Enable VFP3 instructions with only 16 d-registers and no double precision", .dependencies = .{ .ints = .{ 0, 0, 9007199254740992, 0, 0 } } },
            .{ .index = 185, .name = "vfp3sp", .llvm_name = "vfp3sp", .description = "Enable VFP3 instructions with no double precision", .dependencies = .{ .ints = .{ 67108864, 0, 72057594037927936, 0, 0 } } },
            .{ .index = 186, .name = "vfp4", .llvm_name = "vfp4", .description = "Enable VFP4 instructions", .dependencies = .{ .ints = .{ 0, 0, 2900318160026599424, 0, 0 } } },
            .{ .index = 187, .name = "vfp4d16", .llvm_name = "vfp4d16", .description = "Enable VFP4 instructions with only 16 d-registers", .dependencies = .{ .ints = .{ 0, 0, 1188950301625810944, 0, 0 } } },
            .{ .index = 188, .name = "vfp4d16sp", .llvm_name = "vfp4d16sp", .description = "Enable VFP4 instructions with only 16 d-registers and no double precision", .dependencies = .{ .ints = .{ 274877906944, 0, 72057594037927936, 0, 0 } } },
            .{ .index = 189, .name = "vfp4sp", .llvm_name = "vfp4sp", .description = "Enable VFP4 instructions with no double precision", .dependencies = .{ .ints = .{ 0, 0, 1297036692682702848, 0, 0 } } },
            .{ .index = 190, .name = "virtualization", .llvm_name = "virtualization", .description = "Supports Virtualization extension", .dependencies = .{ .ints = .{ 0, 786432, 0, 0, 0 } } },
            .{ .index = 191, .name = "vldn_align", .llvm_name = "vldn-align", .description = "Check for VLDn unaligned access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 192, .name = "vmlx_forwarding", .llvm_name = "vmlx-forwarding", .description = "Has multiplier accumulator forwarding", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 193, .name = "vmlx_hazards", .llvm_name = "vmlx-hazards", .description = "Has VMLx hazards", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 194, .name = "wide_stride_vfp", .llvm_name = "wide-stride-vfp", .description = "Use a wide stride when allocating VFP registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 195, .name = "xscale", .llvm_name = "xscale", .description = "ARMv5te architecture", .dependencies = .{ .ints = .{ 0, 0, 131072, 0, 0 } } },
            .{ .index = 196, .name = "zcz", .llvm_name = "zcz", .description = "Has zero-cycle zeroing instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const arm1020e: Cpu = .{ .name = "arm1020e", .llvm_name = "arm1020e", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm1020t: Cpu = .{ .name = "arm1020t", .llvm_name = "arm1020t", .features = .{ .ints = .{ 0, 0, 65536, 0, 0 } } };
            const arm1022e: Cpu = .{ .name = "arm1022e", .llvm_name = "arm1022e", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm10e: Cpu = .{ .name = "arm10e", .llvm_name = "arm10e", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm10tdmi: Cpu = .{ .name = "arm10tdmi", .llvm_name = "arm10tdmi", .features = .{ .ints = .{ 0, 0, 65536, 0, 0 } } };
            const arm1136j_s: Cpu = .{ .name = "arm1136j_s", .llvm_name = "arm1136j-s", .features = .{ .ints = .{ 0, 0, 524288, 0, 0 } } };
            const arm1136jf_s: Cpu = .{ .name = "arm1136jf_s", .llvm_name = "arm1136jf-s", .features = .{ .ints = .{ 0, 0, 4503599627894785, 0, 0 } } };
            const arm1156t2_s: Cpu = .{ .name = "arm1156t2_s", .llvm_name = "arm1156t2-s", .features = .{ .ints = .{ 0, 0, 33554432, 0, 0 } } };
            const arm1156t2f_s: Cpu = .{ .name = "arm1156t2f_s", .llvm_name = "arm1156t2f-s", .features = .{ .ints = .{ 0, 0, 4503599660924929, 0, 0 } } };
            const arm1176jz_s: Cpu = .{ .name = "arm1176jz_s", .llvm_name = "arm1176jz-s", .features = .{ .ints = .{ 0, 0, 4194304, 0, 0 } } };
            const arm1176jzf_s: Cpu = .{ .name = "arm1176jzf_s", .llvm_name = "arm1176jzf-s", .features = .{ .ints = .{ 0, 0, 4503599631564801, 0, 0 } } };
            const arm710t: Cpu = .{ .name = "arm710t", .llvm_name = "arm710t", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm720t: Cpu = .{ .name = "arm720t", .llvm_name = "arm720t", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm7tdmi: Cpu = .{ .name = "arm7tdmi", .llvm_name = "arm7tdmi", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm7tdmi_s: Cpu = .{ .name = "arm7tdmi_s", .llvm_name = "arm7tdmi-s", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm8: Cpu = .{ .name = "arm8", .llvm_name = "arm8", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const arm810: Cpu = .{ .name = "arm810", .llvm_name = "arm810", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const arm9: Cpu = .{ .name = "arm9", .llvm_name = "arm9", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm920: Cpu = .{ .name = "arm920", .llvm_name = "arm920", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm920t: Cpu = .{ .name = "arm920t", .llvm_name = "arm920t", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm922t: Cpu = .{ .name = "arm922t", .llvm_name = "arm922t", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm926ej_s: Cpu = .{ .name = "arm926ej_s", .llvm_name = "arm926ej-s", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm940t: Cpu = .{ .name = "arm940t", .llvm_name = "arm940t", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const arm946e_s: Cpu = .{ .name = "arm946e_s", .llvm_name = "arm946e-s", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm966e_s: Cpu = .{ .name = "arm966e_s", .llvm_name = "arm966e-s", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm968e_s: Cpu = .{ .name = "arm968e_s", .llvm_name = "arm968e-s", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm9e: Cpu = .{ .name = "arm9e", .llvm_name = "arm9e", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const arm9tdmi: Cpu = .{ .name = "arm9tdmi", .llvm_name = "arm9tdmi", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const baseline: Cpu = .{ .name = "baseline", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 67108864, 0, 0 } } };
            const cortex_a12: Cpu = .{ .name = "cortex_a12", .llvm_name = "cortex-a12", .features = .{ .ints = .{ 1024, 36028797287399424, 4899916394646208640, 1, 0 } } };
            const cortex_a15: Cpu = .{ .name = "cortex_a15", .llvm_name = "cortex-a15", .features = .{ .ints = .{ 1024, 36028797824270336, 14123288431500984452, 0, 0 } } };
            const cortex_a17: Cpu = .{ .name = "cortex_a17", .llvm_name = "cortex-a17", .features = .{ .ints = .{ 1024, 36028797287399424, 4899916394646208640, 1, 0 } } };
            const cortex_a32: Cpu = .{ .name = "cortex_a32", .llvm_name = "cortex-a32", .features = .{ .ints = .{ 0, 0, 8796093022208, 0, 0 } } };
            const cortex_a35: Cpu = .{ .name = "cortex_a35", .llvm_name = "cortex-a35", .features = .{ .ints = .{ 0, 0, 8796093022208, 0, 0 } } };
            const cortex_a5: Cpu = .{ .name = "cortex_a5", .llvm_name = "cortex-a5", .features = .{ .ints = .{ 0, 9547631210293886976, 288230376218820737, 1, 0 } } };
            const cortex_a53: Cpu = .{ .name = "cortex_a53", .llvm_name = "cortex-a53", .features = .{ .ints = .{ 35184372088832, 0, 8796093022208, 0, 0 } } };
            const cortex_a55: Cpu = .{ .name = "cortex_a55", .llvm_name = "cortex-a55", .features = .{ .ints = .{ 2147483648, 0, 34359738368, 0, 0 } } };
            const cortex_a57: Cpu = .{ .name = "cortex_a57", .llvm_name = "cortex-a57", .features = .{ .ints = .{ 35321815237632, 0, 8796093022208, 0, 0 } } };
            const cortex_a7: Cpu = .{ .name = "cortex_a7", .llvm_name = "cortex-a7", .features = .{ .ints = .{ 0, 9547631210293886976, 4899916394646208641, 3, 0 } } };
            const cortex_a710: Cpu = .{ .name = "cortex_a710", .llvm_name = "cortex-a710", .features = .{ .ints = .{ 549755815936, 1048576, 2251799813685248, 0, 0 } } };
            const cortex_a72: Cpu = .{ .name = "cortex_a72", .llvm_name = "cortex-a72", .features = .{ .ints = .{ 137438953472, 0, 8796093022208, 0, 0 } } };
            const cortex_a73: Cpu = .{ .name = "cortex_a73", .llvm_name = "cortex-a73", .features = .{ .ints = .{ 0, 0, 8796093022208, 0, 0 } } };
            const cortex_a75: Cpu = .{ .name = "cortex_a75", .llvm_name = "cortex-a75", .features = .{ .ints = .{ 2147483648, 0, 34359738368, 0, 0 } } };
            const cortex_a76: Cpu = .{ .name = "cortex_a76", .llvm_name = "cortex-a76", .features = .{ .ints = .{ 562952100904964, 0, 34359738368, 0, 0 } } };
            const cortex_a76ae: Cpu = .{ .name = "cortex_a76ae", .llvm_name = "cortex-a76ae", .features = .{ .ints = .{ 562952100904964, 0, 34359738368, 0, 0 } } };
            const cortex_a77: Cpu = .{ .name = "cortex_a77", .llvm_name = "cortex-a77", .features = .{ .ints = .{ 562952100904960, 0, 34359738368, 0, 0 } } };
            const cortex_a78: Cpu = .{ .name = "cortex_a78", .llvm_name = "cortex-a78", .features = .{ .ints = .{ 562952100904960, 0, 34359738368, 0, 0 } } };
            const cortex_a78c: Cpu = .{ .name = "cortex_a78c", .llvm_name = "cortex-a78c", .features = .{ .ints = .{ 562952100904960, 0, 34359738368, 0, 0 } } };
            const cortex_a8: Cpu = .{ .name = "cortex_a8", .llvm_name = "cortex-a8", .features = .{ .ints = .{ 0, 9547648802211495936, 67108993, 3, 0 } } };
            const cortex_a9: Cpu = .{ .name = "cortex_a9", .llvm_name = "cortex-a9", .features = .{ .ints = .{ 292057777152, 36310410239934464, 9223372036921884800, 3, 0 } } };
            const cortex_m0: Cpu = .{ .name = "cortex_m0", .llvm_name = "cortex-m0", .features = .{ .ints = .{ 0, 549755813888, 8388608, 0, 0 } } };
            const cortex_m0plus: Cpu = .{ .name = "cortex_m0plus", .llvm_name = "cortex-m0plus", .features = .{ .ints = .{ 0, 549755813888, 8388608, 0, 0 } } };
            const cortex_m1: Cpu = .{ .name = "cortex_m1", .llvm_name = "cortex-m1", .features = .{ .ints = .{ 0, 549755813888, 8388608, 0, 0 } } };
            const cortex_m23: Cpu = .{ .name = "cortex_m23", .llvm_name = "cortex-m23", .features = .{ .ints = .{ 0, 2748779069440, 17592186044416, 0, 0 } } };
            const cortex_m3: Cpu = .{ .name = "cortex_m3", .llvm_name = "cortex-m3", .features = .{ .ints = .{ 0, 549856477184, 536871424, 0, 0 } } };
            const cortex_m33: Cpu = .{ .name = "cortex_m33", .llvm_name = "cortex-m33", .features = .{ .ints = .{ 8869107466240, 9223372586644144128, 35184372089345, 0, 0 } } };
            const cortex_m35p: Cpu = .{ .name = "cortex_m35p", .llvm_name = "cortex-m35p", .features = .{ .ints = .{ 8869107466240, 9223372586644144128, 35184372089345, 0, 0 } } };
            const cortex_m4: Cpu = .{ .name = "cortex_m4", .llvm_name = "cortex-m4", .features = .{ .ints = .{ 0, 9223372586644144128, 1152921504741065217, 0, 0 } } };
            const cortex_m55: Cpu = .{ .name = "cortex_m55", .llvm_name = "cortex-m55", .features = .{ .ints = .{ 4466765987840, 566969237504, 17179869697, 0, 0 } } };
            const cortex_m7: Cpu = .{ .name = "cortex_m7", .llvm_name = "cortex-m7", .features = .{ .ints = .{ 4398046511104, 0, 134218496, 0, 0 } } };
            const cortex_m85: Cpu = .{ .name = "cortex_m85", .llvm_name = "cortex-m85", .features = .{ .ints = .{ 4398046511104, 35201551958016, 17179869696, 0, 0 } } };
            const cortex_r4: Cpu = .{ .name = "cortex_r4", .llvm_name = "cortex-r4", .features = .{ .ints = .{ 1024, 37154696925806592, 1073741824, 0, 0 } } };
            const cortex_r4f: Cpu = .{ .name = "cortex_r4f", .llvm_name = "cortex-r4f", .features = .{ .ints = .{ 1024, 9548757109932294144, 36028798092705793, 0, 0 } } };
            const cortex_r5: Cpu = .{ .name = "cortex_r5", .llvm_name = "cortex-r5", .features = .{ .ints = .{ 1024, 9547631210025975808, 36028798092705793, 0, 0 } } };
            const cortex_r52: Cpu = .{ .name = "cortex_r52", .llvm_name = "cortex-r52", .features = .{ .ints = .{ 35184372088832, 0, 70368744178176, 0, 0 } } };
            const cortex_r7: Cpu = .{ .name = "cortex_r7", .llvm_name = "cortex-r7", .features = .{ .ints = .{ 274877907968, 9547631210294411264, 36028798092705793, 0, 0 } } };
            const cortex_r8: Cpu = .{ .name = "cortex_r8", .llvm_name = "cortex-r8", .features = .{ .ints = .{ 274877907968, 9547631210294411264, 36028798092705793, 0, 0 } } };
            const cortex_x1: Cpu = .{ .name = "cortex_x1", .llvm_name = "cortex-x1", .features = .{ .ints = .{ 562952100904960, 0, 34359738368, 0, 0 } } };
            const cortex_x1c: Cpu = .{ .name = "cortex_x1c", .llvm_name = "cortex-x1c", .features = .{ .ints = .{ 562952100904960, 0, 34359738368, 0, 0 } } };
            const cyclone: Cpu = .{ .name = "cyclone", .llvm_name = "cyclone", .features = .{ .ints = .{ 536872448, 9259401108751646720, 8796093022737, 16, 0 } } };
            const ep9312: Cpu = .{ .name = "ep9312", .llvm_name = "ep9312", .features = .{ .ints = .{ 0, 0, 32768, 0, 0 } } };
            const exynos_m1: Cpu = .{ .name = "exynos_m1", .llvm_name = null, .features = .{ .ints = .{ 34359738368, 0, 8796093022208, 0, 0 } } };
            const exynos_m2: Cpu = .{ .name = "exynos_m2", .llvm_name = null, .features = .{ .ints = .{ 34359738368, 0, 8796093022208, 0, 0 } } };
            const exynos_m3: Cpu = .{ .name = "exynos_m3", .llvm_name = "exynos-m3", .features = .{ .ints = .{ 34359738368, 0, 8796093022208, 0, 0 } } };
            const exynos_m4: Cpu = .{ .name = "exynos_m4", .llvm_name = "exynos-m4", .features = .{ .ints = .{ 562986460643328, 0, 34359738368, 0, 0 } } };
            const exynos_m5: Cpu = .{ .name = "exynos_m5", .llvm_name = "exynos-m5", .features = .{ .ints = .{ 562986460643328, 0, 34359738368, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const iwmmxt: Cpu = .{ .name = "iwmmxt", .llvm_name = "iwmmxt", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
            const krait: Cpu = .{ .name = "krait", .llvm_name = "krait", .features = .{ .ints = .{ 1024, 36028797556621312, 9511602413073596416, 1, 0 } } };
            const kryo: Cpu = .{ .name = "kryo", .llvm_name = "kryo", .features = .{ .ints = .{ 0, 0, 8796093022208, 0, 0 } } };
            const mpcore: Cpu = .{ .name = "mpcore", .llvm_name = "mpcore", .features = .{ .ints = .{ 0, 0, 4503599629467649, 0, 0 } } };
            const mpcorenovfp: Cpu = .{ .name = "mpcorenovfp", .llvm_name = "mpcorenovfp", .features = .{ .ints = .{ 0, 0, 2097152, 0, 0 } } };
            const neoverse_n1: Cpu = .{ .name = "neoverse_n1", .llvm_name = "neoverse-n1", .features = .{ .ints = .{ 2147483648, 0, 34359738368, 0, 0 } } };
            const neoverse_n2: Cpu = .{ .name = "neoverse_n2", .llvm_name = "neoverse-n2", .features = .{ .ints = .{ 2048, 1048576, 274877906944, 0, 0 } } };
            const neoverse_v1: Cpu = .{ .name = "neoverse_v1", .llvm_name = "neoverse-v1", .features = .{ .ints = .{ 562949953423360, 1048576, 137438953472, 0, 0 } } };
            const sc000: Cpu = .{ .name = "sc000", .llvm_name = "sc000", .features = .{ .ints = .{ 0, 549755813888, 8388608, 0, 0 } } };
            const sc300: Cpu = .{ .name = "sc300", .llvm_name = "sc300", .features = .{ .ints = .{ 0, 549822922752, 536871424, 0, 0 } } };
            const strongarm: Cpu = .{ .name = "strongarm", .llvm_name = "strongarm", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const strongarm110: Cpu = .{ .name = "strongarm110", .llvm_name = "strongarm110", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const strongarm1100: Cpu = .{ .name = "strongarm1100", .llvm_name = "strongarm1100", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const strongarm1110: Cpu = .{ .name = "strongarm1110", .llvm_name = "strongarm1110", .features = .{ .ints = .{ 0, 0, 16384, 0, 0 } } };
            const swift: Cpu = .{ .name = "swift", .llvm_name = "swift", .features = .{ .ints = .{ 536872448, 17907016081013997568, 288230376218821137, 6, 0 } } };
            const xscale: Cpu = .{ .name = "xscale", .llvm_name = "xscale", .features = .{ .ints = .{ 0, 0, 131072, 0, 0 } } };
        };
    };
    pub const avr = struct {
        pub const Feature = enum(u6) {
            addsubiw = 0,
            avr0 = 1,
            avr1 = 2,
            avr2 = 3,
            avr25 = 4,
            avr3 = 5,
            avr31 = 6,
            avr35 = 7,
            avr4 = 8,
            avr5 = 9,
            avr51 = 10,
            avr6 = 11,
            avrtiny = 12,
            @"break" = 13,
            des = 14,
            eijmpcall = 15,
            elpm = 16,
            elpmx = 17,
            ijmpcall = 18,
            jmpcall = 19,
            lpm = 20,
            lpmx = 21,
            memmappedregs = 22,
            movw = 23,
            mul = 24,
            progmem = 25,
            rmw = 26,
            smallstack = 27,
            special = 28,
            spm = 29,
            spmx = 30,
            sram = 31,
            tinyencoding = 32,
            xmega = 33,
            xmega3 = 34,
            xmegau = 35,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "addsubiw", .llvm_name = "addsubiw", .description = "Enable 16-bit register-immediate addition and subtraction instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "avr0", .llvm_name = "avr0", .description = "The device is a part of the avr0 family", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "avr1", .llvm_name = "avr1", .description = "The device is a part of the avr1 family", .dependencies = .{ .ints = .{ 38797314, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "avr2", .llvm_name = "avr2", .description = "The device is a part of the avr2 family", .dependencies = .{ .ints = .{ 2147745797, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "avr25", .llvm_name = "avr25", .description = "The device is a part of the avr25 family", .dependencies = .{ .ints = .{ 547364872, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "avr3", .llvm_name = "avr3", .description = "The device is a part of the avr3 family", .dependencies = .{ .ints = .{ 524296, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "avr31", .llvm_name = "avr31", .description = "The device is a part of the avr31 family", .dependencies = .{ .ints = .{ 65568, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "avr35", .llvm_name = "avr35", .description = "The device is a part of the avr35 family", .dependencies = .{ .ints = .{ 547364896, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "avr4", .llvm_name = "avr4", .description = "The device is a part of the avr4 family", .dependencies = .{ .ints = .{ 564142088, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "avr5", .llvm_name = "avr5", .description = "The device is a part of the avr5 family", .dependencies = .{ .ints = .{ 564142112, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "avr51", .llvm_name = "avr51", .description = "The device is a part of the avr51 family", .dependencies = .{ .ints = .{ 197120, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "avr6", .llvm_name = "avr6", .description = "The device is a part of the avr6 family", .dependencies = .{ .ints = .{ 33792, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "avrtiny", .llvm_name = "avrtiny", .description = "The device is a part of the avrtiny family", .dependencies = .{ .ints = .{ 6576676866, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "break", .llvm_name = "break", .description = "The device supports the `BREAK` debugging instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "des", .llvm_name = "des", .description = "The device supports the `DES k` encryption instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "eijmpcall", .llvm_name = "eijmpcall", .description = "The device supports the `EIJMP`/`EICALL` instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "elpm", .llvm_name = "elpm", .description = "The device supports the ELPM instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "elpmx", .llvm_name = "elpmx", .description = "The device supports the `ELPM Rd, Z[+]` instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "ijmpcall", .llvm_name = "ijmpcall", .description = "The device supports `IJMP`/`ICALL`instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "jmpcall", .llvm_name = "jmpcall", .description = "The device supports the `JMP` and `CALL` instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "lpm", .llvm_name = "lpm", .description = "The device supports the `LPM` instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "lpmx", .llvm_name = "lpmx", .description = "The device supports the `LPM Rd, Z[+]` instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "memmappedregs", .llvm_name = "memmappedregs", .description = "The device has CPU registers mapped in data address space", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "movw", .llvm_name = "movw", .description = "The device supports the 16-bit MOVW instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "mul", .llvm_name = "mul", .description = "The device supports the multiplication instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "progmem", .llvm_name = "progmem", .description = "The device has a separate flash namespace", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "rmw", .llvm_name = "rmw", .description = "The device supports the read-write-modify instructions: XCH, LAS, LAC, LAT", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "smallstack", .llvm_name = "smallstack", .description = "The device has an 8-bit stack pointer", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "special", .llvm_name = "special", .description = "Enable use of the entire instruction set - used for debugging", .dependencies = .{ .ints = .{ 3858751489, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "spm", .llvm_name = "spm", .description = "The device supports the `SPM` instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "spmx", .llvm_name = "spmx", .description = "The device supports the `SPM Z+` instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "sram", .llvm_name = "sram", .description = "The device has random access memory", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "tinyencoding", .llvm_name = "tinyencoding", .description = "The device has Tiny core specific instruction encodings", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "xmega", .llvm_name = "xmega", .description = "The device is a part of the xmega family", .dependencies = .{ .ints = .{ 3821002755, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "xmega3", .llvm_name = "xmega3", .description = "The device is a part of the xmega3 family", .dependencies = .{ .ints = .{ 2210144259, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "xmegau", .llvm_name = "xmegau", .description = "The device is a part of the xmegau family", .dependencies = .{ .ints = .{ 8657043456, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const at43usb320: Cpu = .{ .name = "at43usb320", .llvm_name = "at43usb320", .features = .{ .ints = .{ 64, 0, 0, 0, 0 } } };
            const at43usb355: Cpu = .{ .name = "at43usb355", .llvm_name = "at43usb355", .features = .{ .ints = .{ 32, 0, 0, 0, 0 } } };
            const at76c711: Cpu = .{ .name = "at76c711", .llvm_name = "at76c711", .features = .{ .ints = .{ 32, 0, 0, 0, 0 } } };
            const at86rf401: Cpu = .{ .name = "at86rf401", .llvm_name = "at86rf401", .features = .{ .ints = .{ 10485768, 0, 0, 0, 0 } } };
            const at90c8534: Cpu = .{ .name = "at90c8534", .llvm_name = "at90c8534", .features = .{ .ints = .{ 8, 0, 0, 0, 0 } } };
            const at90can128: Cpu = .{ .name = "at90can128", .llvm_name = "at90can128", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const at90can32: Cpu = .{ .name = "at90can32", .llvm_name = "at90can32", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90can64: Cpu = .{ .name = "at90can64", .llvm_name = "at90can64", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90pwm1: Cpu = .{ .name = "at90pwm1", .llvm_name = "at90pwm1", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90pwm161: Cpu = .{ .name = "at90pwm161", .llvm_name = "at90pwm161", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90pwm2: Cpu = .{ .name = "at90pwm2", .llvm_name = "at90pwm2", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90pwm216: Cpu = .{ .name = "at90pwm216", .llvm_name = "at90pwm216", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90pwm2b: Cpu = .{ .name = "at90pwm2b", .llvm_name = "at90pwm2b", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90pwm3: Cpu = .{ .name = "at90pwm3", .llvm_name = "at90pwm3", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90pwm316: Cpu = .{ .name = "at90pwm316", .llvm_name = "at90pwm316", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90pwm3b: Cpu = .{ .name = "at90pwm3b", .llvm_name = "at90pwm3b", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90pwm81: Cpu = .{ .name = "at90pwm81", .llvm_name = "at90pwm81", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const at90s1200: Cpu = .{ .name = "at90s1200", .llvm_name = "at90s1200", .features = .{ .ints = .{ 134217730, 0, 0, 0, 0 } } };
            const at90s2313: Cpu = .{ .name = "at90s2313", .llvm_name = "at90s2313", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s2323: Cpu = .{ .name = "at90s2323", .llvm_name = "at90s2323", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s2333: Cpu = .{ .name = "at90s2333", .llvm_name = "at90s2333", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s2343: Cpu = .{ .name = "at90s2343", .llvm_name = "at90s2343", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s4414: Cpu = .{ .name = "at90s4414", .llvm_name = "at90s4414", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s4433: Cpu = .{ .name = "at90s4433", .llvm_name = "at90s4433", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s4434: Cpu = .{ .name = "at90s4434", .llvm_name = "at90s4434", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const at90s8515: Cpu = .{ .name = "at90s8515", .llvm_name = "at90s8515", .features = .{ .ints = .{ 8, 0, 0, 0, 0 } } };
            const at90s8535: Cpu = .{ .name = "at90s8535", .llvm_name = "at90s8535", .features = .{ .ints = .{ 8, 0, 0, 0, 0 } } };
            const at90scr100: Cpu = .{ .name = "at90scr100", .llvm_name = "at90scr100", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90usb1286: Cpu = .{ .name = "at90usb1286", .llvm_name = "at90usb1286", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const at90usb1287: Cpu = .{ .name = "at90usb1287", .llvm_name = "at90usb1287", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const at90usb162: Cpu = .{ .name = "at90usb162", .llvm_name = "at90usb162", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const at90usb646: Cpu = .{ .name = "at90usb646", .llvm_name = "at90usb646", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90usb647: Cpu = .{ .name = "at90usb647", .llvm_name = "at90usb647", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const at90usb82: Cpu = .{ .name = "at90usb82", .llvm_name = "at90usb82", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const at94k: Cpu = .{ .name = "at94k", .llvm_name = "at94k", .features = .{ .ints = .{ 27263008, 0, 0, 0, 0 } } };
            const ata5272: Cpu = .{ .name = "ata5272", .llvm_name = "ata5272", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const ata5505: Cpu = .{ .name = "ata5505", .llvm_name = "ata5505", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const ata5702m322: Cpu = .{ .name = "ata5702m322", .llvm_name = "ata5702m322", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5782: Cpu = .{ .name = "ata5782", .llvm_name = "ata5782", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5790: Cpu = .{ .name = "ata5790", .llvm_name = "ata5790", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5790n: Cpu = .{ .name = "ata5790n", .llvm_name = "ata5790n", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5791: Cpu = .{ .name = "ata5791", .llvm_name = "ata5791", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5795: Cpu = .{ .name = "ata5795", .llvm_name = "ata5795", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata5831: Cpu = .{ .name = "ata5831", .llvm_name = "ata5831", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata6285: Cpu = .{ .name = "ata6285", .llvm_name = "ata6285", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const ata6286: Cpu = .{ .name = "ata6286", .llvm_name = "ata6286", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const ata6289: Cpu = .{ .name = "ata6289", .llvm_name = "ata6289", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const ata6612c: Cpu = .{ .name = "ata6612c", .llvm_name = "ata6612c", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const ata6613c: Cpu = .{ .name = "ata6613c", .llvm_name = "ata6613c", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata6614q: Cpu = .{ .name = "ata6614q", .llvm_name = "ata6614q", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata6616c: Cpu = .{ .name = "ata6616c", .llvm_name = "ata6616c", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const ata6617c: Cpu = .{ .name = "ata6617c", .llvm_name = "ata6617c", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const ata664251: Cpu = .{ .name = "ata664251", .llvm_name = "ata664251", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const ata8210: Cpu = .{ .name = "ata8210", .llvm_name = "ata8210", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const ata8510: Cpu = .{ .name = "ata8510", .llvm_name = "ata8510", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega103: Cpu = .{ .name = "atmega103", .llvm_name = "atmega103", .features = .{ .ints = .{ 64, 0, 0, 0, 0 } } };
            const atmega128: Cpu = .{ .name = "atmega128", .llvm_name = "atmega128", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega1280: Cpu = .{ .name = "atmega1280", .llvm_name = "atmega1280", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega1281: Cpu = .{ .name = "atmega1281", .llvm_name = "atmega1281", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega1284: Cpu = .{ .name = "atmega1284", .llvm_name = "atmega1284", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega1284p: Cpu = .{ .name = "atmega1284p", .llvm_name = "atmega1284p", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega1284rfr2: Cpu = .{ .name = "atmega1284rfr2", .llvm_name = "atmega1284rfr2", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega128a: Cpu = .{ .name = "atmega128a", .llvm_name = "atmega128a", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega128rfa1: Cpu = .{ .name = "atmega128rfa1", .llvm_name = "atmega128rfa1", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega128rfr2: Cpu = .{ .name = "atmega128rfr2", .llvm_name = "atmega128rfr2", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const atmega16: Cpu = .{ .name = "atmega16", .llvm_name = "atmega16", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega1608: Cpu = .{ .name = "atmega1608", .llvm_name = "atmega1608", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega1609: Cpu = .{ .name = "atmega1609", .llvm_name = "atmega1609", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega161: Cpu = .{ .name = "atmega161", .llvm_name = "atmega161", .features = .{ .ints = .{ 564133920, 0, 0, 0, 0 } } };
            const atmega162: Cpu = .{ .name = "atmega162", .llvm_name = "atmega162", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega163: Cpu = .{ .name = "atmega163", .llvm_name = "atmega163", .features = .{ .ints = .{ 564133920, 0, 0, 0, 0 } } };
            const atmega164a: Cpu = .{ .name = "atmega164a", .llvm_name = "atmega164a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega164p: Cpu = .{ .name = "atmega164p", .llvm_name = "atmega164p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega164pa: Cpu = .{ .name = "atmega164pa", .llvm_name = "atmega164pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega165: Cpu = .{ .name = "atmega165", .llvm_name = "atmega165", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega165a: Cpu = .{ .name = "atmega165a", .llvm_name = "atmega165a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega165p: Cpu = .{ .name = "atmega165p", .llvm_name = "atmega165p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega165pa: Cpu = .{ .name = "atmega165pa", .llvm_name = "atmega165pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega168: Cpu = .{ .name = "atmega168", .llvm_name = "atmega168", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega168a: Cpu = .{ .name = "atmega168a", .llvm_name = "atmega168a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega168p: Cpu = .{ .name = "atmega168p", .llvm_name = "atmega168p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega168pa: Cpu = .{ .name = "atmega168pa", .llvm_name = "atmega168pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega168pb: Cpu = .{ .name = "atmega168pb", .llvm_name = "atmega168pb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega169: Cpu = .{ .name = "atmega169", .llvm_name = "atmega169", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega169a: Cpu = .{ .name = "atmega169a", .llvm_name = "atmega169a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega169p: Cpu = .{ .name = "atmega169p", .llvm_name = "atmega169p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega169pa: Cpu = .{ .name = "atmega169pa", .llvm_name = "atmega169pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16a: Cpu = .{ .name = "atmega16a", .llvm_name = "atmega16a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16hva: Cpu = .{ .name = "atmega16hva", .llvm_name = "atmega16hva", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16hva2: Cpu = .{ .name = "atmega16hva2", .llvm_name = "atmega16hva2", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16hvb: Cpu = .{ .name = "atmega16hvb", .llvm_name = "atmega16hvb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16hvbrevb: Cpu = .{ .name = "atmega16hvbrevb", .llvm_name = "atmega16hvbrevb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16m1: Cpu = .{ .name = "atmega16m1", .llvm_name = "atmega16m1", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega16u2: Cpu = .{ .name = "atmega16u2", .llvm_name = "atmega16u2", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const atmega16u4: Cpu = .{ .name = "atmega16u4", .llvm_name = "atmega16u4", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega2560: Cpu = .{ .name = "atmega2560", .llvm_name = "atmega2560", .features = .{ .ints = .{ 2048, 0, 0, 0, 0 } } };
            const atmega2561: Cpu = .{ .name = "atmega2561", .llvm_name = "atmega2561", .features = .{ .ints = .{ 2048, 0, 0, 0, 0 } } };
            const atmega2564rfr2: Cpu = .{ .name = "atmega2564rfr2", .llvm_name = "atmega2564rfr2", .features = .{ .ints = .{ 2048, 0, 0, 0, 0 } } };
            const atmega256rfr2: Cpu = .{ .name = "atmega256rfr2", .llvm_name = "atmega256rfr2", .features = .{ .ints = .{ 2048, 0, 0, 0, 0 } } };
            const atmega32: Cpu = .{ .name = "atmega32", .llvm_name = "atmega32", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3208: Cpu = .{ .name = "atmega3208", .llvm_name = "atmega3208", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega3209: Cpu = .{ .name = "atmega3209", .llvm_name = "atmega3209", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega323: Cpu = .{ .name = "atmega323", .llvm_name = "atmega323", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega324a: Cpu = .{ .name = "atmega324a", .llvm_name = "atmega324a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega324p: Cpu = .{ .name = "atmega324p", .llvm_name = "atmega324p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega324pa: Cpu = .{ .name = "atmega324pa", .llvm_name = "atmega324pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega324pb: Cpu = .{ .name = "atmega324pb", .llvm_name = "atmega324pb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega325: Cpu = .{ .name = "atmega325", .llvm_name = "atmega325", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3250: Cpu = .{ .name = "atmega3250", .llvm_name = "atmega3250", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3250a: Cpu = .{ .name = "atmega3250a", .llvm_name = "atmega3250a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3250p: Cpu = .{ .name = "atmega3250p", .llvm_name = "atmega3250p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3250pa: Cpu = .{ .name = "atmega3250pa", .llvm_name = "atmega3250pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega325a: Cpu = .{ .name = "atmega325a", .llvm_name = "atmega325a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega325p: Cpu = .{ .name = "atmega325p", .llvm_name = "atmega325p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega325pa: Cpu = .{ .name = "atmega325pa", .llvm_name = "atmega325pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega328: Cpu = .{ .name = "atmega328", .llvm_name = "atmega328", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega328p: Cpu = .{ .name = "atmega328p", .llvm_name = "atmega328p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega328pb: Cpu = .{ .name = "atmega328pb", .llvm_name = "atmega328pb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega329: Cpu = .{ .name = "atmega329", .llvm_name = "atmega329", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3290: Cpu = .{ .name = "atmega3290", .llvm_name = "atmega3290", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3290a: Cpu = .{ .name = "atmega3290a", .llvm_name = "atmega3290a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3290p: Cpu = .{ .name = "atmega3290p", .llvm_name = "atmega3290p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega3290pa: Cpu = .{ .name = "atmega3290pa", .llvm_name = "atmega3290pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega329a: Cpu = .{ .name = "atmega329a", .llvm_name = "atmega329a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega329p: Cpu = .{ .name = "atmega329p", .llvm_name = "atmega329p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega329pa: Cpu = .{ .name = "atmega329pa", .llvm_name = "atmega329pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32a: Cpu = .{ .name = "atmega32a", .llvm_name = "atmega32a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32c1: Cpu = .{ .name = "atmega32c1", .llvm_name = "atmega32c1", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32hvb: Cpu = .{ .name = "atmega32hvb", .llvm_name = "atmega32hvb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32hvbrevb: Cpu = .{ .name = "atmega32hvbrevb", .llvm_name = "atmega32hvbrevb", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32m1: Cpu = .{ .name = "atmega32m1", .llvm_name = "atmega32m1", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32u2: Cpu = .{ .name = "atmega32u2", .llvm_name = "atmega32u2", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const atmega32u4: Cpu = .{ .name = "atmega32u4", .llvm_name = "atmega32u4", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega32u6: Cpu = .{ .name = "atmega32u6", .llvm_name = "atmega32u6", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega406: Cpu = .{ .name = "atmega406", .llvm_name = "atmega406", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega48: Cpu = .{ .name = "atmega48", .llvm_name = "atmega48", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega4808: Cpu = .{ .name = "atmega4808", .llvm_name = "atmega4808", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega4809: Cpu = .{ .name = "atmega4809", .llvm_name = "atmega4809", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega48a: Cpu = .{ .name = "atmega48a", .llvm_name = "atmega48a", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega48p: Cpu = .{ .name = "atmega48p", .llvm_name = "atmega48p", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega48pa: Cpu = .{ .name = "atmega48pa", .llvm_name = "atmega48pa", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega48pb: Cpu = .{ .name = "atmega48pb", .llvm_name = "atmega48pb", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega64: Cpu = .{ .name = "atmega64", .llvm_name = "atmega64", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega640: Cpu = .{ .name = "atmega640", .llvm_name = "atmega640", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega644: Cpu = .{ .name = "atmega644", .llvm_name = "atmega644", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega644a: Cpu = .{ .name = "atmega644a", .llvm_name = "atmega644a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega644p: Cpu = .{ .name = "atmega644p", .llvm_name = "atmega644p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega644pa: Cpu = .{ .name = "atmega644pa", .llvm_name = "atmega644pa", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega644rfr2: Cpu = .{ .name = "atmega644rfr2", .llvm_name = "atmega644rfr2", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega645: Cpu = .{ .name = "atmega645", .llvm_name = "atmega645", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6450: Cpu = .{ .name = "atmega6450", .llvm_name = "atmega6450", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6450a: Cpu = .{ .name = "atmega6450a", .llvm_name = "atmega6450a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6450p: Cpu = .{ .name = "atmega6450p", .llvm_name = "atmega6450p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega645a: Cpu = .{ .name = "atmega645a", .llvm_name = "atmega645a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega645p: Cpu = .{ .name = "atmega645p", .llvm_name = "atmega645p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega649: Cpu = .{ .name = "atmega649", .llvm_name = "atmega649", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6490: Cpu = .{ .name = "atmega6490", .llvm_name = "atmega6490", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6490a: Cpu = .{ .name = "atmega6490a", .llvm_name = "atmega6490a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega6490p: Cpu = .{ .name = "atmega6490p", .llvm_name = "atmega6490p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega649a: Cpu = .{ .name = "atmega649a", .llvm_name = "atmega649a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega649p: Cpu = .{ .name = "atmega649p", .llvm_name = "atmega649p", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64a: Cpu = .{ .name = "atmega64a", .llvm_name = "atmega64a", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64c1: Cpu = .{ .name = "atmega64c1", .llvm_name = "atmega64c1", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64hve: Cpu = .{ .name = "atmega64hve", .llvm_name = "atmega64hve", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64hve2: Cpu = .{ .name = "atmega64hve2", .llvm_name = "atmega64hve2", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64m1: Cpu = .{ .name = "atmega64m1", .llvm_name = "atmega64m1", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega64rfr2: Cpu = .{ .name = "atmega64rfr2", .llvm_name = "atmega64rfr2", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const atmega8: Cpu = .{ .name = "atmega8", .llvm_name = "atmega8", .features = .{ .ints = .{ 564133896, 0, 0, 0, 0 } } };
            const atmega808: Cpu = .{ .name = "atmega808", .llvm_name = "atmega808", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega809: Cpu = .{ .name = "atmega809", .llvm_name = "atmega809", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const atmega8515: Cpu = .{ .name = "atmega8515", .llvm_name = "atmega8515", .features = .{ .ints = .{ 564133896, 0, 0, 0, 0 } } };
            const atmega8535: Cpu = .{ .name = "atmega8535", .llvm_name = "atmega8535", .features = .{ .ints = .{ 564133896, 0, 0, 0, 0 } } };
            const atmega88: Cpu = .{ .name = "atmega88", .llvm_name = "atmega88", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega88a: Cpu = .{ .name = "atmega88a", .llvm_name = "atmega88a", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega88p: Cpu = .{ .name = "atmega88p", .llvm_name = "atmega88p", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega88pa: Cpu = .{ .name = "atmega88pa", .llvm_name = "atmega88pa", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega88pb: Cpu = .{ .name = "atmega88pb", .llvm_name = "atmega88pb", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega8a: Cpu = .{ .name = "atmega8a", .llvm_name = "atmega8a", .features = .{ .ints = .{ 564133896, 0, 0, 0, 0 } } };
            const atmega8hva: Cpu = .{ .name = "atmega8hva", .llvm_name = "atmega8hva", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const atmega8u2: Cpu = .{ .name = "atmega8u2", .llvm_name = "atmega8u2", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const attiny10: Cpu = .{ .name = "attiny10", .llvm_name = "attiny10", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny102: Cpu = .{ .name = "attiny102", .llvm_name = "attiny102", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny104: Cpu = .{ .name = "attiny104", .llvm_name = "attiny104", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny11: Cpu = .{ .name = "attiny11", .llvm_name = "attiny11", .features = .{ .ints = .{ 134217732, 0, 0, 0, 0 } } };
            const attiny12: Cpu = .{ .name = "attiny12", .llvm_name = "attiny12", .features = .{ .ints = .{ 134217732, 0, 0, 0, 0 } } };
            const attiny13: Cpu = .{ .name = "attiny13", .llvm_name = "attiny13", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny13a: Cpu = .{ .name = "attiny13a", .llvm_name = "attiny13a", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny15: Cpu = .{ .name = "attiny15", .llvm_name = "attiny15", .features = .{ .ints = .{ 134217732, 0, 0, 0, 0 } } };
            const attiny1604: Cpu = .{ .name = "attiny1604", .llvm_name = "attiny1604", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1606: Cpu = .{ .name = "attiny1606", .llvm_name = "attiny1606", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1607: Cpu = .{ .name = "attiny1607", .llvm_name = "attiny1607", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1614: Cpu = .{ .name = "attiny1614", .llvm_name = "attiny1614", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1616: Cpu = .{ .name = "attiny1616", .llvm_name = "attiny1616", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1617: Cpu = .{ .name = "attiny1617", .llvm_name = "attiny1617", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1624: Cpu = .{ .name = "attiny1624", .llvm_name = "attiny1624", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1626: Cpu = .{ .name = "attiny1626", .llvm_name = "attiny1626", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1627: Cpu = .{ .name = "attiny1627", .llvm_name = "attiny1627", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny1634: Cpu = .{ .name = "attiny1634", .llvm_name = "attiny1634", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const attiny167: Cpu = .{ .name = "attiny167", .llvm_name = "attiny167", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const attiny20: Cpu = .{ .name = "attiny20", .llvm_name = "attiny20", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny202: Cpu = .{ .name = "attiny202", .llvm_name = "attiny202", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny204: Cpu = .{ .name = "attiny204", .llvm_name = "attiny204", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny212: Cpu = .{ .name = "attiny212", .llvm_name = "attiny212", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny214: Cpu = .{ .name = "attiny214", .llvm_name = "attiny214", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny22: Cpu = .{ .name = "attiny22", .llvm_name = "attiny22", .features = .{ .ints = .{ 134217736, 0, 0, 0, 0 } } };
            const attiny2313: Cpu = .{ .name = "attiny2313", .llvm_name = "attiny2313", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny2313a: Cpu = .{ .name = "attiny2313a", .llvm_name = "attiny2313a", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny24: Cpu = .{ .name = "attiny24", .llvm_name = "attiny24", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny24a: Cpu = .{ .name = "attiny24a", .llvm_name = "attiny24a", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny25: Cpu = .{ .name = "attiny25", .llvm_name = "attiny25", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny26: Cpu = .{ .name = "attiny26", .llvm_name = "attiny26", .features = .{ .ints = .{ 136314888, 0, 0, 0, 0 } } };
            const attiny261: Cpu = .{ .name = "attiny261", .llvm_name = "attiny261", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny261a: Cpu = .{ .name = "attiny261a", .llvm_name = "attiny261a", .features = .{ .ints = .{ 134217744, 0, 0, 0, 0 } } };
            const attiny28: Cpu = .{ .name = "attiny28", .llvm_name = "attiny28", .features = .{ .ints = .{ 134217732, 0, 0, 0, 0 } } };
            const attiny3216: Cpu = .{ .name = "attiny3216", .llvm_name = "attiny3216", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny3217: Cpu = .{ .name = "attiny3217", .llvm_name = "attiny3217", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny4: Cpu = .{ .name = "attiny4", .llvm_name = "attiny4", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny40: Cpu = .{ .name = "attiny40", .llvm_name = "attiny40", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny402: Cpu = .{ .name = "attiny402", .llvm_name = "attiny402", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny404: Cpu = .{ .name = "attiny404", .llvm_name = "attiny404", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny406: Cpu = .{ .name = "attiny406", .llvm_name = "attiny406", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny412: Cpu = .{ .name = "attiny412", .llvm_name = "attiny412", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny414: Cpu = .{ .name = "attiny414", .llvm_name = "attiny414", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny416: Cpu = .{ .name = "attiny416", .llvm_name = "attiny416", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny417: Cpu = .{ .name = "attiny417", .llvm_name = "attiny417", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny4313: Cpu = .{ .name = "attiny4313", .llvm_name = "attiny4313", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny43u: Cpu = .{ .name = "attiny43u", .llvm_name = "attiny43u", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny44: Cpu = .{ .name = "attiny44", .llvm_name = "attiny44", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny441: Cpu = .{ .name = "attiny441", .llvm_name = "attiny441", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny44a: Cpu = .{ .name = "attiny44a", .llvm_name = "attiny44a", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny45: Cpu = .{ .name = "attiny45", .llvm_name = "attiny45", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny461: Cpu = .{ .name = "attiny461", .llvm_name = "attiny461", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny461a: Cpu = .{ .name = "attiny461a", .llvm_name = "attiny461a", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny48: Cpu = .{ .name = "attiny48", .llvm_name = "attiny48", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny5: Cpu = .{ .name = "attiny5", .llvm_name = "attiny5", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const attiny804: Cpu = .{ .name = "attiny804", .llvm_name = "attiny804", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny806: Cpu = .{ .name = "attiny806", .llvm_name = "attiny806", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny807: Cpu = .{ .name = "attiny807", .llvm_name = "attiny807", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny814: Cpu = .{ .name = "attiny814", .llvm_name = "attiny814", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny816: Cpu = .{ .name = "attiny816", .llvm_name = "attiny816", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny817: Cpu = .{ .name = "attiny817", .llvm_name = "attiny817", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const attiny828: Cpu = .{ .name = "attiny828", .llvm_name = "attiny828", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny84: Cpu = .{ .name = "attiny84", .llvm_name = "attiny84", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny841: Cpu = .{ .name = "attiny841", .llvm_name = "attiny841", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny84a: Cpu = .{ .name = "attiny84a", .llvm_name = "attiny84a", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny85: Cpu = .{ .name = "attiny85", .llvm_name = "attiny85", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny861: Cpu = .{ .name = "attiny861", .llvm_name = "attiny861", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny861a: Cpu = .{ .name = "attiny861a", .llvm_name = "attiny861a", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny87: Cpu = .{ .name = "attiny87", .llvm_name = "attiny87", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny88: Cpu = .{ .name = "attiny88", .llvm_name = "attiny88", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const attiny9: Cpu = .{ .name = "attiny9", .llvm_name = "attiny9", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const atxmega128a1: Cpu = .{ .name = "atxmega128a1", .llvm_name = "atxmega128a1", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega128a1u: Cpu = .{ .name = "atxmega128a1u", .llvm_name = "atxmega128a1u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128a3: Cpu = .{ .name = "atxmega128a3", .llvm_name = "atxmega128a3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega128a3u: Cpu = .{ .name = "atxmega128a3u", .llvm_name = "atxmega128a3u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128a4u: Cpu = .{ .name = "atxmega128a4u", .llvm_name = "atxmega128a4u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128b1: Cpu = .{ .name = "atxmega128b1", .llvm_name = "atxmega128b1", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128b3: Cpu = .{ .name = "atxmega128b3", .llvm_name = "atxmega128b3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128c3: Cpu = .{ .name = "atxmega128c3", .llvm_name = "atxmega128c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega128d3: Cpu = .{ .name = "atxmega128d3", .llvm_name = "atxmega128d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega128d4: Cpu = .{ .name = "atxmega128d4", .llvm_name = "atxmega128d4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega16a4: Cpu = .{ .name = "atxmega16a4", .llvm_name = "atxmega16a4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega16a4u: Cpu = .{ .name = "atxmega16a4u", .llvm_name = "atxmega16a4u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega16c4: Cpu = .{ .name = "atxmega16c4", .llvm_name = "atxmega16c4", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega16d4: Cpu = .{ .name = "atxmega16d4", .llvm_name = "atxmega16d4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega16e5: Cpu = .{ .name = "atxmega16e5", .llvm_name = "atxmega16e5", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega192a3: Cpu = .{ .name = "atxmega192a3", .llvm_name = "atxmega192a3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega192a3u: Cpu = .{ .name = "atxmega192a3u", .llvm_name = "atxmega192a3u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega192c3: Cpu = .{ .name = "atxmega192c3", .llvm_name = "atxmega192c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega192d3: Cpu = .{ .name = "atxmega192d3", .llvm_name = "atxmega192d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega256a3: Cpu = .{ .name = "atxmega256a3", .llvm_name = "atxmega256a3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega256a3b: Cpu = .{ .name = "atxmega256a3b", .llvm_name = "atxmega256a3b", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega256a3bu: Cpu = .{ .name = "atxmega256a3bu", .llvm_name = "atxmega256a3bu", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega256a3u: Cpu = .{ .name = "atxmega256a3u", .llvm_name = "atxmega256a3u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega256c3: Cpu = .{ .name = "atxmega256c3", .llvm_name = "atxmega256c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega256d3: Cpu = .{ .name = "atxmega256d3", .llvm_name = "atxmega256d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega32a4: Cpu = .{ .name = "atxmega32a4", .llvm_name = "atxmega32a4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega32a4u: Cpu = .{ .name = "atxmega32a4u", .llvm_name = "atxmega32a4u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega32c3: Cpu = .{ .name = "atxmega32c3", .llvm_name = "atxmega32c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega32c4: Cpu = .{ .name = "atxmega32c4", .llvm_name = "atxmega32c4", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega32d3: Cpu = .{ .name = "atxmega32d3", .llvm_name = "atxmega32d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega32d4: Cpu = .{ .name = "atxmega32d4", .llvm_name = "atxmega32d4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega32e5: Cpu = .{ .name = "atxmega32e5", .llvm_name = "atxmega32e5", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega384c3: Cpu = .{ .name = "atxmega384c3", .llvm_name = "atxmega384c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega384d3: Cpu = .{ .name = "atxmega384d3", .llvm_name = "atxmega384d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega64a1: Cpu = .{ .name = "atxmega64a1", .llvm_name = "atxmega64a1", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega64a1u: Cpu = .{ .name = "atxmega64a1u", .llvm_name = "atxmega64a1u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64a3: Cpu = .{ .name = "atxmega64a3", .llvm_name = "atxmega64a3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega64a3u: Cpu = .{ .name = "atxmega64a3u", .llvm_name = "atxmega64a3u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64a4u: Cpu = .{ .name = "atxmega64a4u", .llvm_name = "atxmega64a4u", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64b1: Cpu = .{ .name = "atxmega64b1", .llvm_name = "atxmega64b1", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64b3: Cpu = .{ .name = "atxmega64b3", .llvm_name = "atxmega64b3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64c3: Cpu = .{ .name = "atxmega64c3", .llvm_name = "atxmega64c3", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const atxmega64d3: Cpu = .{ .name = "atxmega64d3", .llvm_name = "atxmega64d3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega64d4: Cpu = .{ .name = "atxmega64d4", .llvm_name = "atxmega64d4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const atxmega8e5: Cpu = .{ .name = "atxmega8e5", .llvm_name = "atxmega8e5", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const avr1: Cpu = .{ .name = "avr1", .llvm_name = "avr1", .features = .{ .ints = .{ 4, 0, 0, 0, 0 } } };
            const avr2: Cpu = .{ .name = "avr2", .llvm_name = "avr2", .features = .{ .ints = .{ 8, 0, 0, 0, 0 } } };
            const avr25: Cpu = .{ .name = "avr25", .llvm_name = "avr25", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const avr3: Cpu = .{ .name = "avr3", .llvm_name = "avr3", .features = .{ .ints = .{ 32, 0, 0, 0, 0 } } };
            const avr31: Cpu = .{ .name = "avr31", .llvm_name = "avr31", .features = .{ .ints = .{ 64, 0, 0, 0, 0 } } };
            const avr35: Cpu = .{ .name = "avr35", .llvm_name = "avr35", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const avr4: Cpu = .{ .name = "avr4", .llvm_name = "avr4", .features = .{ .ints = .{ 256, 0, 0, 0, 0 } } };
            const avr5: Cpu = .{ .name = "avr5", .llvm_name = "avr5", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
            const avr51: Cpu = .{ .name = "avr51", .llvm_name = "avr51", .features = .{ .ints = .{ 1024, 0, 0, 0, 0 } } };
            const avr6: Cpu = .{ .name = "avr6", .llvm_name = "avr6", .features = .{ .ints = .{ 2048, 0, 0, 0, 0 } } };
            const avrtiny: Cpu = .{ .name = "avrtiny", .llvm_name = "avrtiny", .features = .{ .ints = .{ 4096, 0, 0, 0, 0 } } };
            const avrxmega1: Cpu = .{ .name = "avrxmega1", .llvm_name = "avrxmega1", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const avrxmega2: Cpu = .{ .name = "avrxmega2", .llvm_name = "avrxmega2", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const avrxmega3: Cpu = .{ .name = "avrxmega3", .llvm_name = "avrxmega3", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const avrxmega4: Cpu = .{ .name = "avrxmega4", .llvm_name = "avrxmega4", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const avrxmega5: Cpu = .{ .name = "avrxmega5", .llvm_name = "avrxmega5", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const avrxmega6: Cpu = .{ .name = "avrxmega6", .llvm_name = "avrxmega6", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const avrxmega7: Cpu = .{ .name = "avrxmega7", .llvm_name = "avrxmega7", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const m3000: Cpu = .{ .name = "m3000", .llvm_name = "m3000", .features = .{ .ints = .{ 512, 0, 0, 0, 0 } } };
        };
    };
    pub const bpf = struct {
        pub const Feature = enum(u2) {
            alu32 = 0,
            dummy = 1,
            dwarfris = 2,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "alu32", .llvm_name = "alu32", .description = "Enable ALU32 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "dummy", .llvm_name = "dummy", .description = "unused feature", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "dwarfris", .llvm_name = "dwarfris", .description = "Disable MCAsmInfo DwarfUsesRelocationsAcrossSections", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const probe: Cpu = .{ .name = "probe", .llvm_name = "probe", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const v1: Cpu = .{ .name = "v1", .llvm_name = "v1", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const v2: Cpu = .{ .name = "v2", .llvm_name = "v2", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const v3: Cpu = .{ .name = "v3", .llvm_name = "v3", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
    pub const csky = struct {
        pub const Feature = enum(u6) {
            @"10e60" = 0,
            @"2e3" = 1,
            @"3e3r1" = 2,
            @"3e3r2" = 3,
            @"3e3r3" = 4,
            @"3e7" = 5,
            @"7e10" = 6,
            btst16 = 7,
            cache = 8,
            ccrt = 9,
            ck801 = 10,
            ck802 = 11,
            ck803 = 12,
            ck803s = 13,
            ck804 = 14,
            ck805 = 15,
            ck807 = 16,
            ck810 = 17,
            ck810v = 18,
            ck860 = 19,
            ck860v = 20,
            constpool = 21,
            doloop = 22,
            dsp1e2 = 23,
            dsp_silan = 24,
            dspe60 = 25,
            dspv2 = 26,
            e1 = 27,
            e2 = 28,
            edsp = 29,
            elrw = 30,
            fdivdu = 31,
            float1e2 = 32,
            float1e3 = 33,
            float3e4 = 34,
            float7e60 = 35,
            floate1 = 36,
            fpuv2_df = 37,
            fpuv2_sf = 38,
            fpuv3_df = 39,
            fpuv3_hf = 40,
            fpuv3_hi = 41,
            fpuv3_sf = 42,
            hard_float = 43,
            hard_float_abi = 44,
            hard_tp = 45,
            high_registers = 46,
            hwdiv = 47,
            istack = 48,
            java = 49,
            mp = 50,
            mp1e2 = 51,
            multiple_stld = 52,
            nvic = 53,
            pushpop = 54,
            smart = 55,
            soft_tp = 56,
            stack_size = 57,
            trust = 58,
            vdsp2e3 = 59,
            vdsp2e60f = 60,
            vdspv1 = 61,
            vdspv2 = 62,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "10e60", .llvm_name = "10e60", .description = "Support CSKY 10e60 instructions", .dependencies = .{ .ints = .{ 64, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "2e3", .llvm_name = "2e3", .description = "Support CSKY 2e3 instructions", .dependencies = .{ .ints = .{ 268435456, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "3e3r1", .llvm_name = "3e3r1", .description = "Support CSKY 3e3r1 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "3e3r2", .llvm_name = "3e3r2", .description = "Support CSKY 3e3r2 instructions", .dependencies = .{ .ints = .{ 4194308, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "3e3r3", .llvm_name = "3e3r3", .description = "Support CSKY 3e3r3 instructions", .dependencies = .{ .ints = .{ 4194304, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "3e7", .llvm_name = "3e7", .description = "Support CSKY 3e7 instructions", .dependencies = .{ .ints = .{ 2, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "7e10", .llvm_name = "7e10", .description = "Support CSKY 7e10 instructions", .dependencies = .{ .ints = .{ 32, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "btst16", .llvm_name = "btst16", .description = "Use the 16-bit btsti instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "cache", .llvm_name = "cache", .description = "Enable cache", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "ccrt", .llvm_name = "ccrt", .description = "Use CSKY compiler runtime", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "ck801", .llvm_name = "ck801", .description = "CSKY ck801 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "ck802", .llvm_name = "ck802", .description = "CSKY ck802 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "ck803", .llvm_name = "ck803", .description = "CSKY ck803 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "ck803s", .llvm_name = "ck803s", .description = "CSKY ck803s processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "ck804", .llvm_name = "ck804", .description = "CSKY ck804 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "ck805", .llvm_name = "ck805", .description = "CSKY ck805 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "ck807", .llvm_name = "ck807", .description = "CSKY ck807 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "ck810", .llvm_name = "ck810", .description = "CSKY ck810 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "ck810v", .llvm_name = "ck810v", .description = "CSKY ck810v processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "ck860", .llvm_name = "ck860", .description = "CSKY ck860 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "ck860v", .llvm_name = "ck860v", .description = "CSKY ck860v processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "constpool", .llvm_name = "constpool", .description = "Dump the constant pool by compiler", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "doloop", .llvm_name = "doloop", .description = "Enable doloop instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "dsp1e2", .llvm_name = "dsp1e2", .description = "Support CSKY dsp1e2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "dsp_silan", .llvm_name = "dsp_silan", .description = "Enable DSP Silan instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "dspe60", .llvm_name = "dspe60", .description = "Support CSKY dspe60 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "dspv2", .llvm_name = "dspv2", .description = "Enable DSP V2.0 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "e1", .llvm_name = "e1", .description = "Support CSKY e1 instructions", .dependencies = .{ .ints = .{ 1073741824, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "e2", .llvm_name = "e2", .description = "Support CSKY e2 instructions", .dependencies = .{ .ints = .{ 134217728, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "edsp", .llvm_name = "edsp", .description = "Enable DSP instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "elrw", .llvm_name = "elrw", .description = "Use the extend LRW instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "fdivdu", .llvm_name = "fdivdu", .description = "Enable float divide instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "float1e2", .llvm_name = "float1e2", .description = "Support CSKY float1e2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "float1e3", .llvm_name = "float1e3", .description = "Support CSKY float1e3 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "float3e4", .llvm_name = "float3e4", .description = "Support CSKY float3e4 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "float7e60", .llvm_name = "float7e60", .description = "Support CSKY float7e60 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "floate1", .llvm_name = "floate1", .description = "Support CSKY floate1 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "fpuv2_df", .llvm_name = "fpuv2_df", .description = "Enable FPUv2 double float instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "fpuv2_sf", .llvm_name = "fpuv2_sf", .description = "Enable FPUv2 single float instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "fpuv3_df", .llvm_name = "fpuv3_df", .description = "Enable FPUv3 double float instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "fpuv3_hf", .llvm_name = "fpuv3_hf", .description = "Enable FPUv3 harf precision operate instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "fpuv3_hi", .llvm_name = "fpuv3_hi", .description = "Enable FPUv3 harf word converting instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "fpuv3_sf", .llvm_name = "fpuv3_sf", .description = "Enable FPUv3 single float instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "hard_float", .llvm_name = "hard-float", .description = "Use hard floating point features", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "hard_float_abi", .llvm_name = "hard-float-abi", .description = "Use hard floating point ABI to pass args", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "hard_tp", .llvm_name = "hard-tp", .description = "Enable TLS Pointer register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "high_registers", .llvm_name = "high-registers", .description = "Enable r16-r31 registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "hwdiv", .llvm_name = "hwdiv", .description = "Enable divide instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "istack", .llvm_name = "istack", .description = "Enable interrupt attribute", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "java", .llvm_name = "java", .description = "Enable java instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "mp", .llvm_name = "mp", .description = "Support CSKY mp instructions", .dependencies = .{ .ints = .{ 2, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "mp1e2", .llvm_name = "mp1e2", .description = "Support CSKY mp1e2 instructions", .dependencies = .{ .ints = .{ 32, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "multiple_stld", .llvm_name = "multiple_stld", .description = "Enable multiple load/store instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 53, .name = "nvic", .llvm_name = "nvic", .description = "Enable NVIC", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "pushpop", .llvm_name = "pushpop", .description = "Enable push/pop instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "smart", .llvm_name = "smart", .description = "Let CPU work in Smart Mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "soft_tp", .llvm_name = "soft-tp", .description = "Disable TLS Pointer register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "stack_size", .llvm_name = "stack-size", .description = "Output stack size information", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 58, .name = "trust", .llvm_name = "trust", .description = "Enable trust instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "vdsp2e3", .llvm_name = "vdsp2e3", .description = "Support CSKY vdsp2e3 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "vdsp2e60f", .llvm_name = "vdsp2e60f", .description = "Support CSKY vdsp2e60f instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "vdspv1", .llvm_name = "vdspv1", .description = "Enable 128bit vdsp-v1 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 62, .name = "vdspv2", .llvm_name = "vdspv2", .description = "Enable vdsp-v2 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const c807: Cpu = .{ .name = "c807", .llvm_name = "c807", .features = .{ .ints = .{ 300861566310482176, 0, 0, 0, 0 } } };
            const c807f: Cpu = .{ .name = "c807f", .llvm_name = "c807f", .features = .{ .ints = .{ 300862079559074048, 0, 0, 0, 0 } } };
            const c810: Cpu = .{ .name = "c810", .llvm_name = "c810", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const c810t: Cpu = .{ .name = "c810t", .llvm_name = "c810t", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const c810tv: Cpu = .{ .name = "c810tv", .llvm_name = "c810tv", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const c810v: Cpu = .{ .name = "c810v", .llvm_name = "c810v", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const c860: Cpu = .{ .name = "c860", .llvm_name = "c860", .features = .{ .ints = .{ 300869846462628249, 0, 0, 0, 0 } } };
            const c860v: Cpu = .{ .name = "c860v", .llvm_name = "c860v", .features = .{ .ints = .{ 6065477369497911705, 0, 0, 0, 0 } } };
            const ck801: Cpu = .{ .name = "ck801", .llvm_name = "ck801", .features = .{ .ints = .{ 288230376285930624, 0, 0, 0, 0 } } };
            const ck801t: Cpu = .{ .name = "ck801t", .llvm_name = "ck801t", .features = .{ .ints = .{ 288230376285930624, 0, 0, 0, 0 } } };
            const ck802: Cpu = .{ .name = "ck802", .llvm_name = "ck802", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const ck802j: Cpu = .{ .name = "ck802j", .llvm_name = "ck802j", .features = .{ .ints = .{ 297800525628311680, 0, 0, 0, 0 } } };
            const ck802t: Cpu = .{ .name = "ck802t", .llvm_name = "ck802t", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const ck803: Cpu = .{ .name = "ck803", .llvm_name = "ck803", .features = .{ .ints = .{ 298504212801654912, 0, 0, 0, 0 } } };
            const ck803e: Cpu = .{ .name = "ck803e", .llvm_name = "ck803e", .features = .{ .ints = .{ 298504213380468864, 0, 0, 0, 0 } } };
            const ck803ef: Cpu = .{ .name = "ck803ef", .llvm_name = "ck803ef", .features = .{ .ints = .{ 298504565567787136, 0, 0, 0, 0 } } };
            const ck803efh: Cpu = .{ .name = "ck803efh", .llvm_name = "ck803efh", .features = .{ .ints = .{ 298504565567787136, 0, 0, 0, 0 } } };
            const ck803efhr1: Cpu = .{ .name = "ck803efhr1", .llvm_name = "ck803efhr1", .features = .{ .ints = .{ 298574934379073668, 0, 0, 0, 0 } } };
            const ck803efhr2: Cpu = .{ .name = "ck803efhr2", .llvm_name = "ck803efhr2", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803efhr3: Cpu = .{ .name = "ck803efhr3", .llvm_name = "ck803efhr3", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803efht: Cpu = .{ .name = "ck803efht", .llvm_name = "ck803efht", .features = .{ .ints = .{ 298504565567787136, 0, 0, 0, 0 } } };
            const ck803efhtr1: Cpu = .{ .name = "ck803efhtr1", .llvm_name = "ck803efhtr1", .features = .{ .ints = .{ 298574934379073668, 0, 0, 0, 0 } } };
            const ck803efhtr2: Cpu = .{ .name = "ck803efhtr2", .llvm_name = "ck803efhtr2", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803efhtr3: Cpu = .{ .name = "ck803efhtr3", .llvm_name = "ck803efhtr3", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803efr1: Cpu = .{ .name = "ck803efr1", .llvm_name = "ck803efr1", .features = .{ .ints = .{ 298574934379073668, 0, 0, 0, 0 } } };
            const ck803efr2: Cpu = .{ .name = "ck803efr2", .llvm_name = "ck803efr2", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803efr3: Cpu = .{ .name = "ck803efr3", .llvm_name = "ck803efr3", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803eft: Cpu = .{ .name = "ck803eft", .llvm_name = "ck803eft", .features = .{ .ints = .{ 298504565567787136, 0, 0, 0, 0 } } };
            const ck803eftr1: Cpu = .{ .name = "ck803eftr1", .llvm_name = "ck803eftr1", .features = .{ .ints = .{ 298574934379073668, 0, 0, 0, 0 } } };
            const ck803eftr2: Cpu = .{ .name = "ck803eftr2", .llvm_name = "ck803eftr2", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803eftr3: Cpu = .{ .name = "ck803eftr3", .llvm_name = "ck803eftr3", .features = .{ .ints = .{ 298574934379073688, 0, 0, 0, 0 } } };
            const ck803eh: Cpu = .{ .name = "ck803eh", .llvm_name = "ck803eh", .features = .{ .ints = .{ 298504213380468864, 0, 0, 0, 0 } } };
            const ck803ehr1: Cpu = .{ .name = "ck803ehr1", .llvm_name = "ck803ehr1", .features = .{ .ints = .{ 298574582191755412, 0, 0, 0, 0 } } };
            const ck803ehr2: Cpu = .{ .name = "ck803ehr2", .llvm_name = "ck803ehr2", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803ehr3: Cpu = .{ .name = "ck803ehr3", .llvm_name = "ck803ehr3", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803eht: Cpu = .{ .name = "ck803eht", .llvm_name = "ck803eht", .features = .{ .ints = .{ 298504213380468864, 0, 0, 0, 0 } } };
            const ck803ehtr1: Cpu = .{ .name = "ck803ehtr1", .llvm_name = "ck803ehtr1", .features = .{ .ints = .{ 298574582191755412, 0, 0, 0, 0 } } };
            const ck803ehtr2: Cpu = .{ .name = "ck803ehtr2", .llvm_name = "ck803ehtr2", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803ehtr3: Cpu = .{ .name = "ck803ehtr3", .llvm_name = "ck803ehtr3", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803er1: Cpu = .{ .name = "ck803er1", .llvm_name = "ck803er1", .features = .{ .ints = .{ 298574582191755412, 0, 0, 0, 0 } } };
            const ck803er2: Cpu = .{ .name = "ck803er2", .llvm_name = "ck803er2", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803er3: Cpu = .{ .name = "ck803er3", .llvm_name = "ck803er3", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803et: Cpu = .{ .name = "ck803et", .llvm_name = "ck803et", .features = .{ .ints = .{ 298504213380468864, 0, 0, 0, 0 } } };
            const ck803etr1: Cpu = .{ .name = "ck803etr1", .llvm_name = "ck803etr1", .features = .{ .ints = .{ 298574582191755412, 0, 0, 0, 0 } } };
            const ck803etr2: Cpu = .{ .name = "ck803etr2", .llvm_name = "ck803etr2", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803etr3: Cpu = .{ .name = "ck803etr3", .llvm_name = "ck803etr3", .features = .{ .ints = .{ 298574582191755416, 0, 0, 0, 0 } } };
            const ck803f: Cpu = .{ .name = "ck803f", .llvm_name = "ck803f", .features = .{ .ints = .{ 298504564988973184, 0, 0, 0, 0 } } };
            const ck803fh: Cpu = .{ .name = "ck803fh", .llvm_name = "ck803fh", .features = .{ .ints = .{ 298504564988973184, 0, 0, 0, 0 } } };
            const ck803fhr1: Cpu = .{ .name = "ck803fhr1", .llvm_name = "ck803fhr1", .features = .{ .ints = .{ 298504565056082068, 0, 0, 0, 0 } } };
            const ck803fhr2: Cpu = .{ .name = "ck803fhr2", .llvm_name = "ck803fhr2", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803fhr3: Cpu = .{ .name = "ck803fhr3", .llvm_name = "ck803fhr3", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803fr1: Cpu = .{ .name = "ck803fr1", .llvm_name = "ck803fr1", .features = .{ .ints = .{ 298504565056082068, 0, 0, 0, 0 } } };
            const ck803fr2: Cpu = .{ .name = "ck803fr2", .llvm_name = "ck803fr2", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803fr3: Cpu = .{ .name = "ck803fr3", .llvm_name = "ck803fr3", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803ft: Cpu = .{ .name = "ck803ft", .llvm_name = "ck803ft", .features = .{ .ints = .{ 298504564988973184, 0, 0, 0, 0 } } };
            const ck803ftr1: Cpu = .{ .name = "ck803ftr1", .llvm_name = "ck803ftr1", .features = .{ .ints = .{ 298504565056082052, 0, 0, 0, 0 } } };
            const ck803ftr2: Cpu = .{ .name = "ck803ftr2", .llvm_name = "ck803ftr2", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803ftr3: Cpu = .{ .name = "ck803ftr3", .llvm_name = "ck803ftr3", .features = .{ .ints = .{ 298504565056082072, 0, 0, 0, 0 } } };
            const ck803h: Cpu = .{ .name = "ck803h", .llvm_name = "ck803h", .features = .{ .ints = .{ 298504212801654912, 0, 0, 0, 0 } } };
            const ck803hr1: Cpu = .{ .name = "ck803hr1", .llvm_name = "ck803hr1", .features = .{ .ints = .{ 298504212868763796, 0, 0, 0, 0 } } };
            const ck803hr2: Cpu = .{ .name = "ck803hr2", .llvm_name = "ck803hr2", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803hr3: Cpu = .{ .name = "ck803hr3", .llvm_name = "ck803hr3", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803ht: Cpu = .{ .name = "ck803ht", .llvm_name = "ck803ht", .features = .{ .ints = .{ 298504212801654912, 0, 0, 0, 0 } } };
            const ck803htr1: Cpu = .{ .name = "ck803htr1", .llvm_name = "ck803htr1", .features = .{ .ints = .{ 298504212868763796, 0, 0, 0, 0 } } };
            const ck803htr2: Cpu = .{ .name = "ck803htr2", .llvm_name = "ck803htr2", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803htr3: Cpu = .{ .name = "ck803htr3", .llvm_name = "ck803htr3", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803r1: Cpu = .{ .name = "ck803r1", .llvm_name = "ck803r1", .features = .{ .ints = .{ 298504212868763796, 0, 0, 0, 0 } } };
            const ck803r2: Cpu = .{ .name = "ck803r2", .llvm_name = "ck803r2", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803r3: Cpu = .{ .name = "ck803r3", .llvm_name = "ck803r3", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803s: Cpu = .{ .name = "ck803s", .llvm_name = "ck803s", .features = .{ .ints = .{ 298504212801663108, 0, 0, 0, 0 } } };
            const ck803se: Cpu = .{ .name = "ck803se", .llvm_name = "ck803se", .features = .{ .ints = .{ 298504213380477060, 0, 0, 0, 0 } } };
            const ck803sef: Cpu = .{ .name = "ck803sef", .llvm_name = "ck803sef", .features = .{ .ints = .{ 298504565567795332, 0, 0, 0, 0 } } };
            const ck803sefn: Cpu = .{ .name = "ck803sefn", .llvm_name = "ck803sefn", .features = .{ .ints = .{ 298504565584572548, 0, 0, 0, 0 } } };
            const ck803sefnt: Cpu = .{ .name = "ck803sefnt", .llvm_name = "ck803sefnt", .features = .{ .ints = .{ 298504565584572548, 0, 0, 0, 0 } } };
            const ck803seft: Cpu = .{ .name = "ck803seft", .llvm_name = "ck803seft", .features = .{ .ints = .{ 298504565567795332, 0, 0, 0, 0 } } };
            const ck803sen: Cpu = .{ .name = "ck803sen", .llvm_name = "ck803sen", .features = .{ .ints = .{ 298504213397254276, 0, 0, 0, 0 } } };
            const ck803sf: Cpu = .{ .name = "ck803sf", .llvm_name = "ck803sf", .features = .{ .ints = .{ 298504564988981380, 0, 0, 0, 0 } } };
            const ck803sfn: Cpu = .{ .name = "ck803sfn", .llvm_name = "ck803sfn", .features = .{ .ints = .{ 298504565005758596, 0, 0, 0, 0 } } };
            const ck803sn: Cpu = .{ .name = "ck803sn", .llvm_name = "ck803sn", .features = .{ .ints = .{ 298504212818440324, 0, 0, 0, 0 } } };
            const ck803snt: Cpu = .{ .name = "ck803snt", .llvm_name = "ck803snt", .features = .{ .ints = .{ 298504212818440324, 0, 0, 0, 0 } } };
            const ck803st: Cpu = .{ .name = "ck803st", .llvm_name = "ck803st", .features = .{ .ints = .{ 298504212801663108, 0, 0, 0, 0 } } };
            const ck803t: Cpu = .{ .name = "ck803t", .llvm_name = "ck803t", .features = .{ .ints = .{ 298504212801654912, 0, 0, 0, 0 } } };
            const ck803tr1: Cpu = .{ .name = "ck803tr1", .llvm_name = "ck803tr1", .features = .{ .ints = .{ 298504212868763796, 0, 0, 0, 0 } } };
            const ck803tr2: Cpu = .{ .name = "ck803tr2", .llvm_name = "ck803tr2", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck803tr3: Cpu = .{ .name = "ck803tr3", .llvm_name = "ck803tr3", .features = .{ .ints = .{ 298504212868763800, 0, 0, 0, 0 } } };
            const ck804: Cpu = .{ .name = "ck804", .llvm_name = "ck804", .features = .{ .ints = .{ 298504212801671320, 0, 0, 0, 0 } } };
            const ck804e: Cpu = .{ .name = "ck804e", .llvm_name = "ck804e", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const ck804ef: Cpu = .{ .name = "ck804ef", .llvm_name = "ck804ef", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const ck804efh: Cpu = .{ .name = "ck804efh", .llvm_name = "ck804efh", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const ck804efht: Cpu = .{ .name = "ck804efht", .llvm_name = "ck804efht", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const ck804eft: Cpu = .{ .name = "ck804eft", .llvm_name = "ck804eft", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const ck804eh: Cpu = .{ .name = "ck804eh", .llvm_name = "ck804eh", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const ck804eht: Cpu = .{ .name = "ck804eht", .llvm_name = "ck804eht", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const ck804et: Cpu = .{ .name = "ck804et", .llvm_name = "ck804et", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const ck804f: Cpu = .{ .name = "ck804f", .llvm_name = "ck804f", .features = .{ .ints = .{ 298504564988989592, 0, 0, 0, 0 } } };
            const ck804fh: Cpu = .{ .name = "ck804fh", .llvm_name = "ck804fh", .features = .{ .ints = .{ 298504564988989592, 0, 0, 0, 0 } } };
            const ck804ft: Cpu = .{ .name = "ck804ft", .llvm_name = "ck804ft", .features = .{ .ints = .{ 298504564988989592, 0, 0, 0, 0 } } };
            const ck804h: Cpu = .{ .name = "ck804h", .llvm_name = "ck804h", .features = .{ .ints = .{ 298504212801671320, 0, 0, 0, 0 } } };
            const ck804ht: Cpu = .{ .name = "ck804ht", .llvm_name = "ck804ht", .features = .{ .ints = .{ 298504212801671320, 0, 0, 0, 0 } } };
            const ck804t: Cpu = .{ .name = "ck804t", .llvm_name = "ck804t", .features = .{ .ints = .{ 298504212801671320, 0, 0, 0, 0 } } };
            const ck805: Cpu = .{ .name = "ck805", .llvm_name = "ck805", .features = .{ .ints = .{ 5486721352276676760, 0, 0, 0, 0 } } };
            const ck805e: Cpu = .{ .name = "ck805e", .llvm_name = "ck805e", .features = .{ .ints = .{ 5486721352343785624, 0, 0, 0, 0 } } };
            const ck805ef: Cpu = .{ .name = "ck805ef", .llvm_name = "ck805ef", .features = .{ .ints = .{ 5486721704531103896, 0, 0, 0, 0 } } };
            const ck805eft: Cpu = .{ .name = "ck805eft", .llvm_name = "ck805eft", .features = .{ .ints = .{ 5486721704531103896, 0, 0, 0, 0 } } };
            const ck805et: Cpu = .{ .name = "ck805et", .llvm_name = "ck805et", .features = .{ .ints = .{ 5486721352343785624, 0, 0, 0, 0 } } };
            const ck805f: Cpu = .{ .name = "ck805f", .llvm_name = "ck805f", .features = .{ .ints = .{ 5486721704463995032, 0, 0, 0, 0 } } };
            const ck805ft: Cpu = .{ .name = "ck805ft", .llvm_name = "ck805ft", .features = .{ .ints = .{ 5486721704463995032, 0, 0, 0, 0 } } };
            const ck805t: Cpu = .{ .name = "ck805t", .llvm_name = "ck805t", .features = .{ .ints = .{ 5486721352276676760, 0, 0, 0, 0 } } };
            const ck807: Cpu = .{ .name = "ck807", .llvm_name = "ck807", .features = .{ .ints = .{ 300861566310482176, 0, 0, 0, 0 } } };
            const ck807e: Cpu = .{ .name = "ck807e", .llvm_name = "ck807e", .features = .{ .ints = .{ 300861566310482176, 0, 0, 0, 0 } } };
            const ck807ef: Cpu = .{ .name = "ck807ef", .llvm_name = "ck807ef", .features = .{ .ints = .{ 300862079559074048, 0, 0, 0, 0 } } };
            const ck807f: Cpu = .{ .name = "ck807f", .llvm_name = "ck807f", .features = .{ .ints = .{ 300862079559074048, 0, 0, 0, 0 } } };
            const ck810: Cpu = .{ .name = "ck810", .llvm_name = "ck810", .features = .{ .ints = .{ 300861566310547776, 0, 0, 0, 0 } } };
            const ck810e: Cpu = .{ .name = "ck810e", .llvm_name = "ck810e", .features = .{ .ints = .{ 300861566310547776, 0, 0, 0, 0 } } };
            const ck810ef: Cpu = .{ .name = "ck810ef", .llvm_name = "ck810ef", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const ck810eft: Cpu = .{ .name = "ck810eft", .llvm_name = "ck810eft", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const ck810eftv: Cpu = .{ .name = "ck810eftv", .llvm_name = "ck810eftv", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const ck810efv: Cpu = .{ .name = "ck810efv", .llvm_name = "ck810efv", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const ck810et: Cpu = .{ .name = "ck810et", .llvm_name = "ck810et", .features = .{ .ints = .{ 300861566310547776, 0, 0, 0, 0 } } };
            const ck810etv: Cpu = .{ .name = "ck810etv", .llvm_name = "ck810etv", .features = .{ .ints = .{ 2606704575524503872, 0, 0, 0, 0 } } };
            const ck810ev: Cpu = .{ .name = "ck810ev", .llvm_name = "ck810ev", .features = .{ .ints = .{ 2606704575524503872, 0, 0, 0, 0 } } };
            const ck810f: Cpu = .{ .name = "ck810f", .llvm_name = "ck810f", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const ck810ft: Cpu = .{ .name = "ck810ft", .llvm_name = "ck810ft", .features = .{ .ints = .{ 300862053789335872, 0, 0, 0, 0 } } };
            const ck810ftv: Cpu = .{ .name = "ck810ftv", .llvm_name = "ck810ftv", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const ck810fv: Cpu = .{ .name = "ck810fv", .llvm_name = "ck810fv", .features = .{ .ints = .{ 2606705063003291968, 0, 0, 0, 0 } } };
            const ck810t: Cpu = .{ .name = "ck810t", .llvm_name = "ck810t", .features = .{ .ints = .{ 300861566310547776, 0, 0, 0, 0 } } };
            const ck810tv: Cpu = .{ .name = "ck810tv", .llvm_name = "ck810tv", .features = .{ .ints = .{ 2606704575524503872, 0, 0, 0, 0 } } };
            const ck810v: Cpu = .{ .name = "ck810v", .llvm_name = "ck810v", .features = .{ .ints = .{ 2606704575524503872, 0, 0, 0, 0 } } };
            const ck860: Cpu = .{ .name = "ck860", .llvm_name = "ck860", .features = .{ .ints = .{ 300861565765681561, 0, 0, 0, 0 } } };
            const ck860f: Cpu = .{ .name = "ck860f", .llvm_name = "ck860f", .features = .{ .ints = .{ 300869846462628249, 0, 0, 0, 0 } } };
            const ck860fv: Cpu = .{ .name = "ck860fv", .llvm_name = "ck860fv", .features = .{ .ints = .{ 6065477369497911705, 0, 0, 0, 0 } } };
            const ck860v: Cpu = .{ .name = "ck860v", .llvm_name = "ck860v", .features = .{ .ints = .{ 6065469088800965017, 0, 0, 0, 0 } } };
            const e801: Cpu = .{ .name = "e801", .llvm_name = "e801", .features = .{ .ints = .{ 288230376285930624, 0, 0, 0, 0 } } };
            const e802: Cpu = .{ .name = "e802", .llvm_name = "e802", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const e802t: Cpu = .{ .name = "e802t", .llvm_name = "e802t", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const e803: Cpu = .{ .name = "e803", .llvm_name = "e803", .features = .{ .ints = .{ 298504212801654936, 0, 0, 0, 0 } } };
            const e803t: Cpu = .{ .name = "e803t", .llvm_name = "e803t", .features = .{ .ints = .{ 298504212801654936, 0, 0, 0, 0 } } };
            const e804d: Cpu = .{ .name = "e804d", .llvm_name = "e804d", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const e804df: Cpu = .{ .name = "e804df", .llvm_name = "e804df", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const e804dft: Cpu = .{ .name = "e804dft", .llvm_name = "e804dft", .features = .{ .ints = .{ 298574933800276120, 0, 0, 0, 0 } } };
            const e804dt: Cpu = .{ .name = "e804dt", .llvm_name = "e804dt", .features = .{ .ints = .{ 298574581612957848, 0, 0, 0, 0 } } };
            const e804f: Cpu = .{ .name = "e804f", .llvm_name = "e804f", .features = .{ .ints = .{ 298504564988989592, 0, 0, 0, 0 } } };
            const e804ft: Cpu = .{ .name = "e804ft", .llvm_name = "e804ft", .features = .{ .ints = .{ 298504564988989592, 0, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const @"i805": Cpu = .{ .name = "i805", .llvm_name = "i805", .features = .{ .ints = .{ 5486721352276676760, 0, 0, 0, 0 } } };
            const i805f: Cpu = .{ .name = "i805f", .llvm_name = "i805f", .features = .{ .ints = .{ 5486721704463995032, 0, 0, 0, 0 } } };
            const r807: Cpu = .{ .name = "r807", .llvm_name = "r807", .features = .{ .ints = .{ 300861566310482176, 0, 0, 0, 0 } } };
            const r807f: Cpu = .{ .name = "r807f", .llvm_name = "r807f", .features = .{ .ints = .{ 300862079559074048, 0, 0, 0, 0 } } };
            const s802: Cpu = .{ .name = "s802", .llvm_name = "s802", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const s802t: Cpu = .{ .name = "s802t", .llvm_name = "s802t", .features = .{ .ints = .{ 297237575674890368, 0, 0, 0, 0 } } };
            const s803: Cpu = .{ .name = "s803", .llvm_name = "s803", .features = .{ .ints = .{ 298504212801654936, 0, 0, 0, 0 } } };
            const s803t: Cpu = .{ .name = "s803t", .llvm_name = "s803t", .features = .{ .ints = .{ 298504212801654936, 0, 0, 0, 0 } } };
        };
    };
    pub const hexagon = struct {
        pub const Feature = enum(u6) {
            audio = 0,
            cabac = 1,
            compound = 2,
            duplex = 3,
            hvx = 4,
            hvx_ieee_fp = 5,
            hvx_length128b = 6,
            hvx_length64b = 7,
            hvx_qfloat = 8,
            hvxv60 = 9,
            hvxv62 = 10,
            hvxv65 = 11,
            hvxv66 = 12,
            hvxv67 = 13,
            hvxv68 = 14,
            hvxv69 = 15,
            hvxv71 = 16,
            hvxv73 = 17,
            long_calls = 18,
            mem_noshuf = 19,
            memops = 20,
            noreturn_stack_elim = 21,
            nvj = 22,
            nvs = 23,
            packets = 24,
            prev65 = 25,
            reserved_r19 = 26,
            small_data = 27,
            tinycore = 28,
            unsafe_fp = 29,
            v5 = 30,
            v55 = 31,
            v60 = 32,
            v62 = 33,
            v65 = 34,
            v66 = 35,
            v67 = 36,
            v68 = 37,
            v69 = 38,
            v71 = 39,
            v73 = 40,
            zreg = 41,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "audio", .llvm_name = "audio", .description = "Hexagon Audio extension instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "cabac", .llvm_name = "cabac", .description = "Emit the CABAC instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "compound", .llvm_name = "compound", .description = "Use compound instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "duplex", .llvm_name = "duplex", .description = "Enable generation of duplex instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "hvx", .llvm_name = "hvx", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "hvx_ieee_fp", .llvm_name = "hvx-ieee-fp", .description = "Hexagon HVX IEEE floating point instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "hvx_length128b", .llvm_name = "hvx-length128b", .description = "Hexagon HVX 128B instructions", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "hvx_length64b", .llvm_name = "hvx-length64b", .description = "Hexagon HVX 64B instructions", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "hvx_qfloat", .llvm_name = "hvx-qfloat", .description = "Hexagon HVX QFloating point instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "hvxv60", .llvm_name = "hvxv60", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "hvxv62", .llvm_name = "hvxv62", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 512, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "hvxv65", .llvm_name = "hvxv65", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 1024, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "hvxv66", .llvm_name = "hvxv66", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 2199023257600, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "hvxv67", .llvm_name = "hvxv67", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 4096, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "hvxv68", .llvm_name = "hvxv68", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "hvxv69", .llvm_name = "hvxv69", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 16384, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "hvxv71", .llvm_name = "hvxv71", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 32768, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "hvxv73", .llvm_name = "hvxv73", .description = "Hexagon HVX instructions", .dependencies = .{ .ints = .{ 65536, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "long_calls", .llvm_name = "long-calls", .description = "Use constant-extended calls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "mem_noshuf", .llvm_name = "mem_noshuf", .description = "Supports mem_noshuf feature", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "memops", .llvm_name = "memops", .description = "Use memop instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "noreturn_stack_elim", .llvm_name = "noreturn-stack-elim", .description = "Eliminate stack allocation in a noreturn function when possible", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "nvj", .llvm_name = "nvj", .description = "Support for new-value jumps", .dependencies = .{ .ints = .{ 16777216, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "nvs", .llvm_name = "nvs", .description = "Support for new-value stores", .dependencies = .{ .ints = .{ 16777216, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "packets", .llvm_name = "packets", .description = "Support for instruction packets", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "prev65", .llvm_name = "prev65", .description = "Support features deprecated in v65", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "reserved_r19", .llvm_name = "reserved-r19", .description = "Reserve register R19", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "small_data", .llvm_name = "small-data", .description = "Allow GP-relative addressing of global variables", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "tinycore", .llvm_name = "tinycore", .description = "Hexagon Tiny Core", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "unsafe_fp", .llvm_name = "unsafe-fp", .description = "Use unsafe FP math", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "v5", .llvm_name = "v5", .description = "Enable Hexagon V5 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "v55", .llvm_name = "v55", .description = "Enable Hexagon V55 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "v60", .llvm_name = "v60", .description = "Enable Hexagon V60 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "v62", .llvm_name = "v62", .description = "Enable Hexagon V62 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "v65", .llvm_name = "v65", .description = "Enable Hexagon V65 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "v66", .llvm_name = "v66", .description = "Enable Hexagon V66 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "v67", .llvm_name = "v67", .description = "Enable Hexagon V67 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "v68", .llvm_name = "v68", .description = "Enable Hexagon V68 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "v69", .llvm_name = "v69", .description = "Enable Hexagon V69 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "v71", .llvm_name = "v71", .description = "Enable Hexagon V71 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "v73", .llvm_name = "v73", .description = "Enable Hexagon V73 architecture", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "zreg", .llvm_name = "zreg", .description = "Hexagon ZReg extension instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 7697596430, 0, 0, 0, 0 } } };
            const hexagonv5: Cpu = .{ .name = "hexagonv5", .llvm_name = "hexagonv5", .features = .{ .ints = .{ 1255145486, 0, 0, 0, 0 } } };
            const hexagonv55: Cpu = .{ .name = "hexagonv55", .llvm_name = "hexagonv55", .features = .{ .ints = .{ 3402629134, 0, 0, 0, 0 } } };
            const hexagonv60: Cpu = .{ .name = "hexagonv60", .llvm_name = "hexagonv60", .features = .{ .ints = .{ 7697596430, 0, 0, 0, 0 } } };
            const hexagonv62: Cpu = .{ .name = "hexagonv62", .llvm_name = "hexagonv62", .features = .{ .ints = .{ 16287531022, 0, 0, 0, 0 } } };
            const hexagonv65: Cpu = .{ .name = "hexagonv65", .llvm_name = "hexagonv65", .features = .{ .ints = .{ 33434370062, 0, 0, 0, 0 } } };
            const hexagonv66: Cpu = .{ .name = "hexagonv66", .llvm_name = "hexagonv66", .features = .{ .ints = .{ 67794108430, 0, 0, 0, 0 } } };
            const hexagonv67: Cpu = .{ .name = "hexagonv67", .llvm_name = "hexagonv67", .features = .{ .ints = .{ 136513585166, 0, 0, 0, 0 } } };
            const hexagonv67t: Cpu = .{ .name = "hexagonv67t", .llvm_name = "hexagonv67t", .features = .{ .ints = .{ 136777826309, 0, 0, 0, 0 } } };
            const hexagonv68: Cpu = .{ .name = "hexagonv68", .llvm_name = "hexagonv68", .features = .{ .ints = .{ 273952538638, 0, 0, 0, 0 } } };
            const hexagonv69: Cpu = .{ .name = "hexagonv69", .llvm_name = "hexagonv69", .features = .{ .ints = .{ 548830445582, 0, 0, 0, 0 } } };
            const hexagonv71: Cpu = .{ .name = "hexagonv71", .llvm_name = "hexagonv71", .features = .{ .ints = .{ 1098586259470, 0, 0, 0, 0 } } };
            const hexagonv71t: Cpu = .{ .name = "hexagonv71t", .llvm_name = "hexagonv71t", .features = .{ .ints = .{ 1098850500613, 0, 0, 0, 0 } } };
            const hexagonv73: Cpu = .{ .name = "hexagonv73", .llvm_name = "hexagonv73", .features = .{ .ints = .{ 2198097887244, 0, 0, 0, 0 } } };
        };
    };
    pub const loongarch = struct {
        pub const Feature = enum(u4) {
            @"32bit" = 0,
            @"64bit" = 1,
            d = 2,
            f = 3,
            la_global_with_abs = 4,
            la_global_with_pcrel = 5,
            la_local_with_abs = 6,
            lasx = 7,
            lbt = 8,
            lsx = 9,
            lvz = 10,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "32bit", .llvm_name = "32bit", .description = "LA32 Basic Integer and Privilege Instruction Set", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "64bit", .llvm_name = "64bit", .description = "LA64 Basic Integer and Privilege Instruction Set", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "d", .llvm_name = "d", .description = "'D' (Double-Precision Floating-Point)", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "f", .llvm_name = "f", .description = "'F' (Single-Precision Floating-Point)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "la_global_with_abs", .llvm_name = "la-global-with-abs", .description = "Expand la.global as la.abs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "la_global_with_pcrel", .llvm_name = "la-global-with-pcrel", .description = "Expand la.global as la.pcrel", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "la_local_with_abs", .llvm_name = "la-local-with-abs", .description = "Expand la.local as la.abs", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "lasx", .llvm_name = "lasx", .description = "'LASX' (Loongson Advanced SIMD Extension)", .dependencies = .{ .ints = .{ 512, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "lbt", .llvm_name = "lbt", .description = "'LBT' (Loongson Binary Translation Extension)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "lsx", .llvm_name = "lsx", .description = "'LSX' (Loongson SIMD Extension)", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "lvz", .llvm_name = "lvz", .description = "'LVZ' (Loongson Virtualization Extension)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const generic_la32: Cpu = .{ .name = "generic_la32", .llvm_name = "generic-la32", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
            const generic_la64: Cpu = .{ .name = "generic_la64", .llvm_name = "generic-la64", .features = .{ .ints = .{ 2, 0, 0, 0, 0 } } };
            const la464: Cpu = .{ .name = "la464", .llvm_name = "la464", .features = .{ .ints = .{ 1410, 0, 0, 0, 0 } } };
        };
    };
    pub const m68k = struct {
        pub const Feature = enum(u5) {
            isa_68000 = 0,
            isa_68010 = 1,
            isa_68020 = 2,
            isa_68030 = 3,
            isa_68040 = 4,
            isa_68060 = 5,
            reserve_a0 = 6,
            reserve_a1 = 7,
            reserve_a2 = 8,
            reserve_a3 = 9,
            reserve_a4 = 10,
            reserve_a5 = 11,
            reserve_a6 = 12,
            reserve_d0 = 13,
            reserve_d1 = 14,
            reserve_d2 = 15,
            reserve_d3 = 16,
            reserve_d4 = 17,
            reserve_d5 = 18,
            reserve_d6 = 19,
            reserve_d7 = 20,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "isa_68000", .llvm_name = "isa-68000", .description = "Is M68000 ISA supported", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "isa_68010", .llvm_name = "isa-68010", .description = "Is M68010 ISA supported", .dependencies = .{ .ints = .{ 1, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "isa_68020", .llvm_name = "isa-68020", .description = "Is M68020 ISA supported", .dependencies = .{ .ints = .{ 2, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "isa_68030", .llvm_name = "isa-68030", .description = "Is M68030 ISA supported", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "isa_68040", .llvm_name = "isa-68040", .description = "Is M68040 ISA supported", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "isa_68060", .llvm_name = "isa-68060", .description = "Is M68060 ISA supported", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "reserve_a0", .llvm_name = "reserve-a0", .description = "Reserve A0 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "reserve_a1", .llvm_name = "reserve-a1", .description = "Reserve A1 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "reserve_a2", .llvm_name = "reserve-a2", .description = "Reserve A2 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "reserve_a3", .llvm_name = "reserve-a3", .description = "Reserve A3 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "reserve_a4", .llvm_name = "reserve-a4", .description = "Reserve A4 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "reserve_a5", .llvm_name = "reserve-a5", .description = "Reserve A5 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "reserve_a6", .llvm_name = "reserve-a6", .description = "Reserve A6 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "reserve_d0", .llvm_name = "reserve-d0", .description = "Reserve D0 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "reserve_d1", .llvm_name = "reserve-d1", .description = "Reserve D1 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "reserve_d2", .llvm_name = "reserve-d2", .description = "Reserve D2 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "reserve_d3", .llvm_name = "reserve-d3", .description = "Reserve D3 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "reserve_d4", .llvm_name = "reserve-d4", .description = "Reserve D4 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "reserve_d5", .llvm_name = "reserve-d5", .description = "Reserve D5 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "reserve_d6", .llvm_name = "reserve-d6", .description = "Reserve D6 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "reserve_d7", .llvm_name = "reserve-d7", .description = "Reserve D7 register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
            const M68000: Cpu = .{ .name = "M68000", .llvm_name = "M68000", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
            const M68010: Cpu = .{ .name = "M68010", .llvm_name = "M68010", .features = .{ .ints = .{ 2, 0, 0, 0, 0 } } };
            const M68020: Cpu = .{ .name = "M68020", .llvm_name = "M68020", .features = .{ .ints = .{ 4, 0, 0, 0, 0 } } };
            const M68030: Cpu = .{ .name = "M68030", .llvm_name = "M68030", .features = .{ .ints = .{ 8, 0, 0, 0, 0 } } };
            const M68040: Cpu = .{ .name = "M68040", .llvm_name = "M68040", .features = .{ .ints = .{ 16, 0, 0, 0, 0 } } };
            const M68060: Cpu = .{ .name = "M68060", .llvm_name = "M68060", .features = .{ .ints = .{ 32, 0, 0, 0, 0 } } };
        };
    };
    pub const mips = struct {
        pub const Feature = enum(u6) {
            abs2008 = 0,
            cnmips = 1,
            cnmipsp = 2,
            crc = 3,
            dsp = 4,
            dspr2 = 5,
            dspr3 = 6,
            eva = 7,
            fp64 = 8,
            fpxx = 9,
            ginv = 10,
            gp64 = 11,
            long_calls = 12,
            micromips = 13,
            mips1 = 14,
            mips16 = 15,
            mips2 = 16,
            mips3 = 17,
            mips32 = 18,
            mips32r2 = 19,
            mips32r3 = 20,
            mips32r5 = 21,
            mips32r6 = 22,
            mips3_32 = 23,
            mips3_32r2 = 24,
            mips3d = 25,
            mips4 = 26,
            mips4_32 = 27,
            mips4_32r2 = 28,
            mips5 = 29,
            mips5_32r2 = 30,
            mips64 = 31,
            mips64r2 = 32,
            mips64r3 = 33,
            mips64r5 = 34,
            mips64r6 = 35,
            msa = 36,
            mt = 37,
            nan2008 = 38,
            noabicalls = 39,
            nomadd4 = 40,
            nooddspreg = 41,
            p5600 = 42,
            ptr64 = 43,
            single_float = 44,
            soft_float = 45,
            sym32 = 46,
            use_indirect_jump_hazard = 47,
            use_tcc_in_div = 48,
            vfpu = 49,
            virt = 50,
            xgot = 51,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "abs2008", .llvm_name = "abs2008", .description = "Disable IEEE 754-2008 abs.fmt mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "cnmips", .llvm_name = "cnmips", .description = "Octeon cnMIPS Support", .dependencies = .{ .ints = .{ 4294967296, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "cnmipsp", .llvm_name = "cnmipsp", .description = "Octeon+ cnMIPS Support", .dependencies = .{ .ints = .{ 2, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "crc", .llvm_name = "crc", .description = "Mips R6 CRC ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "dsp", .llvm_name = "dsp", .description = "Mips DSP ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "dspr2", .llvm_name = "dspr2", .description = "Mips DSP-R2 ASE", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "dspr3", .llvm_name = "dspr3", .description = "Mips DSP-R3 ASE", .dependencies = .{ .ints = .{ 32, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "eva", .llvm_name = "eva", .description = "Mips EVA ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "fp64", .llvm_name = "fp64", .description = "Support 64-bit FP registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "fpxx", .llvm_name = "fpxx", .description = "Support for FPXX", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "ginv", .llvm_name = "ginv", .description = "Mips Global Invalidate ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "gp64", .llvm_name = "gp64", .description = "General Purpose Registers are 64-bit wide", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "long_calls", .llvm_name = "long-calls", .description = "Disable use of the jal instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "micromips", .llvm_name = "micromips", .description = "microMips mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "mips1", .llvm_name = "mips1", .description = "Mips I ISA Support [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "mips16", .llvm_name = "mips16", .description = "Mips16 mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "mips2", .llvm_name = "mips2", .description = "Mips II ISA Support [highly experimental]", .dependencies = .{ .ints = .{ 16384, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "mips3", .llvm_name = "mips3", .description = "MIPS III ISA Support [highly experimental]", .dependencies = .{ .ints = .{ 25233664, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "mips32", .llvm_name = "mips32", .description = "Mips32 ISA Support", .dependencies = .{ .ints = .{ 142671872, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "mips32r2", .llvm_name = "mips32r2", .description = "Mips32r2 ISA Support", .dependencies = .{ .ints = .{ 1359216640, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "mips32r3", .llvm_name = "mips32r3", .description = "Mips32r3 ISA Support", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "mips32r5", .llvm_name = "mips32r5", .description = "Mips32r5 ISA Support", .dependencies = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "mips32r6", .llvm_name = "mips32r6", .description = "Mips32r6 ISA Support [experimental]", .dependencies = .{ .ints = .{ 274880004353, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "mips3_32", .llvm_name = "mips3_32", .description = "Subset of MIPS-III that is also in MIPS32 [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "mips3_32r2", .llvm_name = "mips3_32r2", .description = "Subset of MIPS-III that is also in MIPS32r2 [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "mips3d", .llvm_name = "mips3d", .description = "Mips 3D ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "mips4", .llvm_name = "mips4", .description = "MIPS IV ISA Support", .dependencies = .{ .ints = .{ 402784256, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "mips4_32", .llvm_name = "mips4_32", .description = "Subset of MIPS-IV that is also in MIPS32 [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "mips4_32r2", .llvm_name = "mips4_32r2", .description = "Subset of MIPS-IV that is also in MIPS32r2 [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "mips5", .llvm_name = "mips5", .description = "MIPS V ISA Support [highly experimental]", .dependencies = .{ .ints = .{ 1140850688, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "mips5_32r2", .llvm_name = "mips5_32r2", .description = "Subset of MIPS-V that is also in MIPS32r2 [highly experimental]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "mips64", .llvm_name = "mips64", .description = "Mips64 ISA Support", .dependencies = .{ .ints = .{ 537133056, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "mips64r2", .llvm_name = "mips64r2", .description = "Mips64r2 ISA Support", .dependencies = .{ .ints = .{ 2148007936, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "mips64r3", .llvm_name = "mips64r3", .description = "Mips64r3 ISA Support", .dependencies = .{ .ints = .{ 4296015872, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "mips64r5", .llvm_name = "mips64r5", .description = "Mips64r5 ISA Support", .dependencies = .{ .ints = .{ 8592031744, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "mips64r6", .llvm_name = "mips64r6", .description = "Mips64r6 ISA Support [experimental]", .dependencies = .{ .ints = .{ 17184063488, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "msa", .llvm_name = "msa", .description = "Mips MSA ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "mt", .llvm_name = "mt", .description = "Mips MT ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "nan2008", .llvm_name = "nan2008", .description = "IEEE 754-2008 NaN encoding", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "noabicalls", .llvm_name = "noabicalls", .description = "Disable SVR4-style position-independent code", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "nomadd4", .llvm_name = "nomadd4", .description = "Disable 4-operand madd.fmt and related instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "nooddspreg", .llvm_name = "nooddspreg", .description = "Disable odd numbered single-precision registers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "p5600", .llvm_name = "p5600", .description = "The P5600 Processor", .dependencies = .{ .ints = .{ 2097152, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "ptr64", .llvm_name = "ptr64", .description = "Pointers are 64-bit wide", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "single_float", .llvm_name = "single-float", .description = "Only supports single precision float", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "soft_float", .llvm_name = "soft-float", .description = "Does not support floating point instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "sym32", .llvm_name = "sym32", .description = "Symbols are 32 bit on Mips64", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "use_indirect_jump_hazard", .llvm_name = "use-indirect-jump-hazard", .description = "Use indirect jump guards to prevent certain speculation based attacks", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "use_tcc_in_div", .llvm_name = "use-tcc-in-div", .description = "Force the assembler to use trapping", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "vfpu", .llvm_name = "vfpu", .description = "Enable vector FPU instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "virt", .llvm_name = "virt", .description = "Mips Virtualization ASE", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "xgot", .llvm_name = "xgot", .description = "Assume 32-bit GOT", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 262144, 0, 0, 0, 0 } } };
            const mips1: Cpu = .{ .name = "mips1", .llvm_name = "mips1", .features = .{ .ints = .{ 16384, 0, 0, 0, 0 } } };
            const mips2: Cpu = .{ .name = "mips2", .llvm_name = "mips2", .features = .{ .ints = .{ 65536, 0, 0, 0, 0 } } };
            const mips3: Cpu = .{ .name = "mips3", .llvm_name = "mips3", .features = .{ .ints = .{ 131072, 0, 0, 0, 0 } } };
            const mips32: Cpu = .{ .name = "mips32", .llvm_name = "mips32", .features = .{ .ints = .{ 262144, 0, 0, 0, 0 } } };
            const mips32r2: Cpu = .{ .name = "mips32r2", .llvm_name = "mips32r2", .features = .{ .ints = .{ 524288, 0, 0, 0, 0 } } };
            const mips32r3: Cpu = .{ .name = "mips32r3", .llvm_name = "mips32r3", .features = .{ .ints = .{ 1048576, 0, 0, 0, 0 } } };
            const mips32r5: Cpu = .{ .name = "mips32r5", .llvm_name = "mips32r5", .features = .{ .ints = .{ 2097152, 0, 0, 0, 0 } } };
            const mips32r6: Cpu = .{ .name = "mips32r6", .llvm_name = "mips32r6", .features = .{ .ints = .{ 4194304, 0, 0, 0, 0 } } };
            const mips4: Cpu = .{ .name = "mips4", .llvm_name = "mips4", .features = .{ .ints = .{ 67108864, 0, 0, 0, 0 } } };
            const mips5: Cpu = .{ .name = "mips5", .llvm_name = "mips5", .features = .{ .ints = .{ 536870912, 0, 0, 0, 0 } } };
            const mips64: Cpu = .{ .name = "mips64", .llvm_name = "mips64", .features = .{ .ints = .{ 2147483648, 0, 0, 0, 0 } } };
            const mips64r2: Cpu = .{ .name = "mips64r2", .llvm_name = "mips64r2", .features = .{ .ints = .{ 4294967296, 0, 0, 0, 0 } } };
            const mips64r3: Cpu = .{ .name = "mips64r3", .llvm_name = "mips64r3", .features = .{ .ints = .{ 8589934592, 0, 0, 0, 0 } } };
            const mips64r5: Cpu = .{ .name = "mips64r5", .llvm_name = "mips64r5", .features = .{ .ints = .{ 17179869184, 0, 0, 0, 0 } } };
            const mips64r6: Cpu = .{ .name = "mips64r6", .llvm_name = "mips64r6", .features = .{ .ints = .{ 34359738368, 0, 0, 0, 0 } } };
            const octeon: Cpu = .{ .name = "octeon", .llvm_name = "octeon", .features = .{ .ints = .{ 2, 0, 0, 0, 0 } } };
            const @"octeon+": Cpu = .{ .name = "octeon+", .llvm_name = "octeon+", .features = .{ .ints = .{ 4, 0, 0, 0, 0 } } };
            const p5600: Cpu = .{ .name = "p5600", .llvm_name = "p5600", .features = .{ .ints = .{ 4398046511104, 0, 0, 0, 0 } } };
        };
    };
    pub const msp430 = struct {
        pub const Feature = enum(u2) {
            ext = 0,
            hwmult16 = 1,
            hwmult32 = 2,
            hwmultf5 = 3,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "ext", .llvm_name = "ext", .description = "Enable MSP430-X extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "hwmult16", .llvm_name = "hwmult16", .description = "Enable 16-bit hardware multiplier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "hwmult32", .llvm_name = "hwmult32", .description = "Enable 32-bit hardware multiplier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "hwmultf5", .llvm_name = "hwmultf5", .description = "Enable F5 series hardware multiplier", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const msp430: Cpu = .{ .name = "msp430", .llvm_name = "msp430", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const msp430x: Cpu = .{ .name = "msp430x", .llvm_name = "msp430x", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
        };
    };
    pub const nvptx = struct {
        pub const Feature = enum(u6) {
            ptx32 = 0,
            ptx40 = 1,
            ptx41 = 2,
            ptx42 = 3,
            ptx43 = 4,
            ptx50 = 5,
            ptx60 = 6,
            ptx61 = 7,
            ptx63 = 8,
            ptx64 = 9,
            ptx65 = 10,
            ptx70 = 11,
            ptx71 = 12,
            ptx72 = 13,
            ptx73 = 14,
            ptx74 = 15,
            ptx75 = 16,
            ptx76 = 17,
            ptx77 = 18,
            ptx78 = 19,
            sm_20 = 20,
            sm_21 = 21,
            sm_30 = 22,
            sm_32 = 23,
            sm_35 = 24,
            sm_37 = 25,
            sm_50 = 26,
            sm_52 = 27,
            sm_53 = 28,
            sm_60 = 29,
            sm_61 = 30,
            sm_62 = 31,
            sm_70 = 32,
            sm_72 = 33,
            sm_75 = 34,
            sm_80 = 35,
            sm_86 = 36,
            sm_87 = 37,
            sm_89 = 38,
            sm_90 = 39,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "ptx32", .llvm_name = "ptx32", .description = "Use PTX version 3.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "ptx40", .llvm_name = "ptx40", .description = "Use PTX version 4.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "ptx41", .llvm_name = "ptx41", .description = "Use PTX version 4.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "ptx42", .llvm_name = "ptx42", .description = "Use PTX version 4.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "ptx43", .llvm_name = "ptx43", .description = "Use PTX version 4.3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "ptx50", .llvm_name = "ptx50", .description = "Use PTX version 5.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "ptx60", .llvm_name = "ptx60", .description = "Use PTX version 6.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "ptx61", .llvm_name = "ptx61", .description = "Use PTX version 6.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "ptx63", .llvm_name = "ptx63", .description = "Use PTX version 6.3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "ptx64", .llvm_name = "ptx64", .description = "Use PTX version 6.4", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "ptx65", .llvm_name = "ptx65", .description = "Use PTX version 6.5", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "ptx70", .llvm_name = "ptx70", .description = "Use PTX version 7.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "ptx71", .llvm_name = "ptx71", .description = "Use PTX version 7.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "ptx72", .llvm_name = "ptx72", .description = "Use PTX version 7.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "ptx73", .llvm_name = "ptx73", .description = "Use PTX version 7.3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "ptx74", .llvm_name = "ptx74", .description = "Use PTX version 7.4", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "ptx75", .llvm_name = "ptx75", .description = "Use PTX version 7.5", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "ptx76", .llvm_name = "ptx76", .description = "Use PTX version 7.6", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "ptx77", .llvm_name = "ptx77", .description = "Use PTX version 7.7", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "ptx78", .llvm_name = "ptx78", .description = "Use PTX version 7.8", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "sm_20", .llvm_name = "sm_20", .description = "Target SM 2.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "sm_21", .llvm_name = "sm_21", .description = "Target SM 2.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "sm_30", .llvm_name = "sm_30", .description = "Target SM 3.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "sm_32", .llvm_name = "sm_32", .description = "Target SM 3.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "sm_35", .llvm_name = "sm_35", .description = "Target SM 3.5", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "sm_37", .llvm_name = "sm_37", .description = "Target SM 3.7", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "sm_50", .llvm_name = "sm_50", .description = "Target SM 5.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "sm_52", .llvm_name = "sm_52", .description = "Target SM 5.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "sm_53", .llvm_name = "sm_53", .description = "Target SM 5.3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "sm_60", .llvm_name = "sm_60", .description = "Target SM 6.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "sm_61", .llvm_name = "sm_61", .description = "Target SM 6.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "sm_62", .llvm_name = "sm_62", .description = "Target SM 6.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "sm_70", .llvm_name = "sm_70", .description = "Target SM 7.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "sm_72", .llvm_name = "sm_72", .description = "Target SM 7.2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "sm_75", .llvm_name = "sm_75", .description = "Target SM 7.5", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "sm_80", .llvm_name = "sm_80", .description = "Target SM 8.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "sm_86", .llvm_name = "sm_86", .description = "Target SM 8.6", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "sm_87", .llvm_name = "sm_87", .description = "Target SM 8.7", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "sm_89", .llvm_name = "sm_89", .description = "Target SM 8.9", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "sm_90", .llvm_name = "sm_90", .description = "Target SM 9.0", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const sm_20: Cpu = .{ .name = "sm_20", .llvm_name = "sm_20", .features = .{ .ints = .{ 1048577, 0, 0, 0, 0 } } };
            const sm_21: Cpu = .{ .name = "sm_21", .llvm_name = "sm_21", .features = .{ .ints = .{ 2097153, 0, 0, 0, 0 } } };
            const sm_30: Cpu = .{ .name = "sm_30", .llvm_name = "sm_30", .features = .{ .ints = .{ 4194304, 0, 0, 0, 0 } } };
            const sm_32: Cpu = .{ .name = "sm_32", .llvm_name = "sm_32", .features = .{ .ints = .{ 8388610, 0, 0, 0, 0 } } };
            const sm_35: Cpu = .{ .name = "sm_35", .llvm_name = "sm_35", .features = .{ .ints = .{ 16777217, 0, 0, 0, 0 } } };
            const sm_37: Cpu = .{ .name = "sm_37", .llvm_name = "sm_37", .features = .{ .ints = .{ 33554436, 0, 0, 0, 0 } } };
            const sm_50: Cpu = .{ .name = "sm_50", .llvm_name = "sm_50", .features = .{ .ints = .{ 67108866, 0, 0, 0, 0 } } };
            const sm_52: Cpu = .{ .name = "sm_52", .llvm_name = "sm_52", .features = .{ .ints = .{ 134217732, 0, 0, 0, 0 } } };
            const sm_53: Cpu = .{ .name = "sm_53", .llvm_name = "sm_53", .features = .{ .ints = .{ 268435464, 0, 0, 0, 0 } } };
            const sm_60: Cpu = .{ .name = "sm_60", .llvm_name = "sm_60", .features = .{ .ints = .{ 536870944, 0, 0, 0, 0 } } };
            const sm_61: Cpu = .{ .name = "sm_61", .llvm_name = "sm_61", .features = .{ .ints = .{ 1073741856, 0, 0, 0, 0 } } };
            const sm_62: Cpu = .{ .name = "sm_62", .llvm_name = "sm_62", .features = .{ .ints = .{ 2147483680, 0, 0, 0, 0 } } };
            const sm_70: Cpu = .{ .name = "sm_70", .llvm_name = "sm_70", .features = .{ .ints = .{ 4294967360, 0, 0, 0, 0 } } };
            const sm_72: Cpu = .{ .name = "sm_72", .llvm_name = "sm_72", .features = .{ .ints = .{ 8589934720, 0, 0, 0, 0 } } };
            const sm_75: Cpu = .{ .name = "sm_75", .llvm_name = "sm_75", .features = .{ .ints = .{ 17179869440, 0, 0, 0, 0 } } };
            const sm_80: Cpu = .{ .name = "sm_80", .llvm_name = "sm_80", .features = .{ .ints = .{ 34359740416, 0, 0, 0, 0 } } };
            const sm_86: Cpu = .{ .name = "sm_86", .llvm_name = "sm_86", .features = .{ .ints = .{ 68719480832, 0, 0, 0, 0 } } };
            const sm_87: Cpu = .{ .name = "sm_87", .llvm_name = "sm_87", .features = .{ .ints = .{ 137438986240, 0, 0, 0, 0 } } };
            const sm_89: Cpu = .{ .name = "sm_89", .llvm_name = "sm_89", .features = .{ .ints = .{ 274878431232, 0, 0, 0, 0 } } };
            const sm_90: Cpu = .{ .name = "sm_90", .llvm_name = "sm_90", .features = .{ .ints = .{ 549756338176, 0, 0, 0, 0 } } };
        };
    };
    pub const powerpc = struct {
        pub const Feature = enum(u7) {
            @"64bit" = 0,
            @"64bitregs" = 1,
            aix = 2,
            allow_unaligned_fp_access = 3,
            altivec = 4,
            booke = 5,
            bpermd = 6,
            cmpb = 7,
            crbits = 8,
            crypto = 9,
            direct_move = 10,
            e500 = 11,
            efpu2 = 12,
            extdiv = 13,
            fast_MFLR = 14,
            fcpsgn = 15,
            float128 = 16,
            fpcvt = 17,
            fprnd = 18,
            fpu = 19,
            fre = 20,
            fres = 21,
            frsqrte = 22,
            frsqrtes = 23,
            fsqrt = 24,
            fuse_add_logical = 25,
            fuse_addi_load = 26,
            fuse_addis_load = 27,
            fuse_arith_add = 28,
            fuse_back2back = 29,
            fuse_cmp = 30,
            fuse_logical = 31,
            fuse_logical_add = 32,
            fuse_sha3 = 33,
            fuse_store = 34,
            fuse_wideimm = 35,
            fuse_zeromove = 36,
            fusion = 37,
            hard_float = 38,
            htm = 39,
            icbt = 40,
            invariant_function_descriptors = 41,
            isa_future_instructions = 42,
            isa_v206_instructions = 43,
            isa_v207_instructions = 44,
            isa_v30_instructions = 45,
            isa_v31_instructions = 46,
            isel = 47,
            ldbrx = 48,
            lfiwax = 49,
            longcall = 50,
            mfocrf = 51,
            mma = 52,
            modern_aix_as = 53,
            msync = 54,
            paired_vector_memops = 55,
            partword_atomics = 56,
            pcrelative_memops = 57,
            popcntd = 58,
            power10_vector = 59,
            power8_altivec = 60,
            power8_vector = 61,
            power9_altivec = 62,
            power9_vector = 63,
            ppc4xx = 64,
            ppc6xx = 65,
            ppc_postra_sched = 66,
            ppc_prera_sched = 67,
            predictable_select_expensive = 68,
            prefix_instrs = 69,
            privileged = 70,
            quadword_atomics = 71,
            recipprec = 72,
            rop_protect = 73,
            secure_plt = 74,
            slow_popcntd = 75,
            spe = 76,
            stfiwx = 77,
            two_const_nr = 78,
            vectors_use_two_units = 79,
            vsx = 80,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "64bit", .llvm_name = "64bit", .description = "Enable 64-bit instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "64bitregs", .llvm_name = "64bitregs", .description = "Enable 64-bit registers usage for ppc32 [beta]", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "aix", .llvm_name = "aix", .description = "AIX OS", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "allow_unaligned_fp_access", .llvm_name = "allow-unaligned-fp-access", .description = "CPU does not trap on unaligned FP access", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "altivec", .llvm_name = "altivec", .description = "Enable Altivec instructions", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "booke", .llvm_name = "booke", .description = "Enable Book E instructions", .dependencies = .{ .ints = .{ 1099511627776, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "bpermd", .llvm_name = "bpermd", .description = "Enable the bpermd instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "cmpb", .llvm_name = "cmpb", .description = "Enable the cmpb instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "crbits", .llvm_name = "crbits", .description = "Use condition-register bits individually", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "crypto", .llvm_name = "crypto", .description = "Enable POWER8 Crypto instructions", .dependencies = .{ .ints = .{ 1152921504606846976, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "direct_move", .llvm_name = "direct-move", .description = "Enable Power8 direct move instructions", .dependencies = .{ .ints = .{ 0, 65536, 0, 0, 0 } } },
            .{ .index = 11, .name = "e500", .llvm_name = "e500", .description = "Enable E500/E500mc instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "efpu2", .llvm_name = "efpu2", .description = "Enable Embedded Floating-Point APU 2 instructions", .dependencies = .{ .ints = .{ 0, 4096, 0, 0, 0 } } },
            .{ .index = 13, .name = "extdiv", .llvm_name = "extdiv", .description = "Enable extended divide instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "fast_MFLR", .llvm_name = "fast-MFLR", .description = "MFLR is a fast instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "fcpsgn", .llvm_name = "fcpsgn", .description = "Enable the fcpsgn instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "float128", .llvm_name = "float128", .description = "Enable the __float128 data type for IEEE-754R Binary128.", .dependencies = .{ .ints = .{ 0, 65536, 0, 0, 0 } } },
            .{ .index = 17, .name = "fpcvt", .llvm_name = "fpcvt", .description = "Enable fc[ft]* (unsigned and single-precision) and lfiwzx instructions", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "fprnd", .llvm_name = "fprnd", .description = "Enable the fri[mnpz] instructions", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "fpu", .llvm_name = "fpu", .description = "Enable classic FPU instructions", .dependencies = .{ .ints = .{ 274877906944, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "fre", .llvm_name = "fre", .description = "Enable the fre instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "fres", .llvm_name = "fres", .description = "Enable the fres instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "frsqrte", .llvm_name = "frsqrte", .description = "Enable the frsqrte instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "frsqrtes", .llvm_name = "frsqrtes", .description = "Enable the frsqrtes instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "fsqrt", .llvm_name = "fsqrt", .description = "Enable the fsqrt instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "fuse_add_logical", .llvm_name = "fuse-add-logical", .description = "Target supports Add with Logical Operations fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "fuse_addi_load", .llvm_name = "fuse-addi-load", .description = "Power8 Addi-Load fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "fuse_addis_load", .llvm_name = "fuse-addis-load", .description = "Power8 Addis-Load fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "fuse_arith_add", .llvm_name = "fuse-arith-add", .description = "Target supports Arithmetic Operations with Add fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "fuse_back2back", .llvm_name = "fuse-back2back", .description = "Target supports general back to back fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "fuse_cmp", .llvm_name = "fuse-cmp", .description = "Target supports Comparison Operations fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "fuse_logical", .llvm_name = "fuse-logical", .description = "Target supports Logical Operations fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "fuse_logical_add", .llvm_name = "fuse-logical-add", .description = "Target supports Logical with Add Operations fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "fuse_sha3", .llvm_name = "fuse-sha3", .description = "Target supports SHA3 assist fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "fuse_store", .llvm_name = "fuse-store", .description = "Target supports store clustering", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "fuse_wideimm", .llvm_name = "fuse-wideimm", .description = "Target supports Wide-Immediate fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "fuse_zeromove", .llvm_name = "fuse-zeromove", .description = "Target supports move to SPR with branch fusion", .dependencies = .{ .ints = .{ 137438953472, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "fusion", .llvm_name = "fusion", .description = "Target supports instruction fusion", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "hard_float", .llvm_name = "hard-float", .description = "Enable floating-point instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "htm", .llvm_name = "htm", .description = "Enable Hardware Transactional Memory instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "icbt", .llvm_name = "icbt", .description = "Enable icbt instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "invariant_function_descriptors", .llvm_name = "invariant-function-descriptors", .description = "Assume function descriptors are invariant", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "isa_future_instructions", .llvm_name = "isa-future-instructions", .description = "Enable instructions for Future ISA.", .dependencies = .{ .ints = .{ 70368744177664, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "isa_v206_instructions", .llvm_name = "isa-v206-instructions", .description = "Enable instructions in ISA 2.06.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "isa_v207_instructions", .llvm_name = "isa-v207-instructions", .description = "Enable instructions in ISA 2.07.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "isa_v30_instructions", .llvm_name = "isa-v30-instructions", .description = "Enable instructions in ISA 3.0.", .dependencies = .{ .ints = .{ 17592186044416, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "isa_v31_instructions", .llvm_name = "isa-v31-instructions", .description = "Enable instructions in ISA 3.1.", .dependencies = .{ .ints = .{ 35184372088832, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "isel", .llvm_name = "isel", .description = "Enable the isel instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "ldbrx", .llvm_name = "ldbrx", .description = "Enable the ldbrx instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "lfiwax", .llvm_name = "lfiwax", .description = "Enable the lfiwax instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "longcall", .llvm_name = "longcall", .description = "Always use indirect calls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "mfocrf", .llvm_name = "mfocrf", .description = "Enable the MFOCRF instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "mma", .llvm_name = "mma", .description = "Enable MMA instructions", .dependencies = .{ .ints = .{ 6953557824660045824, 0, 0, 0, 0 } } },
            .{ .index = 53, .name = "modern_aix_as", .llvm_name = "modern-aix-as", .description = "AIX system assembler is modern enough to support new mnes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "msync", .llvm_name = "msync", .description = "Has only the msync instruction instead of sync", .dependencies = .{ .ints = .{ 32, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "paired_vector_memops", .llvm_name = "paired-vector-memops", .description = "32Byte load and store instructions", .dependencies = .{ .ints = .{ 35184372088832, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "partword_atomics", .llvm_name = "partword-atomics", .description = "Enable l[bh]arx and st[bh]cx.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "pcrelative_memops", .llvm_name = "pcrelative-memops", .description = "Enable PC relative Memory Ops", .dependencies = .{ .ints = .{ 0, 32, 0, 0, 0 } } },
            .{ .index = 58, .name = "popcntd", .llvm_name = "popcntd", .description = "Enable the popcnt[dw] instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "power10_vector", .llvm_name = "power10-vector", .description = "Enable POWER10 vector instructions", .dependencies = .{ .ints = .{ 9223442405598953472, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "power8_altivec", .llvm_name = "power8-altivec", .description = "Enable POWER8 Altivec instructions", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "power8_vector", .llvm_name = "power8-vector", .description = "Enable POWER8 vector instructions", .dependencies = .{ .ints = .{ 1152921504606846976, 65536, 0, 0, 0 } } },
            .{ .index = 62, .name = "power9_altivec", .llvm_name = "power9-altivec", .description = "Enable POWER9 Altivec instructions", .dependencies = .{ .ints = .{ 1152956688978935808, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "power9_vector", .llvm_name = "power9-vector", .description = "Enable POWER9 vector instructions", .dependencies = .{ .ints = .{ 6917529027641081856, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "ppc4xx", .llvm_name = "ppc4xx", .description = "Enable PPC 4xx instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 65, .name = "ppc6xx", .llvm_name = "ppc6xx", .description = "Enable PPC 6xx instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 66, .name = "ppc_postra_sched", .llvm_name = "ppc-postra-sched", .description = "Use PowerPC post-RA scheduling strategy", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 67, .name = "ppc_prera_sched", .llvm_name = "ppc-prera-sched", .description = "Use PowerPC pre-RA scheduling strategy", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 68, .name = "predictable_select_expensive", .llvm_name = "predictable-select-expensive", .description = "Prefer likely predicted branches over selects", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 69, .name = "prefix_instrs", .llvm_name = "prefix-instrs", .description = "Enable prefixed instructions", .dependencies = .{ .ints = .{ 6917529027641081856, 0, 0, 0, 0 } } },
            .{ .index = 70, .name = "privileged", .llvm_name = "privileged", .description = "Add privileged instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 71, .name = "quadword_atomics", .llvm_name = "quadword-atomics", .description = "Enable lqarx and stqcx.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 72, .name = "recipprec", .llvm_name = "recipprec", .description = "Assume higher precision reciprocal estimates", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 73, .name = "rop_protect", .llvm_name = "rop-protect", .description = "Add ROP protect", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 74, .name = "secure_plt", .llvm_name = "secure-plt", .description = "Enable secure plt mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 75, .name = "slow_popcntd", .llvm_name = "slow-popcntd", .description = "Has slow popcnt[dw] instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 76, .name = "spe", .llvm_name = "spe", .description = "Enable SPE instructions", .dependencies = .{ .ints = .{ 274877906944, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "stfiwx", .llvm_name = "stfiwx", .description = "Enable the stfiwx instruction", .dependencies = .{ .ints = .{ 524288, 0, 0, 0, 0 } } },
            .{ .index = 78, .name = "two_const_nr", .llvm_name = "two-const-nr", .description = "Requires two constant Newton-Raphson computation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 79, .name = "vectors_use_two_units", .llvm_name = "vectors-use-two-units", .description = "Vectors use two units", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 80, .name = "vsx", .llvm_name = "vsx", .description = "Enable VSX instructions", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const @"440": Cpu = .{ .name = "440", .llvm_name = "440", .features = .{ .ints = .{ 18155136004128768, 0, 0, 0, 0 } } };
            const @"450": Cpu = .{ .name = "450", .llvm_name = "450", .features = .{ .ints = .{ 18155136004128768, 0, 0, 0, 0 } } };
            const @"601": Cpu = .{ .name = "601", .llvm_name = "601", .features = .{ .ints = .{ 524288, 0, 0, 0, 0 } } };
            const @"602": Cpu = .{ .name = "602", .llvm_name = "602", .features = .{ .ints = .{ 524288, 0, 0, 0, 0 } } };
            const @"603": Cpu = .{ .name = "603", .llvm_name = "603", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"603e": Cpu = .{ .name = "603e", .llvm_name = "603e", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"603ev": Cpu = .{ .name = "603ev", .llvm_name = "603ev", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"604": Cpu = .{ .name = "604", .llvm_name = "604", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"604e": Cpu = .{ .name = "604e", .llvm_name = "604e", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"620": Cpu = .{ .name = "620", .llvm_name = "620", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"7400": Cpu = .{ .name = "7400", .llvm_name = "7400", .features = .{ .ints = .{ 6291472, 0, 0, 0, 0 } } };
            const @"7450": Cpu = .{ .name = "7450", .llvm_name = "7450", .features = .{ .ints = .{ 6291472, 0, 0, 0, 0 } } };
            const @"750": Cpu = .{ .name = "750", .llvm_name = "750", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const @"970": Cpu = .{ .name = "970", .llvm_name = "970", .features = .{ .ints = .{ 2251799836753937, 8192, 0, 0, 0 } } };
            const a2: Cpu = .{ .name = "a2", .llvm_name = "a2", .features = .{ .ints = .{ 3245758358126753, 10496, 0, 0, 0 } } };
            const e500: Cpu = .{ .name = "e500", .llvm_name = "e500", .features = .{ .ints = .{ 18155135997837312, 4096, 0, 0, 0 } } };
            const e500mc: Cpu = .{ .name = "e500mc", .llvm_name = "e500mc", .features = .{ .ints = .{ 140737488355360, 8192, 0, 0, 0 } } };
            const e5500: Cpu = .{ .name = "e5500", .llvm_name = "e5500", .features = .{ .ints = .{ 2392537302040609, 8192, 0, 0, 0 } } };
            const future: Cpu = .{ .name = "future", .llvm_name = "future", .features = .{ .ints = .{ 1088619348382640073, 24988, 0, 0, 0 } } };
            const g3: Cpu = .{ .name = "g3", .llvm_name = "g3", .features = .{ .ints = .{ 6291456, 0, 0, 0, 0 } } };
            const g4: Cpu = .{ .name = "g4", .llvm_name = "g4", .features = .{ .ints = .{ 6291472, 0, 0, 0, 0 } } };
            const @"g4+": Cpu = .{ .name = "g4+", .llvm_name = "g4+", .features = .{ .ints = .{ 6291472, 0, 0, 0, 0 } } };
            const g5: Cpu = .{ .name = "g5", .llvm_name = "g5", .features = .{ .ints = .{ 2251799836753937, 8192, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 274877906944, 0, 0, 0, 0 } } };
            const ppc: Cpu = .{ .name = "ppc", .llvm_name = "ppc", .features = .{ .ints = .{ 274877906944, 0, 0, 0, 0 } } };
            const ppc64: Cpu = .{ .name = "ppc64", .llvm_name = "ppc64", .features = .{ .ints = .{ 2251799836753937, 8192, 0, 0, 0 } } };
            const ppc64le: Cpu = .{ .name = "ppc64le", .llvm_name = "ppc64le", .features = .{ .ints = .{ 2669395979416283081, 24976, 0, 0, 0 } } };
            const pwr10: Cpu = .{ .name = "pwr10", .llvm_name = "pwr10", .features = .{ .ints = .{ 1088614950336128969, 24988, 0, 0, 0 } } };
            const pwr3: Cpu = .{ .name = "pwr3", .llvm_name = "pwr3", .features = .{ .ints = .{ 2251799819976721, 8192, 0, 0, 0 } } };
            const pwr4: Cpu = .{ .name = "pwr4", .llvm_name = "pwr4", .features = .{ .ints = .{ 2251799836753937, 8192, 0, 0, 0 } } };
            const pwr5: Cpu = .{ .name = "pwr5", .llvm_name = "pwr5", .features = .{ .ints = .{ 2251799846191121, 8192, 0, 0, 0 } } };
            const pwr5x: Cpu = .{ .name = "pwr5x", .llvm_name = "pwr5x", .features = .{ .ints = .{ 2251799846453265, 8192, 0, 0, 0 } } };
            const pwr6: Cpu = .{ .name = "pwr6", .llvm_name = "pwr6", .features = .{ .ints = .{ 2814749799907473, 8448, 0, 0, 0 } } };
            const pwr6x: Cpu = .{ .name = "pwr6x", .llvm_name = "pwr6x", .features = .{ .ints = .{ 2814749799907473, 8448, 0, 0, 0 } } };
            const pwr7: Cpu = .{ .name = "pwr7", .llvm_name = "pwr7", .features = .{ .ints = .{ 291476134509846729, 90368, 0, 0, 0 } } };
            const pwr8: Cpu = .{ .name = "pwr8", .llvm_name = "pwr8", .features = .{ .ints = .{ 2669395979416283081, 24976, 0, 0, 0 } } };
            const pwr9: Cpu = .{ .name = "pwr9", .llvm_name = "pwr9", .features = .{ .ints = .{ 9586907414669993929, 57756, 0, 0, 0 } } };
        };
    };
    pub const riscv = struct {
        pub const Feature = enum(u7) {
            @"32bit" = 0,
            @"64bit" = 1,
            a = 2,
            c = 3,
            d = 4,
            e = 5,
            experimental_zawrs = 6,
            experimental_zca = 7,
            experimental_zcd = 8,
            experimental_zcf = 9,
            experimental_zihintntl = 10,
            experimental_ztso = 11,
            experimental_zvfh = 12,
            f = 13,
            forced_atomics = 14,
            h = 15,
            lui_addi_fusion = 16,
            m = 17,
            no_default_unroll = 18,
            no_optimized_zero_stride_load = 19,
            no_rvc_hints = 20,
            relax = 21,
            reserve_x1 = 22,
            reserve_x10 = 23,
            reserve_x11 = 24,
            reserve_x12 = 25,
            reserve_x13 = 26,
            reserve_x14 = 27,
            reserve_x15 = 28,
            reserve_x16 = 29,
            reserve_x17 = 30,
            reserve_x18 = 31,
            reserve_x19 = 32,
            reserve_x2 = 33,
            reserve_x20 = 34,
            reserve_x21 = 35,
            reserve_x22 = 36,
            reserve_x23 = 37,
            reserve_x24 = 38,
            reserve_x25 = 39,
            reserve_x26 = 40,
            reserve_x27 = 41,
            reserve_x28 = 42,
            reserve_x29 = 43,
            reserve_x3 = 44,
            reserve_x30 = 45,
            reserve_x31 = 46,
            reserve_x4 = 47,
            reserve_x5 = 48,
            reserve_x6 = 49,
            reserve_x7 = 50,
            reserve_x8 = 51,
            reserve_x9 = 52,
            save_restore = 53,
            short_forward_branch_opt = 54,
            svinval = 55,
            svnapot = 56,
            svpbmt = 57,
            tagged_globals = 58,
            unaligned_scalar_mem = 59,
            v = 60,
            xtheadvdot = 61,
            xventanacondops = 62,
            zba = 63,
            zbb = 64,
            zbc = 65,
            zbkb = 66,
            zbkc = 67,
            zbkx = 68,
            zbs = 69,
            zdinx = 70,
            zfh = 71,
            zfhmin = 72,
            zfinx = 73,
            zhinx = 74,
            zhinxmin = 75,
            zicbom = 76,
            zicbop = 77,
            zicboz = 78,
            zihintpause = 79,
            zk = 80,
            zkn = 81,
            zknd = 82,
            zkne = 83,
            zknh = 84,
            zkr = 85,
            zks = 86,
            zksed = 87,
            zksh = 88,
            zkt = 89,
            zmmul = 90,
            zve32f = 91,
            zve32x = 92,
            zve64d = 93,
            zve64f = 94,
            zve64x = 95,
            zvl1024b = 96,
            zvl128b = 97,
            zvl16384b = 98,
            zvl2048b = 99,
            zvl256b = 100,
            zvl32768b = 101,
            zvl32b = 102,
            zvl4096b = 103,
            zvl512b = 104,
            zvl64b = 105,
            zvl65536b = 106,
            zvl8192b = 107,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "32bit", .llvm_name = "32bit", .description = "Implements RV32", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "64bit", .llvm_name = "64bit", .description = "Implements RV64", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "a", .llvm_name = "a", .description = "'A' (Atomic Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "c", .llvm_name = "c", .description = "'C' (Compressed Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "d", .llvm_name = "d", .description = "'D' (Double-Precision Floating-Point)", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "e", .llvm_name = "e", .description = "Implements RV32E (provides 16 rather than 32 GPRs)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "experimental_zawrs", .llvm_name = "experimental-zawrs", .description = "'Zawrs' (Wait on Reservation Set)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "experimental_zca", .llvm_name = "experimental-zca", .description = "'Zca' (part of the C extension, excluding compressed floating point loads/stores)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "experimental_zcd", .llvm_name = "experimental-zcd", .description = "'Zcd' (Compressed Double-Precision Floating-Point Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "experimental_zcf", .llvm_name = "experimental-zcf", .description = "'Zcf' (Compressed Single-Precision Floating-Point Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "experimental_zihintntl", .llvm_name = "experimental-zihintntl", .description = "'zihintntl' (Non-Temporal Locality Hints)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "experimental_ztso", .llvm_name = "experimental-ztso", .description = "'Ztso' (Memory Model - Total Store Order)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "experimental_zvfh", .llvm_name = "experimental-zvfh", .description = "'Zvfh' (Vector Half-Precision Floating-Point)", .dependencies = .{ .ints = .{ 0, 134217728, 0, 0, 0 } } },
            .{ .index = 13, .name = "f", .llvm_name = "f", .description = "'F' (Single-Precision Floating-Point)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "forced_atomics", .llvm_name = "forced-atomics", .description = "Assume that lock-free native-width atomics are available", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "h", .llvm_name = "h", .description = "'H' (Hypervisor)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "lui_addi_fusion", .llvm_name = "lui-addi-fusion", .description = "Enable LUI+ADDI macrofusion", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "m", .llvm_name = "m", .description = "'M' (Integer Multiplication and Division)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "no_default_unroll", .llvm_name = "no-default-unroll", .description = "Disable default unroll preference.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "no_optimized_zero_stride_load", .llvm_name = "no-optimized-zero-stride-load", .description = "Hasn't optimized (perform fewer memory operations)zero-stride vector load", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "no_rvc_hints", .llvm_name = "no-rvc-hints", .description = "Disable RVC Hint Instructions.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "relax", .llvm_name = "relax", .description = "Enable Linker relaxation.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "reserve_x1", .llvm_name = "reserve-x1", .description = "Reserve X1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "reserve_x10", .llvm_name = "reserve-x10", .description = "Reserve X10", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "reserve_x11", .llvm_name = "reserve-x11", .description = "Reserve X11", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "reserve_x12", .llvm_name = "reserve-x12", .description = "Reserve X12", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "reserve_x13", .llvm_name = "reserve-x13", .description = "Reserve X13", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "reserve_x14", .llvm_name = "reserve-x14", .description = "Reserve X14", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "reserve_x15", .llvm_name = "reserve-x15", .description = "Reserve X15", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "reserve_x16", .llvm_name = "reserve-x16", .description = "Reserve X16", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "reserve_x17", .llvm_name = "reserve-x17", .description = "Reserve X17", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "reserve_x18", .llvm_name = "reserve-x18", .description = "Reserve X18", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "reserve_x19", .llvm_name = "reserve-x19", .description = "Reserve X19", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "reserve_x2", .llvm_name = "reserve-x2", .description = "Reserve X2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "reserve_x20", .llvm_name = "reserve-x20", .description = "Reserve X20", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "reserve_x21", .llvm_name = "reserve-x21", .description = "Reserve X21", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "reserve_x22", .llvm_name = "reserve-x22", .description = "Reserve X22", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "reserve_x23", .llvm_name = "reserve-x23", .description = "Reserve X23", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "reserve_x24", .llvm_name = "reserve-x24", .description = "Reserve X24", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "reserve_x25", .llvm_name = "reserve-x25", .description = "Reserve X25", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "reserve_x26", .llvm_name = "reserve-x26", .description = "Reserve X26", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "reserve_x27", .llvm_name = "reserve-x27", .description = "Reserve X27", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "reserve_x28", .llvm_name = "reserve-x28", .description = "Reserve X28", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "reserve_x29", .llvm_name = "reserve-x29", .description = "Reserve X29", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "reserve_x3", .llvm_name = "reserve-x3", .description = "Reserve X3", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "reserve_x30", .llvm_name = "reserve-x30", .description = "Reserve X30", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "reserve_x31", .llvm_name = "reserve-x31", .description = "Reserve X31", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "reserve_x4", .llvm_name = "reserve-x4", .description = "Reserve X4", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "reserve_x5", .llvm_name = "reserve-x5", .description = "Reserve X5", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "reserve_x6", .llvm_name = "reserve-x6", .description = "Reserve X6", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "reserve_x7", .llvm_name = "reserve-x7", .description = "Reserve X7", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "reserve_x8", .llvm_name = "reserve-x8", .description = "Reserve X8", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "reserve_x9", .llvm_name = "reserve-x9", .description = "Reserve X9", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 53, .name = "save_restore", .llvm_name = "save-restore", .description = "Enable save/restore.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "short_forward_branch_opt", .llvm_name = "short-forward-branch-opt", .description = "Enable short forward branch optimization", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "svinval", .llvm_name = "svinval", .description = "'Svinval' (Fine-Grained Address-Translation Cache Invalidation)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "svnapot", .llvm_name = "svnapot", .description = "'Svnapot' (NAPOT Translation Contiguity)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "svpbmt", .llvm_name = "svpbmt", .description = "'Svpbmt' (Page-Based Memory Types)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 58, .name = "tagged_globals", .llvm_name = "tagged-globals", .description = "Use an instruction sequence for taking the address of a global that allows a memory tag in the upper address bits", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "unaligned_scalar_mem", .llvm_name = "unaligned-scalar-mem", .description = "Has reasonably performant unaligned scalar loads and stores", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "v", .llvm_name = "v", .description = "'V' (Vector Extension for Application Processors)", .dependencies = .{ .ints = .{ 16, 9126805504, 0, 0, 0 } } },
            .{ .index = 61, .name = "xtheadvdot", .llvm_name = "xtheadvdot", .description = "'xtheadvdot' (T-Head Vector Extensions for Dot)", .dependencies = .{ .ints = .{ 1152921504606846976, 0, 0, 0, 0 } } },
            .{ .index = 62, .name = "xventanacondops", .llvm_name = "xventanacondops", .description = "'XVentanaCondOps' (Ventana Conditional Ops)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "zba", .llvm_name = "zba", .description = "'Zba' (Address Generation Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "zbb", .llvm_name = "zbb", .description = "'Zbb' (Basic Bit-Manipulation)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 65, .name = "zbc", .llvm_name = "zbc", .description = "'Zbc' (Carry-Less Multiplication)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 66, .name = "zbkb", .llvm_name = "zbkb", .description = "'Zbkb' (Bitmanip instructions for Cryptography)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 67, .name = "zbkc", .llvm_name = "zbkc", .description = "'Zbkc' (Carry-less multiply instructions for Cryptography)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 68, .name = "zbkx", .llvm_name = "zbkx", .description = "'Zbkx' (Crossbar permutation instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 69, .name = "zbs", .llvm_name = "zbs", .description = "'Zbs' (Single-Bit Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 70, .name = "zdinx", .llvm_name = "zdinx", .description = "'Zdinx' (Double in Integer)", .dependencies = .{ .ints = .{ 0, 512, 0, 0, 0 } } },
            .{ .index = 71, .name = "zfh", .llvm_name = "zfh", .description = "'Zfh' (Half-Precision Floating-Point)", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 72, .name = "zfhmin", .llvm_name = "zfhmin", .description = "'Zfhmin' (Half-Precision Floating-Point Minimal)", .dependencies = .{ .ints = .{ 8192, 0, 0, 0, 0 } } },
            .{ .index = 73, .name = "zfinx", .llvm_name = "zfinx", .description = "'Zfinx' (Float in Integer)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 74, .name = "zhinx", .llvm_name = "zhinx", .description = "'Zhinx' (Half Float in Integer)", .dependencies = .{ .ints = .{ 0, 512, 0, 0, 0 } } },
            .{ .index = 75, .name = "zhinxmin", .llvm_name = "zhinxmin", .description = "'Zhinxmin' (Half Float in Integer Minimal)", .dependencies = .{ .ints = .{ 0, 512, 0, 0, 0 } } },
            .{ .index = 76, .name = "zicbom", .llvm_name = "zicbom", .description = "'Zicbom' (Cache-Block Management Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "zicbop", .llvm_name = "zicbop", .description = "'Zicbop' (Cache-Block Prefetch Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 78, .name = "zicboz", .llvm_name = "zicboz", .description = "'Zicboz' (Cache-Block Zero Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 79, .name = "zihintpause", .llvm_name = "zihintpause", .description = "'zihintpause' (Pause Hint)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 80, .name = "zk", .llvm_name = "zk", .description = "'Zk' (Standard scalar cryptography extension)", .dependencies = .{ .ints = .{ 0, 35782656, 0, 0, 0 } } },
            .{ .index = 81, .name = "zkn", .llvm_name = "zkn", .description = "'Zkn' (NIST Algorithm Suite)", .dependencies = .{ .ints = .{ 0, 1835036, 0, 0, 0 } } },
            .{ .index = 82, .name = "zknd", .llvm_name = "zknd", .description = "'Zknd' (NIST Suite: AES Decryption)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 83, .name = "zkne", .llvm_name = "zkne", .description = "'Zkne' (NIST Suite: AES Encryption)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 84, .name = "zknh", .llvm_name = "zknh", .description = "'Zknh' (NIST Suite: Hash Function Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 85, .name = "zkr", .llvm_name = "zkr", .description = "'Zkr' (Entropy Source Extension)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 86, .name = "zks", .llvm_name = "zks", .description = "'Zks' (ShangMi Algorithm Suite)", .dependencies = .{ .ints = .{ 0, 25165852, 0, 0, 0 } } },
            .{ .index = 87, .name = "zksed", .llvm_name = "zksed", .description = "'Zksed' (ShangMi Suite: SM4 Block Cipher Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 88, .name = "zksh", .llvm_name = "zksh", .description = "'Zksh' (ShangMi Suite: SM3 Hash Function Instructions)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 89, .name = "zkt", .llvm_name = "zkt", .description = "'Zkt' (Data Independent Execution Latency)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 90, .name = "zmmul", .llvm_name = "zmmul", .description = "'Zmmul' (Integer Multiplication)", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 91, .name = "zve32f", .llvm_name = "zve32f", .description = "'Zve32f' (Vector Extensions for Embedded Processors with maximal 32 EEW and F extension)", .dependencies = .{ .ints = .{ 0, 268435456, 0, 0, 0 } } },
            .{ .index = 92, .name = "zve32x", .llvm_name = "zve32x", .description = "'Zve32x' (Vector Extensions for Embedded Processors with maximal 32 EEW)", .dependencies = .{ .ints = .{ 0, 274877906944, 0, 0, 0 } } },
            .{ .index = 93, .name = "zve64d", .llvm_name = "zve64d", .description = "'Zve64d' (Vector Extensions for Embedded Processors with maximal 64 EEW, F and D extension)", .dependencies = .{ .ints = .{ 0, 1073741824, 0, 0, 0 } } },
            .{ .index = 94, .name = "zve64f", .llvm_name = "zve64f", .description = "'Zve64f' (Vector Extensions for Embedded Processors with maximal 64 EEW and F extension)", .dependencies = .{ .ints = .{ 0, 2281701376, 0, 0, 0 } } },
            .{ .index = 95, .name = "zve64x", .llvm_name = "zve64x", .description = "'Zve64x' (Vector Extensions for Embedded Processors with maximal 64 EEW)", .dependencies = .{ .ints = .{ 0, 2199291691008, 0, 0, 0 } } },
            .{ .index = 96, .name = "zvl1024b", .llvm_name = "zvl1024b", .description = "'Zvl' (Minimum Vector Length) 1024", .dependencies = .{ .ints = .{ 0, 1099511627776, 0, 0, 0 } } },
            .{ .index = 97, .name = "zvl128b", .llvm_name = "zvl128b", .description = "'Zvl' (Minimum Vector Length) 128", .dependencies = .{ .ints = .{ 0, 2199023255552, 0, 0, 0 } } },
            .{ .index = 98, .name = "zvl16384b", .llvm_name = "zvl16384b", .description = "'Zvl' (Minimum Vector Length) 16384", .dependencies = .{ .ints = .{ 0, 8796093022208, 0, 0, 0 } } },
            .{ .index = 99, .name = "zvl2048b", .llvm_name = "zvl2048b", .description = "'Zvl' (Minimum Vector Length) 2048", .dependencies = .{ .ints = .{ 0, 4294967296, 0, 0, 0 } } },
            .{ .index = 100, .name = "zvl256b", .llvm_name = "zvl256b", .description = "'Zvl' (Minimum Vector Length) 256", .dependencies = .{ .ints = .{ 0, 8589934592, 0, 0, 0 } } },
            .{ .index = 101, .name = "zvl32768b", .llvm_name = "zvl32768b", .description = "'Zvl' (Minimum Vector Length) 32768", .dependencies = .{ .ints = .{ 0, 17179869184, 0, 0, 0 } } },
            .{ .index = 102, .name = "zvl32b", .llvm_name = "zvl32b", .description = "'Zvl' (Minimum Vector Length) 32", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 103, .name = "zvl4096b", .llvm_name = "zvl4096b", .description = "'Zvl' (Minimum Vector Length) 4096", .dependencies = .{ .ints = .{ 0, 34359738368, 0, 0, 0 } } },
            .{ .index = 104, .name = "zvl512b", .llvm_name = "zvl512b", .description = "'Zvl' (Minimum Vector Length) 512", .dependencies = .{ .ints = .{ 0, 68719476736, 0, 0, 0 } } },
            .{ .index = 105, .name = "zvl64b", .llvm_name = "zvl64b", .description = "'Zvl' (Minimum Vector Length) 64", .dependencies = .{ .ints = .{ 0, 274877906944, 0, 0, 0 } } },
            .{ .index = 106, .name = "zvl65536b", .llvm_name = "zvl65536b", .description = "'Zvl' (Minimum Vector Length) 65536", .dependencies = .{ .ints = .{ 0, 137438953472, 0, 0, 0 } } },
            .{ .index = 107, .name = "zvl8192b", .llvm_name = "zvl8192b", .description = "'Zvl' (Minimum Vector Length) 8192", .dependencies = .{ .ints = .{ 0, 549755813888, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const baseline_rv32: Cpu = .{ .name = "baseline_rv32", .llvm_name = null, .features = .{ .ints = .{ 131101, 0, 0, 0, 0 } } };
            const baseline_rv64: Cpu = .{ .name = "baseline_rv64", .llvm_name = null, .features = .{ .ints = .{ 131102, 0, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const generic_rv32: Cpu = .{ .name = "generic_rv32", .llvm_name = "generic-rv32", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
            const generic_rv64: Cpu = .{ .name = "generic_rv64", .llvm_name = "generic-rv64", .features = .{ .ints = .{ 2, 0, 0, 0, 0 } } };
            const rocket: Cpu = .{ .name = "rocket", .llvm_name = "rocket", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const rocket_rv32: Cpu = .{ .name = "rocket_rv32", .llvm_name = "rocket-rv32", .features = .{ .ints = .{ 1, 0, 0, 0, 0 } } };
            const rocket_rv64: Cpu = .{ .name = "rocket_rv64", .llvm_name = "rocket-rv64", .features = .{ .ints = .{ 2, 0, 0, 0, 0 } } };
            const sifive_7_series: Cpu = .{ .name = "sifive_7_series", .llvm_name = "sifive-7-series", .features = .{ .ints = .{ 18014398509744128, 0, 0, 0, 0 } } };
            const sifive_e20: Cpu = .{ .name = "sifive_e20", .llvm_name = "sifive-e20", .features = .{ .ints = .{ 131081, 0, 0, 0, 0 } } };
            const sifive_e21: Cpu = .{ .name = "sifive_e21", .llvm_name = "sifive-e21", .features = .{ .ints = .{ 131085, 0, 0, 0, 0 } } };
            const sifive_e24: Cpu = .{ .name = "sifive_e24", .llvm_name = "sifive-e24", .features = .{ .ints = .{ 139277, 0, 0, 0, 0 } } };
            const sifive_e31: Cpu = .{ .name = "sifive_e31", .llvm_name = "sifive-e31", .features = .{ .ints = .{ 131085, 0, 0, 0, 0 } } };
            const sifive_e34: Cpu = .{ .name = "sifive_e34", .llvm_name = "sifive-e34", .features = .{ .ints = .{ 139277, 0, 0, 0, 0 } } };
            const sifive_e76: Cpu = .{ .name = "sifive_e76", .llvm_name = "sifive-e76", .features = .{ .ints = .{ 18014398509883405, 0, 0, 0, 0 } } };
            const sifive_s21: Cpu = .{ .name = "sifive_s21", .llvm_name = "sifive-s21", .features = .{ .ints = .{ 131086, 0, 0, 0, 0 } } };
            const sifive_s51: Cpu = .{ .name = "sifive_s51", .llvm_name = "sifive-s51", .features = .{ .ints = .{ 131086, 0, 0, 0, 0 } } };
            const sifive_s54: Cpu = .{ .name = "sifive_s54", .llvm_name = "sifive-s54", .features = .{ .ints = .{ 131102, 0, 0, 0, 0 } } };
            const sifive_s76: Cpu = .{ .name = "sifive_s76", .llvm_name = "sifive-s76", .features = .{ .ints = .{ 18014398509875230, 0, 0, 0, 0 } } };
            const sifive_u54: Cpu = .{ .name = "sifive_u54", .llvm_name = "sifive-u54", .features = .{ .ints = .{ 131102, 0, 0, 0, 0 } } };
            const sifive_u74: Cpu = .{ .name = "sifive_u74", .llvm_name = "sifive-u74", .features = .{ .ints = .{ 18014398509875230, 0, 0, 0, 0 } } };
            const syntacore_scr1_base: Cpu = .{ .name = "syntacore_scr1_base", .llvm_name = "syntacore-scr1-base", .features = .{ .ints = .{ 262153, 0, 0, 0, 0 } } };
            const syntacore_scr1_max: Cpu = .{ .name = "syntacore_scr1_max", .llvm_name = "syntacore-scr1-max", .features = .{ .ints = .{ 393225, 0, 0, 0, 0 } } };
        };
    };
    pub const sparc = struct {
        pub const Feature = enum(u5) {
            deprecated_v8 = 0,
            detectroundchange = 1,
            fixallfdivsqrt = 2,
            hard_quad_float = 3,
            hasleoncasa = 4,
            hasumacsmac = 5,
            insertnopload = 6,
            leon = 7,
            leoncyclecounter = 8,
            leonpwrpsr = 9,
            no_fmuls = 10,
            no_fsmuld = 11,
            popc = 12,
            soft_float = 13,
            soft_mul_div = 14,
            v9 = 15,
            vis = 16,
            vis2 = 17,
            vis3 = 18,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "deprecated_v8", .llvm_name = "deprecated-v8", .description = "Enable deprecated V8 instructions in V9 mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "detectroundchange", .llvm_name = "detectroundchange", .description = "LEON3 erratum detection: Detects any rounding mode change request: use only the round-to-nearest rounding mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "fixallfdivsqrt", .llvm_name = "fixallfdivsqrt", .description = "LEON erratum fix: Fix FDIVS/FDIVD/FSQRTS/FSQRTD instructions with NOPs and floating-point store", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "hard_quad_float", .llvm_name = "hard-quad-float", .description = "Enable quad-word floating point instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "hasleoncasa", .llvm_name = "hasleoncasa", .description = "Enable CASA instruction for LEON3 and LEON4 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "hasumacsmac", .llvm_name = "hasumacsmac", .description = "Enable UMAC and SMAC for LEON3 and LEON4 processors", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "insertnopload", .llvm_name = "insertnopload", .description = "LEON3 erratum fix: Insert a NOP instruction after every single-cycle load instruction when the next instruction is another load/store instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "leon", .llvm_name = "leon", .description = "Enable LEON extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "leoncyclecounter", .llvm_name = "leoncyclecounter", .description = "Use the Leon cycle counter register", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "leonpwrpsr", .llvm_name = "leonpwrpsr", .description = "Enable the PWRPSR instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "no_fmuls", .llvm_name = "no-fmuls", .description = "Disable the fmuls instruction.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "no_fsmuld", .llvm_name = "no-fsmuld", .description = "Disable the fsmuld instruction.", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "popc", .llvm_name = "popc", .description = "Use the popc (population count) instruction", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "soft_float", .llvm_name = "soft-float", .description = "Use software emulation for floating point", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "soft_mul_div", .llvm_name = "soft-mul-div", .description = "Use software emulation for integer multiply and divide", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "v9", .llvm_name = "v9", .description = "Enable SPARC-V9 instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "vis", .llvm_name = "vis", .description = "Enable UltraSPARC Visual Instruction Set extensions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "vis2", .llvm_name = "vis2", .description = "Enable Visual Instruction Set extensions II", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "vis3", .llvm_name = "vis3", .description = "Enable Visual Instruction Set extensions III", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const at697e: Cpu = .{ .name = "at697e", .llvm_name = "at697e", .features = .{ .ints = .{ 192, 0, 0, 0, 0 } } };
            const at697f: Cpu = .{ .name = "at697f", .llvm_name = "at697f", .features = .{ .ints = .{ 192, 0, 0, 0, 0 } } };
            const f934: Cpu = .{ .name = "f934", .llvm_name = "f934", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const gr712rc: Cpu = .{ .name = "gr712rc", .llvm_name = "gr712rc", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const gr740: Cpu = .{ .name = "gr740", .llvm_name = "gr740", .features = .{ .ints = .{ 944, 0, 0, 0, 0 } } };
            const hypersparc: Cpu = .{ .name = "hypersparc", .llvm_name = "hypersparc", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const leon2: Cpu = .{ .name = "leon2", .llvm_name = "leon2", .features = .{ .ints = .{ 128, 0, 0, 0, 0 } } };
            const leon3: Cpu = .{ .name = "leon3", .llvm_name = "leon3", .features = .{ .ints = .{ 160, 0, 0, 0, 0 } } };
            const leon4: Cpu = .{ .name = "leon4", .llvm_name = "leon4", .features = .{ .ints = .{ 176, 0, 0, 0, 0 } } };
            const ma2080: Cpu = .{ .name = "ma2080", .llvm_name = "ma2080", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2085: Cpu = .{ .name = "ma2085", .llvm_name = "ma2085", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2100: Cpu = .{ .name = "ma2100", .llvm_name = "ma2100", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2150: Cpu = .{ .name = "ma2150", .llvm_name = "ma2150", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2155: Cpu = .{ .name = "ma2155", .llvm_name = "ma2155", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2450: Cpu = .{ .name = "ma2450", .llvm_name = "ma2450", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2455: Cpu = .{ .name = "ma2455", .llvm_name = "ma2455", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2480: Cpu = .{ .name = "ma2480", .llvm_name = "ma2480", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2485: Cpu = .{ .name = "ma2485", .llvm_name = "ma2485", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2x5x: Cpu = .{ .name = "ma2x5x", .llvm_name = "ma2x5x", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const ma2x8x: Cpu = .{ .name = "ma2x8x", .llvm_name = "ma2x8x", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const myriad2: Cpu = .{ .name = "myriad2", .llvm_name = "myriad2", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const myriad2_1: Cpu = .{ .name = "myriad2_1", .llvm_name = "myriad2.1", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const myriad2_2: Cpu = .{ .name = "myriad2_2", .llvm_name = "myriad2.2", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const myriad2_3: Cpu = .{ .name = "myriad2_3", .llvm_name = "myriad2.3", .features = .{ .ints = .{ 144, 0, 0, 0, 0 } } };
            const niagara: Cpu = .{ .name = "niagara", .llvm_name = "niagara", .features = .{ .ints = .{ 229377, 0, 0, 0, 0 } } };
            const niagara2: Cpu = .{ .name = "niagara2", .llvm_name = "niagara2", .features = .{ .ints = .{ 233473, 0, 0, 0, 0 } } };
            const niagara3: Cpu = .{ .name = "niagara3", .llvm_name = "niagara3", .features = .{ .ints = .{ 233473, 0, 0, 0, 0 } } };
            const niagara4: Cpu = .{ .name = "niagara4", .llvm_name = "niagara4", .features = .{ .ints = .{ 495617, 0, 0, 0, 0 } } };
            const sparclet: Cpu = .{ .name = "sparclet", .llvm_name = "sparclet", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const sparclite: Cpu = .{ .name = "sparclite", .llvm_name = "sparclite", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const sparclite86x: Cpu = .{ .name = "sparclite86x", .llvm_name = "sparclite86x", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const supersparc: Cpu = .{ .name = "supersparc", .llvm_name = "supersparc", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const tsc701: Cpu = .{ .name = "tsc701", .llvm_name = "tsc701", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const ultrasparc: Cpu = .{ .name = "ultrasparc", .llvm_name = "ultrasparc", .features = .{ .ints = .{ 98305, 0, 0, 0, 0 } } };
            const ultrasparc3: Cpu = .{ .name = "ultrasparc3", .llvm_name = "ultrasparc3", .features = .{ .ints = .{ 229377, 0, 0, 0, 0 } } };
            const ut699: Cpu = .{ .name = "ut699", .llvm_name = "ut699", .features = .{ .ints = .{ 3268, 0, 0, 0, 0 } } };
            const v7: Cpu = .{ .name = "v7", .llvm_name = "v7", .features = .{ .ints = .{ 18432, 0, 0, 0, 0 } } };
            const v8: Cpu = .{ .name = "v8", .llvm_name = "v8", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const v9: Cpu = .{ .name = "v9", .llvm_name = "v9", .features = .{ .ints = .{ 32768, 0, 0, 0, 0 } } };
        };
    };
    pub const spirv = struct {
        pub const Feature = enum(u9) {
            v1_1 = 0,
            v1_2 = 1,
            v1_3 = 2,
            v1_4 = 3,
            v1_5 = 4,
            SPV_AMD_shader_fragment_mask = 5,
            SPV_AMD_gpu_shader_int16 = 6,
            SPV_AMD_gpu_shader_half_float = 7,
            SPV_AMD_texture_gather_bias_lod = 8,
            SPV_AMD_shader_ballot = 9,
            SPV_AMD_gcn_shader = 10,
            SPV_AMD_shader_image_load_store_lod = 11,
            SPV_AMD_shader_explicit_vertex_parameter = 12,
            SPV_AMD_shader_trinary_minmax = 13,
            SPV_AMD_gpu_shader_half_float_fetch = 14,
            SPV_GOOGLE_hlsl_functionality1 = 15,
            SPV_GOOGLE_user_type = 16,
            SPV_GOOGLE_decorate_string = 17,
            SPV_EXT_demote_to_helper_invocation = 18,
            SPV_EXT_descriptor_indexing = 19,
            SPV_EXT_fragment_fully_covered = 20,
            SPV_EXT_shader_stencil_export = 21,
            SPV_EXT_physical_storage_buffer = 22,
            SPV_EXT_shader_atomic_float_add = 23,
            SPV_EXT_shader_atomic_float_min_max = 24,
            SPV_EXT_shader_image_int64 = 25,
            SPV_EXT_fragment_shader_interlock = 26,
            SPV_EXT_fragment_invocation_density = 27,
            SPV_EXT_shader_viewport_index_layer = 28,
            SPV_INTEL_loop_fuse = 29,
            SPV_INTEL_fpga_dsp_control = 30,
            SPV_INTEL_fpga_reg = 31,
            SPV_INTEL_fpga_memory_accesses = 32,
            SPV_INTEL_fpga_loop_controls = 33,
            SPV_INTEL_io_pipes = 34,
            SPV_INTEL_unstructured_loop_controls = 35,
            SPV_INTEL_blocking_pipes = 36,
            SPV_INTEL_device_side_avc_motion_estimation = 37,
            SPV_INTEL_fpga_memory_attributes = 38,
            SPV_INTEL_fp_fast_math_mode = 39,
            SPV_INTEL_media_block_io = 40,
            SPV_INTEL_shader_integer_functions2 = 41,
            SPV_INTEL_subgroups = 42,
            SPV_INTEL_fpga_cluster_attributes = 43,
            SPV_INTEL_kernel_attributes = 44,
            SPV_INTEL_arbitrary_precision_integers = 45,
            SPV_KHR_8bit_storage = 46,
            SPV_KHR_shader_clock = 47,
            SPV_KHR_device_group = 48,
            SPV_KHR_16bit_storage = 49,
            SPV_KHR_variable_pointers = 50,
            SPV_KHR_no_integer_wrap_decoration = 51,
            SPV_KHR_subgroup_vote = 52,
            SPV_KHR_multiview = 53,
            SPV_KHR_shader_ballot = 54,
            SPV_KHR_vulkan_memory_model = 55,
            SPV_KHR_physical_storage_buffer = 56,
            SPV_KHR_workgroup_memory_explicit_layout = 57,
            SPV_KHR_fragment_shading_rate = 58,
            SPV_KHR_shader_atomic_counter_ops = 59,
            SPV_KHR_shader_draw_parameters = 60,
            SPV_KHR_storage_buffer_storage_class = 61,
            SPV_KHR_linkonce_odr = 62,
            SPV_KHR_terminate_invocation = 63,
            SPV_KHR_non_semantic_info = 64,
            SPV_KHR_post_depth_coverage = 65,
            SPV_KHR_expect_assume = 66,
            SPV_KHR_ray_tracing = 67,
            SPV_KHR_ray_query = 68,
            SPV_KHR_float_controls = 69,
            SPV_NV_viewport_array2 = 70,
            SPV_NV_shader_subgroup_partitioned = 71,
            SPV_NVX_multiview_per_view_attributes = 72,
            SPV_NV_ray_tracing = 73,
            SPV_NV_shader_image_footprint = 74,
            SPV_NV_shading_rate = 75,
            SPV_NV_stereo_view_rendering = 76,
            SPV_NV_compute_shader_derivatives = 77,
            SPV_NV_shader_sm_builtins = 78,
            SPV_NV_mesh_shader = 79,
            SPV_NV_geometry_shader_passthrough = 80,
            SPV_NV_fragment_shader_barycentric = 81,
            SPV_NV_cooperative_matrix = 82,
            SPV_NV_sample_mask_override_coverage = 83,
            Matrix = 84,
            Shader = 85,
            Geometry = 86,
            Tessellation = 87,
            Addresses = 88,
            Linkage = 89,
            Kernel = 90,
            Vector16 = 91,
            Float16Buffer = 92,
            Float16 = 93,
            Float64 = 94,
            Int64 = 95,
            Int64Atomics = 96,
            ImageBasic = 97,
            ImageReadWrite = 98,
            ImageMipmap = 99,
            Pipes = 100,
            Groups = 101,
            DeviceEnqueue = 102,
            LiteralSampler = 103,
            AtomicStorage = 104,
            Int16 = 105,
            TessellationPointSize = 106,
            GeometryPointSize = 107,
            ImageGatherExtended = 108,
            StorageImageMultisample = 109,
            UniformBufferArrayDynamicIndexing = 110,
            SampledImageArrayDynamicIndexing = 111,
            StorageBufferArrayDynamicIndexing = 112,
            StorageImageArrayDynamicIndexing = 113,
            ClipDistance = 114,
            CullDistance = 115,
            ImageCubeArray = 116,
            SampleRateShading = 117,
            ImageRect = 118,
            SampledRect = 119,
            GenericPointer = 120,
            Int8 = 121,
            InputAttachment = 122,
            SparseResidency = 123,
            MinLod = 124,
            Sampled1D = 125,
            Image1D = 126,
            SampledCubeArray = 127,
            SampledBuffer = 128,
            ImageBuffer = 129,
            ImageMSArray = 130,
            StorageImageExtendedFormats = 131,
            ImageQuery = 132,
            DerivativeControl = 133,
            InterpolationFunction = 134,
            TransformFeedback = 135,
            GeometryStreams = 136,
            StorageImageReadWithoutFormat = 137,
            StorageImageWriteWithoutFormat = 138,
            MultiViewport = 139,
            SubgroupDispatch = 140,
            NamedBarrier = 141,
            PipeStorage = 142,
            GroupNonUniform = 143,
            GroupNonUniformVote = 144,
            GroupNonUniformArithmetic = 145,
            GroupNonUniformBallot = 146,
            GroupNonUniformShuffle = 147,
            GroupNonUniformShuffleRelative = 148,
            GroupNonUniformClustered = 149,
            GroupNonUniformQuad = 150,
            ShaderLayer = 151,
            ShaderViewportIndex = 152,
            FragmentShadingRateKHR = 153,
            SubgroupBallotKHR = 154,
            DrawParameters = 155,
            WorkgroupMemoryExplicitLayoutKHR = 156,
            WorkgroupMemoryExplicitLayout8BitAccessKHR = 157,
            WorkgroupMemoryExplicitLayout16BitAccessKHR = 158,
            SubgroupVoteKHR = 159,
            StorageBuffer16BitAccess = 160,
            StorageUniformBufferBlock16 = 161,
            UniformAndStorageBuffer16BitAccess = 162,
            StorageUniform16 = 163,
            StoragePushConstant16 = 164,
            StorageInputOutput16 = 165,
            DeviceGroup = 166,
            MultiView = 167,
            VariablePointersStorageBuffer = 168,
            VariablePointers = 169,
            AtomicStorageOps = 170,
            SampleMaskPostDepthCoverage = 171,
            StorageBuffer8BitAccess = 172,
            UniformAndStorageBuffer8BitAccess = 173,
            StoragePushConstant8 = 174,
            DenormPreserve = 175,
            DenormFlushToZero = 176,
            SignedZeroInfNanPreserve = 177,
            RoundingModeRTE = 178,
            RoundingModeRTZ = 179,
            RayQueryProvisionalKHR = 180,
            RayQueryKHR = 181,
            RayTraversalPrimitiveCullingKHR = 182,
            RayTracingKHR = 183,
            Float16ImageAMD = 184,
            ImageGatherBiasLodAMD = 185,
            FragmentMaskAMD = 186,
            StencilExportEXT = 187,
            ImageReadWriteLodAMD = 188,
            Int64ImageEXT = 189,
            ShaderClockKHR = 190,
            SampleMaskOverrideCoverageNV = 191,
            GeometryShaderPassthroughNV = 192,
            ShaderViewportIndexLayerEXT = 193,
            ShaderViewportIndexLayerNV = 194,
            ShaderViewportMaskNV = 195,
            ShaderStereoViewNV = 196,
            PerViewAttributesNV = 197,
            FragmentFullyCoveredEXT = 198,
            MeshShadingNV = 199,
            ImageFootprintNV = 200,
            FragmentBarycentricNV = 201,
            ComputeDerivativeGroupQuadsNV = 202,
            FragmentDensityEXT = 203,
            ShadingRateNV = 204,
            GroupNonUniformPartitionedNV = 205,
            ShaderNonUniform = 206,
            ShaderNonUniformEXT = 207,
            RuntimeDescriptorArray = 208,
            RuntimeDescriptorArrayEXT = 209,
            InputAttachmentArrayDynamicIndexing = 210,
            InputAttachmentArrayDynamicIndexingEXT = 211,
            UniformTexelBufferArrayDynamicIndexing = 212,
            UniformTexelBufferArrayDynamicIndexingEXT = 213,
            StorageTexelBufferArrayDynamicIndexing = 214,
            StorageTexelBufferArrayDynamicIndexingEXT = 215,
            UniformBufferArrayNonUniformIndexing = 216,
            UniformBufferArrayNonUniformIndexingEXT = 217,
            SampledImageArrayNonUniformIndexing = 218,
            SampledImageArrayNonUniformIndexingEXT = 219,
            StorageBufferArrayNonUniformIndexing = 220,
            StorageBufferArrayNonUniformIndexingEXT = 221,
            StorageImageArrayNonUniformIndexing = 222,
            StorageImageArrayNonUniformIndexingEXT = 223,
            InputAttachmentArrayNonUniformIndexing = 224,
            InputAttachmentArrayNonUniformIndexingEXT = 225,
            UniformTexelBufferArrayNonUniformIndexing = 226,
            UniformTexelBufferArrayNonUniformIndexingEXT = 227,
            StorageTexelBufferArrayNonUniformIndexing = 228,
            StorageTexelBufferArrayNonUniformIndexingEXT = 229,
            RayTracingNV = 230,
            VulkanMemoryModel = 231,
            VulkanMemoryModelKHR = 232,
            VulkanMemoryModelDeviceScope = 233,
            VulkanMemoryModelDeviceScopeKHR = 234,
            PhysicalStorageBufferAddresses = 235,
            PhysicalStorageBufferAddressesEXT = 236,
            ComputeDerivativeGroupLinearNV = 237,
            RayTracingProvisionalKHR = 238,
            CooperativeMatrixNV = 239,
            FragmentShaderSampleInterlockEXT = 240,
            FragmentShaderShadingRateInterlockEXT = 241,
            ShaderSMBuiltinsNV = 242,
            FragmentShaderPixelInterlockEXT = 243,
            DemoteToHelperInvocationEXT = 244,
            SubgroupShuffleINTEL = 245,
            SubgroupBufferBlockIOINTEL = 246,
            SubgroupImageBlockIOINTEL = 247,
            SubgroupImageMediaBlockIOINTEL = 248,
            RoundToInfinityINTEL = 249,
            FloatingPointModeINTEL = 250,
            IntegerFunctions2INTEL = 251,
            FunctionPointersINTEL = 252,
            IndirectReferencesINTEL = 253,
            AsmINTEL = 254,
            AtomicFloat32MinMaxEXT = 255,
            AtomicFloat64MinMaxEXT = 256,
            AtomicFloat16MinMaxEXT = 257,
            VectorComputeINTEL = 258,
            VectorAnyINTEL = 259,
            ExpectAssumeKHR = 260,
            SubgroupAvcMotionEstimationINTEL = 261,
            SubgroupAvcMotionEstimationIntraINTEL = 262,
            SubgroupAvcMotionEstimationChromaINTEL = 263,
            VariableLengthArrayINTEL = 264,
            FunctionFloatControlINTEL = 265,
            FPGAMemoryAttributesINTEL = 266,
            FPFastMathModeINTEL = 267,
            ArbitraryPrecisionIntegersINTEL = 268,
            UnstructuredLoopControlsINTEL = 269,
            FPGALoopControlsINTEL = 270,
            KernelAttributesINTEL = 271,
            FPGAKernelAttributesINTEL = 272,
            FPGAMemoryAccessesINTEL = 273,
            FPGAClusterAttributesINTEL = 274,
            LoopFuseINTEL = 275,
            FPGABufferLocationINTEL = 276,
            USMStorageClassesINTEL = 277,
            IOPipesINTEL = 278,
            BlockingPipesINTEL = 279,
            FPGARegINTEL = 280,
            AtomicFloat32AddEXT = 281,
            AtomicFloat64AddEXT = 282,
            LongConstantCompositeINTEL = 283,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "v1_1", .llvm_name = null, .description = "SPIR-V version 1.1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "v1_2", .llvm_name = null, .description = "SPIR-V version 1.2", .dependencies = .{ .ints = .{ 1, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "v1_3", .llvm_name = null, .description = "SPIR-V version 1.3", .dependencies = .{ .ints = .{ 2, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "v1_4", .llvm_name = null, .description = "SPIR-V version 1.4", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "v1_5", .llvm_name = null, .description = "SPIR-V version 1.5", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "SPV_AMD_shader_fragment_mask", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_shader_fragment_mask", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "SPV_AMD_gpu_shader_int16", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_gpu_shader_int16", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "SPV_AMD_gpu_shader_half_float", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_gpu_shader_half_float", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "SPV_AMD_texture_gather_bias_lod", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_texture_gather_bias_lod", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "SPV_AMD_shader_ballot", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_shader_ballot", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "SPV_AMD_gcn_shader", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_gcn_shader", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "SPV_AMD_shader_image_load_store_lod", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_shader_image_load_store_lod", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "SPV_AMD_shader_explicit_vertex_parameter", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_shader_explicit_vertex_parameter", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "SPV_AMD_shader_trinary_minmax", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_shader_trinary_minmax", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "SPV_AMD_gpu_shader_half_float_fetch", .llvm_name = null, .description = "SPIR-V extension SPV_AMD_gpu_shader_half_float_fetch", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "SPV_GOOGLE_hlsl_functionality1", .llvm_name = null, .description = "SPIR-V extension SPV_GOOGLE_hlsl_functionality1", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "SPV_GOOGLE_user_type", .llvm_name = null, .description = "SPIR-V extension SPV_GOOGLE_user_type", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "SPV_GOOGLE_decorate_string", .llvm_name = null, .description = "SPIR-V extension SPV_GOOGLE_decorate_string", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "SPV_EXT_demote_to_helper_invocation", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_demote_to_helper_invocation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "SPV_EXT_descriptor_indexing", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_descriptor_indexing", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "SPV_EXT_fragment_fully_covered", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_fragment_fully_covered", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "SPV_EXT_shader_stencil_export", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_shader_stencil_export", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "SPV_EXT_physical_storage_buffer", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_physical_storage_buffer", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "SPV_EXT_shader_atomic_float_add", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_shader_atomic_float_add", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "SPV_EXT_shader_atomic_float_min_max", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_shader_atomic_float_min_max", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "SPV_EXT_shader_image_int64", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_shader_image_int64", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "SPV_EXT_fragment_shader_interlock", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_fragment_shader_interlock", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "SPV_EXT_fragment_invocation_density", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_fragment_invocation_density", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "SPV_EXT_shader_viewport_index_layer", .llvm_name = null, .description = "SPIR-V extension SPV_EXT_shader_viewport_index_layer", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "SPV_INTEL_loop_fuse", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_loop_fuse", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "SPV_INTEL_fpga_dsp_control", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_dsp_control", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "SPV_INTEL_fpga_reg", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_reg", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "SPV_INTEL_fpga_memory_accesses", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_memory_accesses", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "SPV_INTEL_fpga_loop_controls", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_loop_controls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "SPV_INTEL_io_pipes", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_io_pipes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "SPV_INTEL_unstructured_loop_controls", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_unstructured_loop_controls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "SPV_INTEL_blocking_pipes", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_blocking_pipes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "SPV_INTEL_device_side_avc_motion_estimation", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_device_side_avc_motion_estimation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "SPV_INTEL_fpga_memory_attributes", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_memory_attributes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "SPV_INTEL_fp_fast_math_mode", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fp_fast_math_mode", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "SPV_INTEL_media_block_io", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_media_block_io", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 41, .name = "SPV_INTEL_shader_integer_functions2", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_shader_integer_functions2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 42, .name = "SPV_INTEL_subgroups", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_subgroups", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 43, .name = "SPV_INTEL_fpga_cluster_attributes", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_fpga_cluster_attributes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 44, .name = "SPV_INTEL_kernel_attributes", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_kernel_attributes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 45, .name = "SPV_INTEL_arbitrary_precision_integers", .llvm_name = null, .description = "SPIR-V extension SPV_INTEL_arbitrary_precision_integers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 46, .name = "SPV_KHR_8bit_storage", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_8bit_storage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 47, .name = "SPV_KHR_shader_clock", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_shader_clock", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 48, .name = "SPV_KHR_device_group", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_device_group", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 49, .name = "SPV_KHR_16bit_storage", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_16bit_storage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 50, .name = "SPV_KHR_variable_pointers", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_variable_pointers", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 51, .name = "SPV_KHR_no_integer_wrap_decoration", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_no_integer_wrap_decoration", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 52, .name = "SPV_KHR_subgroup_vote", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_subgroup_vote", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 53, .name = "SPV_KHR_multiview", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_multiview", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 54, .name = "SPV_KHR_shader_ballot", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_shader_ballot", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 55, .name = "SPV_KHR_vulkan_memory_model", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_vulkan_memory_model", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 56, .name = "SPV_KHR_physical_storage_buffer", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_physical_storage_buffer", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 57, .name = "SPV_KHR_workgroup_memory_explicit_layout", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_workgroup_memory_explicit_layout", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 58, .name = "SPV_KHR_fragment_shading_rate", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_fragment_shading_rate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 59, .name = "SPV_KHR_shader_atomic_counter_ops", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_shader_atomic_counter_ops", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 60, .name = "SPV_KHR_shader_draw_parameters", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_shader_draw_parameters", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 61, .name = "SPV_KHR_storage_buffer_storage_class", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_storage_buffer_storage_class", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 62, .name = "SPV_KHR_linkonce_odr", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_linkonce_odr", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 63, .name = "SPV_KHR_terminate_invocation", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_terminate_invocation", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 64, .name = "SPV_KHR_non_semantic_info", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_non_semantic_info", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 65, .name = "SPV_KHR_post_depth_coverage", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_post_depth_coverage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 66, .name = "SPV_KHR_expect_assume", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_expect_assume", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 67, .name = "SPV_KHR_ray_tracing", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_ray_tracing", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 68, .name = "SPV_KHR_ray_query", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_ray_query", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 69, .name = "SPV_KHR_float_controls", .llvm_name = null, .description = "SPIR-V extension SPV_KHR_float_controls", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 70, .name = "SPV_NV_viewport_array2", .llvm_name = null, .description = "SPIR-V extension SPV_NV_viewport_array2", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 71, .name = "SPV_NV_shader_subgroup_partitioned", .llvm_name = null, .description = "SPIR-V extension SPV_NV_shader_subgroup_partitioned", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 72, .name = "SPV_NVX_multiview_per_view_attributes", .llvm_name = null, .description = "SPIR-V extension SPV_NVX_multiview_per_view_attributes", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 73, .name = "SPV_NV_ray_tracing", .llvm_name = null, .description = "SPIR-V extension SPV_NV_ray_tracing", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 74, .name = "SPV_NV_shader_image_footprint", .llvm_name = null, .description = "SPIR-V extension SPV_NV_shader_image_footprint", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 75, .name = "SPV_NV_shading_rate", .llvm_name = null, .description = "SPIR-V extension SPV_NV_shading_rate", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 76, .name = "SPV_NV_stereo_view_rendering", .llvm_name = null, .description = "SPIR-V extension SPV_NV_stereo_view_rendering", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 77, .name = "SPV_NV_compute_shader_derivatives", .llvm_name = null, .description = "SPIR-V extension SPV_NV_compute_shader_derivatives", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 78, .name = "SPV_NV_shader_sm_builtins", .llvm_name = null, .description = "SPIR-V extension SPV_NV_shader_sm_builtins", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 79, .name = "SPV_NV_mesh_shader", .llvm_name = null, .description = "SPIR-V extension SPV_NV_mesh_shader", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 80, .name = "SPV_NV_geometry_shader_passthrough", .llvm_name = null, .description = "SPIR-V extension SPV_NV_geometry_shader_passthrough", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 81, .name = "SPV_NV_fragment_shader_barycentric", .llvm_name = null, .description = "SPIR-V extension SPV_NV_fragment_shader_barycentric", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 82, .name = "SPV_NV_cooperative_matrix", .llvm_name = null, .description = "SPIR-V extension SPV_NV_cooperative_matrix", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 83, .name = "SPV_NV_sample_mask_override_coverage", .llvm_name = null, .description = "SPIR-V extension SPV_NV_sample_mask_override_coverage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 84, .name = "Matrix", .llvm_name = null, .description = "Enable SPIR-V capability Matrix", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 85, .name = "Shader", .llvm_name = null, .description = "Enable SPIR-V capability Shader", .dependencies = .{ .ints = .{ 0, 1048576, 0, 0, 0 } } },
            .{ .index = 86, .name = "Geometry", .llvm_name = null, .description = "Enable SPIR-V capability Geometry", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 87, .name = "Tessellation", .llvm_name = null, .description = "Enable SPIR-V capability Tessellation", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 88, .name = "Addresses", .llvm_name = null, .description = "Enable SPIR-V capability Addresses", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 89, .name = "Linkage", .llvm_name = null, .description = "Enable SPIR-V capability Linkage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 90, .name = "Kernel", .llvm_name = null, .description = "Enable SPIR-V capability Kernel", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 91, .name = "Vector16", .llvm_name = null, .description = "Enable SPIR-V capability Vector16", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 92, .name = "Float16Buffer", .llvm_name = null, .description = "Enable SPIR-V capability Float16Buffer", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 93, .name = "Float16", .llvm_name = null, .description = "Enable SPIR-V capability Float16", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 94, .name = "Float64", .llvm_name = null, .description = "Enable SPIR-V capability Float64", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 95, .name = "Int64", .llvm_name = null, .description = "Enable SPIR-V capability Int64", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 96, .name = "Int64Atomics", .llvm_name = null, .description = "Enable SPIR-V capability Int64Atomics", .dependencies = .{ .ints = .{ 0, 2147483648, 0, 0, 0 } } },
            .{ .index = 97, .name = "ImageBasic", .llvm_name = null, .description = "Enable SPIR-V capability ImageBasic", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 98, .name = "ImageReadWrite", .llvm_name = null, .description = "Enable SPIR-V capability ImageReadWrite", .dependencies = .{ .ints = .{ 0, 8589934592, 0, 0, 0 } } },
            .{ .index = 99, .name = "ImageMipmap", .llvm_name = null, .description = "Enable SPIR-V capability ImageMipmap", .dependencies = .{ .ints = .{ 0, 8589934592, 0, 0, 0 } } },
            .{ .index = 100, .name = "Pipes", .llvm_name = null, .description = "Enable SPIR-V capability Pipes", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 101, .name = "Groups", .llvm_name = null, .description = "Enable SPIR-V capability Groups", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 102, .name = "DeviceEnqueue", .llvm_name = null, .description = "Enable SPIR-V capability DeviceEnqueue", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 103, .name = "LiteralSampler", .llvm_name = null, .description = "Enable SPIR-V capability LiteralSampler", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 104, .name = "AtomicStorage", .llvm_name = null, .description = "Enable SPIR-V capability AtomicStorage", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 105, .name = "Int16", .llvm_name = null, .description = "Enable SPIR-V capability Int16", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 106, .name = "TessellationPointSize", .llvm_name = null, .description = "Enable SPIR-V capability TessellationPointSize", .dependencies = .{ .ints = .{ 0, 8388608, 0, 0, 0 } } },
            .{ .index = 107, .name = "GeometryPointSize", .llvm_name = null, .description = "Enable SPIR-V capability GeometryPointSize", .dependencies = .{ .ints = .{ 0, 4194304, 0, 0, 0 } } },
            .{ .index = 108, .name = "ImageGatherExtended", .llvm_name = null, .description = "Enable SPIR-V capability ImageGatherExtended", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 109, .name = "StorageImageMultisample", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageMultisample", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 110, .name = "UniformBufferArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability UniformBufferArrayDynamicIndexing", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 111, .name = "SampledImageArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability SampledImageArrayDynamicIndexing", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 112, .name = "StorageBufferArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageBufferArrayDynamicIndexing", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 113, .name = "StorageImageArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageArrayDynamicIndexing", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 114, .name = "ClipDistance", .llvm_name = null, .description = "Enable SPIR-V capability ClipDistance", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 115, .name = "CullDistance", .llvm_name = null, .description = "Enable SPIR-V capability CullDistance", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 116, .name = "ImageCubeArray", .llvm_name = null, .description = "Enable SPIR-V capability ImageCubeArray", .dependencies = .{ .ints = .{ 0, 9223372036854775808, 0, 0, 0 } } },
            .{ .index = 117, .name = "SampleRateShading", .llvm_name = null, .description = "Enable SPIR-V capability SampleRateShading", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 118, .name = "ImageRect", .llvm_name = null, .description = "Enable SPIR-V capability ImageRect", .dependencies = .{ .ints = .{ 0, 36028797018963968, 0, 0, 0 } } },
            .{ .index = 119, .name = "SampledRect", .llvm_name = null, .description = "Enable SPIR-V capability SampledRect", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 120, .name = "GenericPointer", .llvm_name = null, .description = "Enable SPIR-V capability GenericPointer", .dependencies = .{ .ints = .{ 0, 16777216, 0, 0, 0 } } },
            .{ .index = 121, .name = "Int8", .llvm_name = null, .description = "Enable SPIR-V capability Int8", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 122, .name = "InputAttachment", .llvm_name = null, .description = "Enable SPIR-V capability InputAttachment", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 123, .name = "SparseResidency", .llvm_name = null, .description = "Enable SPIR-V capability SparseResidency", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 124, .name = "MinLod", .llvm_name = null, .description = "Enable SPIR-V capability MinLod", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 125, .name = "Sampled1D", .llvm_name = null, .description = "Enable SPIR-V capability Sampled1D", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 126, .name = "Image1D", .llvm_name = null, .description = "Enable SPIR-V capability Image1D", .dependencies = .{ .ints = .{ 0, 2305843009213693952, 0, 0, 0 } } },
            .{ .index = 127, .name = "SampledCubeArray", .llvm_name = null, .description = "Enable SPIR-V capability SampledCubeArray", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 128, .name = "SampledBuffer", .llvm_name = null, .description = "Enable SPIR-V capability SampledBuffer", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 129, .name = "ImageBuffer", .llvm_name = null, .description = "Enable SPIR-V capability ImageBuffer", .dependencies = .{ .ints = .{ 0, 0, 1, 0, 0 } } },
            .{ .index = 130, .name = "ImageMSArray", .llvm_name = null, .description = "Enable SPIR-V capability ImageMSArray", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 131, .name = "StorageImageExtendedFormats", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageExtendedFormats", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 132, .name = "ImageQuery", .llvm_name = null, .description = "Enable SPIR-V capability ImageQuery", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 133, .name = "DerivativeControl", .llvm_name = null, .description = "Enable SPIR-V capability DerivativeControl", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 134, .name = "InterpolationFunction", .llvm_name = null, .description = "Enable SPIR-V capability InterpolationFunction", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 135, .name = "TransformFeedback", .llvm_name = null, .description = "Enable SPIR-V capability TransformFeedback", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 136, .name = "GeometryStreams", .llvm_name = null, .description = "Enable SPIR-V capability GeometryStreams", .dependencies = .{ .ints = .{ 0, 4194304, 0, 0, 0 } } },
            .{ .index = 137, .name = "StorageImageReadWithoutFormat", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageReadWithoutFormat", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 138, .name = "StorageImageWriteWithoutFormat", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageWriteWithoutFormat", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 139, .name = "MultiViewport", .llvm_name = null, .description = "Enable SPIR-V capability MultiViewport", .dependencies = .{ .ints = .{ 0, 4194304, 0, 0, 0 } } },
            .{ .index = 140, .name = "SubgroupDispatch", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupDispatch", .dependencies = .{ .ints = .{ 1, 274877906944, 0, 0, 0 } } },
            .{ .index = 141, .name = "NamedBarrier", .llvm_name = null, .description = "Enable SPIR-V capability NamedBarrier", .dependencies = .{ .ints = .{ 1, 67108864, 0, 0, 0 } } },
            .{ .index = 142, .name = "PipeStorage", .llvm_name = null, .description = "Enable SPIR-V capability PipeStorage", .dependencies = .{ .ints = .{ 1, 68719476736, 0, 0, 0 } } },
            .{ .index = 143, .name = "GroupNonUniform", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniform", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 144, .name = "GroupNonUniformVote", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformVote", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 145, .name = "GroupNonUniformArithmetic", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformArithmetic", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 146, .name = "GroupNonUniformBallot", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformBallot", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 147, .name = "GroupNonUniformShuffle", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformShuffle", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 148, .name = "GroupNonUniformShuffleRelative", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformShuffleRelative", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 149, .name = "GroupNonUniformClustered", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformClustered", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 150, .name = "GroupNonUniformQuad", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformQuad", .dependencies = .{ .ints = .{ 4, 0, 32768, 0, 0 } } },
            .{ .index = 151, .name = "ShaderLayer", .llvm_name = null, .description = "Enable SPIR-V capability ShaderLayer", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 152, .name = "ShaderViewportIndex", .llvm_name = null, .description = "Enable SPIR-V capability ShaderViewportIndex", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 153, .name = "FragmentShadingRateKHR", .llvm_name = null, .description = "Enable SPIR-V capability FragmentShadingRateKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 154, .name = "SubgroupBallotKHR", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupBallotKHR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 155, .name = "DrawParameters", .llvm_name = null, .description = "Enable SPIR-V capability DrawParameters", .dependencies = .{ .ints = .{ 4, 2097152, 0, 0, 0 } } },
            .{ .index = 156, .name = "WorkgroupMemoryExplicitLayoutKHR", .llvm_name = null, .description = "Enable SPIR-V capability WorkgroupMemoryExplicitLayoutKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 157, .name = "WorkgroupMemoryExplicitLayout8BitAccessKHR", .llvm_name = null, .description = "Enable SPIR-V capability WorkgroupMemoryExplicitLayout8BitAccessKHR", .dependencies = .{ .ints = .{ 0, 0, 268435456, 0, 0 } } },
            .{ .index = 158, .name = "WorkgroupMemoryExplicitLayout16BitAccessKHR", .llvm_name = null, .description = "Enable SPIR-V capability WorkgroupMemoryExplicitLayout16BitAccessKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 159, .name = "SubgroupVoteKHR", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupVoteKHR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 160, .name = "StorageBuffer16BitAccess", .llvm_name = null, .description = "Enable SPIR-V capability StorageBuffer16BitAccess", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 161, .name = "StorageUniformBufferBlock16", .llvm_name = null, .description = "Enable SPIR-V capability StorageUniformBufferBlock16", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 162, .name = "UniformAndStorageBuffer16BitAccess", .llvm_name = null, .description = "Enable SPIR-V capability UniformAndStorageBuffer16BitAccess", .dependencies = .{ .ints = .{ 4, 0, 12884901888, 0, 0 } } },
            .{ .index = 163, .name = "StorageUniform16", .llvm_name = null, .description = "Enable SPIR-V capability StorageUniform16", .dependencies = .{ .ints = .{ 4, 0, 12884901888, 0, 0 } } },
            .{ .index = 164, .name = "StoragePushConstant16", .llvm_name = null, .description = "Enable SPIR-V capability StoragePushConstant16", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 165, .name = "StorageInputOutput16", .llvm_name = null, .description = "Enable SPIR-V capability StorageInputOutput16", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 166, .name = "DeviceGroup", .llvm_name = null, .description = "Enable SPIR-V capability DeviceGroup", .dependencies = .{ .ints = .{ 4, 0, 0, 0, 0 } } },
            .{ .index = 167, .name = "MultiView", .llvm_name = null, .description = "Enable SPIR-V capability MultiView", .dependencies = .{ .ints = .{ 4, 2097152, 0, 0, 0 } } },
            .{ .index = 168, .name = "VariablePointersStorageBuffer", .llvm_name = null, .description = "Enable SPIR-V capability VariablePointersStorageBuffer", .dependencies = .{ .ints = .{ 4, 2097152, 0, 0, 0 } } },
            .{ .index = 169, .name = "VariablePointers", .llvm_name = null, .description = "Enable SPIR-V capability VariablePointers", .dependencies = .{ .ints = .{ 4, 0, 1099511627776, 0, 0 } } },
            .{ .index = 170, .name = "AtomicStorageOps", .llvm_name = null, .description = "Enable SPIR-V capability AtomicStorageOps", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 171, .name = "SampleMaskPostDepthCoverage", .llvm_name = null, .description = "Enable SPIR-V capability SampleMaskPostDepthCoverage", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 172, .name = "StorageBuffer8BitAccess", .llvm_name = null, .description = "Enable SPIR-V capability StorageBuffer8BitAccess", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 173, .name = "UniformAndStorageBuffer8BitAccess", .llvm_name = null, .description = "Enable SPIR-V capability UniformAndStorageBuffer8BitAccess", .dependencies = .{ .ints = .{ 16, 0, 17592186044416, 0, 0 } } },
            .{ .index = 174, .name = "StoragePushConstant8", .llvm_name = null, .description = "Enable SPIR-V capability StoragePushConstant8", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 175, .name = "DenormPreserve", .llvm_name = null, .description = "Enable SPIR-V capability DenormPreserve", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 176, .name = "DenormFlushToZero", .llvm_name = null, .description = "Enable SPIR-V capability DenormFlushToZero", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 177, .name = "SignedZeroInfNanPreserve", .llvm_name = null, .description = "Enable SPIR-V capability SignedZeroInfNanPreserve", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 178, .name = "RoundingModeRTE", .llvm_name = null, .description = "Enable SPIR-V capability RoundingModeRTE", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 179, .name = "RoundingModeRTZ", .llvm_name = null, .description = "Enable SPIR-V capability RoundingModeRTZ", .dependencies = .{ .ints = .{ 8, 0, 0, 0, 0 } } },
            .{ .index = 180, .name = "RayQueryProvisionalKHR", .llvm_name = null, .description = "Enable SPIR-V capability RayQueryProvisionalKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 181, .name = "RayQueryKHR", .llvm_name = null, .description = "Enable SPIR-V capability RayQueryKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 182, .name = "RayTraversalPrimitiveCullingKHR", .llvm_name = null, .description = "Enable SPIR-V capability RayTraversalPrimitiveCullingKHR", .dependencies = .{ .ints = .{ 0, 0, 45035996273704960, 0, 0 } } },
            .{ .index = 183, .name = "RayTracingKHR", .llvm_name = null, .description = "Enable SPIR-V capability RayTracingKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 184, .name = "Float16ImageAMD", .llvm_name = null, .description = "Enable SPIR-V capability Float16ImageAMD", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 185, .name = "ImageGatherBiasLodAMD", .llvm_name = null, .description = "Enable SPIR-V capability ImageGatherBiasLodAMD", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 186, .name = "FragmentMaskAMD", .llvm_name = null, .description = "Enable SPIR-V capability FragmentMaskAMD", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 187, .name = "StencilExportEXT", .llvm_name = null, .description = "Enable SPIR-V capability StencilExportEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 188, .name = "ImageReadWriteLodAMD", .llvm_name = null, .description = "Enable SPIR-V capability ImageReadWriteLodAMD", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 189, .name = "Int64ImageEXT", .llvm_name = null, .description = "Enable SPIR-V capability Int64ImageEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 190, .name = "ShaderClockKHR", .llvm_name = null, .description = "Enable SPIR-V capability ShaderClockKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 191, .name = "SampleMaskOverrideCoverageNV", .llvm_name = null, .description = "Enable SPIR-V capability SampleMaskOverrideCoverageNV", .dependencies = .{ .ints = .{ 0, 9007199254740992, 0, 0, 0 } } },
            .{ .index = 192, .name = "GeometryShaderPassthroughNV", .llvm_name = null, .description = "Enable SPIR-V capability GeometryShaderPassthroughNV", .dependencies = .{ .ints = .{ 0, 4194304, 0, 0, 0 } } },
            .{ .index = 193, .name = "ShaderViewportIndexLayerEXT", .llvm_name = null, .description = "Enable SPIR-V capability ShaderViewportIndexLayerEXT", .dependencies = .{ .ints = .{ 0, 0, 2048, 0, 0 } } },
            .{ .index = 194, .name = "ShaderViewportIndexLayerNV", .llvm_name = null, .description = "Enable SPIR-V capability ShaderViewportIndexLayerNV", .dependencies = .{ .ints = .{ 0, 0, 2048, 0, 0 } } },
            .{ .index = 195, .name = "ShaderViewportMaskNV", .llvm_name = null, .description = "Enable SPIR-V capability ShaderViewportMaskNV", .dependencies = .{ .ints = .{ 0, 0, 0, 4, 0 } } },
            .{ .index = 196, .name = "ShaderStereoViewNV", .llvm_name = null, .description = "Enable SPIR-V capability ShaderStereoViewNV", .dependencies = .{ .ints = .{ 0, 0, 0, 8, 0 } } },
            .{ .index = 197, .name = "PerViewAttributesNV", .llvm_name = null, .description = "Enable SPIR-V capability PerViewAttributesNV", .dependencies = .{ .ints = .{ 0, 0, 549755813888, 0, 0 } } },
            .{ .index = 198, .name = "FragmentFullyCoveredEXT", .llvm_name = null, .description = "Enable SPIR-V capability FragmentFullyCoveredEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 199, .name = "MeshShadingNV", .llvm_name = null, .description = "Enable SPIR-V capability MeshShadingNV", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 200, .name = "ImageFootprintNV", .llvm_name = null, .description = "Enable SPIR-V capability ImageFootprintNV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 201, .name = "FragmentBarycentricNV", .llvm_name = null, .description = "Enable SPIR-V capability FragmentBarycentricNV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 202, .name = "ComputeDerivativeGroupQuadsNV", .llvm_name = null, .description = "Enable SPIR-V capability ComputeDerivativeGroupQuadsNV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 203, .name = "FragmentDensityEXT", .llvm_name = null, .description = "Enable SPIR-V capability FragmentDensityEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 204, .name = "ShadingRateNV", .llvm_name = null, .description = "Enable SPIR-V capability ShadingRateNV", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 205, .name = "GroupNonUniformPartitionedNV", .llvm_name = null, .description = "Enable SPIR-V capability GroupNonUniformPartitionedNV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 206, .name = "ShaderNonUniform", .llvm_name = null, .description = "Enable SPIR-V capability ShaderNonUniform", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 207, .name = "ShaderNonUniformEXT", .llvm_name = null, .description = "Enable SPIR-V capability ShaderNonUniformEXT", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 208, .name = "RuntimeDescriptorArray", .llvm_name = null, .description = "Enable SPIR-V capability RuntimeDescriptorArray", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 209, .name = "RuntimeDescriptorArrayEXT", .llvm_name = null, .description = "Enable SPIR-V capability RuntimeDescriptorArrayEXT", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 210, .name = "InputAttachmentArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability InputAttachmentArrayDynamicIndexing", .dependencies = .{ .ints = .{ 16, 288230376151711744, 0, 0, 0 } } },
            .{ .index = 211, .name = "InputAttachmentArrayDynamicIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability InputAttachmentArrayDynamicIndexingEXT", .dependencies = .{ .ints = .{ 16, 288230376151711744, 0, 0, 0 } } },
            .{ .index = 212, .name = "UniformTexelBufferArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability UniformTexelBufferArrayDynamicIndexing", .dependencies = .{ .ints = .{ 16, 0, 1, 0, 0 } } },
            .{ .index = 213, .name = "UniformTexelBufferArrayDynamicIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability UniformTexelBufferArrayDynamicIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 1, 0, 0 } } },
            .{ .index = 214, .name = "StorageTexelBufferArrayDynamicIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageTexelBufferArrayDynamicIndexing", .dependencies = .{ .ints = .{ 16, 0, 2, 0, 0 } } },
            .{ .index = 215, .name = "StorageTexelBufferArrayDynamicIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability StorageTexelBufferArrayDynamicIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 2, 0, 0 } } },
            .{ .index = 216, .name = "UniformBufferArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability UniformBufferArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 217, .name = "UniformBufferArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability UniformBufferArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 218, .name = "SampledImageArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability SampledImageArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 219, .name = "SampledImageArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability SampledImageArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 220, .name = "StorageBufferArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageBufferArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 221, .name = "StorageBufferArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability StorageBufferArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 222, .name = "StorageImageArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 223, .name = "StorageImageArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability StorageImageArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 0, 16384, 0 } } },
            .{ .index = 224, .name = "InputAttachmentArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability InputAttachmentArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 288230376151711744, 0, 16384, 0 } } },
            .{ .index = 225, .name = "InputAttachmentArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability InputAttachmentArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 288230376151711744, 0, 16384, 0 } } },
            .{ .index = 226, .name = "UniformTexelBufferArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability UniformTexelBufferArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 1, 16384, 0 } } },
            .{ .index = 227, .name = "UniformTexelBufferArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability UniformTexelBufferArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 1, 16384, 0 } } },
            .{ .index = 228, .name = "StorageTexelBufferArrayNonUniformIndexing", .llvm_name = null, .description = "Enable SPIR-V capability StorageTexelBufferArrayNonUniformIndexing", .dependencies = .{ .ints = .{ 16, 0, 2, 16384, 0 } } },
            .{ .index = 229, .name = "StorageTexelBufferArrayNonUniformIndexingEXT", .llvm_name = null, .description = "Enable SPIR-V capability StorageTexelBufferArrayNonUniformIndexingEXT", .dependencies = .{ .ints = .{ 16, 0, 2, 16384, 0 } } },
            .{ .index = 230, .name = "RayTracingNV", .llvm_name = null, .description = "Enable SPIR-V capability RayTracingNV", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 231, .name = "VulkanMemoryModel", .llvm_name = null, .description = "Enable SPIR-V capability VulkanMemoryModel", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 232, .name = "VulkanMemoryModelKHR", .llvm_name = null, .description = "Enable SPIR-V capability VulkanMemoryModelKHR", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 233, .name = "VulkanMemoryModelDeviceScope", .llvm_name = null, .description = "Enable SPIR-V capability VulkanMemoryModelDeviceScope", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 234, .name = "VulkanMemoryModelDeviceScopeKHR", .llvm_name = null, .description = "Enable SPIR-V capability VulkanMemoryModelDeviceScopeKHR", .dependencies = .{ .ints = .{ 16, 0, 0, 0, 0 } } },
            .{ .index = 235, .name = "PhysicalStorageBufferAddresses", .llvm_name = null, .description = "Enable SPIR-V capability PhysicalStorageBufferAddresses", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 236, .name = "PhysicalStorageBufferAddressesEXT", .llvm_name = null, .description = "Enable SPIR-V capability PhysicalStorageBufferAddressesEXT", .dependencies = .{ .ints = .{ 16, 2097152, 0, 0, 0 } } },
            .{ .index = 237, .name = "ComputeDerivativeGroupLinearNV", .llvm_name = null, .description = "Enable SPIR-V capability ComputeDerivativeGroupLinearNV", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 238, .name = "RayTracingProvisionalKHR", .llvm_name = null, .description = "Enable SPIR-V capability RayTracingProvisionalKHR", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 239, .name = "CooperativeMatrixNV", .llvm_name = null, .description = "Enable SPIR-V capability CooperativeMatrixNV", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 240, .name = "FragmentShaderSampleInterlockEXT", .llvm_name = null, .description = "Enable SPIR-V capability FragmentShaderSampleInterlockEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 241, .name = "FragmentShaderShadingRateInterlockEXT", .llvm_name = null, .description = "Enable SPIR-V capability FragmentShaderShadingRateInterlockEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 242, .name = "ShaderSMBuiltinsNV", .llvm_name = null, .description = "Enable SPIR-V capability ShaderSMBuiltinsNV", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 243, .name = "FragmentShaderPixelInterlockEXT", .llvm_name = null, .description = "Enable SPIR-V capability FragmentShaderPixelInterlockEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 244, .name = "DemoteToHelperInvocationEXT", .llvm_name = null, .description = "Enable SPIR-V capability DemoteToHelperInvocationEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 245, .name = "SubgroupShuffleINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupShuffleINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 246, .name = "SubgroupBufferBlockIOINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupBufferBlockIOINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 247, .name = "SubgroupImageBlockIOINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupImageBlockIOINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 248, .name = "SubgroupImageMediaBlockIOINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupImageMediaBlockIOINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 249, .name = "RoundToInfinityINTEL", .llvm_name = null, .description = "Enable SPIR-V capability RoundToInfinityINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 250, .name = "FloatingPointModeINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FloatingPointModeINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 251, .name = "IntegerFunctions2INTEL", .llvm_name = null, .description = "Enable SPIR-V capability IntegerFunctions2INTEL", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 252, .name = "FunctionPointersINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FunctionPointersINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 253, .name = "IndirectReferencesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability IndirectReferencesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 254, .name = "AsmINTEL", .llvm_name = null, .description = "Enable SPIR-V capability AsmINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 255, .name = "AtomicFloat32MinMaxEXT", .llvm_name = null, .description = "Enable SPIR-V capability AtomicFloat32MinMaxEXT", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 256, .name = "AtomicFloat64MinMaxEXT", .llvm_name = null, .description = "Enable SPIR-V capability AtomicFloat64MinMaxEXT", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 257, .name = "AtomicFloat16MinMaxEXT", .llvm_name = null, .description = "Enable SPIR-V capability AtomicFloat16MinMaxEXT", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 258, .name = "VectorComputeINTEL", .llvm_name = null, .description = "Enable SPIR-V capability VectorComputeINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 8 } } },
            .{ .index = 259, .name = "VectorAnyINTEL", .llvm_name = null, .description = "Enable SPIR-V capability VectorAnyINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 260, .name = "ExpectAssumeKHR", .llvm_name = null, .description = "Enable SPIR-V capability ExpectAssumeKHR", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 261, .name = "SubgroupAvcMotionEstimationINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupAvcMotionEstimationINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 262, .name = "SubgroupAvcMotionEstimationIntraINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupAvcMotionEstimationIntraINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 263, .name = "SubgroupAvcMotionEstimationChromaINTEL", .llvm_name = null, .description = "Enable SPIR-V capability SubgroupAvcMotionEstimationChromaINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 264, .name = "VariableLengthArrayINTEL", .llvm_name = null, .description = "Enable SPIR-V capability VariableLengthArrayINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 265, .name = "FunctionFloatControlINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FunctionFloatControlINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 266, .name = "FPGAMemoryAttributesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGAMemoryAttributesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 267, .name = "FPFastMathModeINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPFastMathModeINTEL", .dependencies = .{ .ints = .{ 0, 67108864, 0, 0, 0 } } },
            .{ .index = 268, .name = "ArbitraryPrecisionIntegersINTEL", .llvm_name = null, .description = "Enable SPIR-V capability ArbitraryPrecisionIntegersINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 269, .name = "UnstructuredLoopControlsINTEL", .llvm_name = null, .description = "Enable SPIR-V capability UnstructuredLoopControlsINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 270, .name = "FPGALoopControlsINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGALoopControlsINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 271, .name = "KernelAttributesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability KernelAttributesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 272, .name = "FPGAKernelAttributesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGAKernelAttributesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 273, .name = "FPGAMemoryAccessesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGAMemoryAccessesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 274, .name = "FPGAClusterAttributesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGAClusterAttributesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 275, .name = "LoopFuseINTEL", .llvm_name = null, .description = "Enable SPIR-V capability LoopFuseINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 276, .name = "FPGABufferLocationINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGABufferLocationINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 277, .name = "USMStorageClassesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability USMStorageClassesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 278, .name = "IOPipesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability IOPipesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 279, .name = "BlockingPipesINTEL", .llvm_name = null, .description = "Enable SPIR-V capability BlockingPipesINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 280, .name = "FPGARegINTEL", .llvm_name = null, .description = "Enable SPIR-V capability FPGARegINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 281, .name = "AtomicFloat32AddEXT", .llvm_name = null, .description = "Enable SPIR-V capability AtomicFloat32AddEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 282, .name = "AtomicFloat64AddEXT", .llvm_name = null, .description = "Enable SPIR-V capability AtomicFloat64AddEXT", .dependencies = .{ .ints = .{ 0, 2097152, 0, 0, 0 } } },
            .{ .index = 283, .name = "LongConstantCompositeINTEL", .llvm_name = null, .description = "Enable SPIR-V capability LongConstantCompositeINTEL", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
    pub const s390x = struct {
        pub const Feature = enum(u6) {
            bear_enhancement = 0,
            deflate_conversion = 1,
            dfp_packed_conversion = 2,
            dfp_zoned_conversion = 3,
            distinct_ops = 4,
            enhanced_dat_2 = 5,
            enhanced_sort = 6,
            execution_hint = 7,
            fast_serialization = 8,
            fp_extension = 9,
            guarded_storage = 10,
            high_word = 11,
            insert_reference_bits_multiple = 12,
            interlocked_access1 = 13,
            load_and_trap = 14,
            load_and_zero_rightmost_byte = 15,
            load_store_on_cond = 16,
            load_store_on_cond_2 = 17,
            message_security_assist_extension3 = 18,
            message_security_assist_extension4 = 19,
            message_security_assist_extension5 = 20,
            message_security_assist_extension7 = 21,
            message_security_assist_extension8 = 22,
            message_security_assist_extension9 = 23,
            miscellaneous_extensions = 24,
            miscellaneous_extensions_2 = 25,
            miscellaneous_extensions_3 = 26,
            nnp_assist = 27,
            population_count = 28,
            processor_activity_instrumentation = 29,
            processor_assist = 30,
            reset_dat_protection = 31,
            reset_reference_bits_multiple = 32,
            soft_float = 33,
            transactional_execution = 34,
            vector = 35,
            vector_enhancements_1 = 36,
            vector_enhancements_2 = 37,
            vector_packed_decimal = 38,
            vector_packed_decimal_enhancement = 39,
            vector_packed_decimal_enhancement_2 = 40,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "bear_enhancement", .llvm_name = "bear-enhancement", .description = "Assume that the BEAR-enhancement facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "deflate_conversion", .llvm_name = "deflate-conversion", .description = "Assume that the deflate-conversion facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "dfp_packed_conversion", .llvm_name = "dfp-packed-conversion", .description = "Assume that the DFP packed-conversion facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "dfp_zoned_conversion", .llvm_name = "dfp-zoned-conversion", .description = "Assume that the DFP zoned-conversion facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "distinct_ops", .llvm_name = "distinct-ops", .description = "Assume that the distinct-operands facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "enhanced_dat_2", .llvm_name = "enhanced-dat-2", .description = "Assume that the enhanced-DAT facility 2 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "enhanced_sort", .llvm_name = "enhanced-sort", .description = "Assume that the enhanced-sort facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "execution_hint", .llvm_name = "execution-hint", .description = "Assume that the execution-hint facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "fast_serialization", .llvm_name = "fast-serialization", .description = "Assume that the fast-serialization facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "fp_extension", .llvm_name = "fp-extension", .description = "Assume that the floating-point extension facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "guarded_storage", .llvm_name = "guarded-storage", .description = "Assume that the guarded-storage facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "high_word", .llvm_name = "high-word", .description = "Assume that the high-word facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 12, .name = "insert_reference_bits_multiple", .llvm_name = "insert-reference-bits-multiple", .description = "Assume that the insert-reference-bits-multiple facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 13, .name = "interlocked_access1", .llvm_name = "interlocked-access1", .description = "Assume that interlocked-access facility 1 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 14, .name = "load_and_trap", .llvm_name = "load-and-trap", .description = "Assume that the load-and-trap facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 15, .name = "load_and_zero_rightmost_byte", .llvm_name = "load-and-zero-rightmost-byte", .description = "Assume that the load-and-zero-rightmost-byte facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 16, .name = "load_store_on_cond", .llvm_name = "load-store-on-cond", .description = "Assume that the load/store-on-condition facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 17, .name = "load_store_on_cond_2", .llvm_name = "load-store-on-cond-2", .description = "Assume that the load/store-on-condition facility 2 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 18, .name = "message_security_assist_extension3", .llvm_name = "message-security-assist-extension3", .description = "Assume that the message-security-assist extension facility 3 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 19, .name = "message_security_assist_extension4", .llvm_name = "message-security-assist-extension4", .description = "Assume that the message-security-assist extension facility 4 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 20, .name = "message_security_assist_extension5", .llvm_name = "message-security-assist-extension5", .description = "Assume that the message-security-assist extension facility 5 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 21, .name = "message_security_assist_extension7", .llvm_name = "message-security-assist-extension7", .description = "Assume that the message-security-assist extension facility 7 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 22, .name = "message_security_assist_extension8", .llvm_name = "message-security-assist-extension8", .description = "Assume that the message-security-assist extension facility 8 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 23, .name = "message_security_assist_extension9", .llvm_name = "message-security-assist-extension9", .description = "Assume that the message-security-assist extension facility 9 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 24, .name = "miscellaneous_extensions", .llvm_name = "miscellaneous-extensions", .description = "Assume that the miscellaneous-extensions facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 25, .name = "miscellaneous_extensions_2", .llvm_name = "miscellaneous-extensions-2", .description = "Assume that the miscellaneous-extensions facility 2 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 26, .name = "miscellaneous_extensions_3", .llvm_name = "miscellaneous-extensions-3", .description = "Assume that the miscellaneous-extensions facility 3 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 27, .name = "nnp_assist", .llvm_name = "nnp-assist", .description = "Assume that the NNP-assist facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 28, .name = "population_count", .llvm_name = "population-count", .description = "Assume that the population-count facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 29, .name = "processor_activity_instrumentation", .llvm_name = "processor-activity-instrumentation", .description = "Assume that the processor-activity-instrumentation facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 30, .name = "processor_assist", .llvm_name = "processor-assist", .description = "Assume that the processor-assist facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 31, .name = "reset_dat_protection", .llvm_name = "reset-dat-protection", .description = "Assume that the reset-DAT-protection facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 32, .name = "reset_reference_bits_multiple", .llvm_name = "reset-reference-bits-multiple", .description = "Assume that the reset-reference-bits-multiple facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 33, .name = "soft_float", .llvm_name = "soft-float", .description = "Use software emulation for floating point", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 34, .name = "transactional_execution", .llvm_name = "transactional-execution", .description = "Assume that the transactional-execution facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 35, .name = "vector", .llvm_name = "vector", .description = "Assume that the vectory facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 36, .name = "vector_enhancements_1", .llvm_name = "vector-enhancements-1", .description = "Assume that the vector enhancements facility 1 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 37, .name = "vector_enhancements_2", .llvm_name = "vector-enhancements-2", .description = "Assume that the vector enhancements facility 2 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 38, .name = "vector_packed_decimal", .llvm_name = "vector-packed-decimal", .description = "Assume that the vector packed decimal facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 39, .name = "vector_packed_decimal_enhancement", .llvm_name = "vector-packed-decimal-enhancement", .description = "Assume that the vector packed decimal enhancement facility is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 40, .name = "vector_packed_decimal_enhancement_2", .llvm_name = "vector-packed-decimal-enhancement-2", .description = "Assume that the vector packed decimal enhancement facility 2 is installed", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const arch10: Cpu = .{ .name = "arch10", .llvm_name = "arch10", .features = .{ .ints = .{ 22834670520, 0, 0, 0, 0 } } };
            const arch11: Cpu = .{ .name = "arch11", .llvm_name = "arch11", .features = .{ .ints = .{ 57195621308, 0, 0, 0, 0 } } };
            const arch12: Cpu = .{ .name = "arch12", .llvm_name = "arch12", .features = .{ .ints = .{ 400832855996, 0, 0, 0, 0 } } };
            const arch13: Cpu = .{ .name = "arch13", .llvm_name = "arch13", .features = .{ .ints = .{ 1088103120894, 0, 0, 0, 0 } } };
            const arch14: Cpu = .{ .name = "arch14", .llvm_name = "arch14", .features = .{ .ints = .{ 2190433320959, 0, 0, 0, 0 } } };
            const arch8: Cpu = .{ .name = "arch8", .llvm_name = "arch8", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const arch9: Cpu = .{ .name = "arch9", .llvm_name = "arch9", .features = .{ .ints = .{ 4564265744, 0, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const z10: Cpu = .{ .name = "z10", .llvm_name = "z10", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
            const z13: Cpu = .{ .name = "z13", .llvm_name = "z13", .features = .{ .ints = .{ 57195621308, 0, 0, 0, 0 } } };
            const z14: Cpu = .{ .name = "z14", .llvm_name = "z14", .features = .{ .ints = .{ 400832855996, 0, 0, 0, 0 } } };
            const z15: Cpu = .{ .name = "z15", .llvm_name = "z15", .features = .{ .ints = .{ 1088103120894, 0, 0, 0, 0 } } };
            const z16: Cpu = .{ .name = "z16", .llvm_name = "z16", .features = .{ .ints = .{ 2190433320959, 0, 0, 0, 0 } } };
            const z196: Cpu = .{ .name = "z196", .llvm_name = "z196", .features = .{ .ints = .{ 4564265744, 0, 0, 0, 0 } } };
            const zEC12: Cpu = .{ .name = "zEC12", .llvm_name = "zEC12", .features = .{ .ints = .{ 22834670520, 0, 0, 0, 0 } } };
        };
    };
    pub const ve = struct {
        pub const Feature = enum(u0) {
            vpu = 0,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "vpu", .llvm_name = "vpu", .description = "Enable the VPU", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
    pub const wasm = struct {
        pub const Feature = enum(u4) {
            atomics = 0,
            bulk_memory = 1,
            exception_handling = 2,
            extended_const = 3,
            multivalue = 4,
            mutable_globals = 5,
            nontrapping_fptoint = 6,
            reference_types = 7,
            relaxed_simd = 8,
            sign_ext = 9,
            simd128 = 10,
            tail_call = 11,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "atomics", .llvm_name = "atomics", .description = "Enable Atomics", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 1, .name = "bulk_memory", .llvm_name = "bulk-memory", .description = "Enable bulk memory operations", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 2, .name = "exception_handling", .llvm_name = "exception-handling", .description = "Enable Wasm exception handling", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 3, .name = "extended_const", .llvm_name = "extended-const", .description = "Enable extended const expressions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 4, .name = "multivalue", .llvm_name = "multivalue", .description = "Enable multivalue blocks, instructions, and functions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 5, .name = "mutable_globals", .llvm_name = "mutable-globals", .description = "Enable mutable globals", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 6, .name = "nontrapping_fptoint", .llvm_name = "nontrapping-fptoint", .description = "Enable non-trapping float-to-int conversion operators", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 7, .name = "reference_types", .llvm_name = "reference-types", .description = "Enable reference types", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 8, .name = "relaxed_simd", .llvm_name = "relaxed-simd", .description = "Enable relaxed-simd instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 9, .name = "sign_ext", .llvm_name = "sign-ext", .description = "Enable sign extension operators", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 10, .name = "simd128", .llvm_name = "simd128", .description = "Enable 128-bit SIMD", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
            .{ .index = 11, .name = "tail_call", .llvm_name = "tail-call", .description = "Enable tail call instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const bleeding_edge: Cpu = .{ .name = "bleeding_edge", .llvm_name = "bleeding-edge", .features = .{ .ints = .{ 3683, 0, 0, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 544, 0, 0, 0, 0 } } };
            const mvp: Cpu = .{ .name = "mvp", .llvm_name = "mvp", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
    pub const x86 = struct {
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
        pub const all_features: []const Cpu.Feature = &.{
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
            const alderlake: Cpu = .{ .name = "alderlake", .llvm_name = "alderlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
            const amdfam10: Cpu = .{ .name = "amdfam10", .llvm_name = "amdfam10", .features = .{ .ints = .{ 19791209299992, 108095328917391362, 285220872, 0, 0 } } };
            const athlon: Cpu = .{ .name = "athlon", .llvm_name = "athlon", .features = .{ .ints = .{ 37383395344392, 4294967296, 285212712, 0, 0 } } };
            const athlon64: Cpu = .{ .name = "athlon64", .llvm_name = "athlon64", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
            const athlon64_sse3: Cpu = .{ .name = "athlon64_sse3", .llvm_name = "athlon64-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
            const athlon_4: Cpu = .{ .name = "athlon_4", .llvm_name = "athlon-4", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
            const athlon_fx: Cpu = .{ .name = "athlon_fx", .llvm_name = "athlon-fx", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
            const athlon_mp: Cpu = .{ .name = "athlon_mp", .llvm_name = "athlon-mp", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
            const athlon_tbird: Cpu = .{ .name = "athlon_tbird", .llvm_name = "athlon-tbird", .features = .{ .ints = .{ 37383395344392, 4294967296, 285212712, 0, 0 } } };
            const athlon_xp: Cpu = .{ .name = "athlon_xp", .llvm_name = "athlon-xp", .features = .{ .ints = .{ 37383395344392, 4294969344, 285212968, 0, 0 } } };
            const atom: Cpu = .{ .name = "atom", .llvm_name = "atom", .features = .{ .ints = .{ 19791209299984, 36028810309863424, 285245488, 0, 0 } } };
            const barcelona: Cpu = .{ .name = "barcelona", .llvm_name = "barcelona", .features = .{ .ints = .{ 19791209299992, 108095328917391362, 285220872, 0, 0 } } };
            const bdver1: Cpu = .{ .name = "bdver1", .llvm_name = "bdver1", .features = .{ .ints = .{ 72086250059726928, 108095346248255490, 1895825416, 0, 0 } } };
            const bdver2: Cpu = .{ .name = "bdver2", .llvm_name = "bdver2", .features = .{ .ints = .{ 9872200531374506064, 108095346248255618, 1895956488, 0, 0 } } };
            const bdver3: Cpu = .{ .name = "bdver3", .llvm_name = "bdver3", .features = .{ .ints = .{ 9872200531374506064, 108095346248256130, 5117181960, 0, 0 } } };
            const bdver4: Cpu = .{ .name = "bdver4", .llvm_name = "bdver4", .features = .{ .ints = .{ 9872200565734252624, 108376823640885890, 5117181960, 0, 0 } } };
            const bonnell: Cpu = .{ .name = "bonnell", .llvm_name = "bonnell", .features = .{ .ints = .{ 19791209299984, 36028810309863424, 285245488, 0, 0 } } };
            const broadwell: Cpu = .{ .name = "broadwell", .llvm_name = "broadwell", .features = .{ .ints = .{ 163706337799184560, 4648568195887008413, 4580179968, 0, 0 } } };
            const btver1: Cpu = .{ .name = "btver1", .llvm_name = "btver1", .features = .{ .ints = .{ 144134979285155856, 108095329051609154, 285253640, 0, 0 } } };
            const btver2: Cpu = .{ .name = "btver2", .llvm_name = "btver2", .features = .{ .ints = .{ 16861787084334039120, 108095346499913794, 4563410952, 0, 0 } } };
            const c3: Cpu = .{ .name = "c3", .llvm_name = "c3", .features = .{ .ints = .{ 4, 0, 285212704, 0, 0 } } };
            const c3_2: Cpu = .{ .name = "c3_2", .llvm_name = "c3-2", .features = .{ .ints = .{ 37383395344384, 134219776, 285212960, 0, 0 } } };
            const cannonlake: Cpu = .{ .name = "cannonlake", .llvm_name = "cannonlake", .features = .{ .ints = .{ 1297206343979368688, 5801490318969145917, 15317598208, 0, 0 } } };
            const cascadelake: Cpu = .{ .name = "cascadelake", .llvm_name = "cascadelake", .features = .{ .ints = .{ 1315221292357976304, 4648568814362298941, 15317598208, 0, 0 } } };
            const cooperlake: Cpu = .{ .name = "cooperlake", .llvm_name = "cooperlake", .features = .{ .ints = .{ 1315221292357927152, 4648568814362298941, 15317598208, 0, 0 } } };
            const core2: Cpu = .{ .name = "core2", .llvm_name = "core2", .features = .{ .ints = .{ 19791209299984, 36028801515259904, 285245472, 0, 0 } } };
            const core_avx2: Cpu = .{ .name = "core_avx2", .llvm_name = "core-avx2", .features = .{ .ints = .{ 163706337799184528, 4647996449840564893, 4580179968, 0, 0 } } };
            const core_avx_i: Cpu = .{ .name = "core_avx_i", .llvm_name = "core-avx-i", .features = .{ .ints = .{ 162439648864370704, 4647996449538312709, 4580180032, 0, 0 } } };
            const corei7: Cpu = .{ .name = "corei7", .llvm_name = "corei7", .features = .{ .ints = .{ 28587302322192, 36028938954213376, 285216768, 0, 0 } } };
            const corei7_avx: Cpu = .{ .name = "corei7_avx", .llvm_name = "corei7-avx", .features = .{ .ints = .{ 162158173887664144, 4647714974561601541, 4580180032, 0, 0 } } };
            const emeraldrapids: Cpu = .{ .name = "emeraldrapids", .llvm_name = "emeraldrapids", .features = .{ .ints = .{ 1349631750520882608, 3639850477552016957, 15431630848, 0, 0 } } };
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 144150372447944720, 4611686018494627841, 285212672, 0, 0 } } };
            const geode: Cpu = .{ .name = "geode", .llvm_name = "geode", .features = .{ .ints = .{ 35184372088840, 0, 285212704, 0, 0 } } };
            const goldmont: Cpu = .{ .name = "goldmont", .llvm_name = "goldmont", .features = .{ .ints = .{ 9241415297544486992, 10413175718820186624, 15318650897, 0, 0 } } };
            const goldmont_plus: Cpu = .{ .name = "goldmont_plus", .llvm_name = "goldmont-plus", .features = .{ .ints = .{ 9223400899035005008, 10413263679750408704, 15318650897, 0, 0 } } };
            const grandridge: Cpu = .{ .name = "grandridge", .llvm_name = "grandridge", .features = .{ .ints = .{ 9223687526898729008, 12863257148955859584, 15499001873, 0, 0 } } };
            const graniterapids: Cpu = .{ .name = "graniterapids", .llvm_name = "graniterapids", .features = .{ .ints = .{ 1349631750520883120, 3639852676575272509, 15431630848, 0, 0 } } };
            const haswell: Cpu = .{ .name = "haswell", .llvm_name = "haswell", .features = .{ .ints = .{ 163706337799184528, 4647996449840564893, 4580179968, 0, 0 } } };
            const @"i386": Cpu = .{ .name = "i386", .llvm_name = "i386", .features = .{ .ints = .{ 0, 0, 285212704, 0, 0 } } };
            const @"i486": Cpu = .{ .name = "i486", .llvm_name = "i486", .features = .{ .ints = .{ 0, 0, 285212704, 0, 0 } } };
            const @"i586": Cpu = .{ .name = "i586", .llvm_name = "i586", .features = .{ .ints = .{ 35184372088832, 0, 285212704, 0, 0 } } };
            const @"i686": Cpu = .{ .name = "i686", .llvm_name = "i686", .features = .{ .ints = .{ 37383395344384, 0, 285212704, 0, 0 } } };
            const icelake_client: Cpu = .{ .name = "icelake_client", .llvm_name = "icelake-client", .features = .{ .ints = .{ 1297206344684044464, 1189874652106071613, 15330181120, 0, 0 } } };
            const icelake_server: Cpu = .{ .name = "icelake_server", .llvm_name = "icelake-server", .features = .{ .ints = .{ 1297206894439858352, 1189874686465809981, 15397289984, 0, 0 } } };
            const ivybridge: Cpu = .{ .name = "ivybridge", .llvm_name = "ivybridge", .features = .{ .ints = .{ 162439648864370704, 4647996449538312709, 4580180032, 0, 0 } } };
            const k6: Cpu = .{ .name = "k6", .llvm_name = "k6", .features = .{ .ints = .{ 35184372088832, 134217728, 285212704, 0, 0 } } };
            const k6_2: Cpu = .{ .name = "k6_2", .llvm_name = "k6-2", .features = .{ .ints = .{ 35184372088836, 0, 285212704, 0, 0 } } };
            const k6_3: Cpu = .{ .name = "k6_3", .llvm_name = "k6-3", .features = .{ .ints = .{ 35184372088836, 0, 285212704, 0, 0 } } };
            const k8: Cpu = .{ .name = "k8", .llvm_name = "k8", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
            const k8_sse3: Cpu = .{ .name = "k8_sse3", .llvm_name = "k8-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
            const knl: Cpu = .{ .name = "knl", .llvm_name = "knl", .features = .{ .ints = .{ 10376322180312596592, 13871945730232551936, 4563402770, 0, 0 } } };
            const knm: Cpu = .{ .name = "knm", .llvm_name = "knm", .features = .{ .ints = .{ 10376322180849467504, 13871945730232551936, 4563402770, 0, 0 } } };
            const lakemont: Cpu = .{ .name = "lakemont", .llvm_name = "lakemont", .features = .{ .ints = .{ 35184372088832, 0, 16777376, 0, 0 } } };
            const meteorlake: Cpu = .{ .name = "meteorlake", .llvm_name = "meteorlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
            const nehalem: Cpu = .{ .name = "nehalem", .llvm_name = "nehalem", .features = .{ .ints = .{ 28587302322192, 36028938954213376, 285216768, 0, 0 } } };
            const nocona: Cpu = .{ .name = "nocona", .llvm_name = "nocona", .features = .{ .ints = .{ 19791209299984, 4429187072, 285213728, 0, 0 } } };
            const opteron: Cpu = .{ .name = "opteron", .llvm_name = "opteron", .features = .{ .ints = .{ 37383395344408, 72057598332897282, 285213224, 0, 0 } } };
            const opteron_sse3: Cpu = .{ .name = "opteron_sse3", .llvm_name = "opteron-sse3", .features = .{ .ints = .{ 19791209299992, 72057598332897282, 285213736, 0, 0 } } };
            const penryn: Cpu = .{ .name = "penryn", .llvm_name = "penryn", .features = .{ .ints = .{ 19791209299984, 36028801515259904, 285214752, 0, 0 } } };
            const pentium: Cpu = .{ .name = "pentium", .llvm_name = "pentium", .features = .{ .ints = .{ 35184372088832, 0, 285212704, 0, 0 } } };
            const pentium2: Cpu = .{ .name = "pentium2", .llvm_name = "pentium2", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212704, 0, 0 } } };
            const pentium3: Cpu = .{ .name = "pentium3", .llvm_name = "pentium3", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212960, 0, 0 } } };
            const pentium3m: Cpu = .{ .name = "pentium3m", .llvm_name = "pentium3m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285212960, 0, 0 } } };
            const pentium4: Cpu = .{ .name = "pentium4", .llvm_name = "pentium4", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
            const pentium4m: Cpu = .{ .name = "pentium4m", .llvm_name = "pentium4m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
            const pentium_m: Cpu = .{ .name = "pentium_m", .llvm_name = "pentium-m", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213216, 0, 0 } } };
            const pentium_mmx: Cpu = .{ .name = "pentium_mmx", .llvm_name = "pentium-mmx", .features = .{ .ints = .{ 35184372088832, 134217728, 285212704, 0, 0 } } };
            const pentiumpro: Cpu = .{ .name = "pentiumpro", .llvm_name = "pentiumpro", .features = .{ .ints = .{ 37383395344384, 4294967296, 285212704, 0, 0 } } };
            const prescott: Cpu = .{ .name = "prescott", .llvm_name = "prescott", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213728, 0, 0 } } };
            const raptorlake: Cpu = .{ .name = "raptorlake", .llvm_name = "raptorlake", .features = .{ .ints = .{ 1324369370633207984, 8251535946223622845, 15497953280, 0, 0 } } };
            const rocketlake: Cpu = .{ .name = "rocketlake", .llvm_name = "rocketlake", .features = .{ .ints = .{ 1297206344684044464, 1189874652106071613, 15330181120, 0, 0 } } };
            const sandybridge: Cpu = .{ .name = "sandybridge", .llvm_name = "sandybridge", .features = .{ .ints = .{ 162158173887664144, 4647714974561601541, 4580180032, 0, 0 } } };
            const sapphirerapids: Cpu = .{ .name = "sapphirerapids", .llvm_name = "sapphirerapids", .features = .{ .ints = .{ 1349631750520882608, 3639850477552016957, 15431630848, 0, 0 } } };
            const sierraforest: Cpu = .{ .name = "sierraforest", .llvm_name = "sierraforest", .features = .{ .ints = .{ 9223687526898729008, 12863221964583770752, 15499001873, 0, 0 } } };
            const silvermont: Cpu = .{ .name = "silvermont", .llvm_name = "silvermont", .features = .{ .ints = .{ 9529645398818291728, 9259691264260048896, 287313941, 0, 0 } } };
            const skx: Cpu = .{ .name = "skx", .llvm_name = "skx", .features = .{ .ints = .{ 1315221292223758576, 4648568814362298941, 15317598208, 0, 0 } } };
            const skylake: Cpu = .{ .name = "skylake", .llvm_name = "skylake", .features = .{ .ints = .{ 1315502217377095920, 4648568195887008445, 15317598208, 0, 0 } } };
            const skylake_avx512: Cpu = .{ .name = "skylake_avx512", .llvm_name = "skylake-avx512", .features = .{ .ints = .{ 1315221292223758576, 4648568814362298941, 15317598208, 0, 0 } } };
            const slm: Cpu = .{ .name = "slm", .llvm_name = "slm", .features = .{ .ints = .{ 9529645398818291728, 9259691264260048896, 287313941, 0, 0 } } };
            const tigerlake: Cpu = .{ .name = "tigerlake", .llvm_name = "tigerlake", .features = .{ .ints = .{ 1297206894708293808, 3495717662930378301, 15330181120, 0, 0 } } };
            const tremont: Cpu = .{ .name = "tremont", .llvm_name = "tremont", .features = .{ .ints = .{ 9223401448790818896, 10413263679750412800, 15318650897, 0, 0 } } };
            const westmere: Cpu = .{ .name = "westmere", .llvm_name = "westmere", .features = .{ .ints = .{ 28587302322192, 36028956134082560, 285216768, 0, 0 } } };
            const winchip2: Cpu = .{ .name = "winchip2", .llvm_name = "winchip2", .features = .{ .ints = .{ 4, 0, 285212704, 0, 0 } } };
            const winchip_c6: Cpu = .{ .name = "winchip_c6", .llvm_name = "winchip-c6", .features = .{ .ints = .{ 0, 134217728, 285212704, 0, 0 } } };
            const x86_64: Cpu = .{ .name = "x86_64", .llvm_name = "x86-64", .features = .{ .ints = .{ 37383395344400, 13835058059778590720, 285213184, 0, 0 } } };
            const x86_64_v2: Cpu = .{ .name = "x86_64_v2", .llvm_name = "x86-64-v2", .features = .{ .ints = .{ 162158173887660048, 4647714957381732357, 285216832, 0, 0 } } };
            const x86_64_v3: Cpu = .{ .name = "x86_64_v3", .llvm_name = "x86-64-v3", .features = .{ .ints = .{ 163565600310829200, 4647714957683722397, 1358954496, 0, 0 } } };
            const x86_64_v4: Cpu = .{ .name = "x86_64_v4", .llvm_name = "x86-64-v4", .features = .{ .ints = .{ 1315079730101682320, 4647715507439536189, 1358954496, 0, 0 } } };
            const yonah: Cpu = .{ .name = "yonah", .llvm_name = "yonah", .features = .{ .ints = .{ 37383395344384, 4429187072, 285213728, 0, 0 } } };
            const znver1: Cpu = .{ .name = "znver1", .llvm_name = "znver1", .features = .{ .ints = .{ 14555945552589103344, 1261861278184377011, 15317606408, 0, 0 } } };
            const znver2: Cpu = .{ .name = "znver2", .llvm_name = "znver2", .features = .{ .ints = .{ 14555946102344917232, 1262072384416910003, 15384715272, 0, 0 } } };
            const znver3: Cpu = .{ .name = "znver3", .llvm_name = "znver3", .features = .{ .ints = .{ 14555946102344917168, 1262072436023889587, 15397298184, 0, 0 } } };
            const znver4: Cpu = .{ .name = "znver4", .llvm_name = "znver4", .features = .{ .ints = .{ 14555664628161364144, 3567915445237587507, 15397298184, 0, 0 } } };
        };
    };
    pub const xtensa = struct {
        pub const Feature = enum(u0) {
            density = 0,
        };
        pub const all_features: []const Cpu.Feature = &.{
            .{ .name = "density", .llvm_name = "density", .description = "Enable Density instructions", .dependencies = .{ .ints = .{ 0, 0, 0, 0, 0 } } },
        };
        pub const cpu = struct {
            const generic: Cpu = .{ .name = "generic", .llvm_name = "generic", .features = .{ .ints = .{ 0, 0, 0, 0, 0 } } };
        };
    };
};
