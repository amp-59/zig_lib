const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks3.zig");
const mach = @import("../mach.zig");
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
    @setRuntimeSafety(false);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len = len +% 1;
    mach.memcpy(buf + len, "build-", 6);
    len = len +% 6;
    mach.memcpy(buf + len, @tagName(cmd.kind).ptr, @tagName(cmd.kind).len);
    len = len +% @tagName(cmd.kind).len;
    buf[len] = 0;
    len = len +% 1;
    if (cmd.emit_bin) |emit_bin| {
        switch (emit_bin) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-bin".*;
                    len = len +% 10;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-bin".*;
                    len = len +% 10;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[13]u8, buf + len).* = "-fno-emit-bin".*;
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
                    @ptrCast(*[10]u8, buf + len).* = "-femit-asm".*;
                    len = len +% 10;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-asm".*;
                    len = len +% 10;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[13]u8, buf + len).* = "-fno-emit-asm".*;
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
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-ir".*;
                    len = len +% 14;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-ir".*;
                    len = len +% 14;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[17]u8, buf + len).* = "-fno-emit-llvm-ir".*;
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
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-bc".*;
                    len = len +% 14;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-bc".*;
                    len = len +% 14;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[17]u8, buf + len).* = "-fno-emit-llvm-bc".*;
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
                    @ptrCast(*[8]u8, buf + len).* = "-femit-h".*;
                    len = len +% 8;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[8]u8, buf + len).* = "-femit-h".*;
                    len = len +% 8;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[11]u8, buf + len).* = "-fno-emit-h".*;
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
                    @ptrCast(*[11]u8, buf + len).* = "-femit-docs".*;
                    len = len +% 11;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-docs".*;
                    len = len +% 11;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[14]u8, buf + len).* = "-fno-emit-docs".*;
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
                    @ptrCast(*[15]u8, buf + len).* = "-femit-analysis".*;
                    len = len +% 15;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-analysis".*;
                    len = len +% 15;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[18]u8, buf + len).* = "-fno-emit-analysis".*;
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
                    @ptrCast(*[13]u8, buf + len).* = "-femit-implib".*;
                    len = len +% 13;
                    buf[len] = 61;
                    len = len +% 1;
                    len = len +% arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[13]u8, buf + len).* = "-femit-implib".*;
                    len = len +% 13;
                    buf[len] = 0;
                    len = len +% 1;
                }
            },
            .no => {
                @ptrCast(*[16]u8, buf + len).* = "-fno-emit-implib".*;
                len = len +% 16;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        @ptrCast(*[11]u8, buf + len).* = "--cache-dir".*;
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, cache_root.ptr, cache_root.len);
        len = len +% cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        @ptrCast(*[18]u8, buf + len).* = "--global-cache-dir".*;
        len = len +% 18;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, global_cache_root.ptr, global_cache_root.len);
        len = len +% global_cache_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        @ptrCast(*[13]u8, buf + len).* = "--zig-lib-dir".*;
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, zig_lib_root.ptr, zig_lib_root.len);
        len = len +% zig_lib_root.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.listen) |listen| {
        @ptrCast(*[8]u8, buf + len).* = "--listen".*;
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(listen).ptr, @tagName(listen).len);
        len = len +% @tagName(listen).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.target) |target| {
        @ptrCast(*[7]u8, buf + len).* = "-target".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, target.ptr, target.len);
        len = len +% target.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.cpu) |cpu| {
        @ptrCast(*[5]u8, buf + len).* = "-mcpu".*;
        len = len +% 5;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, cpu.ptr, cpu.len);
        len = len +% cpu.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.code_model) |code_model| {
        @ptrCast(*[8]u8, buf + len).* = "-mcmodel".*;
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(code_model).ptr, @tagName(code_model).len);
        len = len +% @tagName(code_model).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            @ptrCast(*[10]u8, buf + len).* = "-mred-zone".*;
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-mno-red-zone".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            @ptrCast(*[20]u8, buf + len).* = "-fomit-frame-pointer".*;
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[23]u8, buf + len).* = "-fno-omit-frame-pointer".*;
            len = len +% 23;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.exec_model) |exec_model| {
        @ptrCast(*[12]u8, buf + len).* = "-mexec-model".*;
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, exec_model.ptr, exec_model.len);
        len = len +% exec_model.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.name) |name| {
        @ptrCast(*[6]u8, buf + len).* = "--name".*;
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, name.ptr, name.len);
        len = len +% name.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                @ptrCast(*[8]u8, buf + len).* = "-fsoname".*;
                len = len +% 8;
                buf[len] = 0;
                len = len +% 1;
                mach.memcpy(buf + len, arg.ptr, arg.len);
                len = len +% arg.len;
                buf[len] = 0;
                len = len +% 1;
            },
            .no => {
                @ptrCast(*[11]u8, buf + len).* = "-fno-soname".*;
                len = len +% 11;
                buf[len] = 0;
                len = len +% 1;
            },
        }
    }
    if (cmd.mode) |mode| {
        @ptrCast(*[2]u8, buf + len).* = "-O".*;
        len = len +% 2;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(mode).ptr, @tagName(mode).len);
        len = len +% @tagName(mode).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        @ptrCast(*[15]u8, buf + len).* = "--main-pkg-path".*;
        len = len +% 15;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, main_pkg_path.ptr, main_pkg_path.len);
        len = len +% main_pkg_path.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            @ptrCast(*[5]u8, buf + len).* = "-fPIC".*;
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-PIC".*;
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            @ptrCast(*[5]u8, buf + len).* = "-fPIE".*;
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-PIE".*;
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            @ptrCast(*[5]u8, buf + len).* = "-flto".*;
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-lto".*;
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            @ptrCast(*[13]u8, buf + len).* = "-fstack-check".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "-fno-stack-check".*;
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            @ptrCast(*[13]u8, buf + len).* = "-fstack-check".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-stack-protector".*;
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            @ptrCast(*[12]u8, buf + len).* = "-fsanitize-c".*;
            len = len +% 12;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[15]u8, buf + len).* = "-fno-sanitize-c".*;
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            @ptrCast(*[10]u8, buf + len).* = "-fvalgrind".*;
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-fno-valgrind".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            @ptrCast(*[17]u8, buf + len).* = "-fsanitize-thread".*;
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-sanitize-thread".*;
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            @ptrCast(*[15]u8, buf + len).* = "-funwind-tables".*;
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[18]u8, buf + len).* = "-fno-unwind-tables".*;
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            @ptrCast(*[6]u8, buf + len).* = "-fLLVM".*;
            len = len +% 6;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-LLVM".*;
            len = len +% 9;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            @ptrCast(*[7]u8, buf + len).* = "-fClang".*;
            len = len +% 7;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[10]u8, buf + len).* = "-fno-Clang".*;
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            @ptrCast(*[17]u8, buf + len).* = "-freference-trace".*;
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-reference-trace".*;
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            @ptrCast(*[15]u8, buf + len).* = "-ferror-tracing".*;
            len = len +% 15;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[18]u8, buf + len).* = "-fno-error-tracing".*;
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            @ptrCast(*[17]u8, buf + len).* = "-fsingle-threaded".*;
            len = len +% 17;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-single-threaded".*;
            len = len +% 20;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            @ptrCast(*[19]u8, buf + len).* = "-ffunction-sections".*;
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[22]u8, buf + len).* = "-fno-function-sections".*;
            len = len +% 22;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            @ptrCast(*[7]u8, buf + len).* = "-fstrip".*;
            len = len +% 7;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[10]u8, buf + len).* = "-fno-strip".*;
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            @ptrCast(*[18]u8, buf + len).* = "-fformatted-panics".*;
            len = len +% 18;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-formatted-panics".*;
            len = len +% 21;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.format) |format| {
        @ptrCast(*[5]u8, buf + len).* = "-ofmt".*;
        len = len +% 5;
        buf[len] = 61;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len = len +% @tagName(format).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dirafter) |dirafter| {
        @ptrCast(*[10]u8, buf + len).* = "-idirafter".*;
        len = len +% 10;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, dirafter.ptr, dirafter.len);
        len = len +% dirafter.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.system) |system| {
        @ptrCast(*[8]u8, buf + len).* = "-isystem".*;
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, system.ptr, system.len);
        len = len +% system.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.include) |include| {
        @ptrCast(*[2]u8, buf + len).* = "-I".*;
        len = len +% 2;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, include.ptr, include.len);
        len = len +% include.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.libc) |libc| {
        @ptrCast(*[6]u8, buf + len).* = "--libc".*;
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, libc.ptr, libc.len);
        len = len +% libc.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.library) |library| {
        @ptrCast(*[9]u8, buf + len).* = "--library".*;
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, library.ptr, library.len);
        len = len +% library.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            @ptrCast(*[16]u8, buf + len).* = "--needed-library".*;
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
            mach.memcpy(buf + len, value.ptr, value.len);
            len = len +% value.len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            @ptrCast(*[19]u8, buf + len).* = "--library-directory".*;
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
            mach.memcpy(buf + len, value.ptr, value.len);
            len = len +% value.len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.link_script) |link_script| {
        @ptrCast(*[8]u8, buf + len).* = "--script".*;
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, link_script.ptr, link_script.len);
        len = len +% link_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.version_script) |version_script| {
        @ptrCast(*[16]u8, buf + len).* = "--version-script".*;
        len = len +% 16;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, version_script.ptr, version_script.len);
        len = len +% version_script.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        @ptrCast(*[16]u8, buf + len).* = "--dynamic-linker".*;
        len = len +% 16;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, dynamic_linker.ptr, dynamic_linker.len);
        len = len +% dynamic_linker.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.sysroot) |sysroot| {
        @ptrCast(*[9]u8, buf + len).* = "--sysroot".*;
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, sysroot.ptr, sysroot.len);
        len = len +% sysroot.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.entry) |entry| {
        @ptrCast(*[7]u8, buf + len).* = "--entry".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, entry.ptr, entry.len);
        len = len +% entry.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            @ptrCast(*[5]u8, buf + len).* = "-fLLD".*;
            len = len +% 5;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-LLD".*;
            len = len +% 8;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            @ptrCast(*[13]u8, buf + len).* = "-fcompiler-rt".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "-fno-compiler-rt".*;
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.rpath) |rpath| {
        @ptrCast(*[6]u8, buf + len).* = "-rpath".*;
        len = len +% 6;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, rpath.ptr, rpath.len);
        len = len +% rpath.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            @ptrCast(*[16]u8, buf + len).* = "-feach-lib-rpath".*;
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[19]u8, buf + len).* = "-fno-each-lib-rpath".*;
            len = len +% 19;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            @ptrCast(*[23]u8, buf + len).* = "-fallow-shlib-undefined".*;
            len = len +% 23;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[26]u8, buf + len).* = "-fno-allow-shlib-undefined".*;
            len = len +% 26;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            @ptrCast(*[10]u8, buf + len).* = "-fbuild-id".*;
            len = len +% 10;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-fno-build-id".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            @ptrCast(*[30]u8, buf + len).* = "--compress-debug-sections=zlib".*;
            len = len +% 30;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[30]u8, buf + len).* = "--compress-debug-sections=none".*;
            len = len +% 30;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            @ptrCast(*[13]u8, buf + len).* = "--gc-sections".*;
            len = len +% 13;
            buf[len] = 0;
            len = len +% 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "--no-gc-sections".*;
            len = len +% 16;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.stack) |stack| {
        @ptrCast(*[7]u8, buf + len).* = "--stack".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        const s: []const u8 = builtin.fmt.ud64(stack).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.image_base) |image_base| {
        @ptrCast(*[12]u8, buf + len).* = "--image-base".*;
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
        const s: []const u8 = builtin.fmt.ud64(image_base).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
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
        @ptrCast(*[3]u8, buf + len).* = "-lc".*;
        len = len +% 3;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.rdynamic) {
        @ptrCast(*[9]u8, buf + len).* = "-rdynamic".*;
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.dynamic) {
        @ptrCast(*[8]u8, buf + len).* = "-dynamic".*;
        len = len +% 8;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.static) {
        @ptrCast(*[7]u8, buf + len).* = "-static".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.symbolic) {
        @ptrCast(*[10]u8, buf + len).* = "-Bsymbolic".*;
        len = len +% 10;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            @ptrCast(*[2]u8, buf + len).* = "-z".*;
            len = len +% 2;
            buf[len] = 0;
            len = len +% 1;
            mach.memcpy(buf + len, @tagName(value).ptr, @tagName(value).len);
            len = len +% @tagName(value).len;
            buf[len] = 0;
            len = len +% 1;
        }
    }
    if (cmd.files) |files| {
        len = len +% formatMap(files).formatWriteBuf(buf + len);
    }
    if (cmd.color) |color| {
        @ptrCast(*[7]u8, buf + len).* = "--color".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.time_report) {
        @ptrCast(*[13]u8, buf + len).* = "-ftime-report".*;
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.stack_report) {
        @ptrCast(*[14]u8, buf + len).* = "-fstack-report".*;
        len = len +% 14;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_link) {
        @ptrCast(*[14]u8, buf + len).* = "--verbose-link".*;
        len = len +% 14;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_cc) {
        @ptrCast(*[12]u8, buf + len).* = "--verbose-cc".*;
        len = len +% 12;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_air) {
        @ptrCast(*[13]u8, buf + len).* = "--verbose-air".*;
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_mir) {
        @ptrCast(*[13]u8, buf + len).* = "--verbose-mir".*;
        len = len +% 13;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_ir) {
        @ptrCast(*[17]u8, buf + len).* = "--verbose-llvm-ir".*;
        len = len +% 17;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_cimport) {
        @ptrCast(*[17]u8, buf + len).* = "--verbose-cimport".*;
        len = len +% 17;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.verbose_llvm_cpu_features) {
        @ptrCast(*[27]u8, buf + len).* = "--verbose-llvm-cpu-features".*;
        len = len +% 27;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_log) |debug_log| {
        @ptrCast(*[11]u8, buf + len).* = "--debug-log".*;
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, debug_log.ptr, debug_log.len);
        len = len +% debug_log.len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_compiler_errors) {
        @ptrCast(*[22]u8, buf + len).* = "--debug-compile-errors".*;
        len = len +% 22;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.debug_link_snapshot) {
        @ptrCast(*[21]u8, buf + len).* = "--debug-link-snapshot".*;
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
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len = len +% 1;
    mach.memcpy(buf + len, "fmt\x00", 4);
    len = len +% 4;
    if (cmd.color) |color| {
        @ptrCast(*[7]u8, buf + len).* = "--color".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len = len +% @tagName(color).len;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.stdin) {
        @ptrCast(*[7]u8, buf + len).* = "--stdin".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.check) {
        @ptrCast(*[7]u8, buf + len).* = "--check".*;
        len = len +% 7;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.ast_check) {
        @ptrCast(*[11]u8, buf + len).* = "--ast-check".*;
        len = len +% 11;
        buf[len] = 0;
        len = len +% 1;
    }
    if (cmd.exclude) |exclude| {
        @ptrCast(*[9]u8, buf + len).* = "--exclude".*;
        len = len +% 9;
        buf[len] = 0;
        len = len +% 1;
        mach.memcpy(buf + len, exclude.ptr, exclude.len);
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
