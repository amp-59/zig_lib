const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");

const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = mem.fmt_wr_spec;
    tmp.integral = .{ .format = .dec };
    break :blk tmp;
};

pub const BuildCmdSpec = struct {
    max_len: u64 = 1024 * 1024,
    max_args: u64 = 1024,
    Allocator: ?type = null,
};
pub fn BuildCmd(comptime spec: BuildCmdSpec) type {
    return struct {
        const Builder: type = @This();
        const Allocator: type = spec.Allocator.?;
        const String: type = Allocator.StructuredVectorLowAligned(u8, 8);
        const StaticString: type = mem.StaticString(spec.max_len);
        const Pointers: type = mem.StaticArray([*:0]u8, spec.max_args);
        cmd: enum { exe, lib, obj, fmt, ast_check, run },
        root: [:0]const u8,
        watch: bool = false,
        color: ?enum(u2) { on = 0, off = 1, auto = 2 } = null,
        emit_bin: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_asm: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_llvm_ir: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_llvm_bc: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_h: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_docs: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_analysis: ?union(enum) { yes: ?[]const u8, no: void } = null,
        emit_implib: ?union(enum) { yes: ?[]const u8, no: void } = null,
        show_builtin: bool = false,
        cache_dir: ?[]const u8 = null,
        global_cache_dir: ?[]const u8 = null,
        zig_lib_dir: ?[]const u8 = null,
        enable_cache: bool = false,
        target: ?[]const u8 = null,
        cpu: ?[]const u8 = null,
        cmodel: ?enum(u3) { default = 0, tiny = 1, small = 2, kernel = 3, medium = 4, large = 5 } = null,
        red_zone: ?bool = null,
        omit_frame_pointer: ?bool = null,
        exec_model: ?[]const u8 = null,
        name: ?[]const u8 = null,
        O: ?@TypeOf(builtin.zig.mode) = null,
        main_pkg_path: ?[]const u8 = null,
        pic: ?bool = null,
        pie: ?bool = null,
        lto: ?bool = null,
        stack_check: ?bool = null,
        sanitize_c: ?bool = null,
        valgrind: ?bool = null,
        sanitize_thread: ?bool = null,
        dll_export_fns: ?bool = null,
        unwind_tables: ?bool = null,
        llvm: ?bool = null,
        clang: ?bool = null,
        stage1: ?bool = null,
        single_threaded: ?bool = null,
        builtin: bool = false,
        function_sections: ?bool = null,
        strip: ?bool = null,
        fmt: ?enum(u4) { elf = 0, c = 1, wasm = 2, coff = 3, macho = 4, spirv = 5, plan9 = 6, hex = 7, raw = 8 } = null,
        dirafter: ?[]const u8 = null,
        system: ?[]const u8 = null,
        include: ?[]const u8 = null,
        macros: ?Macros = null,
        packages: ?Packages = null,
        soname: ?union(enum) { yes: []const u8, no: void } = null,
        dynamic: bool = false,
        static: bool = false,
        gc_sections: ?bool = null,
        stack: ?u64 = null,
        z: ?enum(u4) { nodelete = 0, notext = 1, defs = 2, origin = 3, nocopyreloc = 4, now = 5, lazy = 6, relro = 7, norelro = 8 } = null,
        fn allocateCommandString(build: Builder, allocator: *Allocator) !String {
            var array: String = try String.init(allocator, 512);
            try array.appendMany(allocator, "zig\x00");
            switch (build.cmd) {
                .lib, .exe, .obj => {
                    try array.appendMany(allocator, "build-");
                    try array.appendMany(allocator, @tagName(build.cmd));
                    try array.appendOne(allocator, '\x00');
                },
                .fmt, .ast_check, .run => {
                    try array.appendMany(allocator, @tagName(build.cmd));
                    try array.appendOne(allocator, '\x00');
                },
            }
            if (build.watch) {
                try array.appendAny(fmt_spec, allocator, .{"--watch\x00"});
            }
            if (build.color) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--color\x00", how, "\x00" });
            }
            if (build.emit_bin) |emit_bin| {
                switch (emit_bin) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-bin=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-bin\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-bin\x00"});
                    },
                }
            }
            if (build.emit_asm) |emit_asm| {
                switch (emit_asm) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-asm=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-asm\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-asm\x00"});
                    },
                }
            }
            if (build.emit_llvm_ir) |emit_llvm_ir| {
                switch (emit_llvm_ir) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-llvm-ir=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-llvm-ir\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-llvm-ir\x00"});
                    },
                }
            }
            if (build.emit_llvm_bc) |emit_llvm_bc| {
                switch (emit_llvm_bc) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-llvm-bc=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-llvm-bc\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-llvm-bc\x00"});
                    },
                }
            }
            if (build.emit_h) |emit_h| {
                switch (emit_h) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-h=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-h\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-h\x00"});
                    },
                }
            }
            if (build.emit_docs) |emit_docs| {
                switch (emit_docs) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-docs=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-docs\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-docs\x00"});
                    },
                }
            }
            if (build.emit_analysis) |emit_analysis| {
                switch (emit_analysis) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-analysis=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-analysis\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-analysis\x00"});
                    },
                }
            }
            if (build.emit_implib) |emit_implib| {
                switch (emit_implib) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            try array.appendAny(fmt_spec, allocator, .{ "-femit-implib=", yes_arg, "\x00" });
                        } else {
                            try array.appendAny(fmt_spec, allocator, .{"-femit-implib\x00"});
                        }
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-emit-implib\x00"});
                    },
                }
            }
            if (build.show_builtin) {
                try array.appendAny(fmt_spec, allocator, .{"--show-builtin\x00"});
            }
            if (build.cache_dir) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--cache-dir\x00", how, "\x00" });
            }
            if (build.global_cache_dir) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--global-cache-dir\x00", how, "\x00" });
            }
            if (build.zig_lib_dir) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--zig-lib-dir\x00", how, "\x00" });
            }
            if (build.enable_cache) {
                try array.appendAny(fmt_spec, allocator, .{"--enable-cache\x00"});
            }
            if (build.target) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-target\x00", how, "\x00" });
            }
            if (build.cpu) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-mcpu\x00", how, "\x00" });
            }
            if (build.cmodel) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-mcmodel\x00", how, "\x00" });
            }
            if (build.red_zone) |red_zone| {
                if (red_zone) {
                    try array.appendAny(fmt_spec, allocator, .{"-mred-zone\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-mno-red-zone\x00"});
                }
            }
            if (build.omit_frame_pointer) |omit_frame_pointer| {
                if (omit_frame_pointer) {
                    try array.appendAny(fmt_spec, allocator, .{"-fomit-frame-pointer\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-omit-frame-pointer\x00"});
                }
            }
            if (build.exec_model) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-mexec-model\x00", how, "\x00" });
            }
            if (build.name) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--name\x00", how, "\x00" });
            }
            if (build.O) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-O\x00", how, "\x00" });
            }
            if (build.main_pkg_path) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--main-pkg-path\x00", how, "\x00" });
            }
            if (build.pic) |pic| {
                if (pic) {
                    try array.appendAny(fmt_spec, allocator, .{"-fPIC\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-PIC\x00"});
                }
            }
            if (build.pie) |pie| {
                if (pie) {
                    try array.appendAny(fmt_spec, allocator, .{"-fPIE\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-PIE\x00"});
                }
            }
            if (build.lto) |lto| {
                if (lto) {
                    try array.appendAny(fmt_spec, allocator, .{"-flto\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-lto\x00"});
                }
            }
            if (build.stack_check) |stack_check| {
                if (stack_check) {
                    try array.appendAny(fmt_spec, allocator, .{"-fstack-check\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-stack-check\x00"});
                }
            }
            if (build.sanitize_c) |sanitize_c| {
                if (sanitize_c) {
                    try array.appendAny(fmt_spec, allocator, .{"-fsanitize-c\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-sanitize-c\x00"});
                }
            }
            if (build.valgrind) |valgrind| {
                if (valgrind) {
                    try array.appendAny(fmt_spec, allocator, .{"-fvalgrind\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-valgrind\x00"});
                }
            }
            if (build.sanitize_thread) |sanitize_thread| {
                if (sanitize_thread) {
                    try array.appendAny(fmt_spec, allocator, .{"-fsanitize-thread\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-sanitize-thread\x00"});
                }
            }
            if (build.dll_export_fns) |dll_export_fns| {
                if (dll_export_fns) {
                    try array.appendAny(fmt_spec, allocator, .{"-fdll-export-fns\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-dll-export-fns\x00"});
                }
            }
            if (build.unwind_tables) |unwind_tables| {
                if (unwind_tables) {
                    try array.appendAny(fmt_spec, allocator, .{"-funwind-tables\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-unwind-tables\x00"});
                }
            }
            if (build.llvm) |llvm| {
                if (llvm) {
                    try array.appendAny(fmt_spec, allocator, .{"-fLLVM\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-LLVM\x00"});
                }
            }
            if (build.clang) |clang| {
                if (clang) {
                    try array.appendAny(fmt_spec, allocator, .{"-fClang\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-Clang\x00"});
                }
            }
            if (build.stage1) |stage1| {
                if (stage1) {
                    try array.appendAny(fmt_spec, allocator, .{"-fstage1\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-stage1\x00"});
                }
            }
            if (build.single_threaded) |single_threaded| {
                if (single_threaded) {
                    try array.appendAny(fmt_spec, allocator, .{"-fsingle-threaded\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-single-threaded\x00"});
                }
            }
            if (build.builtin) {
                try array.appendAny(fmt_spec, allocator, .{"-fbuiltin\x00"});
            }
            if (build.function_sections) |function_sections| {
                if (function_sections) {
                    try array.appendAny(fmt_spec, allocator, .{"-ffunction-sections\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-function-sections\x00"});
                }
            }
            if (build.strip) |strip| {
                if (strip) {
                    try array.appendAny(fmt_spec, allocator, .{"-fstrip\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"-fno-strip\x00"});
                }
            }
            if (build.fmt) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-ofmt\x00", how, "\x00" });
            }
            if (build.dirafter) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-dirafter\x00", how, "\x00" });
            }
            if (build.system) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-isystem\x00", how, "\x00" });
            }
            if (build.include) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-I\x00", how, "\x00" });
            }
            if (build.macros) |how| {
                try array.appendAny(fmt_spec, allocator, .{how});
            }
            if (build.packages) |how| {
                try array.appendAny(fmt_spec, allocator, .{how});
            }
            if (build.soname) |soname| {
                switch (soname) {
                    .yes => |yes_arg| {
                        try array.appendAny(fmt_spec, allocator, .{ "-fsoname\x00", yes_arg, "\x00" });
                    },
                    .no => {
                        try array.appendAny(fmt_spec, allocator, .{"-fno-soname\x00"});
                    },
                }
            }
            if (build.dynamic) {
                try array.appendAny(fmt_spec, allocator, .{"-dynamic\x00"});
            }
            if (build.static) {
                try array.appendAny(fmt_spec, allocator, .{"-static\x00"});
            }
            if (build.gc_sections) |gc_sections| {
                if (gc_sections) {
                    try array.appendAny(fmt_spec, allocator, .{"--gc-sections\x00"});
                } else {
                    try array.appendAny(fmt_spec, allocator, .{"--no-gc-sections\x00"});
                }
            }
            if (build.stack) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "--stack\x00", how, "\x00" });
            }
            if (build.z) |how| {
                try array.appendAny(fmt_spec, allocator, .{ "-z\x00", how, "\x00" });
            }

            try array.appendAny(mem.ptr_wr_spec, allocator, .{ build.root, "\x00" });
            return array;
        }
        fn commandString(build: Builder) anyerror!StaticString {
            var array: StaticString = .{};
            array.writeMany("zig\x00");
            switch (build.cmd) {
                .lib, .exe, .obj => {
                    array.writeMany("build-");
                    array.writeMany(@tagName(build.cmd));
                    array.writeOne('\x00');
                },
                .fmt, .ast_check, .run => {
                    array.writeMany(@tagName(build.cmd));
                    array.writeOne('\x00');
                },
            }
            if (build.watch) {
                array.writeAny(fmt_spec, .{"--watch\x00"});
            }
            if (build.color) |how| {
                array.writeAny(fmt_spec, .{ "--color\x00", how, "\x00" });
            }
            if (build.emit_bin) |emit_bin| {
                switch (emit_bin) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-bin=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-bin\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-bin\x00"});
                    },
                }
            }
            if (build.emit_asm) |emit_asm| {
                switch (emit_asm) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-asm=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-asm\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-asm\x00"});
                    },
                }
            }
            if (build.emit_llvm_ir) |emit_llvm_ir| {
                switch (emit_llvm_ir) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-llvm-ir=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-llvm-ir\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-llvm-ir\x00"});
                    },
                }
            }
            if (build.emit_llvm_bc) |emit_llvm_bc| {
                switch (emit_llvm_bc) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-llvm-bc=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-llvm-bc\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-llvm-bc\x00"});
                    },
                }
            }
            if (build.emit_h) |emit_h| {
                switch (emit_h) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-h=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-h\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-h\x00"});
                    },
                }
            }
            if (build.emit_docs) |emit_docs| {
                switch (emit_docs) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-docs=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-docs\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-docs\x00"});
                    },
                }
            }
            if (build.emit_analysis) |emit_analysis| {
                switch (emit_analysis) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-analysis=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-analysis\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-analysis\x00"});
                    },
                }
            }
            if (build.emit_implib) |emit_implib| {
                switch (emit_implib) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeAny(fmt_spec, .{ "-femit-implib=", yes_arg, "\x00" });
                        } else {
                            array.writeAny(fmt_spec, .{"-femit-implib\x00"});
                        }
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-emit-implib\x00"});
                    },
                }
            }
            if (build.show_builtin) {
                array.writeAny(fmt_spec, .{"--show-builtin\x00"});
            }
            if (build.cache_dir) |how| {
                array.writeAny(fmt_spec, .{ "--cache-dir\x00", how, "\x00" });
            }
            if (build.global_cache_dir) |how| {
                array.writeAny(fmt_spec, .{ "--global-cache-dir\x00", how, "\x00" });
            }
            if (build.zig_lib_dir) |how| {
                array.writeAny(fmt_spec, .{ "--zig-lib-dir\x00", how, "\x00" });
            }
            if (build.enable_cache) {
                array.writeAny(fmt_spec, .{"--enable-cache\x00"});
            }
            if (build.target) |how| {
                array.writeAny(fmt_spec, .{ "-target\x00", how, "\x00" });
            }
            if (build.cpu) |how| {
                array.writeAny(fmt_spec, .{ "-mcpu\x00", how, "\x00" });
            }
            if (build.cmodel) |how| {
                array.writeAny(fmt_spec, .{ "-mcmodel\x00", how, "\x00" });
            }
            if (build.red_zone) |red_zone| {
                if (red_zone) {
                    array.writeAny(fmt_spec, .{"-mred-zone\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-mno-red-zone\x00"});
                }
            }
            if (build.omit_frame_pointer) |omit_frame_pointer| {
                if (omit_frame_pointer) {
                    array.writeAny(fmt_spec, .{"-fomit-frame-pointer\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-omit-frame-pointer\x00"});
                }
            }
            if (build.exec_model) |how| {
                array.writeAny(fmt_spec, .{ "-mexec-model\x00", how, "\x00" });
            }
            if (build.name) |how| {
                array.writeAny(fmt_spec, .{ "--name\x00", how, "\x00" });
            }
            if (build.O) |how| {
                array.writeAny(fmt_spec, .{ "-O\x00", how, "\x00" });
            }
            if (build.main_pkg_path) |how| {
                array.writeAny(fmt_spec, .{ "--main-pkg-path\x00", how, "\x00" });
            }
            if (build.pic) |pic| {
                if (pic) {
                    array.writeAny(fmt_spec, .{"-fPIC\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-PIC\x00"});
                }
            }
            if (build.pie) |pie| {
                if (pie) {
                    array.writeAny(fmt_spec, .{"-fPIE\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-PIE\x00"});
                }
            }
            if (build.lto) |lto| {
                if (lto) {
                    array.writeAny(fmt_spec, .{"-flto\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-lto\x00"});
                }
            }
            if (build.stack_check) |stack_check| {
                if (stack_check) {
                    array.writeAny(fmt_spec, .{"-fstack-check\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-stack-check\x00"});
                }
            }
            if (build.sanitize_c) |sanitize_c| {
                if (sanitize_c) {
                    array.writeAny(fmt_spec, .{"-fsanitize-c\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-sanitize-c\x00"});
                }
            }
            if (build.valgrind) |valgrind| {
                if (valgrind) {
                    array.writeAny(fmt_spec, .{"-fvalgrind\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-valgrind\x00"});
                }
            }
            if (build.sanitize_thread) |sanitize_thread| {
                if (sanitize_thread) {
                    array.writeAny(fmt_spec, .{"-fsanitize-thread\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-sanitize-thread\x00"});
                }
            }
            if (build.dll_export_fns) |dll_export_fns| {
                if (dll_export_fns) {
                    array.writeAny(fmt_spec, .{"-fdll-export-fns\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-dll-export-fns\x00"});
                }
            }
            if (build.unwind_tables) |unwind_tables| {
                if (unwind_tables) {
                    array.writeAny(fmt_spec, .{"-funwind-tables\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-unwind-tables\x00"});
                }
            }
            if (build.llvm) |llvm| {
                if (llvm) {
                    array.writeAny(fmt_spec, .{"-fLLVM\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-LLVM\x00"});
                }
            }
            if (build.clang) |clang| {
                if (clang) {
                    array.writeAny(fmt_spec, .{"-fClang\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-Clang\x00"});
                }
            }
            if (build.stage1) |stage1| {
                if (stage1) {
                    array.writeAny(fmt_spec, .{"-fstage1\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-stage1\x00"});
                }
            }
            if (build.single_threaded) |single_threaded| {
                if (single_threaded) {
                    array.writeAny(fmt_spec, .{"-fsingle-threaded\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-single-threaded\x00"});
                }
            }
            if (build.builtin) {
                array.writeAny(fmt_spec, .{"-fbuiltin\x00"});
            }
            if (build.function_sections) |function_sections| {
                if (function_sections) {
                    array.writeAny(fmt_spec, .{"-ffunction-sections\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-function-sections\x00"});
                }
            }
            if (build.strip) |strip| {
                if (strip) {
                    array.writeAny(fmt_spec, .{"-fstrip\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"-fno-strip\x00"});
                }
            }
            if (build.fmt) |how| {
                array.writeAny(fmt_spec, .{ "-ofmt\x00", how, "\x00" });
            }
            if (build.dirafter) |how| {
                array.writeAny(fmt_spec, .{ "-dirafter\x00", how, "\x00" });
            }
            if (build.system) |how| {
                array.writeAny(fmt_spec, .{ "-isystem\x00", how, "\x00" });
            }
            if (build.include) |how| {
                array.writeAny(fmt_spec, .{ "-I\x00", how, "\x00" });
            }
            if (build.macros) |how| {
                array.writeAny(fmt_spec, .{how});
            }
            if (build.packages) |how| {
                array.writeAny(fmt_spec, .{how});
            }
            if (build.soname) |soname| {
                switch (soname) {
                    .yes => |yes_arg| {
                        array.writeAny(fmt_spec, .{ "-fsoname\x00", yes_arg, "\x00" });
                    },
                    .no => {
                        array.writeAny(fmt_spec, .{"-fno-soname\x00"});
                    },
                }
            }
            if (build.dynamic) {
                array.writeAny(fmt_spec, .{"-dynamic\x00"});
            }
            if (build.static) {
                array.writeAny(fmt_spec, .{"-static\x00"});
            }
            if (build.gc_sections) |gc_sections| {
                if (gc_sections) {
                    array.writeAny(fmt_spec, .{"--gc-sections\x00"});
                } else {
                    array.writeAny(fmt_spec, .{"--no-gc-sections\x00"});
                }
            }
            if (build.stack) |how| {
                array.writeAny(fmt_spec, .{ "--stack\x00", how, "\x00" });
            }
            if (build.z) |how| {
                array.writeAny(fmt_spec, .{ "-z\x00", how, "\x00" });
            }

            array.writeAny(mem.ptr_wr_spec, .{ build.root, "\x00" });
            return array;
        }

        pub fn allocateShow(build: Builder, allocator: *Allocator) !void {
            var ad: BuildCmd.ArgData = try build.parcelDataV(&allocator);
            for (ad.ptrs.readAll()) |argp| {
                try file.write(2, mem.manyToSlice(argp));
                try file.write(2, "\n");
            }
            allocator.discard();
        }
        pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
            return genericExec(vars, try build.allocateCommandString(allocator));
        }
        pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
            return genericExec(vars, try build.commandString());
        }
        fn genericExec(vars: [][*:0]u8, array: anytype) !u64 {
            const dir_fd: u64 = try file.find(vars, "zig");
            defer file.close(.{ .errors = null }, dir_fd);
            var args: Pointers = .{};
            var idx: u64 = 0;
            for (array.readAll()) |c, i| {
                if (c == 0) {
                    args.writeOne(array.referAllDefined()[idx..i :0].ptr);
                    idx = i + 1;
                }
            }
            if (args.impl.start() != args.impl.next()) {
                mem.set(args.impl.next(), @as(u64, 0), 1);
            }
            if (args.len() != 0) {
                return proc.commandAt(.{}, dir_fd, "zig", args.referAllDefined(), vars);
            }
            return 0;
        }
    };
}

pub const Packages = []const Pkg;
pub const Macros = []const Macro;

pub const Pkg = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(pkg: Pkg, array: anytype) void {
        array.writeMany("--pkg-begin");
        array.writeOne(0);
        array.writeMany(pkg.name);
        array.writeOne(0);
        array.writeMany(pkg.path);
        array.writeOne(0);
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                array.writeOne(0);
                dep.formatWrite(array);
            }
        }
        array.writeMany("--pkg-end");
        array.writeOne(0);
    }
    pub fn formatLength(pkg: Pkg) u64 {
        var len: u64 = 0;
        len += 11;
        len += 1;
        len += pkg.name.len;
        len += 1;
        len += pkg.path.len;
        len += 1;
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                len += 1;
                len += dep.formatLength();
            }
        }
        len += 9;
        len += 1;
        return len;
    }
};
/// Zig says value does not need to be defined, in which case default to 1
pub const Macro = struct {
    name: []const u8,
    value: ?[]const u8 = null,
    pub fn formatWrite(macro: Macro, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(macro.name);
        if (macro.value) |value| {
            array.writeMany("=");
            array.writeMany(value);
        }
        array.writeOne(0);
    }
    pub fn formatLength(macro: Macro) u64 {
        var len: u64 = 0;
        len += 2;
        len += macro.name.len;
        if (macro.value) |value| {
            len += 1;
            len += value.len;
        }
        len += 1;
        return len;
    }
};
