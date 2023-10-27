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
        ptr += fmt.Ud64.formatWriteBuf(.{ .value = passes }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.main_mod_path) |main_mod_path| {
        ptr[0..16].* = "--main-mod-path\x00".*;
        ptr += 16;
        ptr = fmt.strcpyEqu(ptr, main_mod_path);
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
    if (cmd.data_sections) |data_sections| {
        if (data_sections) {
            ptr[0..16].* = "-fdata-sections\x00".*;
            ptr += 16;
        } else {
            ptr[0..19].* = "-fno-data-sections\x00".*;
            ptr += 19;
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
            ptr[0..6].* = "-flld\x00".*;
            ptr += 6;
        } else {
            ptr[0..9].* = "-fno-lld\x00".*;
            ptr += 9;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            ptr[0..7].* = "-fllvm\x00".*;
            ptr += 7;
        } else {
            ptr[0..10].* = "-fno-llvm\x00".*;
            ptr += 10;
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
        ptr += fmt.Ud64.formatWriteBuf(.{ .value = stack }, ptr);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.image_base) |image_base| {
        ptr[0..13].* = "--image-base\x00".*;
        ptr += 13;
        ptr += fmt.Ud64.formatWriteBuf(.{ .value = image_base }, ptr);
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
    if (cmd.incremental_compilation) {
        ptr[0..20].* = "--debug-incremental\x00".*;
        ptr += 20;
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
        len +%= fmt.Ud64.formatLength(.{ .value = passes });
        len +%= 1;
    }
    if (cmd.main_mod_path) |main_mod_path| {
        len +%= 16;
        len +%= main_mod_path.len;
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
    if (cmd.data_sections) |data_sections| {
        if (data_sections) {
            len +%= 16;
        } else {
            len +%= 19;
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
    if (cmd.llvm) |llvm| {
        if (llvm) {
            len +%= 7;
        } else {
            len +%= 10;
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
        len +%= fmt.Ud64.formatLength(.{ .value = stack });
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        len +%= 13;
        len +%= fmt.Ud64.formatLength(.{ .value = image_base });
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
    if (cmd.incremental_compilation) {
        len +%= 20;
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
        ptr += fmt.Ud64.formatWriteBuf(.{ .value = pad_to }, ptr);
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
        len +%= fmt.Ud64.formatLength(.{ .value = pad_to });
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
