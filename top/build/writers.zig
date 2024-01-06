const fmt = @import("../fmt.zig");
const file = @import("../file.zig");
const tasks = @import("tasks.zig");
const types = @import("types.zig");
pub usingnamespace @import("../start.zig");
export fn writeBuildCommand(
    buf: [*]u8,
    cmd: *tasks.BuildCommand,
    zig_exe_ptr: [*]const u8,
    zig_exe_len: usize,
    files_ptr: [*]const types.Path,
    files_len: usize,
) callconv(.C) [*]u8 {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr = fmt.strcpyEqu(ptr, "build-");
    ptr = fmt.strcpyEqu(ptr, @tagName(cmd.kind));
    ptr[0] = 0;
    ptr += 1;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-bin\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-bin\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-bin\x00");
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-asm\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-asm\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-asm\x00");
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-llvm-ir\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-llvm-ir\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-llvm-ir\x00");
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-llvm-bc\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-llvm-bc\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-llvm-bc\x00");
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-h\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-h\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-h\x00");
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-docs\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-docs\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-docs\x00");
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    ptr = fmt.strcpyEqu(ptr, "-femit-analysis\x3d");
                    ptr += arg.formatWriteBuf(ptr);
                } else {
                    ptr = fmt.strcpyEqu(ptr, "-femit-analysis\x00");
                }
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-emit-analysis\x00");
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        ptr = fmt.strcpyEqu(ptr, "--cache-dir\x00");
        ptr = fmt.strcpyEqu(ptr, cache_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        ptr = fmt.strcpyEqu(ptr, "--global-cache-dir\x00");
        ptr = fmt.strcpyEqu(ptr, global_cache_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        ptr = fmt.strcpyEqu(ptr, "--zig-lib-dir\x00");
        ptr = fmt.strcpyEqu(ptr, zig_lib_root);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.listen) |listen| {
        ptr = fmt.strcpyEqu(ptr, "--listen\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(listen));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.target) |target| {
        ptr = fmt.strcpyEqu(ptr, "-target\x00");
        ptr = fmt.strcpyEqu(ptr, target);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.cpu) |cpu| {
        ptr = fmt.strcpyEqu(ptr, "-mcpu\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(cpu));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.code_model) |code_model| {
        ptr = fmt.strcpyEqu(ptr, "-mcmodel\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(code_model));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.runtime_safety) |runtime_safety| {
        if (runtime_safety) {
            ptr = fmt.strcpyEqu(ptr, "-fruntime-safety\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-runtime-safety\x00");
        }
    }
    if (cmd.panic_data) |panic_data| {
        if (panic_data) {
            ptr = fmt.strcpyEqu(ptr, "-fpanic-data\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-panic-data\x00");
        }
    }
    if (cmd.check_unwrapped_error) |check_unwrapped_error| {
        if (check_unwrapped_error) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-unwrapped-error\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-unwrapped-error\x00");
        }
    }
    if (cmd.check_unwrapped_null) |check_unwrapped_null| {
        if (check_unwrapped_null) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-unwrapped-null\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-unwrapped-null\x00");
        }
    }
    if (cmd.check_returned_noreturn) |check_returned_noreturn| {
        if (check_returned_noreturn) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-returned-noreturn\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-returned-noreturn\x00");
        }
    }
    if (cmd.check_reached_unreachable) |check_reached_unreachable| {
        if (check_reached_unreachable) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-reached-unreachable\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-reached-unreachable\x00");
        }
    }
    if (cmd.check_accessed_out_of_bounds) |check_accessed_out_of_bounds| {
        if (check_accessed_out_of_bounds) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-accessed-out-of-bounds\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-accessed-out-of-bounds\x00");
        }
    }
    if (cmd.check_accessed_out_of_order) |check_accessed_out_of_order| {
        if (check_accessed_out_of_order) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-accessed-out-of-order\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-accessed-out-of-order\x00");
        }
    }
    if (cmd.check_accessed_inactive_field) |check_accessed_inactive_field| {
        if (check_accessed_inactive_field) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-accessed-inactive-field\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-accessed-inactive-field\x00");
        }
    }
    if (cmd.check_divided_by_zero) |check_divided_by_zero| {
        if (check_divided_by_zero) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-divided-by-zero\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-divided-by-zero\x00");
        }
    }
    if (cmd.check_memcpy_argument_aliasing) |check_memcpy_argument_aliasing| {
        if (check_memcpy_argument_aliasing) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-memcpy-argument-aliasing\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-memcpy-argument-aliasing\x00");
        }
    }
    if (cmd.check_mismatched_memcpy_argument_lengths) |check_mismatched_memcpy_argument_lengths| {
        if (check_mismatched_memcpy_argument_lengths) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-mismatched-memcpy-argument-lengths\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-mismatched-memcpy-argument-lengths\x00");
        }
    }
    if (cmd.check_mismatched_for_loop_capture_lengths) |check_mismatched_for_loop_capture_lengths| {
        if (check_mismatched_for_loop_capture_lengths) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-mismatched-for-loop-capture-lengths\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-mismatched-for-loop-capture-lengths\x00");
        }
    }
    if (cmd.check_mismatched_sentinel) |check_mismatched_sentinel| {
        if (check_mismatched_sentinel) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-mismatched-sentinel\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-mismatched-sentinel\x00");
        }
    }
    if (cmd.check_shift_amt_overflowed) |check_shift_amt_overflowed| {
        if (check_shift_amt_overflowed) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-shift-amt-overflowed\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-shift-amt-overflowed\x00");
        }
    }
    if (cmd.check_arith_exact) |check_arith_exact| {
        if (check_arith_exact) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-arith-exact\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-arith-exact\x00");
        }
    }
    if (cmd.check_arith_overflowed) |check_arith_overflowed| {
        if (check_arith_overflowed) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-arith-overflowed\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-arith-overflowed\x00");
        }
    }
    if (cmd.check_cast_truncated_data) |check_cast_truncated_data| {
        if (check_cast_truncated_data) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-truncated-data\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-truncated-data\x00");
        }
    }
    if (cmd.check_cast_to_enum_from_invalid) |check_cast_to_enum_from_invalid| {
        if (check_cast_to_enum_from_invalid) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-to-enum-from-invalid\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-to-enum-from-invalid\x00");
        }
    }
    if (cmd.check_cast_to_error_from_invalid) |check_cast_to_error_from_invalid| {
        if (check_cast_to_error_from_invalid) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-to-error-from-invalid\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-to-error-from-invalid\x00");
        }
    }
    if (cmd.check_cast_to_pointer_from_invalid) |check_cast_to_pointer_from_invalid| {
        if (check_cast_to_pointer_from_invalid) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-to-pointer-from-invalid\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-to-pointer-from-invalid\x00");
        }
    }
    if (cmd.check_cast_to_int_from_invalid) |check_cast_to_int_from_invalid| {
        if (check_cast_to_int_from_invalid) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-to-int-from-invalid\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-to-int-from-invalid\x00");
        }
    }
    if (cmd.check_cast_to_unsigned_from_negative) |check_cast_to_unsigned_from_negative| {
        if (check_cast_to_unsigned_from_negative) {
            ptr = fmt.strcpyEqu(ptr, "-fcheck-cast-to-unsigned-from-negative\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-check-cast-to-unsigned-from-negative\x00");
        }
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            ptr = fmt.strcpyEqu(ptr, "-mred-zone\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-mno-red-zone\x00");
        }
    }
    if (cmd.implicit_builtins) |implicit_builtins| {
        if (implicit_builtins) {
            ptr = fmt.strcpyEqu(ptr, "-fbuiltin\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-builtin\x00");
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            ptr = fmt.strcpyEqu(ptr, "-fomit-frame-pointer\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-omit-frame-pointer\x00");
        }
    }
    if (cmd.exec_model) |exec_model| {
        ptr = fmt.strcpyEqu(ptr, "-mexec-model\x00");
        ptr = fmt.strcpyEqu(ptr, exec_model);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.name) |name| {
        ptr = fmt.strcpyEqu(ptr, "--name\x00");
        ptr = fmt.strcpyEqu(ptr, name);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                ptr = fmt.strcpyEqu(ptr, "-fsoname\x00");
                ptr = fmt.strcpyEqu(ptr, arg);
                ptr[0] = 0;
                ptr += 1;
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-soname\x00");
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
        ptr = fmt.strcpyEqu(ptr, "-fopt-bisect-limit\x3d");
        ptr = fmt.Ud64.write(ptr, passes);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.main_mod_path) |main_mod_path| {
        ptr = fmt.strcpyEqu(ptr, "--main-mod-path\x00");
        ptr = fmt.strcpyEqu(ptr, main_mod_path);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            ptr = fmt.strcpyEqu(ptr, "-fPIC\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-PIC\x00");
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            ptr = fmt.strcpyEqu(ptr, "-fPIE\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-PIE\x00");
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            ptr = fmt.strcpyEqu(ptr, "-flto\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-lto\x00");
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            ptr = fmt.strcpyEqu(ptr, "-fstack-check\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-stack-check\x00");
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            ptr = fmt.strcpyEqu(ptr, "-fstack-protector\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-stack-protector\x00");
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            ptr = fmt.strcpyEqu(ptr, "-fsanitize-c\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-c\x00");
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            ptr = fmt.strcpyEqu(ptr, "-fvalgrind\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-valgrind\x00");
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            ptr = fmt.strcpyEqu(ptr, "-fsanitize-thread\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-thread\x00");
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            ptr = fmt.strcpyEqu(ptr, "-funwind-tables\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-unwind-tables\x00");
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            ptr = fmt.strcpyEqu(ptr, "-freference-trace\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-reference-trace\x00");
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            ptr = fmt.strcpyEqu(ptr, "-ferror-tracing\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-error-tracing\x00");
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            ptr = fmt.strcpyEqu(ptr, "-fsingle-threaded\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-single-threaded\x00");
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            ptr = fmt.strcpyEqu(ptr, "-ffunction-sections\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-function-sections\x00");
        }
    }
    if (cmd.data_sections) |data_sections| {
        if (data_sections) {
            ptr = fmt.strcpyEqu(ptr, "-fdata-sections\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-data-sections\x00");
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            ptr = fmt.strcpyEqu(ptr, "-fstrip\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-strip\x00");
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            ptr = fmt.strcpyEqu(ptr, "-fformatted-panics\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-formatted-panics\x00");
        }
    }
    if (cmd.format) |format| {
        ptr = fmt.strcpyEqu(ptr, "-ofmt\x3d");
        ptr = fmt.strcpyEqu(ptr, @tagName(format));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.dirafter) |dirafter| {
        ptr = fmt.strcpyEqu(ptr, "-idirafter\x00");
        ptr = fmt.strcpyEqu(ptr, dirafter);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.system) |system| {
        ptr = fmt.strcpyEqu(ptr, "-isystem\x00");
        ptr = fmt.strcpyEqu(ptr, system);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.libc) |libc| {
        ptr = fmt.strcpyEqu(ptr, "--libc\x00");
        ptr = fmt.strcpyEqu(ptr, libc);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.library) |library| {
        ptr = fmt.strcpyEqu(ptr, "--library\x00");
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
            ptr = fmt.strcpyEqu(ptr, "--needed-library\x00");
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            ptr = fmt.strcpyEqu(ptr, "--library-directory\x00");
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.link_script) |link_script| {
        ptr = fmt.strcpyEqu(ptr, "--script\x00");
        ptr = fmt.strcpyEqu(ptr, link_script);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.version_script) |version_script| {
        ptr = fmt.strcpyEqu(ptr, "--version-script\x00");
        ptr = fmt.strcpyEqu(ptr, version_script);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        ptr = fmt.strcpyEqu(ptr, "--dynamic-linker\x00");
        ptr = fmt.strcpyEqu(ptr, dynamic_linker);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.sysroot) |sysroot| {
        ptr = fmt.strcpyEqu(ptr, "--sysroot\x00");
        ptr = fmt.strcpyEqu(ptr, sysroot);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.entry) |entry| {
        switch (entry) {
            .yes => |arg| {
                ptr = fmt.strcpyEqu(ptr, "-fentry\x3d");
                ptr = fmt.strcpyEqu(ptr, arg);
                ptr[0] = 0;
                ptr += 1;
            },
            .no => {
                ptr = fmt.strcpyEqu(ptr, "-fno-entry\x00");
            },
        }
    }
    if (cmd.lld) |lld| {
        if (lld) {
            ptr = fmt.strcpyEqu(ptr, "-flld\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-lld\x00");
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            ptr = fmt.strcpyEqu(ptr, "-fllvm\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-llvm\x00");
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            ptr = fmt.strcpyEqu(ptr, "-fcompiler-rt\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-compiler-rt\x00");
        }
    }
    if (cmd.rpath) |rpath| {
        ptr = fmt.strcpyEqu(ptr, "-rpath\x00");
        ptr = fmt.strcpyEqu(ptr, rpath);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            ptr = fmt.strcpyEqu(ptr, "-feach-lib-rpath\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-each-lib-rpath\x00");
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            ptr = fmt.strcpyEqu(ptr, "-fallow-shlib-undefined\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-allow-shlib-undefined\x00");
        }
    }
    if (cmd.build_id) |build_id| {
        ptr = fmt.strcpyEqu(ptr, "--build-id\x3d");
        ptr = fmt.strcpyEqu(ptr, @tagName(build_id));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.eh_frame_hdr) {
        ptr = fmt.strcpyEqu(ptr, "--eh-frame-hdr\x00");
    }
    if (cmd.emit_relocs) {
        ptr = fmt.strcpyEqu(ptr, "--emit-relocs\x00");
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            ptr = fmt.strcpyEqu(ptr, "--gc-sections\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "--no-gc-sections\x00");
        }
    }
    if (cmd.stack) |stack| {
        ptr = fmt.strcpyEqu(ptr, "--stack\x00");
        ptr = fmt.Ud64.write(ptr, stack);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.image_base) |image_base| {
        ptr = fmt.strcpyEqu(ptr, "--image-base\x00");
        ptr = fmt.Ud64.write(ptr, image_base);
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
    for (cmd.mods) |*value| {
        ptr = tasks.BuildModuleCommand.write(ptr, value);
    }
    if (cmd.dependencies) |dependencies| {
        ptr += types.ModuleDependencies.formatWriteBuf(.{ .value = dependencies }, ptr);
    }
    if (cmd.deps) |deps| {
        ptr += types.ModuleDependencies.formatWriteBuf(.{ .value = deps }, ptr);
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
        ptr = fmt.strcpyEqu(ptr, "-rdynamic\x00");
    }
    if (cmd.dynamic) {
        ptr = fmt.strcpyEqu(ptr, "-dynamic\x00");
    }
    if (cmd.static) {
        ptr = fmt.strcpyEqu(ptr, "-static\x00");
    }
    if (cmd.symbolic) {
        ptr = fmt.strcpyEqu(ptr, "-Bsymbolic\x00");
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
        ptr = fmt.strcpyEqu(ptr, "--color\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(color));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.incremental_compilation) {
        ptr = fmt.strcpyEqu(ptr, "--debug-incremental\x00");
    }
    if (cmd.time_report) {
        ptr = fmt.strcpyEqu(ptr, "-ftime-report\x00");
    }
    if (cmd.stack_report) {
        ptr = fmt.strcpyEqu(ptr, "-fstack-report\x00");
    }
    if (cmd.verbose_link) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-link\x00");
    }
    if (cmd.verbose_cc) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-cc\x00");
    }
    if (cmd.verbose_air) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-air\x00");
    }
    if (cmd.verbose_mir) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-mir\x00");
    }
    if (cmd.verbose_llvm_ir) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-llvm-ir\x00");
    }
    if (cmd.verbose_cimport) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-cimport\x00");
    }
    if (cmd.verbose_llvm_cpu_features) {
        ptr = fmt.strcpyEqu(ptr, "--verbose-llvm-cpu-features\x00");
    }
    if (cmd.debug_log) |debug_log| {
        ptr = fmt.strcpyEqu(ptr, "--debug-log\x00");
        ptr = fmt.strcpyEqu(ptr, debug_log);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.debug_compiler_errors) {
        ptr = fmt.strcpyEqu(ptr, "--debug-compile-errors\x00");
    }
    if (cmd.debug_link_snapshot) {
        ptr = fmt.strcpyEqu(ptr, "--debug-link-snapshot\x00");
    }
    return ptr;
}
export fn lengthBuildCommand(cmd: *tasks.BuildCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var len: usize = 8 +% zig_exe.len +% @tagName(cmd.kind).len;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 11 +% arg.formatLength();
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
                    len +%= 11 +% arg.formatLength();
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
                    len +%= 15 +% arg.formatLength();
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
                    len +%= 15 +% arg.formatLength();
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
                    len +%= 9 +% arg.formatLength();
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
                    len +%= 12 +% arg.formatLength();
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
                    len +%= 16 +% arg.formatLength();
                } else {
                    len +%= 16;
                }
            },
            .no => {
                len +%= 19;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        len +%= 13 +% cache_root.len;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        len +%= 20 +% global_cache_root.len;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        len +%= 15 +% zig_lib_root.len;
    }
    if (cmd.listen) |listen| {
        len +%= 10 +% @tagName(listen).len;
    }
    if (cmd.target) |target| {
        len +%= 9 +% target.len;
    }
    if (cmd.cpu) |cpu| {
        len +%= 7 +% @tagName(cpu).len;
    }
    if (cmd.code_model) |code_model| {
        len +%= 10 +% @tagName(code_model).len;
    }
    if (cmd.runtime_safety) |runtime_safety| {
        if (runtime_safety) {
            len +%= 17;
        } else {
            len +%= 20;
        }
    }
    if (cmd.panic_data) |panic_data| {
        if (panic_data) {
            len +%= 13;
        } else {
            len +%= 16;
        }
    }
    if (cmd.check_unwrapped_error) |check_unwrapped_error| {
        if (check_unwrapped_error) {
            len +%= 24;
        } else {
            len +%= 27;
        }
    }
    if (cmd.check_unwrapped_null) |check_unwrapped_null| {
        if (check_unwrapped_null) {
            len +%= 23;
        } else {
            len +%= 26;
        }
    }
    if (cmd.check_returned_noreturn) |check_returned_noreturn| {
        if (check_returned_noreturn) {
            len +%= 26;
        } else {
            len +%= 29;
        }
    }
    if (cmd.check_reached_unreachable) |check_reached_unreachable| {
        if (check_reached_unreachable) {
            len +%= 28;
        } else {
            len +%= 31;
        }
    }
    if (cmd.check_accessed_out_of_bounds) |check_accessed_out_of_bounds| {
        if (check_accessed_out_of_bounds) {
            len +%= 31;
        } else {
            len +%= 34;
        }
    }
    if (cmd.check_accessed_out_of_order) |check_accessed_out_of_order| {
        if (check_accessed_out_of_order) {
            len +%= 30;
        } else {
            len +%= 33;
        }
    }
    if (cmd.check_accessed_inactive_field) |check_accessed_inactive_field| {
        if (check_accessed_inactive_field) {
            len +%= 32;
        } else {
            len +%= 35;
        }
    }
    if (cmd.check_divided_by_zero) |check_divided_by_zero| {
        if (check_divided_by_zero) {
            len +%= 24;
        } else {
            len +%= 27;
        }
    }
    if (cmd.check_memcpy_argument_aliasing) |check_memcpy_argument_aliasing| {
        if (check_memcpy_argument_aliasing) {
            len +%= 33;
        } else {
            len +%= 36;
        }
    }
    if (cmd.check_mismatched_memcpy_argument_lengths) |check_mismatched_memcpy_argument_lengths| {
        if (check_mismatched_memcpy_argument_lengths) {
            len +%= 43;
        } else {
            len +%= 46;
        }
    }
    if (cmd.check_mismatched_for_loop_capture_lengths) |check_mismatched_for_loop_capture_lengths| {
        if (check_mismatched_for_loop_capture_lengths) {
            len +%= 44;
        } else {
            len +%= 47;
        }
    }
    if (cmd.check_mismatched_sentinel) |check_mismatched_sentinel| {
        if (check_mismatched_sentinel) {
            len +%= 28;
        } else {
            len +%= 31;
        }
    }
    if (cmd.check_shift_amt_overflowed) |check_shift_amt_overflowed| {
        if (check_shift_amt_overflowed) {
            len +%= 29;
        } else {
            len +%= 32;
        }
    }
    if (cmd.check_arith_exact) |check_arith_exact| {
        if (check_arith_exact) {
            len +%= 20;
        } else {
            len +%= 23;
        }
    }
    if (cmd.check_arith_overflowed) |check_arith_overflowed| {
        if (check_arith_overflowed) {
            len +%= 25;
        } else {
            len +%= 28;
        }
    }
    if (cmd.check_cast_truncated_data) |check_cast_truncated_data| {
        if (check_cast_truncated_data) {
            len +%= 28;
        } else {
            len +%= 31;
        }
    }
    if (cmd.check_cast_to_enum_from_invalid) |check_cast_to_enum_from_invalid| {
        if (check_cast_to_enum_from_invalid) {
            len +%= 34;
        } else {
            len +%= 37;
        }
    }
    if (cmd.check_cast_to_error_from_invalid) |check_cast_to_error_from_invalid| {
        if (check_cast_to_error_from_invalid) {
            len +%= 35;
        } else {
            len +%= 38;
        }
    }
    if (cmd.check_cast_to_pointer_from_invalid) |check_cast_to_pointer_from_invalid| {
        if (check_cast_to_pointer_from_invalid) {
            len +%= 37;
        } else {
            len +%= 40;
        }
    }
    if (cmd.check_cast_to_int_from_invalid) |check_cast_to_int_from_invalid| {
        if (check_cast_to_int_from_invalid) {
            len +%= 33;
        } else {
            len +%= 36;
        }
    }
    if (cmd.check_cast_to_unsigned_from_negative) |check_cast_to_unsigned_from_negative| {
        if (check_cast_to_unsigned_from_negative) {
            len +%= 39;
        } else {
            len +%= 42;
        }
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
        len +%= 14 +% exec_model.len;
    }
    if (cmd.name) |name| {
        len +%= 8 +% name.len;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                len +%= 10 +% arg.len;
            },
            .no => {
                len +%= 12;
            },
        }
    }
    if (cmd.mode) |mode| {
        len +%= 4 +% @tagName(mode).len;
    }
    if (cmd.passes) |passes| {
        len +%= 20 +% fmt.Ud64.length(passes);
    }
    if (cmd.main_mod_path) |main_mod_path| {
        len +%= 17 +% main_mod_path.len;
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
        len +%= 7 +% @tagName(format).len;
    }
    if (cmd.dirafter) |dirafter| {
        len +%= 12 +% dirafter.len;
    }
    if (cmd.system) |system| {
        len +%= 10 +% system.len;
    }
    if (cmd.libc) |libc| {
        len +%= 8 +% libc.len;
    }
    if (cmd.library) |library| {
        len +%= 11 +% library.len;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 4 +% value.len;
        }
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            len +%= 18 +% value.len;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            len +%= 21 +% value.len;
        }
    }
    if (cmd.link_script) |link_script| {
        len +%= 10 +% link_script.len;
    }
    if (cmd.version_script) |version_script| {
        len +%= 18 +% version_script.len;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        len +%= 18 +% dynamic_linker.len;
    }
    if (cmd.sysroot) |sysroot| {
        len +%= 11 +% sysroot.len;
    }
    if (cmd.entry) |entry| {
        switch (entry) {
            .yes => |arg| {
                len +%= 9 +% arg.len;
            },
            .no => {
                len +%= 11;
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
        len +%= 8 +% rpath.len;
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
        len +%= 12 +% @tagName(build_id).len;
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
        len +%= 9 +% fmt.Ud64.length(stack);
    }
    if (cmd.image_base) |image_base| {
        len +%= 14 +% fmt.Ud64.length(image_base);
    }
    if (cmd.macros) |macros| {
        for (macros) |value| {
            len = len +% value.formatLength();
        }
    }
    if (cmd.modules) |modules| {
        for (modules) |value| {
            len = len +% value.formatLength();
        }
    }
    if (cmd.dependencies) |dependencies| {
        len = len +% types.ModuleDependencies.formatLength(.{ .value = dependencies });
    }
    if (cmd.deps) |deps| {
        len = len +% types.ModuleDependencies.formatLength(.{ .value = deps });
    }
    if (cmd.cflags) |cflags| {
        len = len +% types.ExtraFlags.formatLength(.{ .value = cflags });
    }
    if (cmd.rcflags) |rcflags| {
        len = len +% types.ExtraFlags.formatLength(.{ .value = rcflags });
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
            len +%= 4 +% @tagName(value).len;
        }
    }
    for (files) |value| {
        len = len +% value.formatLength();
    }
    if (cmd.color) |color| {
        len +%= 9 +% @tagName(color).len;
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
        len +%= 13 +% debug_log.len;
    }
    if (cmd.debug_compiler_errors) {
        len +%= 23;
    }
    if (cmd.debug_link_snapshot) {
        len +%= 22;
    }
    return len;
}
export fn writeBuildModuleCommand(
    buf: [*]u8,
    cmd: *tasks.BuildModuleCommand,
) callconv(.C) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    if (cmd.target) |target| {
        ptr = fmt.strcpyEqu(ptr, "-target\x00");
        ptr = fmt.strcpyEqu(ptr, target);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.mode) |mode| {
        ptr[0..3].* = "-O\x00".*;
        ptr += 3;
        ptr = fmt.strcpyEqu(ptr, @tagName(mode));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.format) |format| {
        ptr = fmt.strcpyEqu(ptr, "-ofmt\x3d");
        ptr = fmt.strcpyEqu(ptr, @tagName(format));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.mcpu) |mcpu| {
        ptr = fmt.strcpyEqu(ptr, "--mcpu\x00");
        ptr = fmt.strcpyEqu(ptr, mcpu);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.code_model) |code_model| {
        ptr = fmt.strcpyEqu(ptr, "-mcmodel\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(code_model));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            ptr = fmt.strcpyEqu(ptr, "-mred-zone\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-mno-red-zone\x00");
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            ptr = fmt.strcpyEqu(ptr, "-fomit-frame-pointer\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-omit-frame-pointer\x00");
        }
    }
    if (cmd.pic) |pic| {
        if (pic) {
            ptr = fmt.strcpyEqu(ptr, "-fPIC\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-PIC\x00");
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            ptr = fmt.strcpyEqu(ptr, "-fstack-check\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-stack-check\x00");
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            ptr = fmt.strcpyEqu(ptr, "-fstack-protector\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-stack-protector\x00");
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            ptr = fmt.strcpyEqu(ptr, "-fsanitize-c\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-c\x00");
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            ptr = fmt.strcpyEqu(ptr, "-fvalgrind\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-valgrind\x00");
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            ptr = fmt.strcpyEqu(ptr, "-fsanitize-thread\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-thread\x00");
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            ptr = fmt.strcpyEqu(ptr, "-funwind-tables\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-unwind-tables\x00");
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            ptr = fmt.strcpyEqu(ptr, "-ferror-tracing\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-error-tracing\x00");
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            ptr = fmt.strcpyEqu(ptr, "-fsingle-threaded\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-single-threaded\x00");
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            ptr = fmt.strcpyEqu(ptr, "-fstrip\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-strip\x00");
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            ptr = fmt.strcpyEqu(ptr, "-fformatted-panics\x00");
        } else {
            ptr = fmt.strcpyEqu(ptr, "-fno-formatted-panics\x00");
        }
    }
    if (cmd.dirafter) |dirafter| {
        ptr = fmt.strcpyEqu(ptr, "-idirafter\x00");
        ptr = fmt.strcpyEqu(ptr, dirafter);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.system) |system| {
        ptr = fmt.strcpyEqu(ptr, "-isystem\x00");
        ptr = fmt.strcpyEqu(ptr, system);
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
    if (cmd.cflags) |cflags| {
        ptr += types.ExtraFlags.formatWriteBuf(.{ .value = cflags }, ptr);
    }
    if (cmd.rcflags) |rcflags| {
        ptr += types.ExtraFlags.formatWriteBuf(.{ .value = rcflags }, ptr);
    }
    if (cmd.macros) |macros| {
        for (macros) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
    }
    if (cmd.library) |library| {
        ptr = fmt.strcpyEqu(ptr, "--library\x00");
        ptr = fmt.strcpyEqu(ptr, library);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            ptr = fmt.strcpyEqu(ptr, "-needed-library\x00");
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.weak_library) |weak_library| {
        for (weak_library) |value| {
            ptr = fmt.strcpyEqu(ptr, "-weak_library\x00");
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            ptr = fmt.strcpyEqu(ptr, "--library-directory\x00");
            ptr = fmt.strcpyEqu(ptr, value);
            ptr[0] = 0;
            ptr += 1;
        }
    }
    ptr = fmt.strcpyEqu(ptr, "--mod\x00");
    ptr = fmt.strcpyEqu(ptr, cmd.name);
    ptr[0] = 0;
    ptr += 1;
    ptr = fmt.strcpyEqu(ptr, cmd.path);
    ptr[0] = 0;
    ptr += 1;
    return ptr;
}
export fn lengthBuildModuleCommand(cmd: *tasks.BuildModuleCommand) callconv(.C) usize {
    @setRuntimeSafety(false);
    var len: usize = 0;
    if (cmd.target) |target| {
        len +%= 9 +% target.len;
    }
    if (cmd.mode) |mode| {
        len +%= 4 +% @tagName(mode).len;
    }
    if (cmd.format) |format| {
        len +%= 7 +% @tagName(format).len;
    }
    if (cmd.mcpu) |mcpu| {
        len +%= 8 +% mcpu.len;
    }
    if (cmd.code_model) |code_model| {
        len +%= 10 +% @tagName(code_model).len;
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
    if (cmd.pic) |pic| {
        if (pic) {
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
    if (cmd.dirafter) |dirafter| {
        len +%= 12 +% dirafter.len;
    }
    if (cmd.system) |system| {
        len +%= 10 +% system.len;
    }
    if (cmd.include) |include| {
        for (include) |value| {
            len +%= 4 +% value.len;
        }
    }
    if (cmd.cflags) |cflags| {
        len = len +% types.ExtraFlags.formatLength(.{ .value = cflags });
    }
    if (cmd.rcflags) |rcflags| {
        len = len +% types.ExtraFlags.formatLength(.{ .value = rcflags });
    }
    if (cmd.macros) |macros| {
        for (macros) |value| {
            len = len +% value.formatLength();
        }
    }
    if (cmd.library) |library| {
        len +%= 11 +% library.len;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            len +%= 17 +% value.len;
        }
    }
    if (cmd.weak_library) |weak_library| {
        for (weak_library) |value| {
            len +%= 15 +% value.len;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            len +%= 21 +% value.len;
        }
    }
    return len +% 8 +% cmd.name.len +% cmd.path.len;
}
export fn writeArchiveCommand(
    buf: [*]u8,
    cmd: *tasks.ArchiveCommand,
    zig_exe_ptr: [*]const u8,
    zig_exe_len: usize,
    files_ptr: [*]const types.Path,
    files_len: usize,
) callconv(.C) [*]u8 {
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
        ptr = fmt.strcpyEqu(ptr, "--format\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(format));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.plugin) {
        ptr = fmt.strcpyEqu(ptr, "--plugin\x00");
    }
    if (cmd.output) |output| {
        ptr = fmt.strcpyEqu(ptr, "--output\x00");
        ptr = fmt.strcpyEqu(ptr, output);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.thin) {
        ptr = fmt.strcpyEqu(ptr, "--thin\x00");
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
    return ptr;
}
export fn lengthArchiveCommand(cmd: *tasks.ArchiveCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, files_ptr: [*]const types.Path, files_len: usize) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    const files: []const types.Path = files_ptr[0..files_len];
    @setRuntimeSafety(false);
    var len: usize = 4 +% zig_exe.len;
    if (cmd.format) |format| {
        len +%= 10 +% @tagName(format).len;
    }
    if (cmd.plugin) {
        len +%= 9;
    }
    if (cmd.output) |output| {
        len +%= 10 +% output.len;
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
    len +%= 1 +% @tagName(cmd.operation).len;
    for (files) |value| {
        len = len +% value.formatLength();
    }
    return len;
}
export fn writeObjcopyCommand(
    buf: [*]u8,
    cmd: *tasks.ObjcopyCommand,
    zig_exe_ptr: [*]const u8,
    zig_exe_len: usize,
    path: types.Path,
) callconv(.C) [*]u8 {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr = fmt.strcpyEqu(ptr, "objcopy\x00");
    if (cmd.output_target) |output_target| {
        ptr = fmt.strcpyEqu(ptr, "--output-target\x00");
        ptr = fmt.strcpyEqu(ptr, output_target);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.only_section) |only_section| {
        ptr = fmt.strcpyEqu(ptr, "--only-section\x00");
        ptr = fmt.strcpyEqu(ptr, only_section);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.pad_to) |pad_to| {
        ptr = fmt.strcpyEqu(ptr, "--pad-to\x00");
        ptr = fmt.Ud64.write(ptr, pad_to);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.strip_debug) {
        ptr = fmt.strcpyEqu(ptr, "--strip-debug\x00");
    }
    if (cmd.strip_all) {
        ptr = fmt.strcpyEqu(ptr, "--strip-all\x00");
    }
    if (cmd.debug_only) {
        ptr = fmt.strcpyEqu(ptr, "--only-keep-debug\x00");
    }
    if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
        ptr = fmt.strcpyEqu(ptr, "--add-gnu-debuglink\x00");
        ptr = fmt.strcpyEqu(ptr, add_gnu_debuglink);
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.extract_to) |extract_to| {
        ptr = fmt.strcpyEqu(ptr, "--extract-to\x00");
        ptr = fmt.strcpyEqu(ptr, extract_to);
        ptr[0] = 0;
        ptr += 1;
    }
    ptr += path.formatWriteBuf(ptr);
    return ptr;
}
export fn lengthObjcopyCommand(cmd: *tasks.ObjcopyCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, path: types.Path) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 9 +% zig_exe.len;
    if (cmd.output_target) |output_target| {
        len +%= 17 +% output_target.len;
    }
    if (cmd.only_section) |only_section| {
        len +%= 16 +% only_section.len;
    }
    if (cmd.pad_to) |pad_to| {
        len +%= 10 +% fmt.Ud64.length(pad_to);
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
        len +%= 21 +% add_gnu_debuglink.len;
    }
    if (cmd.extract_to) |extract_to| {
        len +%= 14 +% extract_to.len;
    }
    return len +% path.formatLength();
}
export fn writeFormatCommand(
    buf: [*]u8,
    cmd: *tasks.FormatCommand,
    zig_exe_ptr: [*]const u8,
    zig_exe_len: usize,
    pathname: types.Path,
) callconv(.C) [*]u8 {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = fmt.strcpyEqu(ptr, zig_exe);
    ptr[0] = 0;
    ptr += 1;
    ptr[0..4].* = "fmt\x00".*;
    ptr += 4;
    if (cmd.color) |color| {
        ptr = fmt.strcpyEqu(ptr, "--color\x00");
        ptr = fmt.strcpyEqu(ptr, @tagName(color));
        ptr[0] = 0;
        ptr += 1;
    }
    if (cmd.stdin) {
        ptr = fmt.strcpyEqu(ptr, "--stdin\x00");
    }
    if (cmd.check) {
        ptr = fmt.strcpyEqu(ptr, "--check\x00");
    }
    if (cmd.ast_check) {
        ptr = fmt.strcpyEqu(ptr, "--ast-check\x00");
    }
    if (cmd.exclude) |exclude| {
        ptr = fmt.strcpyEqu(ptr, "--exclude\x00");
        ptr = fmt.strcpyEqu(ptr, exclude);
        ptr[0] = 0;
        ptr += 1;
    }
    ptr += pathname.formatWriteBuf(ptr);
    return ptr;
}
export fn lengthFormatCommand(cmd: *tasks.FormatCommand, zig_exe_ptr: [*]const u8, zig_exe_len: usize, pathname: types.Path) callconv(.C) usize {
    const zig_exe: []const u8 = zig_exe_ptr[0..zig_exe_len];
    @setRuntimeSafety(false);
    var len: usize = 5 +% zig_exe.len;
    if (cmd.color) |color| {
        len +%= 9 +% @tagName(color).len;
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
        len +%= 11 +% exclude.len;
    }
    return len +% pathname.formatLength();
}
