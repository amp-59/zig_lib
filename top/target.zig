pub const Target = struct {
    cpu: Cpu,
    os: Os,
    abi: Abi,
    ofmt: ObjectFormat,
    pub const Set = struct {
        ints: [5]usize,
    };
    pub const Feature = struct {
        index: u9 = undefined,
        name: []const u8 = undefined,
        llvm_name: ?[:0]const u8,
        description: []const u8,
        dependencies: Set,
    };
    pub const Cpu = struct {
        arch: Arch,
        model: *const Model,
        features: Set,
        pub const Model = struct {
            name: []const u8,
            llvm_name: ?[:0]const u8,
            features: Set,
        };
        pub const Arch = enum(u6) {
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
        };
    };
    pub const Os = struct {
        tag: Tag,
        version_range: VersionRange,
        pub const Tag = enum(u6) {
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
        };
        pub const Version = struct {
            major: usize,
            minor: usize,
            patch: usize,
            pre: ?[]const u8 = null,
            build: ?[]const u8 = null,
        };
        pub const Range = struct {
            min: Version,
            max: Version,
        };
        pub const LinuxVersionRange = struct {
            range: Range,
            glibc: Version,
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
        pub const VersionRange = union {
            none: void,
            semver: Range,
            linux: LinuxVersionRange,
            windows: struct {
                min: WindowsVersion,
                max: WindowsVersion,
            },
        };
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
    pub const aarch64 = @import("./target/aarch64.zig");
    pub const x86 = @import("./target/x86.zig");
};
