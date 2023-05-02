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
        []const []const u8 => return types.CFlags,
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
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-bin", 10);
                    len = len +% 10;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-bin", 10);
                    len = len +% 10;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-bin", 13);
                len = len +% 13;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-asm", 10);
                    len = len +% 10;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-asm", 10);
                    len = len +% 10;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-asm", 13);
                len = len +% 13;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-llvm-ir", 14);
                    len = len +% 14;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-llvm-ir", 14);
                    len = len +% 14;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-llvm-ir", 17);
                len = len +% 17;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-llvm-bc", 14);
                    len = len +% 14;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-llvm-bc", 14);
                    len = len +% 14;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-llvm-bc", 17);
                len = len +% 17;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-h", 8);
                    len = len +% 8;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-h", 8);
                    len = len +% 8;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-h", 11);
                len = len +% 11;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-docs", 11);
                    len = len +% 11;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-docs", 11);
                    len = len +% 11;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-docs", 14);
                len = len +% 14;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-analysis", 15);
                    len = len +% 15;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-analysis", 15);
                    len = len +% 15;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-analysis", 18);
                len = len +% 18;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    @memcpy(buf + len, "-femit-implib", 13);
                    len = len +% 13;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @memcpy(buf + len, "-femit-implib", 13);
                    len = len +% 13;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @memcpy(buf + len, "-fno-emit-implib", 16);
                len = len +% 16;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        @memcpy(buf + len, "--cache-dir", 11);
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, cache_root.ptr, cache_root.len);
        len = len +% cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        @memcpy(buf + len, "--global-cache-dir", 18);
        len = len +% 18;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, global_cache_root.ptr, global_cache_root.len);
        len = len +% global_cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        @memcpy(buf + len, "--zig-lib-dir", 13);
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, zig_lib_root.ptr, zig_lib_root.len);
        len = len +% zig_lib_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.listen) |listen| {
        @memcpy(buf + len, "--listen", 8);
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, @tagName(listen).ptr, @tagName(listen).len);
        len = len +% @tagName(listen).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.target) |target| {
        @memcpy(buf + len, "-target", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, target.ptr, target.len);
        len = len +% target.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.cpu) |cpu| {
        @memcpy(buf + len, "-mcpu", 5);
        len = len +% 5;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, cpu.ptr, cpu.len);
        len = len +% cpu.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.code_model) |code_model| {
        @memcpy(buf + len, "-mcmodel", 8);
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, @tagName(code_model).ptr, @tagName(code_model).len);
        len = len +% @tagName(code_model).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            @memcpy(buf + len, "-mred-zone", 10);
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-mno-red-zone", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            @memcpy(buf + len, "-fomit-frame-pointer", 20);
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-omit-frame-pointer", 23);
            len = len +% 23;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.exec_model) |exec_model| {
        @memcpy(buf + len, "-mexec-model", 12);
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, exec_model.ptr, exec_model.len);
        len = len +% exec_model.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.name) |name| {
        @memcpy(buf + len, "--name", 6);
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, name.ptr, name.len);
        len = len +% name.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                @memcpy(buf + len, "-fsoname", 8);
                len = len +% 8;
                buf[len] = 0;
                len = len +% 1;
                @memcpy(buf + len, arg.ptr, arg.len);
                len = len +% arg.len;
                buf[len] = 0;
                len = len +% 1;
            },
            .no => {
                @memcpy(buf + len, "-fno-soname", 11);
                len = len +% 11;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.mode) |mode| {
        @memcpy(buf + len, "-O", 2);
        len = len +% 2;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, @tagName(mode).ptr, @tagName(mode).len);
        len = len +% @tagName(mode).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        @memcpy(buf + len, "--main-pkg-path", 15);
        len = len +% 15;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, main_pkg_path.ptr, main_pkg_path.len);
        len = len +% main_pkg_path.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            @memcpy(buf + len, "-fPIC", 5);
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-PIC", 8);
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            @memcpy(buf + len, "-fPIE", 5);
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-PIE", 8);
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            @memcpy(buf + len, "-flto", 5);
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-lto", 8);
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            @memcpy(buf + len, "-fstack-check", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-stack-check", 16);
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            @memcpy(buf + len, "-fstack-check", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-stack-protector", 20);
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            @memcpy(buf + len, "-fsanitize-c", 12);
            len = len +% 12;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-sanitize-c", 15);
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            @memcpy(buf + len, "-fvalgrind", 10);
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-valgrind", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            @memcpy(buf + len, "-fsanitize-thread", 17);
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-sanitize-thread", 20);
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            @memcpy(buf + len, "-funwind-tables", 15);
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-unwind-tables", 18);
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            @memcpy(buf + len, "-fLLVM", 6);
            len = len +% 6;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-LLVM", 9);
            len = len +% 9;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            @memcpy(buf + len, "-fClang", 7);
            len = len +% 7;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-Clang", 10);
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            @memcpy(buf + len, "-freference-trace", 17);
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-reference-trace", 20);
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            @memcpy(buf + len, "-ferror-tracing", 15);
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-error-tracing", 18);
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            @memcpy(buf + len, "-fsingle-threaded", 17);
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-single-threaded", 20);
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            @memcpy(buf + len, "-ffunction-sections", 19);
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-function-sections", 22);
            len = len +% 22;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            @memcpy(buf + len, "-fstrip", 7);
            len = len +% 7;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-strip", 10);
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            @memcpy(buf + len, "-fformatted-panics", 18);
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-formatted-panics", 21);
            len = len +% 21;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.format) |format| {
        @memcpy(buf + len, "-ofmt", 5);
        len = len +% 5;
        buf[len] = 61;
        len = len +% 1;
        @memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len = len +% @tagName(format).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dirafter) |dirafter| {
        @memcpy(buf + len, "-idirafter", 10);
        len = len +% 10;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, dirafter.ptr, dirafter.len);
        len = len +% dirafter.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.system) |system| {
        @memcpy(buf + len, "-isystem", 8);
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, system.ptr, system.len);
        len = len +% system.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.include) |include| {
        @memcpy(buf + len, "-I", 2);
        len = len +% 2;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, include.ptr, include.len);
        len = len +% include.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.libc) |libc| {
        @memcpy(buf + len, "--libc", 6);
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, libc.ptr, libc.len);
        len = len +% libc.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.library) |library| {
        @memcpy(buf + len, "--library", 9);
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, library.ptr, library.len);
        len = len +% library.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            @memcpy(buf + len, "--needed-library", 16);
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
            @memcpy(buf + len, value.ptr, value.len);
            len = len +% value.len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            @memcpy(buf + len, "--library-directory", 19);
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
            @memcpy(buf + len, value.ptr, value.len);
            len = len +% value.len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.link_script) |link_script| {
        @memcpy(buf + len, "--script", 8);
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, link_script.ptr, link_script.len);
        len = len +% link_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.version_script) |version_script| {
        @memcpy(buf + len, "--version-script", 16);
        len = len +% 16;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, version_script.ptr, version_script.len);
        len = len +% version_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        @memcpy(buf + len, "--dynamic-linker", 16);
        len = len +% 16;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, dynamic_linker.ptr, dynamic_linker.len);
        len = len +% dynamic_linker.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.sysroot) |sysroot| {
        @memcpy(buf + len, "--sysroot", 9);
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, sysroot.ptr, sysroot.len);
        len = len +% sysroot.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.entry) |entry| {
        @memcpy(buf + len, "--entry", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, entry.ptr, entry.len);
        len = len +% entry.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            @memcpy(buf + len, "-fLLD", 5);
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-LLD", 8);
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            @memcpy(buf + len, "-fcompiler-rt", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-compiler-rt", 16);
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.rpath) |rpath| {
        @memcpy(buf + len, "-rpath", 6);
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, rpath.ptr, rpath.len);
        len = len +% rpath.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            @memcpy(buf + len, "-feach-lib-rpath", 16);
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-each-lib-rpath", 19);
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            @memcpy(buf + len, "-fallow-shlib-undefined", 23);
            len = len +% 23;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-allow-shlib-undefined", 26);
            len = len +% 26;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            @memcpy(buf + len, "-fbuild-id", 10);
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "-fno-build-id", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            @memcpy(buf + len, "--compress-debug-sections=zlib", 30);
            len = len +% 30;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "--compress-debug-sections=none", 30);
            len = len +% 30;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            @memcpy(buf + len, "--gc-sections", 13);
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @memcpy(buf + len, "--no-gc-sections", 16);
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack) |stack| {
        @memcpy(buf + len, "--stack", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        const s: []const u8 = builtin.fmt.ud64(stack).readAll();
        @memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.image_base) |image_base| {
        @memcpy(buf + len, "--image-base", 12);
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
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
        len = len +% formatMap(cflags).formatWriteBuf(buf + len);
    }
    if (cmd.link_libc) {
        @memcpy(buf + len, "-lc", 3);
        len = len +% 3;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.rdynamic) {
        @memcpy(buf + len, "-rdynamic", 9);
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dynamic) {
        @memcpy(buf + len, "-dynamic", 8);
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.static) {
        @memcpy(buf + len, "-static", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.symbolic) {
        @memcpy(buf + len, "-Bsymbolic", 10);
        len = len +% 10;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            @memcpy(buf + len, "-z", 2);
            len = len +% 2;
            buf[len] = 0;
            len = len +% 1;
            @memcpy(buf + len, @tagName(value).ptr, @tagName(value).len);
            len = len +% @tagName(value).len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.files) |files| {
        len = len +% formatMap(files).formatWriteBuf(buf + len);
    }
    if (cmd.color) |color| {
        @memcpy(buf + len, "--color", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.time_report) {
        @memcpy(buf + len, "-ftime-report", 13);
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.stack_report) {
        @memcpy(buf + len, "-fstack-report", 14);
        len = len +% 14;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_link) {
        @memcpy(buf + len, "--verbose-link", 14);
        len = len +% 14;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_cc) {
        @memcpy(buf + len, "--verbose-cc", 12);
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_air) {
        @memcpy(buf + len, "--verbose-air", 13);
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_mir) {
        @memcpy(buf + len, "--verbose-mir", 13);
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_ir) {
        @memcpy(buf + len, "--verbose-llvm-ir", 17);
        len = len +% 17;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_cimport) {
        @memcpy(buf + len, "--verbose-cimport", 17);
        len = len +% 17;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_cpu_features) {
        @memcpy(buf + len, "--verbose-llvm-cpu-features", 27);
        len = len +% 27;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_log) |debug_log| {
        @memcpy(buf + len, "--debug-log", 11);
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, debug_log.ptr, debug_log.len);
        len = len +% debug_log.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_compiler_errors) {
        @memcpy(buf + len, "--debug-compile-errors", 22);
        len = len +% 22;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_link_snapshot) {
        @memcpy(buf + len, "--debug-link-snapshot", 21);
        len = len +% 21;
        buf[len] = 0;
        len = len +% 1;
    }
    len = len +% root_path.formatWriteBuf(buf + len);
    buf[len] = 0;
    return len;
}
pub fn buildLength(cmd: *const tasks.BuildCommand, zig_exe: []const u8, root_path: types.Path) u64 {
    @setRuntimeSafety(false);
    var len: u64 = zig_exe.len +% @tagName(cmd.kind).len +% 8;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 10;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 10;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 13;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 10;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 10;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 13;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 14;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 14;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 17;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 14;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 14;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 17;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 8;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 8;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 11;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 11;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 11;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 14;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 15;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 15;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 18;
                len = len +% 1;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    len = len +% 13;
                    len = len +% 1;
                    len = len +% arg.formatLength();
                } else {
                    len = len +% 13;
                    len = len +% 1;
                }
            },
            .no => {
                len = len +% 16;
                len = len +% 1;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        len = len +% 11;
        len = len +% 1;
        len = len +% cache_root.len;
        len = len +% 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        len = len +% 18;
        len = len +% 1;
        len = len +% global_cache_root.len;
        len = len +% 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        len = len +% 13;
        len = len +% 1;
        len = len +% zig_lib_root.len;
        len = len +% 1;
    }
    if (cmd.listen) |listen| {
        len = len +% 8;
        len = len +% 1;
        len = len +% @tagName(listen).len;
        len = len +% 1;
    }
    if (cmd.target) |target| {
        len = len +% 7;
        len = len +% 1;
        len = len +% target.len;
        len = len +% 1;
    }
    if (cmd.cpu) |cpu| {
        len = len +% 5;
        len = len +% 1;
        len = len +% cpu.len;
        len = len +% 1;
    }
    if (cmd.code_model) |code_model| {
        len = len +% 8;
        len = len +% 1;
        len = len +% @tagName(code_model).len;
        len = len +% 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            len = len +% 10;
            len = len +% 1;
        } else {
            len = len +% 13;
            len = len +% 1;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            len = len +% 20;
            len = len +% 1;
        } else {
            len = len +% 23;
            len = len +% 1;
        }
    }
    if (cmd.exec_model) |exec_model| {
        len = len +% 12;
        len = len +% 1;
        len = len +% exec_model.len;
        len = len +% 1;
    }
    if (cmd.name) |name| {
        len = len +% 6;
        len = len +% 1;
        len = len +% name.len;
        len = len +% 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                len = len +% 8;
                len = len +% 1;
                len = len +% arg.len;
                len = len +% 1;
            },
            .no => {
                len = len +% 11;
                len = len +% 1;
            },
        }
    }
    if (cmd.mode) |mode| {
        len = len +% 2;
        len = len +% 1;
        len = len +% @tagName(mode).len;
        len = len +% 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        len = len +% 15;
        len = len +% 1;
        len = len +% main_pkg_path.len;
        len = len +% 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            len = len +% 5;
            len = len +% 1;
        } else {
            len = len +% 8;
            len = len +% 1;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            len = len +% 5;
            len = len +% 1;
        } else {
            len = len +% 8;
            len = len +% 1;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            len = len +% 5;
            len = len +% 1;
        } else {
            len = len +% 8;
            len = len +% 1;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            len = len +% 13;
            len = len +% 1;
        } else {
            len = len +% 16;
            len = len +% 1;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            len = len +% 13;
            len = len +% 1;
        } else {
            len = len +% 20;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            len = len +% 12;
            len = len +% 1;
        } else {
            len = len +% 15;
            len = len +% 1;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            len = len +% 10;
            len = len +% 1;
        } else {
            len = len +% 13;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            len = len +% 17;
            len = len +% 1;
        } else {
            len = len +% 20;
            len = len +% 1;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            len = len +% 15;
            len = len +% 1;
        } else {
            len = len +% 18;
            len = len +% 1;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            len = len +% 6;
            len = len +% 1;
        } else {
            len = len +% 9;
            len = len +% 1;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            len = len +% 7;
            len = len +% 1;
        } else {
            len = len +% 10;
            len = len +% 1;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            len = len +% 17;
            len = len +% 1;
        } else {
            len = len +% 20;
            len = len +% 1;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            len = len +% 15;
            len = len +% 1;
        } else {
            len = len +% 18;
            len = len +% 1;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            len = len +% 17;
            len = len +% 1;
        } else {
            len = len +% 20;
            len = len +% 1;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            len = len +% 19;
            len = len +% 1;
        } else {
            len = len +% 22;
            len = len +% 1;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            len = len +% 7;
            len = len +% 1;
        } else {
            len = len +% 10;
            len = len +% 1;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            len = len +% 18;
            len = len +% 1;
        } else {
            len = len +% 21;
            len = len +% 1;
        }
    }
    if (cmd.format) |format| {
        len = len +% 5;
        len = len +% 1;
        len = len +% @tagName(format).len;
        len = len +% 1;
    }
    if (cmd.dirafter) |dirafter| {
        len = len +% 10;
        len = len +% 1;
        len = len +% dirafter.len;
        len = len +% 1;
    }
    if (cmd.system) |system| {
        len = len +% 8;
        len = len +% 1;
        len = len +% system.len;
        len = len +% 1;
    }
    if (cmd.include) |include| {
        len = len +% 2;
        len = len +% 1;
        len = len +% include.len;
        len = len +% 1;
    }
    if (cmd.libc) |libc| {
        len = len +% 6;
        len = len +% 1;
        len = len +% libc.len;
        len = len +% 1;
    }
    if (cmd.library) |library| {
        len = len +% 9;
        len = len +% 1;
        len = len +% library.len;
        len = len +% 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            len = len +% 16;
            len = len +% 1;
            len = len +% value.len;
            len = len +% 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            len = len +% 19;
            len = len +% 1;
            len = len +% value.len;
            len = len +% 1;
        }
    }
    if (cmd.link_script) |link_script| {
        len = len +% 8;
        len = len +% 1;
        len = len +% link_script.len;
        len = len +% 1;
    }
    if (cmd.version_script) |version_script| {
        len = len +% 16;
        len = len +% 1;
        len = len +% version_script.len;
        len = len +% 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        len = len +% 16;
        len = len +% 1;
        len = len +% dynamic_linker.len;
        len = len +% 1;
    }
    if (cmd.sysroot) |sysroot| {
        len = len +% 9;
        len = len +% 1;
        len = len +% sysroot.len;
        len = len +% 1;
    }
    if (cmd.entry) |entry| {
        len = len +% 7;
        len = len +% 1;
        len = len +% entry.len;
        len = len +% 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            len = len +% 5;
            len = len +% 1;
        } else {
            len = len +% 8;
            len = len +% 1;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            len = len +% 13;
            len = len +% 1;
        } else {
            len = len +% 16;
            len = len +% 1;
        }
    }
    if (cmd.rpath) |rpath| {
        len = len +% 6;
        len = len +% 1;
        len = len +% rpath.len;
        len = len +% 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            len = len +% 16;
            len = len +% 1;
        } else {
            len = len +% 19;
            len = len +% 1;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            len = len +% 23;
            len = len +% 1;
        } else {
            len = len +% 26;
            len = len +% 1;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            len = len +% 10;
            len = len +% 1;
        } else {
            len = len +% 13;
            len = len +% 1;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            len = len +% 30;
            len = len +% 1;
        } else {
            len = len +% 30;
            len = len +% 1;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            len = len +% 13;
            len = len +% 1;
        } else {
            len = len +% 16;
            len = len +% 1;
        }
    }
    if (cmd.stack) |stack| {
        len = len +% 7;
        len = len +% 1;
        len = len +% builtin.fmt.ud64(stack).readAll().len;
        len = len +% 1;
    }
    if (cmd.image_base) |image_base| {
        len = len +% 12;
        len = len +% 1;
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
        len = len +% formatMap(cflags).formatLength();
    }
    if (cmd.link_libc) {
        len = len +% 3;
        len = len +% 1;
    }
    if (cmd.rdynamic) {
        len = len +% 9;
        len = len +% 1;
    }
    if (cmd.dynamic) {
        len = len +% 8;
        len = len +% 1;
    }
    if (cmd.static) {
        len = len +% 7;
        len = len +% 1;
    }
    if (cmd.symbolic) {
        len = len +% 10;
        len = len +% 1;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            len = len +% 2;
            len = len +% 1;
            len = len +% @tagName(value).len;
            len = len +% 1;
        }
    }
    if (cmd.files) |files| {
        len = len +% formatMap(files).formatLength();
    }
    if (cmd.color) |color| {
        len = len +% 7;
        len = len +% 1;
        len = len +% @tagName(color).len;
        len = len +% 1;
    }
    if (cmd.time_report) {
        len = len +% 13;
        len = len +% 1;
    }
    if (cmd.stack_report) {
        len = len +% 14;
        len = len +% 1;
    }
    if (cmd.verbose_link) {
        len = len +% 14;
        len = len +% 1;
    }
    if (cmd.verbose_cc) {
        len = len +% 12;
        len = len +% 1;
    }
    if (cmd.verbose_air) {
        len = len +% 13;
        len = len +% 1;
    }
    if (cmd.verbose_mir) {
        len = len +% 13;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_ir) {
        len = len +% 17;
        len = len +% 1;
    }
    if (cmd.verbose_cimport) {
        len = len +% 17;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_cpu_features) {
        len = len +% 27;
        len = len +% 1;
    }
    if (cmd.debug_log) |debug_log| {
        len = len +% 11;
        len = len +% 1;
        len = len +% debug_log.len;
        len = len +% 1;
    }
    if (cmd.debug_compiler_errors) {
        len = len +% 22;
        len = len +% 1;
    }
    if (cmd.debug_link_snapshot) {
        len = len +% 21;
        len = len +% 1;
    }
    return len +% root_path.formatLength() +% 1;
}
pub fn formatWriteBuf(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @setRuntimeSafety(false);
    @memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len = len +% 1;
    @memcpy(buf + len, "fmt\x00", 4);
    len = len +% 4;
    if (cmd.color) |color| {
        @memcpy(buf + len, "--color", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        @memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.stdin) {
        @memcpy(buf + len, "--stdin", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.check) {
        @memcpy(buf + len, "--check", 7);
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.ast_check) {
        @memcpy(buf + len, "--ast-check", 11);
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.exclude) |exclude| {
        @memcpy(buf + len, "--exclude", 9);
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
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
        len = len +% 7;
        len = len +% 1;
        len = len +% @tagName(color).len;
        len = len +% 1;
    }
    if (cmd.stdin) {
        len = len +% 7;
        len = len +% 1;
    }
    if (cmd.check) {
        len = len +% 7;
        len = len +% 1;
    }
    if (cmd.ast_check) {
        len = len +% 11;
        len = len +% 1;
    }
    if (cmd.exclude) |exclude| {
        len = len +% 9;
        len = len +% 1;
        len = len +% exclude.len;
        len = len +% 1;
    }
    return len +% root_path.formatLength() +% 1;
}
