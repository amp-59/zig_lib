const fmt = @import("../fmt.zig");
const file = @import("../file.zig");
const tasks = @import("./tasks.zig");
const types = @import("./types.zig");
pub usingnamespace @import("../start.zig");
export fn formatWriteBufBuildCommand(cmd: *tasks.BuildCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize, buf: [*]u8) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..6].* = "build-".*;
    ptr += 6;
    ptr = fmt.strcpyEqu(ptr, @tagName(cmd.kind));
    ptr[0] = 0;
    ptr += 1;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..11].* = "-femit-bin\x3d".*;
                    ptr += 11;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..11].* = "-femit-bin\x00".*;
                    ptr += 11;
                }
            },
            .no => {
                ptr[0..14].* = "-fno-emit-bin\x00".*;
                ptr += 14;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..11].* = "-femit-asm\x3d".*;
                    ptr += 11;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..11].* = "-femit-asm\x00".*;
                    ptr += 11;
                }
            },
            .no => {
                ptr[0..14].* = "-fno-emit-asm\x00".*;
                ptr += 14;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..15].* = "-femit-llvm-ir\x3d".*;
                    ptr += 15;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..15].* = "-femit-llvm-ir\x00".*;
                    ptr += 15;
                }
            },
            .no => {
                ptr[0..18].* = "-fno-emit-llvm-ir\x00".*;
                ptr += 18;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..15].* = "-femit-llvm-bc\x3d".*;
                    ptr += 15;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..15].* = "-femit-llvm-bc\x00".*;
                    ptr += 15;
                }
            },
            .no => {
                ptr[0..18].* = "-fno-emit-llvm-bc\x00".*;
                ptr += 18;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..9].* = "-femit-h\x3d".*;
                    ptr += 9;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..9].* = "-femit-h\x00".*;
                    ptr += 9;
                }
            },
            .no => {
                ptr[0..12].* = "-fno-emit-h\x00".*;
                ptr += 12;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..12].* = "-femit-docs\x3d".*;
                    ptr += 12;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..12].* = "-femit-docs\x00".*;
                    ptr += 12;
                }
            },
            .no => {
                ptr[0..15].* = "-fno-emit-docs\x00".*;
                ptr += 15;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..16].* = "-femit-analysis\x3d".*;
                    ptr += 16;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..16].* = "-femit-analysis\x00".*;
                    ptr += 16;
                }
            },
            .no => {
                ptr[0..19].* = "-fno-emit-analysis\x00".*;
                ptr += 19;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr[0..14].* = "-femit-implib\x3d".*;
                    ptr += 14;
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr[0..14].* = "-femit-implib\x00".*;
                    ptr += 14;
                }
            },
            .no => {
                ptr[0..17].* = "-fno-emit-implib\x00".*;
                ptr += 17;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        ptr[0..12].* = "--cache-dir\x00".*;
        ptr += 12;
        ptr = fmt.strcpyEqu(ptr, cache_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        ptr[0..19].* = "--global-cache-dir\x00".*;
        ptr += 19;
        ptr = fmt.strcpyEqu(ptr, global_cache_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        ptr[0..14].* = "--zig-lib-dir\x00".*;
        ptr += 14;
        ptr = fmt.strcpyEqu(ptr, zig_lib_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.listen) |listen| {
        ptr[0..9].* = "--listen\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, @tagName(listen));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.target) |target| {
        ptr[0..8].* = "-target\x00".*;
        ptr += 8;
        ptr = fmt.strcpyEqu(ptr, target);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.cpu) |cpu| {
        ptr[0..6].* = "-mcpu\x00".*;
        ptr += 6;
        ptr = fmt.strcpyEqu(ptr, cpu);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.code_model) |code_model| {
        ptr[0..9].* = "-mcmodel\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, @tagName(code_model));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            ptr[0..11].* = "-mred-zone\x00".*;
            ptr += 11;
        } else {
            ptr[0..14].* = "-mno-red-zone\x00".*;
            ptr += 14;
        }
    }
    if (cmd.implicit_builtins) |implicit_builtins| {
        if (implicit_builtins) {
            ptr[0..10].* = "-fbuiltin\x00".*;
            ptr += 10;
        } else {
            ptr[0..13].* = "-fno-builtin\x00".*;
            ptr += 13;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            ptr[0..21].* = "-fomit-frame-pointer\x00".*;
            ptr += 21;
        } else {
            ptr[0..24].* = "-fno-omit-frame-pointer\x00".*;
            ptr += 24;
        }
    }
    if (cmd.exec_model) |exec_model| {
        ptr[0..13].* = "-mexec-model\x00".*;
        ptr += 13;
        ptr = fmt.strcpyEqu(ptr, exec_model);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.name) |name| {
        ptr[0..7].* = "--name\x00".*;
        ptr += 7;
        ptr = fmt.strcpyEqu(ptr, name);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                ptr[0..9].* = "-fsoname\x00".*;
                ptr += 9;
                ptr = fmt.strcpyEqu(ptr, arg);
                ptr[0] = 0;
                ptr += 1;
            },
            .no => {
                ptr[0..12].* = "-fno-soname\x00".*;
                ptr += 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        ptr[0..3].* = "-O\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, @tagName(mode));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.passes) |passes| {
        ptr[0..19].* = "-fopt-bisect-limit\x3d".*;
        ptr += 19;
        ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = passes }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        ptr[0..16].* = "--main-pkg-path\x00".*;
        ptr += 16;
        ptr = fmt.strcpyEqu(ptr, main_pkg_path);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            ptr[0..6].* = "-fPIC\x00".*;
            ptr += 6;
        } else {
            ptr[0..9].* = "-fno-PIC\x00".*;
            ptr += 9;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            ptr[0..6].* = "-fPIE\x00".*;
            ptr += 6;
        } else {
            ptr[0..9].* = "-fno-PIE\x00".*;
            ptr += 9;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            ptr[0..6].* = "-flto\x00".*;
            ptr += 6;
        } else {
            ptr[0..9].* = "-fno-lto\x00".*;
            ptr += 9;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            ptr[0..14].* = "-fstack-check\x00".*;
            ptr += 14;
        } else {
            ptr[0..17].* = "-fno-stack-check\x00".*;
            ptr += 17;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            ptr[0..18].* = "-fstack-protector\x00".*;
            ptr += 18;
        } else {
            ptr[0..21].* = "-fno-stack-protector\x00".*;
            ptr += 21;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            ptr[0..13].* = "-fsanitize-c\x00".*;
            ptr += 13;
        } else {
            ptr[0..16].* = "-fno-sanitize-c\x00".*;
            ptr += 16;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            ptr[0..11].* = "-fvalgrind\x00".*;
            ptr += 11;
        } else {
            ptr[0..14].* = "-fno-valgrind\x00".*;
            ptr += 14;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            ptr[0..18].* = "-fsanitize-thread\x00".*;
            ptr += 18;
        } else {
            ptr[0..21].* = "-fno-sanitize-thread\x00".*;
            ptr += 21;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            ptr[0..16].* = "-funwind-tables\x00".*;
            ptr += 16;
        } else {
            ptr[0..19].* = "-fno-unwind-tables\x00".*;
            ptr += 19;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            ptr[0..18].* = "-freference-trace\x00".*;
            ptr += 18;
        } else {
            ptr[0..21].* = "-fno-reference-trace\x00".*;
            ptr += 21;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            ptr[0..16].* = "-ferror-tracing\x00".*;
            ptr += 16;
        } else {
            ptr[0..19].* = "-fno-error-tracing\x00".*;
            ptr += 19;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            ptr[0..18].* = "-fsingle-threaded\x00".*;
            ptr += 18;
        } else {
            ptr[0..21].* = "-fno-single-threaded\x00".*;
            ptr += 21;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            ptr[0..20].* = "-ffunction-sections\x00".*;
            ptr += 20;
        } else {
            ptr[0..23].* = "-fno-function-sections\x00".*;
            ptr += 23;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            ptr[0..8].* = "-fstrip\x00".*;
            ptr += 8;
        } else {
            ptr[0..11].* = "-fno-strip\x00".*;
            ptr += 11;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            ptr[0..19].* = "-fformatted-panics\x00".*;
            ptr += 19;
        } else {
            ptr[0..22].* = "-fno-formatted-panics\x00".*;
            ptr += 22;
        }
    }
    if (cmd.format) |format| {
        ptr[0..6].* = "-ofmt\x3d".*;
        ptr += 6;
        ptr = fmt.strcpyEqu(ptr, @tagName(format));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.dirafter) |dirafter| {
        ptr[0..11].* = "-idirafter\x00".*;
        ptr += 11;
        ptr = fmt.strcpyEqu(ptr, dirafter);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.system) |system| {
        ptr[0..9].* = "-isystem\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, system);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.libc) |libc| {
        ptr[0..7].* = "--libc\x00".*;
        ptr += 7;
        ptr = fmt.strcpyEqu(ptr, libc);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.library) |library| {
        ptr[0..10].* = "--library\x00".*;
        ptr += 10;
        ptr = fmt.strcpyEqu(ptr, library);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            ptr[0..3].* = "-I\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            ptr[0..17].* = "--needed-library\x00".*;
            ptr += 17;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            ptr[0..20].* = "--library-directory\x00".*;
            ptr += 20;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.link_script) |link_script| {
        ptr[0..9].* = "--script\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, link_script);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.version_script) |version_script| {
        ptr[0..17].* = "--version-script\x00".*;
        ptr += 17;
        ptr = fmt.strcpyEqu(ptr, version_script);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        ptr[0..17].* = "--dynamic-linker\x00".*;
        ptr += 17;
        ptr = fmt.strcpyEqu(ptr, dynamic_linker);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.sysroot) |sysroot| {
        ptr[0..10].* = "--sysroot\x00".*;
        ptr += 10;
        ptr = fmt.strcpyEqu(ptr, sysroot);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.entry) |entry| {
        ptr[0..8].* = "--entry\x00".*;
        ptr += 8;
        ptr = fmt.strcpyEqu(ptr, entry);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            ptr[0..6].* = "-fLLD\x00".*;
            ptr += 6;
        } else {
            ptr[0..9].* = "-fno-LLD\x00".*;
            ptr += 9;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            ptr[0..14].* = "-fcompiler-rt\x00".*;
            ptr += 14;
        } else {
            ptr[0..17].* = "-fno-compiler-rt\x00".*;
            ptr += 17;
        }
    }
    if (cmd.rpath) |rpath| {
        ptr[0..7].* = "-rpath\x00".*;
        ptr += 7;
        ptr = fmt.strcpyEqu(ptr, rpath);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            ptr[0..17].* = "-feach-lib-rpath\x00".*;
            ptr += 17;
        } else {
            ptr[0..20].* = "-fno-each-lib-rpath\x00".*;
            ptr += 20;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            ptr[0..24].* = "-fallow-shlib-undefined\x00".*;
            ptr += 24;
        } else {
            ptr[0..27].* = "-fno-allow-shlib-undefined\x00".*;
            ptr += 27;
        }
    }
    if (cmd.build_id) |build_id| {
        ptr[0..11].* = "--build-id\x3d".*;
        ptr += 11;
        ptr = fmt.strcpyEqu(ptr, @tagName(build_id));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.eh_frame_hdr) {
        ptr[0..15].* = "--eh-frame-hdr\x00".*;
        ptr += 15;
    }
    if (cmd.emit_relocs) {
        ptr[0..14].* = "--emit-relocs\x00".*;
        ptr += 14;
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            ptr[0..14].* = "--gc-sections\x00".*;
            ptr += 14;
        } else {
            ptr[0..17].* = "--no-gc-sections\x00".*;
            ptr += 17;
        }
    }
    if (cmd.stack) |stack| {
        ptr[0..8].* = "--stack\x00".*;
        ptr += 8;
        ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = stack }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.image_base) |image_base| {
        ptr[0..13].* = "--image-base\x00".*;
        ptr += 13;
        ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = image_base }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.macros) |macros| {
        for (macros) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
    }
    if (cmd.modules) |modules| {
        for (modules) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
    }
    if (cmd.dependencies) |dependencies| {
        ptr += types.ModuleDependencies.formatWriteBuf(.{ .value = dependencies }, ptr);
    }
    if (cmd.cflags) |cflags| {
        ptr += types.ExtraFlags.formatWriteBuf(.{ .value = cflags }, ptr);
    }
    if (cmd.rcflags) |rcflags| {
        ptr += types.ExtraFlags.formatWriteBuf(.{ .value = rcflags }, ptr);
    }
    if (cmd.link_libc) {
        ptr[0..4].* = "-lc\x00".*;
        ptr += 4;
    }
    if (cmd.rdynamic) {
        ptr[0..10].* = "-rdynamic\x00".*;
        ptr += 10;
    }
    if (cmd.dynamic) {
        ptr[0..9].* = "-dynamic\x00".*;
        ptr += 9;
    }
    if (cmd.static) {
        ptr[0..8].* = "-static\x00".*;
        ptr += 8;
    }
    if (cmd.symbolic) {
        ptr[0..11].* = "-Bsymbolic\x00".*;
        ptr += 11;
    }
    if (cmd.link_flags) |link_flags| {
        for (link_flags) |value| {
            ptr[0..3].* = "-z\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, @tagName(value));
            ptr[0] = 0;
            ptr += 1;
        }
    }
    for (files) |value| {
        ptr += value.formatWriteBuf(ptr);
    }
    if (cmd.color) |color| {
        ptr[0..8].* = "--color\x00".*;
        ptr += 8;
        ptr = fmt.strcpyEqu(ptr, @tagName(color));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.time_report) {
        ptr[0..14].* = "-ftime-report\x00".*;
        ptr += 14;
    }
    if (cmd.stack_report) {
        ptr[0..15].* = "-fstack-report\x00".*;
        ptr += 15;
    }
    if (cmd.verbose_link) {
        ptr[0..15].* = "--verbose-link\x00".*;
        ptr += 15;
    }
    if (cmd.verbose_cc) {
        ptr[0..13].* = "--verbose-cc\x00".*;
        ptr += 13;
    }
    if (cmd.verbose_air) {
        ptr[0..14].* = "--verbose-air\x00".*;
        ptr += 14;
    }
    if (cmd.verbose_mir) {
        ptr[0..14].* = "--verbose-mir\x00".*;
        ptr += 14;
    }
    if (cmd.verbose_llvm_ir) {
        ptr[0..18].* = "--verbose-llvm-ir\x00".*;
        ptr += 18;
    }
    if (cmd.verbose_cimport) {
        ptr[0..18].* = "--verbose-cimport\x00".*;
        ptr += 18;
    }
    if (cmd.verbose_llvm_cpu_features) {
        ptr[0..28].* = "--verbose-llvm-cpu-features\x00".*;
        ptr += 28;
    }
    if (cmd.debug_log) |debug_log| {
        ptr[0..12].* = "--debug-log\x00".*;
        ptr += 12;
        ptr = fmt.strcpyEqu(ptr, debug_log);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.debug_compiler_errors) {
        ptr[0..23].* = "--debug-compile-errors\x00".*;
        ptr += 23;
    }
    if (cmd.debug_link_snapshot) {
        ptr[0..22].* = "--debug-link-snapshot\x00".*;
        ptr += 22;
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthBuildCommand(cmd: *tasks.BuildCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= zig_exe.len;
    len +%= 1;
    len +%= 6;
    len +%= @tagName(cmd.kind).len;
    len +%= 1;
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
    if (cmd.implicit_builtins) |implicit_builtins| {
        if (implicit_builtins) {
            len +%= 10;
        } else {
            len +%= 13;
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
        len +%= fmt.Type.Ud64.formatLength(.{ .value = passes });
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
            len +%= 18;
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
        len +%= 11;
        len +%= @tagName(build_id).len;
        len +%= 1;
    }
    if (cmd.eh_frame_hdr) {
        len +%= 15;
    }
    if (cmd.emit_relocs) {
        len +%= 14;
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
        len +%= fmt.Type.Ud64.formatLength(.{ .value = stack });
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        len +%= 13;
        len +%= fmt.Type.Ud64.formatLength(.{ .value = image_base });
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        for (macros) |value| {
            len +%= value.formatLength();
        }
    }
    if (cmd.modules) |modules| {
        for (modules) |value| {
            len +%= value.formatLength();
        }
    }
    if (cmd.dependencies) |dependencies| {
        len +%= types.ModuleDependencies.formatLength(.{ .value = dependencies });
    }
    if (cmd.cflags) |cflags| {
        len +%= types.ExtraFlags.formatLength(.{ .value = cflags });
    }
    if (cmd.rcflags) |rcflags| {
        len +%= types.ExtraFlags.formatLength(.{ .value = rcflags });
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
    if (cmd.link_flags) |link_flags| {
        for (link_flags) |value| {
            len +%= 3;
            len +%= @tagName(value).len;
            len +%= 1;
        }
    }
    for (files) |value| {
        len +%= value.formatLength();
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
    return len;
}
export fn formatWriteBufArchiveCommand(cmd: *tasks.ArchiveCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize, buf: [*]u8) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..3].* = "ar\x00".*;
    ptr += 3;
    if (cmd.format) |format| {
        ptr[0..9].* = "--format\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, @tagName(format));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.plugin) {
        ptr[0..9].* = "--plugin\x00".*;
        ptr += 9;
    }
    if (cmd.output) |output| {
        ptr[0..9].* = "--output\x00".*;
        ptr += 9;
        ptr = fmt.strcpyEqu(ptr, output);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.thin) {
        ptr[0..7].* = "--thin\x00".*;
        ptr += 7;
    }
    if (cmd.after) {
        ptr[0..1].* = "a".*;
        ptr += 1;
    }
    if (cmd.before) {
        ptr[0..1].* = "b".*;
        ptr += 1;
    }
    if (cmd.create) {
        ptr[0..1].* = "c".*;
        ptr += 1;
    }
    if (cmd.zero_ids) {
        ptr[0..1].* = "D".*;
        ptr += 1;
    }
    if (cmd.real_ids) {
        ptr[0..1].* = "U".*;
        ptr += 1;
    }
    if (cmd.append) {
        ptr[0..1].* = "L".*;
        ptr += 1;
    }
    if (cmd.preserve_dates) {
        ptr[0..1].* = "o".*;
        ptr += 1;
    }
    if (cmd.index) {
        ptr[0..1].* = "s".*;
        ptr += 1;
    }
    if (cmd.no_symbol_table) {
        ptr[0..1].* = "S".*;
        ptr += 1;
    }
    if (cmd.update) {
        ptr[0..1].* = "u".*;
        ptr += 1;
    }
    ptr = fmt.strcpyEqu(ptr, @tagName(cmd.operation));
    ptr[0] = 0;
    ptr += 1;
    for (files) |value| {
        ptr += value.formatWriteBuf(ptr);
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthArchiveCommand(cmd: *tasks.ArchiveCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= zig_exe.len;
    len +%= 1;
    len +%= 3;
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
    for (files) |value| {
        len +%= value.formatLength();
    }
    return len;
}
export fn formatWriteBufObjcopyCommand(cmd: *tasks.ObjcopyCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, path: types.Path, buf: [*]u8) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..8].* = "objcopy\x00".*;
    ptr += 8;
    if (cmd.output_target) |output_target| {
        ptr[0..16].* = "--output-target\x00".*;
        ptr += 16;
        ptr = fmt.strcpyEqu(ptr, output_target);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.only_section) |only_section| {
        ptr[0..15].* = "--only-section\x00".*;
        ptr += 15;
        ptr = fmt.strcpyEqu(ptr, only_section);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.pad_to) |pad_to| {
        ptr[0..9].* = "--pad-to\x00".*;
        ptr += 9;
        ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = pad_to }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.strip_debug) {
        ptr[0..14].* = "--strip-debug\x00".*;
        ptr += 14;
    }
    if (cmd.strip_all) {
        ptr[0..12].* = "--strip-all\x00".*;
        ptr += 12;
    }
    if (cmd.debug_only) {
        ptr[0..18].* = "--only-keep-debug\x00".*;
        ptr += 18;
    }
    if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
        ptr[0..20].* = "--add-gnu-debuglink\x00".*;
        ptr += 20;
        ptr = fmt.strcpyEqu(ptr, add_gnu_debuglink);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.extract_to) |extract_to| {
        ptr[0..13].* = "--extract-to\x00".*;
        ptr += 13;
        ptr = fmt.strcpyEqu(ptr, extract_to);
        ptr[0] = 0;
        ptr += 1;
    }
    ptr += path.formatWriteBuf(ptr);
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthObjcopyCommand(cmd: *tasks.ObjcopyCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, path: types.Path) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= zig_exe.len;
    len +%= 1;
    len +%= 8;
    if (cmd.output_target) |output_target| {
        len +%= 16;
        len +%= output_target.len;
        len +%= 1;
    }
    if (cmd.only_section) |only_section| {
        len +%= 15;
        len +%= only_section.len;
        len +%= 1;
    }
    if (cmd.pad_to) |pad_to| {
        len +%= 9;
        len +%= fmt.Type.Ud64.formatLength(.{ .value = pad_to });
        len +%= 1;
    }
    if (cmd.strip_debug) {
        len +%= 14;
    }
    if (cmd.strip_all) {
        len +%= 12;
    }
    if (cmd.debug_only) {
        len +%= 18;
    }
    if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
        len +%= 20;
        len +%= add_gnu_debuglink.len;
        len +%= 1;
    }
    if (cmd.extract_to) |extract_to| {
        len +%= 13;
        len +%= extract_to.len;
        len +%= 1;
    }
    len +%= path.formatLength();
    return len;
}
export fn formatWriteBufHarecCommand(cmd: *tasks.HarecCommand, harec_exe_ptr: [*]const u8, harec_exe_len: usize, buf: [*]u8) callconv(.C) usize {
    const harec_exe: []const u8 = harec_exe_ptr[0..harec_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, harec_exe);
    ptr[0] = 0;
    ptr += 1;
    if (cmd.arch) |arch| {
        ptr[0..3].* = "-a\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, arch);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.defs) |defs| {
        ptr += types.Macros.formatWriteBuf(.{ .value = defs }, ptr);
    }
    if (cmd.output) |output| {
        ptr[0..3].* = "-o\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, output);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.tags) |tags| {
        for (tags) |value| {
            ptr[0..2].* = "-T".*;
            ptr += 2;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.typedefs) {
        ptr[0..3].* = "-t\x00".*;
        ptr += 3;
    }
    if (cmd.namespace) {
        ptr[0..3].* = "-N\x00".*;
        ptr += 3;
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthHarecCommand(cmd: *tasks.HarecCommand, harec_exe_ptr: [*]const u8, harec_exe_len: usize) callconv(.C) usize {
    const harec_exe: []const u8 = harec_exe_ptr[0..harec_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= harec_exe.len;
    len +%= 1;
    if (cmd.arch) |arch| {
        len +%= 3;
        len +%= arch.len;
        len +%= 1;
    }
    if (cmd.defs) |defs| {
        len +%= types.Macros.formatLength(.{ .value = defs });
    }
    if (cmd.output) |output| {
        len +%= 3;
        len +%= output.len;
        len +%= 1;
    }
    if (cmd.tags) |tags| {
        for (tags) |value| {
            len +%= 2;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.typedefs) {
        len +%= 3;
    }
    if (cmd.namespace) {
        len +%= 3;
    }
    return len;
}
export fn formatWriteBufTableGenCommand(cmd: *tasks.TableGenCommand, buf: [*]u8) callconv(.C) usize {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    if (cmd.color) |color| {
        ptr[0..8].* = "--color\x00".*;
        ptr += 8;
        ptr = fmt.strcpyEqu(ptr, @tagName(color));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.macros) |macros| {
        ptr += types.Macros.formatWriteBuf(.{ .value = macros }, ptr);
    }
    if (cmd.include) |include| {
        for (include) |value| {
            ptr[0..2].* = "-I".*;
            ptr += 2;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.dependencies) |dependencies| {
        for (dependencies) |value| {
            ptr[0..3].* = "-d\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.print_records) {
        ptr[0..16].* = "--print-records\x00".*;
        ptr += 16;
    }
    if (cmd.print_detailed_records) {
        ptr[0..25].* = "--print-detailed-records\x00".*;
        ptr += 25;
    }
    if (cmd.null_backend) {
        ptr[0..15].* = "--null-backend\x00".*;
        ptr += 15;
    }
    if (cmd.dump_json) {
        ptr[0..12].* = "--dump-json\x00".*;
        ptr += 12;
    }
    if (cmd.gen_emitter) {
        ptr[0..14].* = "--gen-emitter\x00".*;
        ptr += 14;
    }
    if (cmd.gen_register_info) {
        ptr[0..20].* = "--gen-register-info\x00".*;
        ptr += 20;
    }
    if (cmd.gen_instr_info) {
        ptr[0..17].* = "--gen-instr-info\x00".*;
        ptr += 17;
    }
    if (cmd.gen_instr_docs) {
        ptr[0..17].* = "--gen-instr-docs\x00".*;
        ptr += 17;
    }
    if (cmd.gen_callingconv) {
        ptr[0..18].* = "--gen-callingconv\x00".*;
        ptr += 18;
    }
    if (cmd.gen_asm_writer) {
        ptr[0..17].* = "--gen-asm-writer\x00".*;
        ptr += 17;
    }
    if (cmd.gen_disassembler) {
        ptr[0..19].* = "--gen-disassembler\x00".*;
        ptr += 19;
    }
    if (cmd.gen_pseudo_lowering) {
        ptr[0..22].* = "--gen-pseudo-lowering\x00".*;
        ptr += 22;
    }
    if (cmd.gen_compress_inst_emitter) {
        ptr[0..28].* = "--gen-compress-inst-emitter\x00".*;
        ptr += 28;
    }
    if (cmd.gen_asm_matcher) {
        ptr[0..18].* = "--gen-asm-matcher\x00".*;
        ptr += 18;
    }
    if (cmd.gen_dag_isel) {
        ptr[0..15].* = "--gen-dag-isel\x00".*;
        ptr += 15;
    }
    if (cmd.gen_dfa_packetizer) {
        ptr[0..21].* = "--gen-dfa-packetizer\x00".*;
        ptr += 21;
    }
    if (cmd.gen_fast_isel) {
        ptr[0..16].* = "--gen-fast-isel\x00".*;
        ptr += 16;
    }
    if (cmd.gen_subtarget) {
        ptr[0..16].* = "--gen-subtarget\x00".*;
        ptr += 16;
    }
    if (cmd.gen_intrinsic_enums) {
        ptr[0..22].* = "--gen-intrinsic-enums\x00".*;
        ptr += 22;
    }
    if (cmd.gen_intrinsic_impl) {
        ptr[0..21].* = "--gen-intrinsic-impl\x00".*;
        ptr += 21;
    }
    if (cmd.print_enums) {
        ptr[0..14].* = "--print-enums\x00".*;
        ptr += 14;
    }
    if (cmd.print_sets) {
        ptr[0..13].* = "--print-sets\x00".*;
        ptr += 13;
    }
    if (cmd.gen_opt_parser_defs) {
        ptr[0..22].* = "--gen-opt-parser-defs\x00".*;
        ptr += 22;
    }
    if (cmd.gen_opt_rst) {
        ptr[0..14].* = "--gen-opt-rst\x00".*;
        ptr += 14;
    }
    if (cmd.gen_ctags) {
        ptr[0..12].* = "--gen-ctags\x00".*;
        ptr += 12;
    }
    if (cmd.gen_attrs) {
        ptr[0..12].* = "--gen-attrs\x00".*;
        ptr += 12;
    }
    if (cmd.gen_searchable_tables) {
        ptr[0..24].* = "--gen-searchable-tables\x00".*;
        ptr += 24;
    }
    if (cmd.gen_global_isel) {
        ptr[0..18].* = "--gen-global-isel\x00".*;
        ptr += 18;
    }
    if (cmd.gen_global_isel_combiner) {
        ptr[0..27].* = "--gen-global-isel-combiner\x00".*;
        ptr += 27;
    }
    if (cmd.gen_x86_EVEX2VEX_tables) {
        ptr[0..26].* = "--gen-x86-EVEX2VEX-tables\x00".*;
        ptr += 26;
    }
    if (cmd.gen_x86_fold_tables) {
        ptr[0..22].* = "--gen-x86-fold-tables\x00".*;
        ptr += 22;
    }
    if (cmd.gen_x86_mnemonic_tables) {
        ptr[0..26].* = "--gen-x86-mnemonic-tables\x00".*;
        ptr += 26;
    }
    if (cmd.gen_register_bank) {
        ptr[0..20].* = "--gen-register-bank\x00".*;
        ptr += 20;
    }
    if (cmd.gen_exegesis) {
        ptr[0..15].* = "--gen-exegesis\x00".*;
        ptr += 15;
    }
    if (cmd.gen_automata) {
        ptr[0..15].* = "--gen-automata\x00".*;
        ptr += 15;
    }
    if (cmd.gen_directive_decl) {
        ptr[0..21].* = "--gen-directive-decl\x00".*;
        ptr += 21;
    }
    if (cmd.gen_directive_impl) {
        ptr[0..21].* = "--gen-directive-impl\x00".*;
        ptr += 21;
    }
    if (cmd.gen_dxil_operation) {
        ptr[0..21].* = "--gen-dxil-operation\x00".*;
        ptr += 21;
    }
    if (cmd.gen_riscv_target_def) {
        ptr[0..23].* = "--gen-riscv-target_def\x00".*;
        ptr += 23;
    }
    if (cmd.output) |output| {
        ptr[0..3].* = "-o\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, output);
        ptr[0] = 0;
        ptr += 1;
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthTableGenCommand(cmd: *tasks.TableGenCommand) callconv(.C) usize {
    @setRuntimeSafety(false);
    var len: usize = 0;
    if (cmd.color) |color| {
        len +%= 8;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.macros) |macros| {
        len +%= types.Macros.formatLength(.{ .value = macros });
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 2;
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
    return len;
}
export fn formatWriteBufLLCCommand(cmd: *tasks.LLCCommand, buf: [*]u8) callconv(.C) usize {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    if (cmd.color) {
        ptr[0..8].* = "--color\x00".*;
        ptr += 8;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            ptr[0..3].* = "-I\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.optimize) |optimize| {
        ptr[0..3].* = "-O\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, @tagName(optimize));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.emit_addrsig) {
        ptr[0..10].* = "--addrsig\x00".*;
        ptr += 10;
    }
    if (cmd.align_loops) |align_loops| {
        ptr[0..14].* = "--align-loops\x00".*;
        ptr += 14;
        ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = align_loops }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.aarch64_use_aa) {
        ptr[0..17].* = "--aarch64-use-aa\x00".*;
        ptr += 17;
    }
    if (cmd.abort_on_max_devirt_iterations_reached) {
        ptr[0..41].* = "--abort-on-max-devirt-iterations-reached\x00".*;
        ptr += 41;
    }
    if (cmd.allow_ginsert_as_artifact) {
        ptr[0..28].* = "--allow-ginsert-as-artifact\x00".*;
        ptr += 28;
    }
    if (cmd.amdgpu_bypass_slow_div) {
        ptr[0..25].* = "--amdgpu-bypass-slow-div\x00".*;
        ptr += 25;
    }
    if (cmd.amdgpu_disable_loop_alignment) {
        ptr[0..32].* = "--amdgpu-disable-loop-alignment\x00".*;
        ptr += 32;
    }
    if (cmd.amdgpu_dpp_combine) {
        ptr[0..21].* = "--amdgpu-dpp-combine\x00".*;
        ptr += 21;
    }
    if (cmd.amdgpu_dump_hsa_metadata) {
        ptr[0..27].* = "--amdgpu-dump-hsa-metadata\x00".*;
        ptr += 27;
    }
    if (cmd.amdgpu_enable_merge_m0) {
        ptr[0..25].* = "--amdgpu-enable-merge-m0\x00".*;
        ptr += 25;
    }
    if (cmd.amdgpu_enable_power_sched) {
        ptr[0..28].* = "--amdgpu-enable-power-sched\x00".*;
        ptr += 28;
    }
    if (cmd.amdgpu_sdwa_peephole) {
        ptr[0..23].* = "--amdgpu-sdwa-peephole\x00".*;
        ptr += 23;
    }
    if (cmd.amdgpu_use_aa_in_codegen) {
        ptr[0..27].* = "--amdgpu-use-aa-in-codegen\x00".*;
        ptr += 27;
    }
    if (cmd.amdgpu_verify_hsa_metadata) {
        ptr[0..29].* = "--amdgpu-verify-hsa-metadata\x00".*;
        ptr += 29;
    }
    if (cmd.amdgpu_vgpr_index_mode) {
        ptr[0..25].* = "--amdgpu-vgpr-index-mode\x00".*;
        ptr += 25;
    }
    if (cmd.asm_show_inst) {
        ptr[0..16].* = "--asm-show-inst\x00".*;
        ptr += 16;
    }
    if (cmd.asm_verbose) {
        ptr[0..14].* = "--asm-verbose\x00".*;
        ptr += 14;
    }
    if (cmd.atomic_counter_update_promoted) {
        ptr[0..33].* = "--atomic-counter-update-promoted\x00".*;
        ptr += 33;
    }
    if (cmd.atomic_first_counter) {
        ptr[0..23].* = "--atomic-first-counter\x00".*;
        ptr += 23;
    }
    if (cmd.bounds_checking_single_trap) {
        ptr[0..30].* = "--bounds-checking-single-trap\x00".*;
        ptr += 30;
    }
    if (cmd.cs_profile_generate) {
        ptr[0..22].* = "--cs-profile-generate\x00".*;
        ptr += 22;
    }
    if (cmd.data_sections) {
        ptr[0..16].* = "--data-sections\x00".*;
        ptr += 16;
    }
    if (cmd.debug_entry_values) {
        ptr[0..21].* = "--debug-entry-values\x00".*;
        ptr += 21;
    }
    if (cmd.debug_info_correlate) {
        ptr[0..23].* = "--debug-info-correlate\x00".*;
        ptr += 23;
    }
    if (cmd.debugify_quiet) {
        ptr[0..17].* = "--debugify-quiet\x00".*;
        ptr += 17;
    }
    if (cmd.disable_promote_alloca_to_lds) {
        ptr[0..32].* = "--disable-promote-alloca-to-lds\x00".*;
        ptr += 32;
    }
    if (cmd.disable_promote_alloca_to_vector) {
        ptr[0..35].* = "--disable-promote-alloca-to-vector\x00".*;
        ptr += 35;
    }
    if (cmd.disable_simplify_libcalls) {
        ptr[0..28].* = "--disable-simplify-libcalls\x00".*;
        ptr += 28;
    }
    if (cmd.disable_tail_calls) {
        ptr[0..21].* = "--disable-tail-calls\x00".*;
        ptr += 21;
    }
    if (cmd.do_counter_promotion) {
        ptr[0..23].* = "--do-counter-promotion\x00".*;
        ptr += 23;
    }
    if (cmd.dwarf64) {
        ptr[0..10].* = "--dwarf64\x00".*;
        ptr += 10;
    }
    if (cmd.emit_call_site_info) {
        ptr[0..22].* = "--emit-call-site-info\x00".*;
        ptr += 22;
    }
    if (cmd.emulated_tls) {
        ptr[0..15].* = "--emulated-tls\x00".*;
        ptr += 15;
    }
    if (cmd.enable_approx_func_fp_math) {
        ptr[0..29].* = "--enable-approx-func-fp-math\x00".*;
        ptr += 29;
    }
    if (cmd.enable_cse_in_irtranslator) {
        ptr[0..29].* = "--enable-cse-in-irtranslator\x00".*;
        ptr += 29;
    }
    if (cmd.enable_cse_in_legalizer) {
        ptr[0..26].* = "--enable-cse-in-legalizer\x00".*;
        ptr += 26;
    }
    if (cmd.enable_emscripten_cxx_exceptions) {
        ptr[0..35].* = "--enable-emscripten-cxx-exceptions\x00".*;
        ptr += 35;
    }
    if (cmd.enable_emscripten_sjlj) {
        ptr[0..25].* = "--enable-emscripten-sjlj\x00".*;
        ptr += 25;
    }
    if (cmd.enable_gvn_hoist) {
        ptr[0..19].* = "--enable-gvn-hoist\x00".*;
        ptr += 19;
    }
    if (cmd.enable_gvn_sink) {
        ptr[0..18].* = "--enable-gvn-sink\x00".*;
        ptr += 18;
    }
    if (cmd.enable_jmc_instrument) {
        ptr[0..24].* = "--enable-jmc-instrument\x00".*;
        ptr += 24;
    }
    if (cmd.enable_name_compression) {
        ptr[0..26].* = "--enable-name-compression\x00".*;
        ptr += 26;
    }
    if (cmd.enable_no_infs_fp_math) {
        ptr[0..25].* = "--enable-no-infs-fp-math\x00".*;
        ptr += 25;
    }
    if (cmd.enable_no_nans_fp_math) {
        ptr[0..25].* = "--enable-no-nans-fp-math\x00".*;
        ptr += 25;
    }
    if (cmd.enable_no_signed_zeros_fp_math) {
        ptr[0..33].* = "--enable-no-signed-zeros-fp-math\x00".*;
        ptr += 33;
    }
    if (cmd.enable_no_trapping_fp_math) {
        ptr[0..29].* = "--enable-no-trapping-fp-math\x00".*;
        ptr += 29;
    }
    if (cmd.enable_split_backedge_in_load_pre) {
        ptr[0..24].* = "--enable-unsafe-fp-math\x00".*;
        ptr += 24;
    }
    if (cmd.enable_unsafe_fp_math) {
        ptr[0..24].* = "--enable-unsafe-fp-math\x00".*;
        ptr += 24;
    }
    if (cmd.experimental_debug_variable_locations) {
        ptr[0..40].* = "--experimental-debug-variable-locations\x00".*;
        ptr += 40;
    }
    if (cmd.fatal_warnings) {
        ptr[0..17].* = "--fatal-warnings\x00".*;
        ptr += 17;
    }
    if (cmd.force_dwarf_frame_section) {
        ptr[0..28].* = "--force-dwarf-frame-section\x00".*;
        ptr += 28;
    }
    if (cmd.function_sections) {
        ptr[0..20].* = "--function-sections\x00".*;
        ptr += 20;
    }
    if (cmd.generate_merged_base_profiles) {
        ptr[0..32].* = "--generate-merged-base-profiles\x00".*;
        ptr += 32;
    }
    if (cmd.hash_based_counter_split) {
        ptr[0..27].* = "--hash-based-counter-split\x00".*;
        ptr += 27;
    }
    if (cmd.hot_cold_split) {
        ptr[0..17].* = "--hot-cold-split\x00".*;
        ptr += 17;
    }
    if (cmd.ignore_xcoff_visibility) {
        ptr[0..26].* = "--ignore-xcoff-visibility\x00".*;
        ptr += 26;
    }
    if (cmd.import_all_index) {
        ptr[0..19].* = "--import-all-index\x00".*;
        ptr += 19;
    }
    if (cmd.incremental_linker_compatible) {
        ptr[0..32].* = "--incremental-linker-compatible\x00".*;
        ptr += 32;
    }
    if (cmd.instcombine_code_sinking) {
        ptr[0..27].* = "--instcombine-code-sinking\x00".*;
        ptr += 27;
    }
    if (cmd.instcombine_negator_enabled) {
        ptr[0..30].* = "--instcombine-negator-enabled\x00".*;
        ptr += 30;
    }
    if (cmd.instrprof_atomic_counter_update_all) {
        ptr[0..38].* = "--instrprof-atomic-counter-update-all\x00".*;
        ptr += 38;
    }
    if (cmd.mips16_constant_islands) {
        ptr[0..26].* = "--mips16-constant-islands\x00".*;
        ptr += 26;
    }
    if (cmd.mips16_hard_float) {
        ptr[0..20].* = "--mips16-hard-float\x00".*;
        ptr += 20;
    }
    if (cmd.mir_strip_debugify_only) {
        ptr[0..26].* = "--mir-strip-debugify-only\x00".*;
        ptr += 26;
    }
    if (cmd.mno_compound) {
        ptr[0..15].* = "--mno-compound\x00".*;
        ptr += 15;
    }
    if (cmd.mno_fixup) {
        ptr[0..12].* = "--mno-fixup\x00".*;
        ptr += 12;
    }
    if (cmd.mno_ldc1_sdc1) {
        ptr[0..16].* = "--mno-ldc1-sdc1\x00".*;
        ptr += 16;
    }
    if (cmd.mno_pairing) {
        ptr[0..14].* = "--mno-pairing\x00".*;
        ptr += 14;
    }
    if (cmd.mwarn_missing_parenthesis) {
        ptr[0..28].* = "--mwarn-missing-parenthesis\x00".*;
        ptr += 28;
    }
    if (cmd.mwarn_noncontigious_register) {
        ptr[0..31].* = "--mwarn-noncontigious-register\x00".*;
        ptr += 31;
    }
    if (cmd.mwarn_sign_mismatch) {
        ptr[0..22].* = "--mwarn-sign-mismatch\x00".*;
        ptr += 22;
    }
    if (cmd.no_deprecated_warn) {
        ptr[0..21].* = "--no-deprecated-warn\x00".*;
        ptr += 21;
    }
    if (cmd.no_discriminators) {
        ptr[0..20].* = "--no-discriminators\x00".*;
        ptr += 20;
    }
    if (cmd.no_type_check) {
        ptr[0..16].* = "--no-type-check\x00".*;
        ptr += 16;
    }
    if (cmd.no_warn) {
        ptr[0..10].* = "--no-warn\x00".*;
        ptr += 10;
    }
    if (cmd.no_xray_index) {
        ptr[0..16].* = "--no-xray-index\x00".*;
        ptr += 16;
    }
    if (cmd.nozero_initialized_in_bss) {
        ptr[0..28].* = "--nozero-initialized-in-bss\x00".*;
        ptr += 28;
    }
    if (cmd.nvptx_sched4reg) {
        ptr[0..18].* = "--nvptx-sched4reg\x00".*;
        ptr += 18;
    }
    if (cmd.opaque_pointers) {
        ptr[0..18].* = "--opaque-pointers\x00".*;
        ptr += 18;
    }
    if (cmd.poison_checking_function_local) {
        ptr[0..33].* = "--poison-checking-function-local\x00".*;
        ptr += 33;
    }
    if (cmd.print_pipeline_passes) {
        ptr[0..24].* = "--print-pipeline-passes\x00".*;
        ptr += 24;
    }
    if (cmd.r600_ir_structurize) {
        ptr[0..22].* = "--r600-ir-structurize\x00".*;
        ptr += 22;
    }
    if (cmd.rdf_dump) {
        ptr[0..11].* = "--rdf-dump\x00".*;
        ptr += 11;
    }
    if (cmd.relax_elf_relocations) {
        ptr[0..24].* = "--relax-elf-relocations\x00".*;
        ptr += 24;
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthLLCCommand(cmd: *tasks.LLCCommand) callconv(.C) usize {
    @setRuntimeSafety(false);
    var len: usize = 0;
    if (cmd.color) {
        len +%= 8;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 3;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.optimize) |optimize| {
        len +%= 3;
        len +%= @tagName(optimize).len;
        len +%= 1;
    }
    if (cmd.emit_addrsig) {
        len +%= 10;
    }
    if (cmd.align_loops) |align_loops| {
        len +%= 14;
        len +%= fmt.Type.Ud64.formatLength(.{ .value = align_loops });
        len +%= 1;
    }
    if (cmd.aarch64_use_aa) {
        len +%= 17;
    }
    if (cmd.abort_on_max_devirt_iterations_reached) {
        len +%= 41;
    }
    if (cmd.allow_ginsert_as_artifact) {
        len +%= 28;
    }
    if (cmd.amdgpu_bypass_slow_div) {
        len +%= 25;
    }
    if (cmd.amdgpu_disable_loop_alignment) {
        len +%= 32;
    }
    if (cmd.amdgpu_dpp_combine) {
        len +%= 21;
    }
    if (cmd.amdgpu_dump_hsa_metadata) {
        len +%= 27;
    }
    if (cmd.amdgpu_enable_merge_m0) {
        len +%= 25;
    }
    if (cmd.amdgpu_enable_power_sched) {
        len +%= 28;
    }
    if (cmd.amdgpu_sdwa_peephole) {
        len +%= 23;
    }
    if (cmd.amdgpu_use_aa_in_codegen) {
        len +%= 27;
    }
    if (cmd.amdgpu_verify_hsa_metadata) {
        len +%= 29;
    }
    if (cmd.amdgpu_vgpr_index_mode) {
        len +%= 25;
    }
    if (cmd.asm_show_inst) {
        len +%= 16;
    }
    if (cmd.asm_verbose) {
        len +%= 14;
    }
    if (cmd.atomic_counter_update_promoted) {
        len +%= 33;
    }
    if (cmd.atomic_first_counter) {
        len +%= 23;
    }
    if (cmd.bounds_checking_single_trap) {
        len +%= 30;
    }
    if (cmd.cs_profile_generate) {
        len +%= 22;
    }
    if (cmd.data_sections) {
        len +%= 16;
    }
    if (cmd.debug_entry_values) {
        len +%= 21;
    }
    if (cmd.debug_info_correlate) {
        len +%= 23;
    }
    if (cmd.debugify_quiet) {
        len +%= 17;
    }
    if (cmd.disable_promote_alloca_to_lds) {
        len +%= 32;
    }
    if (cmd.disable_promote_alloca_to_vector) {
        len +%= 35;
    }
    if (cmd.disable_simplify_libcalls) {
        len +%= 28;
    }
    if (cmd.disable_tail_calls) {
        len +%= 21;
    }
    if (cmd.do_counter_promotion) {
        len +%= 23;
    }
    if (cmd.dwarf64) {
        len +%= 10;
    }
    if (cmd.emit_call_site_info) {
        len +%= 22;
    }
    if (cmd.emulated_tls) {
        len +%= 15;
    }
    if (cmd.enable_approx_func_fp_math) {
        len +%= 29;
    }
    if (cmd.enable_cse_in_irtranslator) {
        len +%= 29;
    }
    if (cmd.enable_cse_in_legalizer) {
        len +%= 26;
    }
    if (cmd.enable_emscripten_cxx_exceptions) {
        len +%= 35;
    }
    if (cmd.enable_emscripten_sjlj) {
        len +%= 25;
    }
    if (cmd.enable_gvn_hoist) {
        len +%= 19;
    }
    if (cmd.enable_gvn_sink) {
        len +%= 18;
    }
    if (cmd.enable_jmc_instrument) {
        len +%= 24;
    }
    if (cmd.enable_name_compression) {
        len +%= 26;
    }
    if (cmd.enable_no_infs_fp_math) {
        len +%= 25;
    }
    if (cmd.enable_no_nans_fp_math) {
        len +%= 25;
    }
    if (cmd.enable_no_signed_zeros_fp_math) {
        len +%= 33;
    }
    if (cmd.enable_no_trapping_fp_math) {
        len +%= 29;
    }
    if (cmd.enable_split_backedge_in_load_pre) {
        len +%= 24;
    }
    if (cmd.enable_unsafe_fp_math) {
        len +%= 24;
    }
    if (cmd.experimental_debug_variable_locations) {
        len +%= 40;
    }
    if (cmd.fatal_warnings) {
        len +%= 17;
    }
    if (cmd.force_dwarf_frame_section) {
        len +%= 28;
    }
    if (cmd.function_sections) {
        len +%= 20;
    }
    if (cmd.generate_merged_base_profiles) {
        len +%= 32;
    }
    if (cmd.hash_based_counter_split) {
        len +%= 27;
    }
    if (cmd.hot_cold_split) {
        len +%= 17;
    }
    if (cmd.ignore_xcoff_visibility) {
        len +%= 26;
    }
    if (cmd.import_all_index) {
        len +%= 19;
    }
    if (cmd.incremental_linker_compatible) {
        len +%= 32;
    }
    if (cmd.instcombine_code_sinking) {
        len +%= 27;
    }
    if (cmd.instcombine_negator_enabled) {
        len +%= 30;
    }
    if (cmd.instrprof_atomic_counter_update_all) {
        len +%= 38;
    }
    if (cmd.mips16_constant_islands) {
        len +%= 26;
    }
    if (cmd.mips16_hard_float) {
        len +%= 20;
    }
    if (cmd.mir_strip_debugify_only) {
        len +%= 26;
    }
    if (cmd.mno_compound) {
        len +%= 15;
    }
    if (cmd.mno_fixup) {
        len +%= 12;
    }
    if (cmd.mno_ldc1_sdc1) {
        len +%= 16;
    }
    if (cmd.mno_pairing) {
        len +%= 14;
    }
    if (cmd.mwarn_missing_parenthesis) {
        len +%= 28;
    }
    if (cmd.mwarn_noncontigious_register) {
        len +%= 31;
    }
    if (cmd.mwarn_sign_mismatch) {
        len +%= 22;
    }
    if (cmd.no_deprecated_warn) {
        len +%= 21;
    }
    if (cmd.no_discriminators) {
        len +%= 20;
    }
    if (cmd.no_type_check) {
        len +%= 16;
    }
    if (cmd.no_warn) {
        len +%= 10;
    }
    if (cmd.no_xray_index) {
        len +%= 16;
    }
    if (cmd.nozero_initialized_in_bss) {
        len +%= 28;
    }
    if (cmd.nvptx_sched4reg) {
        len +%= 18;
    }
    if (cmd.opaque_pointers) {
        len +%= 18;
    }
    if (cmd.poison_checking_function_local) {
        len +%= 33;
    }
    if (cmd.print_pipeline_passes) {
        len +%= 24;
    }
    if (cmd.r600_ir_structurize) {
        len +%= 22;
    }
    if (cmd.rdf_dump) {
        len +%= 11;
    }
    if (cmd.relax_elf_relocations) {
        len +%= 24;
    }
    return len;
}
export fn formatWriteBufFetchCommand(cmd: *tasks.FetchCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, buf: [*]u8) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..5].* = "fetch".*;
    ptr += 5;
    if (cmd.global_cache_root) |global_cache_root| {
        ptr[0..19].* = "--global-cache-dir\x00".*;
        ptr += 19;
        ptr = fmt.strcpyEqu(ptr, global_cache_root);
        ptr[0] = 0;
        ptr += 1;
    }
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthFetchCommand(cmd: *tasks.FetchCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= zig_exe.len;
    len +%= 1;
    len +%= 5;
    if (cmd.global_cache_root) |global_cache_root| {
        len +%= 19;
        len +%= global_cache_root.len;
        len +%= 1;
    }
    return len;
}
export fn formatWriteBufFormatCommand(cmd: *tasks.FormatCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, pathname: types.Path, buf: [*]u8) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..4].* = "fmt\x00".*;
    ptr += 4;
    if (cmd.color) |color| {
        ptr[0..8].* = "--color\x00".*;
        ptr += 8;
        ptr = fmt.strcpyEqu(ptr, @tagName(color));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.stdin) {
        ptr[0..8].* = "--stdin\x00".*;
        ptr += 8;
    }
    if (cmd.check) {
        ptr[0..8].* = "--check\x00".*;
        ptr += 8;
    }
    if (cmd.ast_check) {
        ptr[0..12].* = "--ast-check\x00".*;
        ptr += 12;
    }
    if (cmd.exclude) |exclude| {
        ptr[0..10].* = "--exclude\x00".*;
        ptr += 10;
        ptr = fmt.strcpyEqu(ptr, exclude);
        ptr[0] = 0;
        ptr += 1;
    }
    ptr += pathname.formatWriteBuf(ptr);
    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
export fn formatLengthFormatCommand(cmd: *tasks.FormatCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, pathname: types.Path) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 0;
    len +%= zig_exe.len;
    len +%= 1;
    len +%= 4;
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
    len +%= pathname.formatLength();
    return len;
}
