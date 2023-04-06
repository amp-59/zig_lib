const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const types = @import("./types.zig");
const reinterpret_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = spec.reinterpret.print;
    tmp.composite.map = &.{
        .{
            .in = []const types.ModuleDependency,
            .out = types.ModuleDependencies,
        },
        .{
            .in = []const types.Path,
            .out = types.Files,
        },
    };
    break :blk tmp;
};
pub fn buildLength(cmd: *const types.BuildCommand) u64 {
    var len: u64 = 0;
    if (cmd.builtin) {
        len +%= 10;
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
    if (cmd.color) |how| {
        len +%= 8;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 11;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
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
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 11;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
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
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 15;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                    len +%= 1;
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
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 15;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                    len +%= 1;
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
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 9;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                    len +%= 1;
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
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 12;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                    len +%= 1;
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
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 16;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
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
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    len +%= 14;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
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
    if (cmd.cache_root) |how| {
        len +%= 12;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.global_cache_root) |how| {
        len +%= 19;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.zig_lib_root) |how| {
        len +%= 14;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.enable_cache) {
        len +%= 15;
    }
    if (cmd.target) |how| {
        len +%= 8;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.cpu) |how| {
        len +%= 6;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.code_model) |how| {
        len +%= 9;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
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
    if (cmd.exec_model) |how| {
        len +%= 13;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.name) |how| {
        len +%= 7;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.mode) |how| {
        len +%= 3;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.main_pkg_path) |how| {
        len +%= 16;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
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
    if (cmd.fmt) |how| {
        len +%= 6;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.dirafter) |how| {
        len +%= 10;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.system) |how| {
        len +%= 9;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.include) |how| {
        len +%= 3;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.libc) |how| {
        len +%= 7;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.library) |how| {
        len +%= 10;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.needed_library) |how| {
        len +%= 17;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.library_directory) |how| {
        len +%= 20;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.link_script) |how| {
        len +%= 9;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.version_script) |how| {
        len +%= 17;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.dynamic_linker) |how| {
        len +%= 17;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.sysroot) |how| {
        len +%= 10;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.version) {
        len +%= 10;
    }
    if (cmd.entry) |how| {
        len +%= 8;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |yes_arg| {
                len +%= 9;
                len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                len +%= 1;
            },
            .no => {
                len +%= 12;
            },
        }
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
    if (cmd.rpath) |how| {
        len +%= 7;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
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
    if (cmd.compress_debug_sections) |how| {
        len +%= 26;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            len +%= 14;
        } else {
            len +%= 17;
        }
    }
    if (cmd.stack) |how| {
        len +%= 8;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.image_base) |how| {
        len +%= 13;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.macros) |how| {
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
    }
    if (cmd.modules) |how| {
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
    }
    if (cmd.dependencies) |how| {
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
    }
    if (cmd.cflags) |how| {
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
    }
    if (cmd.z) |how| {
        len +%= 3;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    if (cmd.files) |how| {
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
    }
    return len;
}
pub fn buildWrite(cmd: *const types.BuildCommand, array: anytype) void {
    if (cmd.builtin) {
        array.writeMany("-fbuiltin\x00");
    }
    if (cmd.link_libc) {
        array.writeMany("-lc\x00");
    }
    if (cmd.rdynamic) {
        array.writeMany("-rdynamic\x00");
    }
    if (cmd.dynamic) {
        array.writeMany("-dynamic\x00");
    }
    if (cmd.static) {
        array.writeMany("-static\x00");
    }
    if (cmd.symbolic) {
        array.writeMany("-Bsymbolic\x00");
    }
    if (cmd.color) |how| {
        array.writeMany("--color\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-bin=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-bin\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-bin\x00");
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-asm=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-asm\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-asm\x00");
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-llvm-ir=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-llvm-ir\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-llvm-ir\x00");
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-llvm-bc=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-llvm-bc\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-llvm-bc\x00");
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-h=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-h\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-h\x00");
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-docs=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-docs\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-docs\x00");
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-analysis=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-analysis\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-analysis\x00");
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany("-femit-implib=");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany("-femit-implib\x00");
                }
            },
            .no => {
                array.writeMany("-fno-emit-implib\x00");
            },
        }
    }
    if (cmd.cache_root) |how| {
        array.writeMany("--cache-dir\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.global_cache_root) |how| {
        array.writeMany("--global-cache-dir\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.zig_lib_root) |how| {
        array.writeMany("--zig-lib-dir\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.enable_cache) {
        array.writeMany("--enable-cache\x00");
    }
    if (cmd.target) |how| {
        array.writeMany("-target\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.cpu) |how| {
        array.writeMany("-mcpu\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.code_model) |how| {
        array.writeMany("-mcmodel\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            array.writeMany("-mred-zone\x00");
        } else {
            array.writeMany("-mno-red-zone\x00");
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            array.writeMany("-fomit-frame-pointer\x00");
        } else {
            array.writeMany("-fno-omit-frame-pointer\x00");
        }
    }
    if (cmd.exec_model) |how| {
        array.writeMany("-mexec-model\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.name) |how| {
        array.writeMany("--name\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.mode) |how| {
        array.writeMany("-O\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.main_pkg_path) |how| {
        array.writeMany("--main-pkg-path\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.pic) |pic| {
        if (pic) {
            array.writeMany("-fPIC\x00");
        } else {
            array.writeMany("-fno-PIC\x00");
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            array.writeMany("-fPIE\x00");
        } else {
            array.writeMany("-fno-PIE\x00");
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            array.writeMany("-flto\x00");
        } else {
            array.writeMany("-fno-lto\x00");
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            array.writeMany("-fstack-check\x00");
        } else {
            array.writeMany("-fno-stack-check\x00");
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            array.writeMany("-fstack-check\x00");
        } else {
            array.writeMany("-fno-stack-protector\x00");
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            array.writeMany("-fsanitize-c\x00");
        } else {
            array.writeMany("-fno-sanitize-c\x00");
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            array.writeMany("-fvalgrind\x00");
        } else {
            array.writeMany("-fno-valgrind\x00");
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            array.writeMany("-fsanitize-thread\x00");
        } else {
            array.writeMany("-fno-sanitize-thread\x00");
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            array.writeMany("-funwind-tables\x00");
        } else {
            array.writeMany("-fno-unwind-tables\x00");
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            array.writeMany("-fLLVM\x00");
        } else {
            array.writeMany("-fno-LLVM\x00");
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            array.writeMany("-fClang\x00");
        } else {
            array.writeMany("-fno-Clang\x00");
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            array.writeMany("-freference-trace\x00");
        } else {
            array.writeMany("-fno-reference-trace\x00");
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            array.writeMany("-ferror-tracing\x00");
        } else {
            array.writeMany("-fno-error-tracing\x00");
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            array.writeMany("-fsingle-threaded\x00");
        } else {
            array.writeMany("-fno-single-threaded\x00");
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            array.writeMany("-ffunction-sections\x00");
        } else {
            array.writeMany("-fno-function-sections\x00");
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            array.writeMany("-fstrip\x00");
        } else {
            array.writeMany("-fno-strip\x00");
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            array.writeMany("-fformatted-panics\x00");
        } else {
            array.writeMany("-fno-formatted-panics\x00");
        }
    }
    if (cmd.fmt) |how| {
        array.writeMany("-ofmt\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.dirafter) |how| {
        array.writeMany("-dirafter\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.system) |how| {
        array.writeMany("-isystem\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.include) |how| {
        array.writeMany("-I\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.libc) |how| {
        array.writeMany("--libc\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.library) |how| {
        array.writeMany("--library\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.needed_library) |how| {
        array.writeMany("--needed-library\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.library_directory) |how| {
        array.writeMany("--library-directory\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.link_script) |how| {
        array.writeMany("--script\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.version_script) |how| {
        array.writeMany("--version-script\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.dynamic_linker) |how| {
        array.writeMany("--dynamic-linker\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.sysroot) |how| {
        array.writeMany("--sysroot\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.version) {
        array.writeMany("--version\x00");
    }
    if (cmd.entry) |how| {
        array.writeMany("--entry\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |yes_arg| {
                array.writeMany("-fsoname\x00");
                array.writeAny(reinterpret_spec, yes_arg);
                array.writeOne('\x00');
            },
            .no => {
                array.writeMany("-fno-soname\x00");
            },
        }
    }
    if (cmd.lld) |lld| {
        if (lld) {
            array.writeMany("-fLLD\x00");
        } else {
            array.writeMany("-fno-LLD\x00");
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            array.writeMany("-fcompiler-rt\x00");
        } else {
            array.writeMany("-fno-compiler-rt\x00");
        }
    }
    if (cmd.rpath) |how| {
        array.writeMany("-rpath\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            array.writeMany("-feach-lib-rpath\x00");
        } else {
            array.writeMany("-fno-each-lib-rpath\x00");
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            array.writeMany("-fallow-shlib-undefined\x00");
        } else {
            array.writeMany("-fno-allow-shlib-undefined\x00");
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            array.writeMany("-fbuild-id\x00");
        } else {
            array.writeMany("-fno-build-id\x00");
        }
    }
    if (cmd.compress_debug_sections) |how| {
        array.writeMany("--compress-debug-sections\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            array.writeMany("--gc-sections\x00");
        } else {
            array.writeMany("--no-gc-sections\x00");
        }
    }
    if (cmd.stack) |how| {
        array.writeMany("--stack\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.image_base) |how| {
        array.writeMany("--image-base\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.macros) |how| {
        array.writeAny(reinterpret_spec, how);
    }
    if (cmd.modules) |how| {
        array.writeAny(reinterpret_spec, how);
    }
    if (cmd.dependencies) |how| {
        array.writeAny(reinterpret_spec, how);
    }
    if (cmd.cflags) |how| {
        array.writeAny(reinterpret_spec, how);
    }
    if (cmd.z) |how| {
        array.writeMany("-z\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.files) |how| {
        array.writeAny(reinterpret_spec, how);
    }
}
pub fn formatLength(cmd: *const types.FormatCommand) u64 {
    var len: u64 = 0;
    if (cmd.color) |how| {
        len +%= 8;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
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
    if (cmd.exclude) |how| {
        len +%= 10;
        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        len +%= 1;
    }
    return len;
}
pub fn formatWrite(cmd: *const types.FormatCommand, array: anytype) void {
    if (cmd.color) |how| {
        array.writeMany("--color\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
    if (cmd.stdin) {
        array.writeMany("--stdin\x00");
    }
    if (cmd.check) {
        array.writeMany("--check\x00");
    }
    if (cmd.ast_check) {
        array.writeMany("--ast-check\x00");
    }
    if (cmd.exclude) |how| {
        array.writeMany("--exclude\x00");
        array.writeAny(reinterpret_spec, how);
        array.writeOne('\x00');
    }
}
