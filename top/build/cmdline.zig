const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks.zig");
const safety: bool = false;
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
    @setRuntimeSafety(safety);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len +%= 1;
    mach.memcpy(buf + len, "build-", 6);
    len +%= 6;
    mach.memcpy(buf + len, @tagName(cmd.kind).ptr, @tagName(cmd.kind).len);
    len +%= @tagName(cmd.kind).len;
    buf[len] = 0;
    len +%= 1;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-bin\x3d".*;
                    len +%= 11;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-bin\x00".*;
                    len +%= 11;
                }
            },
            .no => {
                @ptrCast(*[14]u8, buf + len).* = "-fno-emit-bin\x00".*;
                len +%= 14;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-asm\x3d".*;
                    len +%= 11;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-asm\x00".*;
                    len +%= 11;
                }
            },
            .no => {
                @ptrCast(*[14]u8, buf + len).* = "-fno-emit-asm\x00".*;
                len +%= 14;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-ir\x3d".*;
                    len +%= 15;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-ir\x00".*;
                    len +%= 15;
                }
            },
            .no => {
                @ptrCast(*[18]u8, buf + len).* = "-fno-emit-llvm-ir\x00".*;
                len +%= 18;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-bc\x3d".*;
                    len +%= 15;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-bc\x00".*;
                    len +%= 15;
                }
            },
            .no => {
                @ptrCast(*[18]u8, buf + len).* = "-fno-emit-llvm-bc\x00".*;
                len +%= 18;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[9]u8, buf + len).* = "-femit-h\x3d".*;
                    len +%= 9;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[9]u8, buf + len).* = "-femit-h\x00".*;
                    len +%= 9;
                }
            },
            .no => {
                @ptrCast(*[12]u8, buf + len).* = "-fno-emit-h\x00".*;
                len +%= 12;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[12]u8, buf + len).* = "-femit-docs\x3d".*;
                    len +%= 12;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[12]u8, buf + len).* = "-femit-docs\x00".*;
                    len +%= 12;
                }
            },
            .no => {
                @ptrCast(*[15]u8, buf + len).* = "-fno-emit-docs\x00".*;
                len +%= 15;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[16]u8, buf + len).* = "-femit-analysis\x3d".*;
                    len +%= 16;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[16]u8, buf + len).* = "-femit-analysis\x00".*;
                    len +%= 16;
                }
            },
            .no => {
                @ptrCast(*[19]u8, buf + len).* = "-fno-emit-analysis\x00".*;
                len +%= 19;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-implib\x3d".*;
                    len +%= 14;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-implib\x00".*;
                    len +%= 14;
                }
            },
            .no => {
                @ptrCast(*[17]u8, buf + len).* = "-fno-emit-implib\x00".*;
                len +%= 17;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        @ptrCast(*[12]u8, buf + len).* = "--cache-dir\x00".*;
        len +%= 12;
        mach.memcpy(buf + len, cache_root.ptr, cache_root.len);
        len +%= cache_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        @ptrCast(*[19]u8, buf + len).* = "--global-cache-dir\x00".*;
        len +%= 19;
        mach.memcpy(buf + len, global_cache_root.ptr, global_cache_root.len);
        len +%= global_cache_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        @ptrCast(*[14]u8, buf + len).* = "--zig-lib-dir\x00".*;
        len +%= 14;
        mach.memcpy(buf + len, zig_lib_root.ptr, zig_lib_root.len);
        len +%= zig_lib_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.listen) |listen| {
        @ptrCast(*[9]u8, buf + len).* = "--listen\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, @tagName(listen).ptr, @tagName(listen).len);
        len +%= @tagName(listen).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.target) |target| {
        @ptrCast(*[8]u8, buf + len).* = "-target\x00".*;
        len +%= 8;
        mach.memcpy(buf + len, target.ptr, target.len);
        len +%= target.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.cpu) |cpu| {
        @ptrCast(*[6]u8, buf + len).* = "-mcpu\x00".*;
        len +%= 6;
        mach.memcpy(buf + len, cpu.ptr, cpu.len);
        len +%= cpu.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.code_model) |code_model| {
        @ptrCast(*[9]u8, buf + len).* = "-mcmodel\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, @tagName(code_model).ptr, @tagName(code_model).len);
        len +%= @tagName(code_model).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            @ptrCast(*[11]u8, buf + len).* = "-mred-zone\x00".*;
            len +%= 11;
        } else {
            @ptrCast(*[14]u8, buf + len).* = "-mno-red-zone\x00".*;
            len +%= 14;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            @ptrCast(*[21]u8, buf + len).* = "-fomit-frame-pointer\x00".*;
            len +%= 21;
        } else {
            @ptrCast(*[24]u8, buf + len).* = "-fno-omit-frame-pointer\x00".*;
            len +%= 24;
        }
    }
    if (cmd.exec_model) |exec_model| {
        @ptrCast(*[13]u8, buf + len).* = "-mexec-model\x00".*;
        len +%= 13;
        mach.memcpy(buf + len, exec_model.ptr, exec_model.len);
        len +%= exec_model.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.name) |name| {
        @ptrCast(*[7]u8, buf + len).* = "--name\x00".*;
        len +%= 7;
        mach.memcpy(buf + len, name.ptr, name.len);
        len +%= name.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                @ptrCast(*[9]u8, buf + len).* = "-fsoname\x00".*;
                len +%= 9;
                mach.memcpy(buf + len, arg.ptr, arg.len);
                len +%= arg.len;
                buf[len] = 0;
                len +%= 1;
            },
            .no => {
                @ptrCast(*[12]u8, buf + len).* = "-fno-soname\x00".*;
                len +%= 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        @ptrCast(*[3]u8, buf + len).* = "-O\x00".*;
        len +%= 3;
        mach.memcpy(buf + len, @tagName(mode).ptr, @tagName(mode).len);
        len +%= @tagName(mode).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.passes) |passes| {
        @ptrCast(*[19]u8, buf + len).* = "-fopt-bisect-limit\x3d".*;
        len +%= 19;
        const s: []const u8 = builtin.fmt.ud64(passes).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        @ptrCast(*[16]u8, buf + len).* = "--main-pkg-path\x00".*;
        len +%= 16;
        mach.memcpy(buf + len, main_pkg_path.ptr, main_pkg_path.len);
        len +%= main_pkg_path.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            @ptrCast(*[6]u8, buf + len).* = "-fPIC\x00".*;
            len +%= 6;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-PIC\x00".*;
            len +%= 9;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            @ptrCast(*[6]u8, buf + len).* = "-fPIE\x00".*;
            len +%= 6;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-PIE\x00".*;
            len +%= 9;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            @ptrCast(*[6]u8, buf + len).* = "-flto\x00".*;
            len +%= 6;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-lto\x00".*;
            len +%= 9;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            @ptrCast(*[14]u8, buf + len).* = "-fstack-check\x00".*;
            len +%= 14;
        } else {
            @ptrCast(*[17]u8, buf + len).* = "-fno-stack-check\x00".*;
            len +%= 17;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            @ptrCast(*[14]u8, buf + len).* = "-fstack-check\x00".*;
            len +%= 14;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-stack-protector\x00".*;
            len +%= 21;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            @ptrCast(*[13]u8, buf + len).* = "-fsanitize-c\x00".*;
            len +%= 13;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "-fno-sanitize-c\x00".*;
            len +%= 16;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            @ptrCast(*[11]u8, buf + len).* = "-fvalgrind\x00".*;
            len +%= 11;
        } else {
            @ptrCast(*[14]u8, buf + len).* = "-fno-valgrind\x00".*;
            len +%= 14;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            @ptrCast(*[18]u8, buf + len).* = "-fsanitize-thread\x00".*;
            len +%= 18;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-sanitize-thread\x00".*;
            len +%= 21;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            @ptrCast(*[16]u8, buf + len).* = "-funwind-tables\x00".*;
            len +%= 16;
        } else {
            @ptrCast(*[19]u8, buf + len).* = "-fno-unwind-tables\x00".*;
            len +%= 19;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            @ptrCast(*[7]u8, buf + len).* = "-fLLVM\x00".*;
            len +%= 7;
        } else {
            @ptrCast(*[10]u8, buf + len).* = "-fno-LLVM\x00".*;
            len +%= 10;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            @ptrCast(*[8]u8, buf + len).* = "-fClang\x00".*;
            len +%= 8;
        } else {
            @ptrCast(*[11]u8, buf + len).* = "-fno-Clang\x00".*;
            len +%= 11;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            @ptrCast(*[18]u8, buf + len).* = "-freference-trace\x00".*;
            len +%= 18;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-reference-trace\x00".*;
            len +%= 21;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            @ptrCast(*[16]u8, buf + len).* = "-ferror-tracing\x00".*;
            len +%= 16;
        } else {
            @ptrCast(*[19]u8, buf + len).* = "-fno-error-tracing\x00".*;
            len +%= 19;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            @ptrCast(*[18]u8, buf + len).* = "-fsingle-threaded\x00".*;
            len +%= 18;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-single-threaded\x00".*;
            len +%= 21;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            @ptrCast(*[20]u8, buf + len).* = "-ffunction-sections\x00".*;
            len +%= 20;
        } else {
            @ptrCast(*[23]u8, buf + len).* = "-fno-function-sections\x00".*;
            len +%= 23;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            @ptrCast(*[8]u8, buf + len).* = "-fstrip\x00".*;
            len +%= 8;
        } else {
            @ptrCast(*[11]u8, buf + len).* = "-fno-strip\x00".*;
            len +%= 11;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            @ptrCast(*[19]u8, buf + len).* = "-fformatted-panics\x00".*;
            len +%= 19;
        } else {
            @ptrCast(*[22]u8, buf + len).* = "-fno-formatted-panics\x00".*;
            len +%= 22;
        }
    }
    if (cmd.format) |format| {
        @ptrCast(*[6]u8, buf + len).* = "-ofmt\x3d".*;
        len +%= 6;
        mach.memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len +%= @tagName(format).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.dirafter) |dirafter| {
        @ptrCast(*[11]u8, buf + len).* = "-idirafter\x00".*;
        len +%= 11;
        mach.memcpy(buf + len, dirafter.ptr, dirafter.len);
        len +%= dirafter.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.system) |system| {
        @ptrCast(*[9]u8, buf + len).* = "-isystem\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, system.ptr, system.len);
        len +%= system.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.libc) |libc| {
        @ptrCast(*[7]u8, buf + len).* = "--libc\x00".*;
        len +%= 7;
        mach.memcpy(buf + len, libc.ptr, libc.len);
        len +%= libc.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.library) |library| {
        @ptrCast(*[10]u8, buf + len).* = "--library\x00".*;
        len +%= 10;
        mach.memcpy(buf + len, library.ptr, library.len);
        len +%= library.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            @ptrCast(*[3]u8, buf + len).* = "-I\x00".*;
            len +%= 3;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            @ptrCast(*[17]u8, buf + len).* = "--needed-library\x00".*;
            len +%= 17;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            @ptrCast(*[20]u8, buf + len).* = "--library-directory\x00".*;
            len +%= 20;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.link_script) |link_script| {
        @ptrCast(*[9]u8, buf + len).* = "--script\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, link_script.ptr, link_script.len);
        len +%= link_script.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.version_script) |version_script| {
        @ptrCast(*[17]u8, buf + len).* = "--version-script\x00".*;
        len +%= 17;
        mach.memcpy(buf + len, version_script.ptr, version_script.len);
        len +%= version_script.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        @ptrCast(*[17]u8, buf + len).* = "--dynamic-linker\x00".*;
        len +%= 17;
        mach.memcpy(buf + len, dynamic_linker.ptr, dynamic_linker.len);
        len +%= dynamic_linker.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.sysroot) |sysroot| {
        @ptrCast(*[10]u8, buf + len).* = "--sysroot\x00".*;
        len +%= 10;
        mach.memcpy(buf + len, sysroot.ptr, sysroot.len);
        len +%= sysroot.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.entry) |entry| {
        @ptrCast(*[8]u8, buf + len).* = "--entry\x00".*;
        len +%= 8;
        mach.memcpy(buf + len, entry.ptr, entry.len);
        len +%= entry.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            @ptrCast(*[6]u8, buf + len).* = "-fLLD\x00".*;
            len +%= 6;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-LLD\x00".*;
            len +%= 9;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            @ptrCast(*[14]u8, buf + len).* = "-fcompiler-rt\x00".*;
            len +%= 14;
        } else {
            @ptrCast(*[17]u8, buf + len).* = "-fno-compiler-rt\x00".*;
            len +%= 17;
        }
    }
    if (cmd.rpath) |rpath| {
        @ptrCast(*[7]u8, buf + len).* = "-rpath\x00".*;
        len +%= 7;
        mach.memcpy(buf + len, rpath.ptr, rpath.len);
        len +%= rpath.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            @ptrCast(*[17]u8, buf + len).* = "-feach-lib-rpath\x00".*;
            len +%= 17;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-each-lib-rpath\x00".*;
            len +%= 20;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            @ptrCast(*[24]u8, buf + len).* = "-fallow-shlib-undefined\x00".*;
            len +%= 24;
        } else {
            @ptrCast(*[27]u8, buf + len).* = "-fno-allow-shlib-undefined\x00".*;
            len +%= 27;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            @ptrCast(*[11]u8, buf + len).* = "-fbuild-id\x00".*;
            len +%= 11;
        } else {
            @ptrCast(*[14]u8, buf + len).* = "-fno-build-id\x00".*;
            len +%= 14;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            @ptrCast(*[31]u8, buf + len).* = "--compress-debug-sections=zlib\x00".*;
            len +%= 31;
        } else {
            @ptrCast(*[31]u8, buf + len).* = "--compress-debug-sections=none\x00".*;
            len +%= 31;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            @ptrCast(*[14]u8, buf + len).* = "--gc-sections\x00".*;
            len +%= 14;
        } else {
            @ptrCast(*[17]u8, buf + len).* = "--no-gc-sections\x00".*;
            len +%= 17;
        }
    }
    if (cmd.stack) |stack| {
        @ptrCast(*[8]u8, buf + len).* = "--stack\x00".*;
        len +%= 8;
        const s: []const u8 = builtin.fmt.ud64(stack).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        @ptrCast(*[13]u8, buf + len).* = "--image-base\x00".*;
        len +%= 13;
        const s: []const u8 = builtin.fmt.ud64(image_base).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        len +%= formatMap(macros).formatWriteBuf(buf + len);
    }
    if (cmd.modules) |modules| {
        len +%= formatMap(modules).formatWriteBuf(buf + len);
    }
    if (cmd.dependencies) |dependencies| {
        len +%= formatMap(dependencies).formatWriteBuf(buf + len);
    }
    if (cmd.cflags) |cflags| {
        len +%= formatMap(cflags).formatWriteBuf(buf + len);
    }
    if (cmd.link_libc) {
        @ptrCast(*[4]u8, buf + len).* = "-lc\x00".*;
        len +%= 4;
    }
    if (cmd.rdynamic) {
        @ptrCast(*[10]u8, buf + len).* = "-rdynamic\x00".*;
        len +%= 10;
    }
    if (cmd.dynamic) {
        @ptrCast(*[9]u8, buf + len).* = "-dynamic\x00".*;
        len +%= 9;
    }
    if (cmd.static) {
        @ptrCast(*[8]u8, buf + len).* = "-static\x00".*;
        len +%= 8;
    }
    if (cmd.symbolic) {
        @ptrCast(*[11]u8, buf + len).* = "-Bsymbolic\x00".*;
        len +%= 11;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            @ptrCast(*[3]u8, buf + len).* = "-z\x00".*;
            len +%= 3;
            mach.memcpy(buf + len, @tagName(value).ptr, @tagName(value).len);
            len +%= @tagName(value).len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.files) |files| {
        len +%= formatMap(files).formatWriteBuf(buf + len);
    }
    if (cmd.color) |color| {
        @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
        len +%= 8;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len +%= @tagName(color).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.time_report) {
        @ptrCast(*[14]u8, buf + len).* = "-ftime-report\x00".*;
        len +%= 14;
    }
    if (cmd.stack_report) {
        @ptrCast(*[15]u8, buf + len).* = "-fstack-report\x00".*;
        len +%= 15;
    }
    if (cmd.verbose_link) {
        @ptrCast(*[15]u8, buf + len).* = "--verbose-link\x00".*;
        len +%= 15;
    }
    if (cmd.verbose_cc) {
        @ptrCast(*[13]u8, buf + len).* = "--verbose-cc\x00".*;
        len +%= 13;
    }
    if (cmd.verbose_air) {
        @ptrCast(*[14]u8, buf + len).* = "--verbose-air\x00".*;
        len +%= 14;
    }
    if (cmd.verbose_mir) {
        @ptrCast(*[14]u8, buf + len).* = "--verbose-mir\x00".*;
        len +%= 14;
    }
    if (cmd.verbose_llvm_ir) {
        @ptrCast(*[18]u8, buf + len).* = "--verbose-llvm-ir\x00".*;
        len +%= 18;
    }
    if (cmd.verbose_cimport) {
        @ptrCast(*[18]u8, buf + len).* = "--verbose-cimport\x00".*;
        len +%= 18;
    }
    if (cmd.verbose_llvm_cpu_features) {
        @ptrCast(*[28]u8, buf + len).* = "--verbose-llvm-cpu-features\x00".*;
        len +%= 28;
    }
    if (cmd.debug_log) |debug_log| {
        @ptrCast(*[12]u8, buf + len).* = "--debug-log\x00".*;
        len +%= 12;
        mach.memcpy(buf + len, debug_log.ptr, debug_log.len);
        len +%= debug_log.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.debug_compiler_errors) {
        @ptrCast(*[23]u8, buf + len).* = "--debug-compile-errors\x00".*;
        len +%= 23;
    }
    if (cmd.debug_link_snapshot) {
        @ptrCast(*[22]u8, buf + len).* = "--debug-link-snapshot\x00".*;
        len +%= 22;
    }
    len +%= root_path.formatWriteBuf(buf + len);
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
                    len +%= 11;
                    len +%= arg.formatLength();
                } else {
                    len +%= 11;
                }
            },
            .no => {
                len +%= 14;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 11;
                    len +%= arg.formatLength();
                } else {
                    len +%= 11;
                }
            },
            .no => {
                len +%= 14;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 15;
                    len +%= arg.formatLength();
                } else {
                    len +%= 15;
                }
            },
            .no => {
                len +%= 18;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 15;
                    len +%= arg.formatLength();
                } else {
                    len +%= 15;
                }
            },
            .no => {
                len +%= 18;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 9;
                    len +%= arg.formatLength();
                } else {
                    len +%= 9;
                }
            },
            .no => {
                len +%= 12;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 12;
                    len +%= arg.formatLength();
                } else {
                    len +%= 12;
                }
            },
            .no => {
                len +%= 15;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 16;
                    len +%= arg.formatLength();
                } else {
                    len +%= 16;
                }
            },
            .no => {
                len +%= 19;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 14;
                    len +%= arg.formatLength();
                } else {
                    len +%= 14;
                }
            },
            .no => {
                len +%= 17;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        len +%= 12;
        len +%= cache_root.len;
        len +%= 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        len +%= 19;
        len +%= global_cache_root.len;
        len +%= 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        len +%= 14;
        len +%= zig_lib_root.len;
        len +%= 1;
    }
    if (cmd.listen) |listen| {
        len +%= 9;
        len +%= @tagName(listen).len;
        len +%= 1;
    }
    if (cmd.target) |target| {
        len +%= 8;
        len +%= target.len;
        len +%= 1;
    }
    if (cmd.cpu) |cpu| {
        len +%= 6;
        len +%= cpu.len;
        len +%= 1;
    }
    if (cmd.code_model) |code_model| {
        len +%= 9;
        len +%= @tagName(code_model).len;
        len +%= 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            len +%= 11;
        } else {
            len +%= 14;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            len +%= 21;
        } else {
            len +%= 24;
        }
    }
    if (cmd.exec_model) |exec_model| {
        len +%= 13;
        len +%= exec_model.len;
        len +%= 1;
    }
    if (cmd.name) |name| {
        len +%= 7;
        len +%= name.len;
        len +%= 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                len +%= 9;
                len +%= arg.len;
                len +%= 1;
            },
            .no => {
                len +%= 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        len +%= 3;
        len +%= @tagName(mode).len;
        len +%= 1;
    }
    if (cmd.passes) |passes| {
        len +%= 19;
        len +%= builtin.fmt.ud64(passes).readAll().len;
        len +%= 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        len +%= 16;
        len +%= main_pkg_path.len;
        len +%= 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            len +%= 6;
        } else {
            len +%= 9;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            len +%= 6;
        } else {
            len +%= 9;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            len +%= 6;
        } else {
            len +%= 9;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            len +%= 14;
        } else {
            len +%= 17;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            len +%= 14;
        } else {
            len +%= 21;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            len +%= 13;
        } else {
            len +%= 16;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            len +%= 11;
        } else {
            len +%= 14;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            len +%= 18;
        } else {
            len +%= 21;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            len +%= 16;
        } else {
            len +%= 19;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            len +%= 7;
        } else {
            len +%= 10;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            len +%= 8;
        } else {
            len +%= 11;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            len +%= 18;
        } else {
            len +%= 21;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            len +%= 16;
        } else {
            len +%= 19;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            len +%= 18;
        } else {
            len +%= 21;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            len +%= 20;
        } else {
            len +%= 23;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            len +%= 8;
        } else {
            len +%= 11;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            len +%= 19;
        } else {
            len +%= 22;
        }
    }
    if (cmd.format) |format| {
        len +%= 6;
        len +%= @tagName(format).len;
        len +%= 1;
    }
    if (cmd.dirafter) |dirafter| {
        len +%= 11;
        len +%= dirafter.len;
        len +%= 1;
    }
    if (cmd.system) |system| {
        len +%= 9;
        len +%= system.len;
        len +%= 1;
    }
    if (cmd.libc) |libc| {
        len +%= 7;
        len +%= libc.len;
        len +%= 1;
    }
    if (cmd.library) |library| {
        len +%= 10;
        len +%= library.len;
        len +%= 1;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 3;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            len +%= 17;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            len +%= 20;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.link_script) |link_script| {
        len +%= 9;
        len +%= link_script.len;
        len +%= 1;
    }
    if (cmd.version_script) |version_script| {
        len +%= 17;
        len +%= version_script.len;
        len +%= 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        len +%= 17;
        len +%= dynamic_linker.len;
        len +%= 1;
    }
    if (cmd.sysroot) |sysroot| {
        len +%= 10;
        len +%= sysroot.len;
        len +%= 1;
    }
    if (cmd.entry) |entry| {
        len +%= 8;
        len +%= entry.len;
        len +%= 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            len +%= 6;
        } else {
            len +%= 9;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            len +%= 14;
        } else {
            len +%= 17;
        }
    }
    if (cmd.rpath) |rpath| {
        len +%= 7;
        len +%= rpath.len;
        len +%= 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            len +%= 17;
        } else {
            len +%= 20;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            len +%= 24;
        } else {
            len +%= 27;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            len +%= 11;
        } else {
            len +%= 14;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            len +%= 31;
        } else {
            len +%= 31;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            len +%= 14;
        } else {
            len +%= 17;
        }
    }
    if (cmd.stack) |stack| {
        len +%= 8;
        len +%= builtin.fmt.ud64(stack).readAll().len;
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        len +%= 13;
        len +%= builtin.fmt.ud64(image_base).readAll().len;
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        len +%= formatMap(macros).formatLength();
    }
    if (cmd.modules) |modules| {
        len +%= formatMap(modules).formatLength();
    }
    if (cmd.dependencies) |dependencies| {
        len +%= formatMap(dependencies).formatLength();
    }
    if (cmd.cflags) |cflags| {
        len +%= formatMap(cflags).formatLength();
    }
    if (cmd.link_libc) {
        len +%= 4;
    }
    if (cmd.rdynamic) {
        len +%= 10;
    }
    if (cmd.dynamic) {
        len +%= 9;
    }
    if (cmd.static) {
        len +%= 8;
    }
    if (cmd.symbolic) {
        len +%= 11;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            len +%= 3;
            len +%= @tagName(value).len;
            len +%= 1;
        }
    }
    if (cmd.files) |files| {
        len +%= formatMap(files).formatLength();
    }
    if (cmd.color) |color| {
        len +%= 8;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.time_report) {
        len +%= 14;
    }
    if (cmd.stack_report) {
        len +%= 15;
    }
    if (cmd.verbose_link) {
        len +%= 15;
    }
    if (cmd.verbose_cc) {
        len +%= 13;
    }
    if (cmd.verbose_air) {
        len +%= 14;
    }
    if (cmd.verbose_mir) {
        len +%= 14;
    }
    if (cmd.verbose_llvm_ir) {
        len +%= 18;
    }
    if (cmd.verbose_cimport) {
        len +%= 18;
    }
    if (cmd.verbose_llvm_cpu_features) {
        len +%= 28;
    }
    if (cmd.debug_log) |debug_log| {
        len +%= 12;
        len +%= debug_log.len;
        len +%= 1;
    }
    if (cmd.debug_compiler_errors) {
        len +%= 23;
    }
    if (cmd.debug_link_snapshot) {
        len +%= 22;
    }
    return len +% root_path.formatLength();
}
pub fn archiveWriteBuf(cmd: *const tasks.ArchiveCommand, zig_exe: []const u8, buf: [*]u8) u64 {
    @setRuntimeSafety(safety);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len +%= 1;
    mach.memcpy(buf + len, "ar\x00", 3);
    len +%= 3;
    if (cmd.format) |format| {
        @ptrCast(*[9]u8, buf + len).* = "--format\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len +%= @tagName(format).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.plugin) {
        @ptrCast(*[9]u8, buf + len).* = "--plugin\x00".*;
        len +%= 9;
    }
    if (cmd.output) |output| {
        @ptrCast(*[9]u8, buf + len).* = "--output\x00".*;
        len +%= 9;
        mach.memcpy(buf + len, output.ptr, output.len);
        len +%= output.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.thin) {
        @ptrCast(*[7]u8, buf + len).* = "--thin\x00".*;
        len +%= 7;
    }
    if (cmd.after) {
        @ptrCast(*[1]u8, buf + len).* = "a".*;
        len +%= 1;
    }
    if (cmd.before) {
        @ptrCast(*[1]u8, buf + len).* = "b".*;
        len +%= 1;
    }
    if (cmd.create) {
        @ptrCast(*[1]u8, buf + len).* = "c".*;
        len +%= 1;
    }
    if (cmd.zero_ids) {
        @ptrCast(*[1]u8, buf + len).* = "D".*;
        len +%= 1;
    }
    if (cmd.real_ids) {
        @ptrCast(*[1]u8, buf + len).* = "U".*;
        len +%= 1;
    }
    if (cmd.append) {
        @ptrCast(*[1]u8, buf + len).* = "L".*;
        len +%= 1;
    }
    if (cmd.preserve_dates) {
        @ptrCast(*[1]u8, buf + len).* = "o".*;
        len +%= 1;
    }
    if (cmd.index) {
        @ptrCast(*[1]u8, buf + len).* = "s".*;
        len +%= 1;
    }
    if (cmd.no_symbol_table) {
        @ptrCast(*[1]u8, buf + len).* = "S".*;
        len +%= 1;
    }
    if (cmd.update) {
        @ptrCast(*[1]u8, buf + len).* = "u".*;
        len +%= 1;
    }
    mach.memcpy(buf + len, @tagName(cmd.operation).ptr, @tagName(cmd.operation).len);
    len +%= @tagName(cmd.operation).len;
    buf[len] = 0;
    len +%= 1;
    if (cmd.archive) |archive| {
        len +%= archive.formatWriteBuf(buf + len);
    }
    if (cmd.files) |files| {
        len +%= formatMap(files).formatWriteBuf(buf + len);
    }
    buf[len] = 0;
    return len;
}
pub fn archiveLength(cmd: *const tasks.ArchiveCommand, zig_exe: []const u8) u64 {
    @setRuntimeSafety(safety);
    var len: u64 = zig_exe.len +% 4;
    if (cmd.format) |format| {
        len +%= 9;
        len +%= @tagName(format).len;
        len +%= 1;
    }
    if (cmd.plugin) {
        len +%= 9;
    }
    if (cmd.output) |output| {
        len +%= 9;
        len +%= output.len;
        len +%= 1;
    }
    if (cmd.thin) {
        len +%= 7;
    }
    if (cmd.after) {
        len +%= 1;
    }
    if (cmd.before) {
        len +%= 1;
    }
    if (cmd.create) {
        len +%= 1;
    }
    if (cmd.zero_ids) {
        len +%= 1;
    }
    if (cmd.real_ids) {
        len +%= 1;
    }
    if (cmd.append) {
        len +%= 1;
    }
    if (cmd.preserve_dates) {
        len +%= 1;
    }
    if (cmd.index) {
        len +%= 1;
    }
    if (cmd.no_symbol_table) {
        len +%= 1;
    }
    if (cmd.update) {
        len +%= 1;
    }
    len +%= @tagName(cmd.operation).len;
    len +%= 1;
    if (cmd.archive) |archive| {
        len +%= archive.formatLength();
    }
    if (cmd.files) |files| {
        len +%= formatMap(files).formatLength();
    }
    return len;
}
pub fn formatWriteBuf(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @setRuntimeSafety(safety);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len +%= 1;
    mach.memcpy(buf + len, "fmt\x00", 4);
    len +%= 4;
    if (cmd.color) |color| {
        @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
        len +%= 8;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len +%= @tagName(color).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.stdin) {
        @ptrCast(*[8]u8, buf + len).* = "--stdin\x00".*;
        len +%= 8;
    }
    if (cmd.check) {
        @ptrCast(*[8]u8, buf + len).* = "--check\x00".*;
        len +%= 8;
    }
    if (cmd.ast_check) {
        @ptrCast(*[12]u8, buf + len).* = "--ast-check\x00".*;
        len +%= 12;
    }
    if (cmd.exclude) |exclude| {
        @ptrCast(*[10]u8, buf + len).* = "--exclude\x00".*;
        len +%= 10;
        mach.memcpy(buf + len, exclude.ptr, exclude.len);
        len +%= exclude.len;
        buf[len] = 0;
        len +%= 1;
    }
    len +%= root_path.formatWriteBuf(buf + len);
    buf[len] = 0;
    return len;
}
pub fn formatLength(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path) u64 {
    @setRuntimeSafety(safety);
    var len: u64 = zig_exe.len +% 5;
    if (cmd.color) |color| {
        len +%= 8;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.stdin) {
        len +%= 8;
    }
    if (cmd.check) {
        len +%= 8;
    }
    if (cmd.ast_check) {
        len +%= 12;
    }
    if (cmd.exclude) |exclude| {
        len +%= 10;
        len +%= exclude.len;
        len +%= 1;
    }
    return len +% root_path.formatLength();
}
pub fn tblgenWriteBuf(cmd: *const tasks.TblgenCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @setRuntimeSafety(safety);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len +%= 1;
    mach.memcpy(buf + len, "fmt\x00", 4);
    len +%= 4;
    if (cmd.color) |color| {
        @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
        len +%= 8;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len +%= @tagName(color).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        len +%= formatMap(macros).formatWriteBuf(buf + len);
    }
    if (cmd.include) |include| {
        for (include) |value| {
            @ptrCast(*[3]u8, buf + len).* = "-I\x00".*;
            len +%= 3;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.dependencies) |dependencies| {
        for (dependencies) |value| {
            @ptrCast(*[3]u8, buf + len).* = "-d\x00".*;
            len +%= 3;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.print_records) {
        @ptrCast(*[16]u8, buf + len).* = "--print-records\x00".*;
        len +%= 16;
    }
    if (cmd.print_detailed_records) {
        @ptrCast(*[25]u8, buf + len).* = "--print-detailed-records\x00".*;
        len +%= 25;
    }
    if (cmd.null_backend) {
        @ptrCast(*[15]u8, buf + len).* = "--null-backend\x00".*;
        len +%= 15;
    }
    if (cmd.dump_json) {
        @ptrCast(*[12]u8, buf + len).* = "--dump-json\x00".*;
        len +%= 12;
    }
    if (cmd.gen_emitter) {
        @ptrCast(*[14]u8, buf + len).* = "--gen-emitter\x00".*;
        len +%= 14;
    }
    if (cmd.gen_register_info) {
        @ptrCast(*[20]u8, buf + len).* = "--gen-register-info\x00".*;
        len +%= 20;
    }
    if (cmd.gen_instr_info) {
        @ptrCast(*[17]u8, buf + len).* = "--gen-instr-info\x00".*;
        len +%= 17;
    }
    if (cmd.gen_instr_docs) {
        @ptrCast(*[17]u8, buf + len).* = "--gen-instr-docs\x00".*;
        len +%= 17;
    }
    if (cmd.gen_callingconv) {
        @ptrCast(*[18]u8, buf + len).* = "--gen-callingconv\x00".*;
        len +%= 18;
    }
    if (cmd.gen_asm_writer) {
        @ptrCast(*[17]u8, buf + len).* = "--gen-asm-writer\x00".*;
        len +%= 17;
    }
    if (cmd.gen_disassembler) {
        @ptrCast(*[19]u8, buf + len).* = "--gen-disassembler\x00".*;
        len +%= 19;
    }
    if (cmd.gen_pseudo_lowering) {
        @ptrCast(*[22]u8, buf + len).* = "--gen-pseudo-lowering\x00".*;
        len +%= 22;
    }
    if (cmd.gen_compress_inst_emitter) {
        @ptrCast(*[28]u8, buf + len).* = "--gen-compress-inst-emitter\x00".*;
        len +%= 28;
    }
    if (cmd.gen_asm_matcher) {
        @ptrCast(*[18]u8, buf + len).* = "--gen-asm-matcher\x00".*;
        len +%= 18;
    }
    if (cmd.gen_dag_isel) {
        @ptrCast(*[15]u8, buf + len).* = "--gen-dag-isel\x00".*;
        len +%= 15;
    }
    if (cmd.gen_dfa_packetizer) {
        @ptrCast(*[21]u8, buf + len).* = "--gen-dfa-packetizer\x00".*;
        len +%= 21;
    }
    if (cmd.gen_fast_isel) {
        @ptrCast(*[16]u8, buf + len).* = "--gen-fast-isel\x00".*;
        len +%= 16;
    }
    if (cmd.gen_subtarget) {
        @ptrCast(*[16]u8, buf + len).* = "--gen-subtarget\x00".*;
        len +%= 16;
    }
    if (cmd.gen_intrinsic_enums) {
        @ptrCast(*[22]u8, buf + len).* = "--gen-intrinsic-enums\x00".*;
        len +%= 22;
    }
    if (cmd.gen_intrinsic_impl) {
        @ptrCast(*[21]u8, buf + len).* = "--gen-intrinsic-impl\x00".*;
        len +%= 21;
    }
    if (cmd.print_enums) {
        @ptrCast(*[14]u8, buf + len).* = "--print-enums\x00".*;
        len +%= 14;
    }
    if (cmd.print_sets) {
        @ptrCast(*[13]u8, buf + len).* = "--print-sets\x00".*;
        len +%= 13;
    }
    if (cmd.gen_opt_parser_defs) {
        @ptrCast(*[22]u8, buf + len).* = "--gen-opt-parser-defs\x00".*;
        len +%= 22;
    }
    if (cmd.gen_opt_rst) {
        @ptrCast(*[14]u8, buf + len).* = "--gen-opt-rst\x00".*;
        len +%= 14;
    }
    if (cmd.gen_ctags) {
        @ptrCast(*[12]u8, buf + len).* = "--gen-ctags\x00".*;
        len +%= 12;
    }
    if (cmd.gen_attrs) {
        @ptrCast(*[12]u8, buf + len).* = "--gen-attrs\x00".*;
        len +%= 12;
    }
    if (cmd.gen_searchable_tables) {
        @ptrCast(*[24]u8, buf + len).* = "--gen-searchable-tables\x00".*;
        len +%= 24;
    }
    if (cmd.gen_global_isel) {
        @ptrCast(*[18]u8, buf + len).* = "--gen-global-isel\x00".*;
        len +%= 18;
    }
    if (cmd.gen_global_isel_combiner) {
        @ptrCast(*[27]u8, buf + len).* = "--gen-global-isel-combiner\x00".*;
        len +%= 27;
    }
    if (cmd.gen_x86_EVEX2VEX_tables) {
        @ptrCast(*[26]u8, buf + len).* = "--gen-x86-EVEX2VEX-tables\x00".*;
        len +%= 26;
    }
    if (cmd.gen_x86_fold_tables) {
        @ptrCast(*[22]u8, buf + len).* = "--gen-x86-fold-tables\x00".*;
        len +%= 22;
    }
    if (cmd.gen_x86_mnemonic_tables) {
        @ptrCast(*[26]u8, buf + len).* = "--gen-x86-mnemonic-tables\x00".*;
        len +%= 26;
    }
    if (cmd.gen_register_bank) {
        @ptrCast(*[20]u8, buf + len).* = "--gen-register-bank\x00".*;
        len +%= 20;
    }
    if (cmd.gen_exegesis) {
        @ptrCast(*[15]u8, buf + len).* = "--gen-exegesis\x00".*;
        len +%= 15;
    }
    if (cmd.gen_automata) {
        @ptrCast(*[15]u8, buf + len).* = "--gen-automata\x00".*;
        len +%= 15;
    }
    if (cmd.gen_directive_decl) {
        @ptrCast(*[21]u8, buf + len).* = "--gen-directive-decl\x00".*;
        len +%= 21;
    }
    if (cmd.gen_directive_impl) {
        @ptrCast(*[21]u8, buf + len).* = "--gen-directive-impl\x00".*;
        len +%= 21;
    }
    if (cmd.gen_dxil_operation) {
        @ptrCast(*[21]u8, buf + len).* = "--gen-dxil-operation\x00".*;
        len +%= 21;
    }
    if (cmd.gen_riscv_target_def) {
        @ptrCast(*[23]u8, buf + len).* = "--gen-riscv-target_def\x00".*;
        len +%= 23;
    }
    if (cmd.output) |output| {
        @ptrCast(*[3]u8, buf + len).* = "-o\x00".*;
        len +%= 3;
        mach.memcpy(buf + len, output.ptr, output.len);
        len +%= output.len;
        buf[len] = 0;
        len +%= 1;
    }
    len +%= root_path.tblgenWriteBuf(buf + len);
    buf[len] = 0;
    return len;
}
pub fn tblgenLength(cmd: *const tasks.TblgenCommand, zig_exe: []const u8, root_path: types.Path) u64 {
    @setRuntimeSafety(safety);
    var len: u64 = zig_exe.len +% 5;
    if (cmd.color) |color| {
        len +%= 8;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        len +%= formatMap(macros).formatLength();
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 3;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.dependencies) |dependencies| {
        for (dependencies) |value| {
            len +%= 3;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.print_records) {
        len +%= 16;
    }
    if (cmd.print_detailed_records) {
        len +%= 25;
    }
    if (cmd.null_backend) {
        len +%= 15;
    }
    if (cmd.dump_json) {
        len +%= 12;
    }
    if (cmd.gen_emitter) {
        len +%= 14;
    }
    if (cmd.gen_register_info) {
        len +%= 20;
    }
    if (cmd.gen_instr_info) {
        len +%= 17;
    }
    if (cmd.gen_instr_docs) {
        len +%= 17;
    }
    if (cmd.gen_callingconv) {
        len +%= 18;
    }
    if (cmd.gen_asm_writer) {
        len +%= 17;
    }
    if (cmd.gen_disassembler) {
        len +%= 19;
    }
    if (cmd.gen_pseudo_lowering) {
        len +%= 22;
    }
    if (cmd.gen_compress_inst_emitter) {
        len +%= 28;
    }
    if (cmd.gen_asm_matcher) {
        len +%= 18;
    }
    if (cmd.gen_dag_isel) {
        len +%= 15;
    }
    if (cmd.gen_dfa_packetizer) {
        len +%= 21;
    }
    if (cmd.gen_fast_isel) {
        len +%= 16;
    }
    if (cmd.gen_subtarget) {
        len +%= 16;
    }
    if (cmd.gen_intrinsic_enums) {
        len +%= 22;
    }
    if (cmd.gen_intrinsic_impl) {
        len +%= 21;
    }
    if (cmd.print_enums) {
        len +%= 14;
    }
    if (cmd.print_sets) {
        len +%= 13;
    }
    if (cmd.gen_opt_parser_defs) {
        len +%= 22;
    }
    if (cmd.gen_opt_rst) {
        len +%= 14;
    }
    if (cmd.gen_ctags) {
        len +%= 12;
    }
    if (cmd.gen_attrs) {
        len +%= 12;
    }
    if (cmd.gen_searchable_tables) {
        len +%= 24;
    }
    if (cmd.gen_global_isel) {
        len +%= 18;
    }
    if (cmd.gen_global_isel_combiner) {
        len +%= 27;
    }
    if (cmd.gen_x86_EVEX2VEX_tables) {
        len +%= 26;
    }
    if (cmd.gen_x86_fold_tables) {
        len +%= 22;
    }
    if (cmd.gen_x86_mnemonic_tables) {
        len +%= 26;
    }
    if (cmd.gen_register_bank) {
        len +%= 20;
    }
    if (cmd.gen_exegesis) {
        len +%= 15;
    }
    if (cmd.gen_automata) {
        len +%= 15;
    }
    if (cmd.gen_directive_decl) {
        len +%= 21;
    }
    if (cmd.gen_directive_impl) {
        len +%= 21;
    }
    if (cmd.gen_dxil_operation) {
        len +%= 21;
    }
    if (cmd.gen_riscv_target_def) {
        len +%= 23;
    }
    if (cmd.output) |output| {
        len +%= 3;
        len +%= output.len;
        len +%= 1;
    }
    return len +% root_path.tblgenLength();
}
