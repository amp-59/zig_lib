const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks3.zig");
fn FormatMap(comptime T: type) type {
    switch (T) {
        []const types.ModuleDependency => return types.ModuleDependencies,
        []const types.Path => return types.Files,
        []const types.Macro => return types.Macros,
        []const types.Module => return types.Modules,
        else => @compileError(@typeName(T)),
    }
}
fn formatMap(any: anytype) FormatMap(@TypeOf(any)) {
    return .{ .value = any };
}
pub fn buildWriteBuf(cmd: *const tasks.BuildCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len = len +% 1;
    @memcpy(buf + len, "build-", 6);
    len = len +% 6;
    @memcpy(buf + len, @tagName(cmd.kind).ptr, @tagName(cmd.kind).len);
    len = len +% @tagName(cmd.kind).len;
    buf[len] = 0;
    len = len +% 1;
    if (cmd.color) |color| {
        @memcpy(buf + len, "--color\x00", 8);
        len = len +% 8;
        @memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-bin=", 11);
                    len = len +% 11;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-bin\x00", 11);
                    len = len +% 11;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-bin\x00", 14);
                len = len +% 14;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-asm=", 11);
                    len = len +% 11;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-asm\x00", 11);
                    len = len +% 11;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-asm\x00", 14);
                len = len +% 14;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-llvm-ir=", 15);
                    len = len +% 15;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-llvm-ir\x00", 15);
                    len = len +% 15;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-llvm-ir\x00", 18);
                len = len +% 18;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-llvm-bc=", 15);
                    len = len +% 15;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-llvm-bc\x00", 15);
                    len = len +% 15;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-llvm-bc\x00", 18);
                len = len +% 18;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-h=", 9);
                    len = len +% 9;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-h\x00", 9);
                    len = len +% 9;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-h\x00", 12);
                len = len +% 12;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-docs=", 12);
                    len = len +% 12;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-docs\x00", 12);
                    len = len +% 12;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-docs\x00", 15);
                len = len +% 15;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-analysis=", 16);
                    len = len +% 16;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-analysis\x00", 16);
                    len = len +% 16;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-analysis\x00", 19);
                len = len +% 19;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    @memcpy(buf + len, "-femit-implib=", 14);
                    len = len +% 14;
                    len = len +% yes_optional_arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-implib\x00", 14);
                    len = len +% 14;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-implib\x00", 17);
                len = len +% 17;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        @memcpy(buf + len, "--cache-dir\x00", 12);
        len = len +% 12;
        @memcpy(buf + len, cache_root.ptr, cache_root.len);
        len = len +% cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        @memcpy(buf + len, "--global-cache-dir\x00", 19);
        len = len +% 19;
        @memcpy(buf + len, global_cache_root.ptr, global_cache_root.len);
        len = len +% global_cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        @memcpy(buf + len, "--zig-lib-dir\x00", 14);
        len = len +% 14;
        @memcpy(buf + len, zig_lib_root.ptr, zig_lib_root.len);
        len = len +% zig_lib_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.listen) |listen| {
        @memcpy(buf + len, "--listen\x00", 9);
        len = len +% 9;
        @memcpy(buf + len, @tagName(listen).ptr, @tagName(listen).len);
        len = len +% @tagName(listen).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.target) |target| {
        @memcpy(buf + len, "-target\x00", 8);
        len = len +% 8;
        @memcpy(buf + len, target.ptr, target.len);
        len = len +% target.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.cpu) |cpu| {
        @memcpy(buf + len, "-mcpu\x00", 6);
        len = len +% 6;
        @memcpy(buf + len, cpu.ptr, cpu.len);
        len = len +% cpu.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.code_model) |code_model| {
        @memcpy(buf + len, "-mcmodel\x00", 9);
        len = len +% 9;
        @memcpy(buf + len, @tagName(code_model).ptr, @tagName(code_model).len);
        len = len +% @tagName(code_model).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            @memcpy(buf + len, "-mred-zone\x00", 11);
            len = len +% 11;
        } else {
            @memcpy(buf + len, "-mno-red-zone\x00", 14);
            len = len +% 14;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            @memcpy(buf + len, "-fomit-frame-pointer\x00", 21);
            len = len +% 21;
        } else {
            @memcpy(buf + len, "-fno-omit-frame-pointer\x00", 24);
            len = len +% 24;
        }
    }
    if (cmd.exec_model) |exec_model| {
        @memcpy(buf + len, "-mexec-model\x00", 13);
        len = len +% 13;
        @memcpy(buf + len, exec_model.ptr, exec_model.len);
        len = len +% exec_model.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.name) |name| {
        @memcpy(buf + len, "--name\x00", 7);
        len = len +% 7;
        @memcpy(buf + len, name.ptr, name.len);
        len = len +% name.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |yes_arg| {
                @memcpy(buf + len, "-fsoname\x00", 9);
                len = len +% 9;
                @memcpy(buf + len, yes_arg.ptr, yes_arg.len);
                len = len +% yes_arg.len;
                buf[len] = 0;
                len = len +% 1;
            },
            .no => {
                @memcpy(buf + len, "-fno-soname\x00", 12);
                len = len +% 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        @memcpy(buf + len, "-O\x00", 3);
        len = len +% 3;
        @memcpy(buf + len, @tagName(mode).ptr, @tagName(mode).len);
        len = len +% @tagName(mode).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        @memcpy(buf + len, "--main-pkg-path\x00", 16);
        len = len +% 16;
        @memcpy(buf + len, main_pkg_path.ptr, main_pkg_path.len);
        len = len +% main_pkg_path.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            @memcpy(buf + len, "-fPIC\x00", 6);
            len = len +% 6;
        } else {
            @memcpy(buf + len, "-fno-PIC\x00", 9);
            len = len +% 9;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            @memcpy(buf + len, "-fPIE\x00", 6);
            len = len +% 6;
        } else {
            @memcpy(buf + len, "-fno-PIE\x00", 9);
            len = len +% 9;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            @memcpy(buf + len, "-flto\x00", 6);
            len = len +% 6;
        } else {
            @memcpy(buf + len, "-fno-lto\x00", 9);
            len = len +% 9;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            @memcpy(buf + len, "-fstack-check\x00", 14);
            len = len +% 14;
        } else {
            @memcpy(buf + len, "-fno-stack-check\x00", 17);
            len = len +% 17;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            @memcpy(buf + len, "-fstack-check\x00", 14);
            len = len +% 14;
        } else {
            @memcpy(buf + len, "-fno-stack-protector\x00", 21);
            len = len +% 21;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            @memcpy(buf + len, "-fsanitize-c\x00", 13);
            len = len +% 13;
        } else {
            @memcpy(buf + len, "-fno-sanitize-c\x00", 16);
            len = len +% 16;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            @memcpy(buf + len, "-fvalgrind\x00", 11);
            len = len +% 11;
        } else {
            @memcpy(buf + len, "-fno-valgrind\x00", 14);
            len = len +% 14;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            @memcpy(buf + len, "-fsanitize-thread\x00", 18);
            len = len +% 18;
        } else {
            @memcpy(buf + len, "-fno-sanitize-thread\x00", 21);
            len = len +% 21;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            @memcpy(buf + len, "-funwind-tables\x00", 16);
            len = len +% 16;
        } else {
            @memcpy(buf + len, "-fno-unwind-tables\x00", 19);
            len = len +% 19;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            @memcpy(buf + len, "-fLLVM\x00", 7);
            len = len +% 7;
        } else {
            @memcpy(buf + len, "-fno-LLVM\x00", 10);
            len = len +% 10;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            @memcpy(buf + len, "-fClang\x00", 8);
            len = len +% 8;
        } else {
            @memcpy(buf + len, "-fno-Clang\x00", 11);
            len = len +% 11;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            @memcpy(buf + len, "-freference-trace\x00", 18);
            len = len +% 18;
        } else {
            @memcpy(buf + len, "-fno-reference-trace\x00", 21);
            len = len +% 21;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            @memcpy(buf + len, "-ferror-tracing\x00", 16);
            len = len +% 16;
        } else {
            @memcpy(buf + len, "-fno-error-tracing\x00", 19);
            len = len +% 19;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            @memcpy(buf + len, "-fsingle-threaded\x00", 18);
            len = len +% 18;
        } else {
            @memcpy(buf + len, "-fno-single-threaded\x00", 21);
            len = len +% 21;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            @memcpy(buf + len, "-ffunction-sections\x00", 20);
            len = len +% 20;
        } else {
            @memcpy(buf + len, "-fno-function-sections\x00", 23);
            len = len +% 23;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            @memcpy(buf + len, "-fstrip\x00", 8);
            len = len +% 8;
        } else {
            @memcpy(buf + len, "-fno-strip\x00", 11);
            len = len +% 11;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            @memcpy(buf + len, "-fformatted-panics\x00", 19);
            len = len +% 19;
        } else {
            @memcpy(buf + len, "-fno-formatted-panics\x00", 22);
            len = len +% 22;
        }
    }
    if (cmd.format) |format| {
        @memcpy(buf + len, "-ofmt\x00", 6);
        len = len +% 6;
        @memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len = len +% @tagName(format).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dirafter) |dirafter| {
        @memcpy(buf + len, "-dirafter\x00", 10);
        len = len +% 10;
        @memcpy(buf + len, dirafter.ptr, dirafter.len);
        len = len +% dirafter.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.system) |system| {
        @memcpy(buf + len, "-isystem\x00", 9);
        len = len +% 9;
        @memcpy(buf + len, system.ptr, system.len);
        len = len +% system.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.include) |include| {
        @memcpy(buf + len, "-I\x00", 3);
        len = len +% 3;
        @memcpy(buf + len, include.ptr, include.len);
        len = len +% include.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.libc) |libc| {
        @memcpy(buf + len, "--libc\x00", 7);
        len = len +% 7;
        @memcpy(buf + len, libc.ptr, libc.len);
        len = len +% libc.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.library) |library| {
        @memcpy(buf + len, "--library\x00", 10);
        len = len +% 10;
        @memcpy(buf + len, library.ptr, library.len);
        len = len +% library.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.needed_library) |needed_library| {
        @memcpy(buf + len, "--needed-library\x00", 17);
        len = len +% 17;
        @memcpy(buf + len, needed_library.ptr, needed_library.len);
        len = len +% needed_library.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.library_directory) |library_directory| {
        @memcpy(buf + len, "--library-directory\x00", 20);
        len = len +% 20;
        @memcpy(buf + len, library_directory.ptr, library_directory.len);
        len = len +% library_directory.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.link_script) |link_script| {
        @memcpy(buf + len, "--script\x00", 9);
        len = len +% 9;
        @memcpy(buf + len, link_script.ptr, link_script.len);
        len = len +% link_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.version_script) |version_script| {
        @memcpy(buf + len, "--version-script\x00", 17);
        len = len +% 17;
        @memcpy(buf + len, version_script.ptr, version_script.len);
        len = len +% version_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        @memcpy(buf + len, "--dynamic-linker\x00", 17);
        len = len +% 17;
        @memcpy(buf + len, dynamic_linker.ptr, dynamic_linker.len);
        len = len +% dynamic_linker.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.sysroot) |sysroot| {
        @memcpy(buf + len, "--sysroot\x00", 10);
        len = len +% 10;
        @memcpy(buf + len, sysroot.ptr, sysroot.len);
        len = len +% sysroot.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.entry) |entry| {
        @memcpy(buf + len, "--entry\x00", 8);
        len = len +% 8;
        @memcpy(buf + len, entry.ptr, entry.len);
        len = len +% entry.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            @memcpy(buf + len, "-fLLD\x00", 6);
            len = len +% 6;
        } else {
            @memcpy(buf + len, "-fno-LLD\x00", 9);
            len = len +% 9;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            @memcpy(buf + len, "-fcompiler-rt\x00", 14);
            len = len +% 14;
        } else {
            @memcpy(buf + len, "-fno-compiler-rt\x00", 17);
            len = len +% 17;
        }
    }
    if (cmd.rpath) |rpath| {
        @memcpy(buf + len, "-rpath\x00", 7);
        len = len +% 7;
        @memcpy(buf + len, rpath.ptr, rpath.len);
        len = len +% rpath.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            @memcpy(buf + len, "-feach-lib-rpath\x00", 17);
            len = len +% 17;
        } else {
            @memcpy(buf + len, "-fno-each-lib-rpath\x00", 20);
            len = len +% 20;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            @memcpy(buf + len, "-fallow-shlib-undefined\x00", 24);
            len = len +% 24;
        } else {
            @memcpy(buf + len, "-fno-allow-shlib-undefined\x00", 27);
            len = len +% 27;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            @memcpy(buf + len, "-fbuild-id\x00", 11);
            len = len +% 11;
        } else {
            @memcpy(buf + len, "-fno-build-id\x00", 14);
            len = len +% 14;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        @memcpy(buf + len, "--compress-debug-sections\x00", 26);
        len = len +% 26;
        @memcpy(buf + len, @tagName(compress_debug_sections).ptr, @tagName(compress_debug_sections).len);
        len = len +% @tagName(compress_debug_sections).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            @memcpy(buf + len, "--gc-sections\x00", 14);
            len = len +% 14;
        } else {
            @memcpy(buf + len, "--no-gc-sections\x00", 17);
            len = len +% 17;
        }
    }
    if (cmd.stack) |stack| {
        @memcpy(buf + len, "--stack\x00", 8);
        len = len +% 8;
        const s: []const u8 = builtin.fmt.ud64(stack).readAll();
        @memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.image_base) |image_base| {
        @memcpy(buf + len, "--image-base\x00", 13);
        len = len +% 13;
        const s: []const u8 = builtin.fmt.ud64(image_base).readAll();
        @memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.macros) |macros| {
        len = len +% formatMap(macros).formatWriteBuf(buf + len);
    }
    if (cmd.modules) |modules| {
        len = len +% formatMap(modules).formatWriteBuf(buf + len);
    }
    if (cmd.dependencies) |dependencies| {
        len = len +% formatMap(dependencies).formatWriteBuf(buf + len);
    }
    if (cmd.cflags) |cflags| {
        len = len +% cflags.formatWriteBuf(buf + len);
    }
    if (cmd.link_libc) {
        @memcpy(buf + len, "-lc\x00", 4);
        len = len +% 4;
    }
    if (cmd.rdynamic) {
        @memcpy(buf + len, "-rdynamic\x00", 10);
        len = len +% 10;
    }
    if (cmd.dynamic) {
        @memcpy(buf + len, "-dynamic\x00", 9);
        len = len +% 9;
    }
    if (cmd.static) {
        @memcpy(buf + len, "-static\x00", 8);
        len = len +% 8;
    }
    if (cmd.symbolic) {
        @memcpy(buf + len, "-Bsymbolic\x00", 11);
        len = len +% 11;
    }
    if (cmd.z) |z| {
        @memcpy(buf + len, "-z\x00", 3);
        len = len +% 3;
        @memcpy(buf + len, @tagName(z).ptr, @tagName(z).len);
        len = len +% @tagName(z).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.files) |files| {
        len = len +% formatMap(files).formatWriteBuf(buf + len);
    }
    if (cmd.time_report) {
        @memcpy(buf + len, "-ftime-report\x00", 14);
        len = len +% 14;
    }
    if (cmd.stack_report) {
        @memcpy(buf + len, "-fstack-report\x00", 15);
        len = len +% 15;
    }
    if (cmd.verbose_link) {
        @memcpy(buf + len, "--verbose-link\x00", 15);
        len = len +% 15;
    }
    if (cmd.verbose_cc) {
        @memcpy(buf + len, "--verbose-cc\x00", 13);
        len = len +% 13;
    }
    if (cmd.verbose_air) {
        @memcpy(buf + len, "--verbose-air\x00", 14);
        len = len +% 14;
    }
    if (cmd.verbose_mir) {
        @memcpy(buf + len, "--verbose-mir\x00", 14);
        len = len +% 14;
    }
    if (cmd.verbose_llvm_ir) {
        @memcpy(buf + len, "--verbose-llvm-ir\x00", 18);
        len = len +% 18;
    }
    if (cmd.verbose_cimport) {
        @memcpy(buf + len, "--verbose-cimport\x00", 18);
        len = len +% 18;
    }
    if (cmd.verbose_llvm_cpu_features) {
        @memcpy(buf + len, "--verbose-llvm-cpu-features\x00", 28);
        len = len +% 28;
    }
    if (cmd.debug_log) |debug_log| {
        @memcpy(buf + len, "--debug-log\x00", 12);
        len = len +% 12;
        @memcpy(buf + len, debug_log.ptr, debug_log.len);
        len = len +% debug_log.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_compiler_errors) {
        @memcpy(buf + len, "--debug-compile-errors\x00", 23);
        len = len +% 23;
    }
    if (cmd.debug_link_snapshot) {
        @memcpy(buf + len, "--debug-link-snapshot\x00", 22);
        len = len +% 22;
    }
    len = len +% root_path.formatWriteBuf(buf + len);
    buf[len] = 0;
    return len;
}
pub fn buildLength(cmd: *const tasks.BuildCommand, zig_exe: []const u8, root_path: types.Path) u64 {
    @setRuntimeSafety(false);
    var len: u64 = zig_exe.len +% @tagName(cmd.kind).len +% 8;
    if (cmd.color) |color| {
        len = len +% 8;
        len = len +% @tagName(color).len;
        len = len +% 1;
    }
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 11;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 11;
                }
            },
            .no => {
                len = len +% 14;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 11;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 11;
                }
            },
            .no => {
                len = len +% 14;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 15;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 15;
                }
            },
            .no => {
                len = len +% 18;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 15;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 15;
                }
            },
            .no => {
                len = len +% 18;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 9;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 9;
                }
            },
            .no => {
                len = len +% 12;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 12;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 12;
                }
            },
            .no => {
                len = len +% 15;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 16;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 16;
                }
            },
            .no => {
                len = len +% 19;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes_arg| {
                if (yes_arg) |yes_optional_arg| {
                    len = len +% 14;
                    len = len +% yes_optional_arg.formatLength();
                } else {
                    len = len +% 14;
                }
            },
            .no => {
                len = len +% 17;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        len = len +% 12;
        len = len +% cache_root.len;
        len = len +% 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        len = len +% 19;
        len = len +% global_cache_root.len;
        len = len +% 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        len = len +% 14;
        len = len +% zig_lib_root.len;
        len = len +% 1;
    }
    if (cmd.listen) |listen| {
        len = len +% 9;
        len = len +% @tagName(listen).len;
        len = len +% 1;
    }
    if (cmd.target) |target| {
        len = len +% 8;
        len = len +% target.len;
        len = len +% 1;
    }
    if (cmd.cpu) |cpu| {
        len = len +% 6;
        len = len +% cpu.len;
        len = len +% 1;
    }
    if (cmd.code_model) |code_model| {
        len = len +% 9;
        len = len +% @tagName(code_model).len;
        len = len +% 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            len = len +% 11;
        } else {
            len = len +% 14;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            len = len +% 21;
        } else {
            len = len +% 24;
        }
    }
    if (cmd.exec_model) |exec_model| {
        len = len +% 13;
        len = len +% exec_model.len;
        len = len +% 1;
    }
    if (cmd.name) |name| {
        len = len +% 7;
        len = len +% name.len;
        len = len +% 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |yes_arg| {
                len = len +% 9;
                len = len +% yes_arg.len;
                len = len +% 1;
            },
            .no => {
                len = len +% 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        len = len +% 3;
        len = len +% @tagName(mode).len;
        len = len +% 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        len = len +% 16;
        len = len +% main_pkg_path.len;
        len = len +% 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            len = len +% 6;
        } else {
            len = len +% 9;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            len = len +% 6;
        } else {
            len = len +% 9;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            len = len +% 6;
        } else {
            len = len +% 9;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            len = len +% 14;
        } else {
            len = len +% 17;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            len = len +% 14;
        } else {
            len = len +% 21;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            len = len +% 13;
        } else {
            len = len +% 16;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            len = len +% 11;
        } else {
            len = len +% 14;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            len = len +% 18;
        } else {
            len = len +% 21;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            len = len +% 16;
        } else {
            len = len +% 19;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            len = len +% 7;
        } else {
            len = len +% 10;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            len = len +% 8;
        } else {
            len = len +% 11;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            len = len +% 18;
        } else {
            len = len +% 21;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            len = len +% 16;
        } else {
            len = len +% 19;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            len = len +% 18;
        } else {
            len = len +% 21;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            len = len +% 20;
        } else {
            len = len +% 23;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            len = len +% 8;
        } else {
            len = len +% 11;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            len = len +% 19;
        } else {
            len = len +% 22;
        }
    }
    if (cmd.format) |format| {
        len = len +% 6;
        len = len +% @tagName(format).len;
        len = len +% 1;
    }
    if (cmd.dirafter) |dirafter| {
        len = len +% 10;
        len = len +% dirafter.len;
        len = len +% 1;
    }
    if (cmd.system) |system| {
        len = len +% 9;
        len = len +% system.len;
        len = len +% 1;
    }
    if (cmd.include) |include| {
        len = len +% 3;
        len = len +% include.len;
        len = len +% 1;
    }
    if (cmd.libc) |libc| {
        len = len +% 7;
        len = len +% libc.len;
        len = len +% 1;
    }
    if (cmd.library) |library| {
        len = len +% 10;
        len = len +% library.len;
        len = len +% 1;
    }
    if (cmd.needed_library) |needed_library| {
        len = len +% 17;
        len = len +% needed_library.len;
        len = len +% 1;
    }
    if (cmd.library_directory) |library_directory| {
        len = len +% 20;
        len = len +% library_directory.len;
        len = len +% 1;
    }
    if (cmd.link_script) |link_script| {
        len = len +% 9;
        len = len +% link_script.len;
        len = len +% 1;
    }
    if (cmd.version_script) |version_script| {
        len = len +% 17;
        len = len +% version_script.len;
        len = len +% 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        len = len +% 17;
        len = len +% dynamic_linker.len;
        len = len +% 1;
    }
    if (cmd.sysroot) |sysroot| {
        len = len +% 10;
        len = len +% sysroot.len;
        len = len +% 1;
    }
    if (cmd.entry) |entry| {
        len = len +% 8;
        len = len +% entry.len;
        len = len +% 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            len = len +% 6;
        } else {
            len = len +% 9;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            len = len +% 14;
        } else {
            len = len +% 17;
        }
    }
    if (cmd.rpath) |rpath| {
        len = len +% 7;
        len = len +% rpath.len;
        len = len +% 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            len = len +% 17;
        } else {
            len = len +% 20;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            len = len +% 24;
        } else {
            len = len +% 27;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            len = len +% 11;
        } else {
            len = len +% 14;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        len = len +% 26;
        len = len +% @tagName(compress_debug_sections).len;
        len = len +% 1;
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            len = len +% 14;
        } else {
            len = len +% 17;
        }
    }
    if (cmd.stack) |stack| {
        len = len +% 8;
        len = len +% builtin.fmt.ud64(stack).readAll().len;
        len = len +% 1;
    }
    if (cmd.image_base) |image_base| {
        len = len +% 13;
        len = len +% builtin.fmt.ud64(image_base).readAll().len;
        len = len +% 1;
    }
    if (cmd.macros) |macros| {
        len = len +% formatMap(macros).formatLength();
    }
    if (cmd.modules) |modules| {
        len = len +% formatMap(modules).formatLength();
    }
    if (cmd.dependencies) |dependencies| {
        len = len +% formatMap(dependencies).formatLength();
    }
    if (cmd.cflags) |cflags| {
        len = len +% cflags.formatLength();
    }
    if (cmd.link_libc) {
        len = len +% 4;
    }
    if (cmd.rdynamic) {
        len = len +% 10;
    }
    if (cmd.dynamic) {
        len = len +% 9;
    }
    if (cmd.static) {
        len = len +% 8;
    }
    if (cmd.symbolic) {
        len = len +% 11;
    }
    if (cmd.z) |z| {
        len = len +% 3;
        len = len +% @tagName(z).len;
        len = len +% 1;
    }
    if (cmd.files) |files| {
        len = len +% formatMap(files).formatLength();
    }
    if (cmd.time_report) {
        len = len +% 14;
    }
    if (cmd.stack_report) {
        len = len +% 15;
    }
    if (cmd.verbose_link) {
        len = len +% 15;
    }
    if (cmd.verbose_cc) {
        len = len +% 13;
    }
    if (cmd.verbose_air) {
        len = len +% 14;
    }
    if (cmd.verbose_mir) {
        len = len +% 14;
    }
    if (cmd.verbose_llvm_ir) {
        len = len +% 18;
    }
    if (cmd.verbose_cimport) {
        len = len +% 18;
    }
    if (cmd.verbose_llvm_cpu_features) {
        len = len +% 28;
    }
    if (cmd.debug_log) |debug_log| {
        len = len +% 12;
        len = len +% debug_log.len;
        len = len +% 1;
    }
    if (cmd.debug_compiler_errors) {
        len = len +% 23;
    }
    if (cmd.debug_link_snapshot) {
        len = len +% 22;
    }
    return len +% root_path.formatLength() +% 1;
}
pub fn formatWriteBuf(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @setRuntimeSafety(false);
    @memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len = len +% 1;
    @memcpy(buf + len, "fmt\\x00", 4);
    len = len +% 4;
    if (cmd.color) |color| {
        @memcpy(buf + len, "--color\x00", 8);
        len = len +% 8;
        @memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.stdin) {
        @memcpy(buf + len, "--stdin\x00", 8);
        len = len +% 8;
    }
    if (cmd.check) {
        @memcpy(buf + len, "--check\x00", 8);
        len = len +% 8;
    }
    if (cmd.ast_check) {
        @memcpy(buf + len, "--ast-check\x00", 12);
        len = len +% 12;
    }
    if (cmd.exclude) |exclude| {
        @memcpy(buf + len, "--exclude\x00", 10);
        len = len +% 10;
        @memcpy(buf + len, exclude.ptr, exclude.len);
        len = len +% exclude.len;
        buf[len] = 0;
        len = len +% 1;
    }
    len = len +% root_path.formatWriteBuf(buf + len);
    buf[len] = 0;
    return len;
}
pub fn formatLength(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path) u64 {
    @setRuntimeSafety(false);
    var len: u64 = zig_exe.len +% 5;
    if (cmd.color) |color| {
        len = len +% 8;
        len = len +% @tagName(color).len;
        len = len +% 1;
    }
    if (cmd.stdin) {
        len = len +% 8;
    }
    if (cmd.check) {
        len = len +% 8;
    }
    if (cmd.ast_check) {
        len = len +% 12;
    }
    if (cmd.exclude) |exclude| {
        len = len +% 10;
        len = len +% exclude.len;
        len = len +% 1;
    }
    return len +% root_path.formatLength() +% 1;
}
