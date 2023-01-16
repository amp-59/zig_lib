const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.fmt;
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
        const Pointers: type = Allocator.StructuredVector([*:0]u8);
        const StaticString: type = mem.StructuredAutomaticVector(u8, null, spec.max_len, 8, .{});
        const StaticPointers: type = mem.StructuredAutomaticVector([*:0]u8, null, spec.max_args, 8, .{});
        const zig: [:0]const u8 = "zig";
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
        fn buildLength(build: Builder) u64 {
            var len: u64 = "zig\x00".len;
            switch (build.cmd) {
                .lib, .exe, .obj => {
                    len += "build-".len + @tagName(build.cmd).len + 1;
                },
                .fmt, .ast_check, .run => {
                    len += @tagName(build.cmd).len + 1;
                },
            }
            if (build.watch) {
                len +%= 10;
            }
            if (build.color) |how| {
                len +%= 10;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.emit_bin) |emit_bin| {
                switch (emit_bin) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 13;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 13;
                        }
                    },
                    .no => {
                        len +%= 16;
                    },
                }
            }
            if (build.emit_asm) |emit_asm| {
                switch (emit_asm) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 13;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 13;
                        }
                    },
                    .no => {
                        len +%= 16;
                    },
                }
            }
            if (build.emit_llvm_ir) |emit_llvm_ir| {
                switch (emit_llvm_ir) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 17;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 17;
                        }
                    },
                    .no => {
                        len +%= 20;
                    },
                }
            }
            if (build.emit_llvm_bc) |emit_llvm_bc| {
                switch (emit_llvm_bc) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 17;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 17;
                        }
                    },
                    .no => {
                        len +%= 20;
                    },
                }
            }
            if (build.emit_h) |emit_h| {
                switch (emit_h) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 11;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 11;
                        }
                    },
                    .no => {
                        len +%= 14;
                    },
                }
            }
            if (build.emit_docs) |emit_docs| {
                switch (emit_docs) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 14;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 14;
                        }
                    },
                    .no => {
                        len +%= 17;
                    },
                }
            }
            if (build.emit_analysis) |emit_analysis| {
                switch (emit_analysis) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 18;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 18;
                        }
                    },
                    .no => {
                        len +%= 21;
                    },
                }
            }
            if (build.emit_implib) |emit_implib| {
                switch (emit_implib) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            len +%= 16;
                            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                            len +%= 1;
                        } else {
                            len +%= 16;
                        }
                    },
                    .no => {
                        len +%= 19;
                    },
                }
            }
            if (build.show_builtin) {
                len +%= 17;
            }
            if (build.cache_dir) |how| {
                len +%= 14;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.global_cache_dir) |how| {
                len +%= 21;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.zig_lib_dir) |how| {
                len +%= 16;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.enable_cache) {
                len +%= 17;
            }
            if (build.target) |how| {
                len +%= 10;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.cpu) |how| {
                len +%= 8;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.cmodel) |how| {
                len +%= 11;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.red_zone) |red_zone| {
                if (red_zone) {
                    len +%= 13;
                } else {
                    len +%= 16;
                }
            }
            if (build.omit_frame_pointer) |omit_frame_pointer| {
                if (omit_frame_pointer) {
                    len +%= 23;
                } else {
                    len +%= 26;
                }
            }
            if (build.exec_model) |how| {
                len +%= 15;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.name) |how| {
                len +%= 9;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.O) |how| {
                len +%= 5;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.main_pkg_path) |how| {
                len +%= 18;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.pic) |pic| {
                if (pic) {
                    len +%= 8;
                } else {
                    len +%= 11;
                }
            }
            if (build.pie) |pie| {
                if (pie) {
                    len +%= 8;
                } else {
                    len +%= 11;
                }
            }
            if (build.lto) |lto| {
                if (lto) {
                    len +%= 8;
                } else {
                    len +%= 11;
                }
            }
            if (build.stack_check) |stack_check| {
                if (stack_check) {
                    len +%= 16;
                } else {
                    len +%= 19;
                }
            }
            if (build.sanitize_c) |sanitize_c| {
                if (sanitize_c) {
                    len +%= 15;
                } else {
                    len +%= 18;
                }
            }
            if (build.valgrind) |valgrind| {
                if (valgrind) {
                    len +%= 13;
                } else {
                    len +%= 16;
                }
            }
            if (build.sanitize_thread) |sanitize_thread| {
                if (sanitize_thread) {
                    len +%= 20;
                } else {
                    len +%= 23;
                }
            }
            if (build.dll_export_fns) |dll_export_fns| {
                if (dll_export_fns) {
                    len +%= 19;
                } else {
                    len +%= 22;
                }
            }
            if (build.unwind_tables) |unwind_tables| {
                if (unwind_tables) {
                    len +%= 18;
                } else {
                    len +%= 21;
                }
            }
            if (build.llvm) |llvm| {
                if (llvm) {
                    len +%= 9;
                } else {
                    len +%= 12;
                }
            }
            if (build.clang) |clang| {
                if (clang) {
                    len +%= 10;
                } else {
                    len +%= 13;
                }
            }
            if (build.stage1) |stage1| {
                if (stage1) {
                    len +%= 11;
                } else {
                    len +%= 14;
                }
            }
            if (build.single_threaded) |single_threaded| {
                if (single_threaded) {
                    len +%= 20;
                } else {
                    len +%= 23;
                }
            }
            if (build.builtin) {
                len +%= 12;
            }
            if (build.function_sections) |function_sections| {
                if (function_sections) {
                    len +%= 22;
                } else {
                    len +%= 25;
                }
            }
            if (build.strip) |strip| {
                if (strip) {
                    len +%= 10;
                } else {
                    len +%= 13;
                }
            }
            if (build.fmt) |how| {
                len +%= 8;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.dirafter) |how| {
                len +%= 12;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.system) |how| {
                len +%= 11;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.include) |how| {
                len +%= 5;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.macros) |how| {
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            }
            if (build.packages) |how| {
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            }
            if (build.soname) |soname| {
                switch (soname) {
                    .yes => |yes_arg| {
                        len +%= 11;
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
                        len +%= 1;
                    },
                    .no => {
                        len +%= 14;
                    },
                }
            }
            if (build.dynamic) {
                len +%= 11;
            }
            if (build.static) {
                len +%= 10;
            }
            if (build.gc_sections) |gc_sections| {
                if (gc_sections) {
                    len +%= 16;
                } else {
                    len +%= 19;
                }
            }
            if (build.stack) |how| {
                len +%= 10;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }
            if (build.z) |how| {
                len +%= 5;
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
                len +%= 1;
            }

            len +%= build.root.len + 1;
            return len;
        }
        fn buildWrite(build: Builder, array: anytype) u64 {
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
                array.writeMany("--watch\x00");
            }
            if (build.color) |how| {
                array.writeMany("--color\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.emit_bin) |emit_bin| {
                switch (emit_bin) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-bin=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-bin\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-bin\x00");
                    },
                }
            }
            if (build.emit_asm) |emit_asm| {
                switch (emit_asm) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-asm=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-asm\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-asm\x00");
                    },
                }
            }
            if (build.emit_llvm_ir) |emit_llvm_ir| {
                switch (emit_llvm_ir) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-llvm-ir=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-llvm-ir\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-llvm-ir\x00");
                    },
                }
            }
            if (build.emit_llvm_bc) |emit_llvm_bc| {
                switch (emit_llvm_bc) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-llvm-bc=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-llvm-bc\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-llvm-bc\x00");
                    },
                }
            }
            if (build.emit_h) |emit_h| {
                switch (emit_h) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-h=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-h\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-h\x00");
                    },
                }
            }
            if (build.emit_docs) |emit_docs| {
                switch (emit_docs) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-docs=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-docs\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-docs\x00");
                    },
                }
            }
            if (build.emit_analysis) |emit_analysis| {
                switch (emit_analysis) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-analysis=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-analysis\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-analysis\x00");
                    },
                }
            }
            if (build.emit_implib) |emit_implib| {
                switch (emit_implib) {
                    .yes => |yes_optional_arg| {
                        if (yes_optional_arg) |yes_arg| {
                            array.writeMany("-femit-implib=");
                            array.writeAny(fmt_spec, yes_arg);
                            array.writeOne(0);
                        } else {
                            array.writeMany("-femit-implib\x00");
                        }
                    },
                    .no => {
                        array.writeMany("-fno-emit-implib\x00");
                    },
                }
            }
            if (build.show_builtin) {
                array.writeMany("--show-builtin\x00");
            }
            if (build.cache_dir) |how| {
                array.writeMany("--cache-dir\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.global_cache_dir) |how| {
                array.writeMany("--global-cache-dir\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.zig_lib_dir) |how| {
                array.writeMany("--zig-lib-dir\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.enable_cache) {
                array.writeMany("--enable-cache\x00");
            }
            if (build.target) |how| {
                array.writeMany("-target\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.cpu) |how| {
                array.writeMany("-mcpu\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.cmodel) |how| {
                array.writeMany("-mcmodel\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.red_zone) |red_zone| {
                if (red_zone) {
                    array.writeMany("-mred-zone\x00");
                } else {
                    array.writeMany("-mno-red-zone\x00");
                }
            }
            if (build.omit_frame_pointer) |omit_frame_pointer| {
                if (omit_frame_pointer) {
                    array.writeMany("-fomit-frame-pointer\x00");
                } else {
                    array.writeMany("-fno-omit-frame-pointer\x00");
                }
            }
            if (build.exec_model) |how| {
                array.writeMany("-mexec-model\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.name) |how| {
                array.writeMany("--name\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.O) |how| {
                array.writeMany("-O\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.main_pkg_path) |how| {
                array.writeMany("--main-pkg-path\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.pic) |pic| {
                if (pic) {
                    array.writeMany("-fPIC\x00");
                } else {
                    array.writeMany("-fno-PIC\x00");
                }
            }
            if (build.pie) |pie| {
                if (pie) {
                    array.writeMany("-fPIE\x00");
                } else {
                    array.writeMany("-fno-PIE\x00");
                }
            }
            if (build.lto) |lto| {
                if (lto) {
                    array.writeMany("-flto\x00");
                } else {
                    array.writeMany("-fno-lto\x00");
                }
            }
            if (build.stack_check) |stack_check| {
                if (stack_check) {
                    array.writeMany("-fstack-check\x00");
                } else {
                    array.writeMany("-fno-stack-check\x00");
                }
            }
            if (build.sanitize_c) |sanitize_c| {
                if (sanitize_c) {
                    array.writeMany("-fsanitize-c\x00");
                } else {
                    array.writeMany("-fno-sanitize-c\x00");
                }
            }
            if (build.valgrind) |valgrind| {
                if (valgrind) {
                    array.writeMany("-fvalgrind\x00");
                } else {
                    array.writeMany("-fno-valgrind\x00");
                }
            }
            if (build.sanitize_thread) |sanitize_thread| {
                if (sanitize_thread) {
                    array.writeMany("-fsanitize-thread\x00");
                } else {
                    array.writeMany("-fno-sanitize-thread\x00");
                }
            }
            if (build.dll_export_fns) |dll_export_fns| {
                if (dll_export_fns) {
                    array.writeMany("-fdll-export-fns\x00");
                } else {
                    array.writeMany("-fno-dll-export-fns\x00");
                }
            }
            if (build.unwind_tables) |unwind_tables| {
                if (unwind_tables) {
                    array.writeMany("-funwind-tables\x00");
                } else {
                    array.writeMany("-fno-unwind-tables\x00");
                }
            }
            if (build.llvm) |llvm| {
                if (llvm) {
                    array.writeMany("-fLLVM\x00");
                } else {
                    array.writeMany("-fno-LLVM\x00");
                }
            }
            if (build.clang) |clang| {
                if (clang) {
                    array.writeMany("-fClang\x00");
                } else {
                    array.writeMany("-fno-Clang\x00");
                }
            }
            if (build.stage1) |stage1| {
                if (stage1) {
                    array.writeMany("-fstage1\x00");
                } else {
                    array.writeMany("-fno-stage1\x00");
                }
            }
            if (build.single_threaded) |single_threaded| {
                if (single_threaded) {
                    array.writeMany("-fsingle-threaded\x00");
                } else {
                    array.writeMany("-fno-single-threaded\x00");
                }
            }
            if (build.builtin) {
                array.writeMany("-fbuiltin\x00");
            }
            if (build.function_sections) |function_sections| {
                if (function_sections) {
                    array.writeMany("-ffunction-sections\x00");
                } else {
                    array.writeMany("-fno-function-sections\x00");
                }
            }
            if (build.strip) |strip| {
                if (strip) {
                    array.writeMany("-fstrip\x00");
                } else {
                    array.writeMany("-fno-strip\x00");
                }
            }
            if (build.fmt) |how| {
                array.writeMany("-ofmt\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.dirafter) |how| {
                array.writeMany("-dirafter\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.system) |how| {
                array.writeMany("-isystem\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.include) |how| {
                array.writeMany("-I\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.macros) |how| {
                array.writeAny(fmt_spec, how);
            }
            if (build.packages) |how| {
                array.writeAny(fmt_spec, how);
            }
            if (build.soname) |soname| {
                switch (soname) {
                    .yes => |yes_arg| {
                        array.writeMany("-fsoname\x00");
                        array.writeAny(fmt_spec, yes_arg);
                        array.writeOne(0);
                    },
                    .no => {
                        array.writeMany("-fno-soname\x00");
                    },
                }
            }
            if (build.dynamic) {
                array.writeMany("-dynamic\x00");
            }
            if (build.static) {
                array.writeMany("-static\x00");
            }
            if (build.gc_sections) |gc_sections| {
                if (gc_sections) {
                    array.writeMany("--gc-sections\x00");
                } else {
                    array.writeMany("--no-gc-sections\x00");
                }
            }
            if (build.stack) |how| {
                array.writeMany("--stack\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }
            if (build.z) |how| {
                array.writeMany("-z\x00");
                array.writeAny(fmt_spec, how);
                array.writeOne(0);
            }

            array.writeMany(build.root);
            array.writeOne('\x00');
            return countArgs(array);
        }

        pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
            var array: String = try meta.wrap(String.init(allocator, build.buildLength()));
            defer array.deinit(allocator);
            var args: Pointers = try meta.wrap(Pointers.init(allocator, build.buildWrite(&array)));
            builtin.assertAboveOrEqual(u64, spec.max_args, makeArgs(array, &args));
            builtin.assertAboveOrEqual(u64, spec.max_len, array.len());
            defer args.deinit(allocator);
            return genericExec(args.referAllDefined(), vars);
        }
        pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
            var array: StaticString = .{};
            var args: StaticPointers = .{};
            _ = build.buildWrite(&array);
            _ = makeArgs(&array, &args);
            return genericExec(args.referAllDefined(), vars);
        }
        fn genericExec(args: [][*:0]u8, vars: [][*:0]u8) !u64 {
            const dir_fd: u64 = try file.find(vars, Builder.zig);
            defer file.close(.{ .errors = null }, dir_fd);
            return proc.commandAt(.{}, dir_fd, Builder.zig, args, vars);
        }
    };
}
/// Environment variables needed to find user home directory
pub fn zigCacheDirGlobal(vars: [][*:0]u8, buf: [:0]u8) ![:0]u8 {
    const home_pathname: [:0]const u8 = try file.home(vars);
    var len: u64 = 0;
    for (home_pathname) |c, i| buf[len + i] = c;
    len += home_pathname.len;
    for ("/.cache/zig") |c, i| buf[len + i] = c;
    return buf[0 .. len + 11 :0];
}
fn countArgs(array: anytype) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count += 1;
        }
    }
    return count + 1;
}
fn makeArgs(array: anytype, args: anytype) u64 {
    var index: u64 = 0;
    for (array.readAll()) |value, i| {
        if (value == 0) {
            args.writeOne(array.referManyWithSentinelAt(index, 0).ptr);
            index = i + 1;
        }
    }
    if (args.len() != 0) {
        mem.set(args.impl.next(), @as(u64, 0), 1);
    }
    return args.len();
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
