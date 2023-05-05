const mach = @import("../mach.zig");
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
    @setRuntimeSafety(false);
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
                    @ptrCast(*[10]u8, buf + len).* = "-femit-bin".*;
                    len +%= 10;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-bin".*;
                    len +%= 10;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[13]u8, buf + len).* = "-fno-emit-bin".*;
                len +%= 13;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-asm".*;
                    len +%= 10;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[10]u8, buf + len).* = "-femit-asm".*;
                    len +%= 10;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[13]u8, buf + len).* = "-fno-emit-asm".*;
                len +%= 13;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-ir".*;
                    len +%= 14;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-ir".*;
                    len +%= 14;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[17]u8, buf + len).* = "-fno-emit-llvm-ir".*;
                len +%= 17;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-bc".*;
                    len +%= 14;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[14]u8, buf + len).* = "-femit-llvm-bc".*;
                    len +%= 14;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[17]u8, buf + len).* = "-fno-emit-llvm-bc".*;
                len +%= 17;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[8]u8, buf + len).* = "-femit-h".*;
                    len +%= 8;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[8]u8, buf + len).* = "-femit-h".*;
                    len +%= 8;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[11]u8, buf + len).* = "-fno-emit-h".*;
                len +%= 11;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-docs".*;
                    len +%= 11;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[11]u8, buf + len).* = "-femit-docs".*;
                    len +%= 11;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[14]u8, buf + len).* = "-fno-emit-docs".*;
                len +%= 14;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-analysis".*;
                    len +%= 15;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[15]u8, buf + len).* = "-femit-analysis".*;
                    len +%= 15;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[18]u8, buf + len).* = "-fno-emit-analysis".*;
                len +%= 18;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    @ptrCast(*[13]u8, buf + len).* = "-femit-implib".*;
                    len +%= 13;
                    buf[len] = 61;
                    len +%= 1;
                    len +%= arg.formatWriteBuf(buf + len);
                } else {
                    @ptrCast(*[13]u8, buf + len).* = "-femit-implib".*;
                    len +%= 13;
                    buf[len] = 0;
                    len +%= 1;
                }
            },
            .no => {
                @ptrCast(*[16]u8, buf + len).* = "-fno-emit-implib".*;
                len +%= 16;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        @ptrCast(*[11]u8, buf + len).* = "--cache-dir".*;
        len +%= 11;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, cache_root.ptr, cache_root.len);
        len +%= cache_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        @ptrCast(*[18]u8, buf + len).* = "--global-cache-dir".*;
        len +%= 18;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, global_cache_root.ptr, global_cache_root.len);
        len +%= global_cache_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        @ptrCast(*[13]u8, buf + len).* = "--zig-lib-dir".*;
        len +%= 13;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, zig_lib_root.ptr, zig_lib_root.len);
        len +%= zig_lib_root.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.listen) |listen| {
        @ptrCast(*[8]u8, buf + len).* = "--listen".*;
        len +%= 8;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(listen).ptr, @tagName(listen).len);
        len +%= @tagName(listen).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.target) |target| {
        @ptrCast(*[7]u8, buf + len).* = "-target".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, target.ptr, target.len);
        len +%= target.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.cpu) |cpu| {
        @ptrCast(*[5]u8, buf + len).* = "-mcpu".*;
        len +%= 5;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, cpu.ptr, cpu.len);
        len +%= cpu.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.code_model) |code_model| {
        @ptrCast(*[8]u8, buf + len).* = "-mcmodel".*;
        len +%= 8;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(code_model).ptr, @tagName(code_model).len);
        len +%= @tagName(code_model).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            @ptrCast(*[10]u8, buf + len).* = "-mred-zone".*;
            len +%= 10;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-mno-red-zone".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            @ptrCast(*[20]u8, buf + len).* = "-fomit-frame-pointer".*;
            len +%= 20;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[23]u8, buf + len).* = "-fno-omit-frame-pointer".*;
            len +%= 23;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.exec_model) |exec_model| {
        @ptrCast(*[12]u8, buf + len).* = "-mexec-model".*;
        len +%= 12;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, exec_model.ptr, exec_model.len);
        len +%= exec_model.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.name) |name| {
        @ptrCast(*[6]u8, buf + len).* = "--name".*;
        len +%= 6;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, name.ptr, name.len);
        len +%= name.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                @ptrCast(*[8]u8, buf + len).* = "-fsoname".*;
                len +%= 8;
                buf[len] = 0;
                len +%= 1;
                mach.memcpy(buf + len, arg.ptr, arg.len);
                len +%= arg.len;
                buf[len] = 0;
                len +%= 1;
            },
            .no => {
                @ptrCast(*[11]u8, buf + len).* = "-fno-soname".*;
                len +%= 11;
                buf[len] = 0;
                len +%= 1;
            },
        }
    }
    if (cmd.mode) |mode| {
        @ptrCast(*[2]u8, buf + len).* = "-O".*;
        len +%= 2;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(mode).ptr, @tagName(mode).len);
        len +%= @tagName(mode).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        @ptrCast(*[15]u8, buf + len).* = "--main-pkg-path".*;
        len +%= 15;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, main_pkg_path.ptr, main_pkg_path.len);
        len +%= main_pkg_path.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            @ptrCast(*[5]u8, buf + len).* = "-fPIC".*;
            len +%= 5;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-PIC".*;
            len +%= 8;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            @ptrCast(*[5]u8, buf + len).* = "-fPIE".*;
            len +%= 5;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-PIE".*;
            len +%= 8;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            @ptrCast(*[5]u8, buf + len).* = "-flto".*;
            len +%= 5;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-lto".*;
            len +%= 8;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            @ptrCast(*[13]u8, buf + len).* = "-fstack-check".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "-fno-stack-check".*;
            len +%= 16;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            @ptrCast(*[13]u8, buf + len).* = "-fstack-check".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-stack-protector".*;
            len +%= 20;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            @ptrCast(*[12]u8, buf + len).* = "-fsanitize-c".*;
            len +%= 12;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[15]u8, buf + len).* = "-fno-sanitize-c".*;
            len +%= 15;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            @ptrCast(*[10]u8, buf + len).* = "-fvalgrind".*;
            len +%= 10;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-fno-valgrind".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            @ptrCast(*[17]u8, buf + len).* = "-fsanitize-thread".*;
            len +%= 17;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-sanitize-thread".*;
            len +%= 20;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            @ptrCast(*[15]u8, buf + len).* = "-funwind-tables".*;
            len +%= 15;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[18]u8, buf + len).* = "-fno-unwind-tables".*;
            len +%= 18;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            @ptrCast(*[6]u8, buf + len).* = "-fLLVM".*;
            len +%= 6;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[9]u8, buf + len).* = "-fno-LLVM".*;
            len +%= 9;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            @ptrCast(*[7]u8, buf + len).* = "-fClang".*;
            len +%= 7;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[10]u8, buf + len).* = "-fno-Clang".*;
            len +%= 10;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            @ptrCast(*[17]u8, buf + len).* = "-freference-trace".*;
            len +%= 17;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-reference-trace".*;
            len +%= 20;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            @ptrCast(*[15]u8, buf + len).* = "-ferror-tracing".*;
            len +%= 15;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[18]u8, buf + len).* = "-fno-error-tracing".*;
            len +%= 18;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            @ptrCast(*[17]u8, buf + len).* = "-fsingle-threaded".*;
            len +%= 17;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[20]u8, buf + len).* = "-fno-single-threaded".*;
            len +%= 20;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            @ptrCast(*[19]u8, buf + len).* = "-ffunction-sections".*;
            len +%= 19;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[22]u8, buf + len).* = "-fno-function-sections".*;
            len +%= 22;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            @ptrCast(*[7]u8, buf + len).* = "-fstrip".*;
            len +%= 7;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[10]u8, buf + len).* = "-fno-strip".*;
            len +%= 10;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            @ptrCast(*[18]u8, buf + len).* = "-fformatted-panics".*;
            len +%= 18;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[21]u8, buf + len).* = "-fno-formatted-panics".*;
            len +%= 21;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.format) |format| {
        @ptrCast(*[5]u8, buf + len).* = "-ofmt".*;
        len +%= 5;
        buf[len] = 61;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(format).ptr, @tagName(format).len);
        len +%= @tagName(format).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.dirafter) |dirafter| {
        @ptrCast(*[10]u8, buf + len).* = "-idirafter".*;
        len +%= 10;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, dirafter.ptr, dirafter.len);
        len +%= dirafter.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.system) |system| {
        @ptrCast(*[8]u8, buf + len).* = "-isystem".*;
        len +%= 8;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, system.ptr, system.len);
        len +%= system.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.include) |include| {
        @ptrCast(*[2]u8, buf + len).* = "-I".*;
        len +%= 2;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, include.ptr, include.len);
        len +%= include.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.libc) |libc| {
        @ptrCast(*[6]u8, buf + len).* = "--libc".*;
        len +%= 6;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, libc.ptr, libc.len);
        len +%= libc.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.library) |library| {
        @ptrCast(*[9]u8, buf + len).* = "--library".*;
        len +%= 9;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, library.ptr, library.len);
        len +%= library.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            @ptrCast(*[16]u8, buf + len).* = "--needed-library".*;
            len +%= 16;
            buf[len] = 0;
            len +%= 1;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            @ptrCast(*[19]u8, buf + len).* = "--library-directory".*;
            len +%= 19;
            buf[len] = 0;
            len +%= 1;
            mach.memcpy(buf + len, value.ptr, value.len);
            len +%= value.len;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.link_script) |link_script| {
        @ptrCast(*[8]u8, buf + len).* = "--script".*;
        len +%= 8;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, link_script.ptr, link_script.len);
        len +%= link_script.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.version_script) |version_script| {
        @ptrCast(*[16]u8, buf + len).* = "--version-script".*;
        len +%= 16;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, version_script.ptr, version_script.len);
        len +%= version_script.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        @ptrCast(*[16]u8, buf + len).* = "--dynamic-linker".*;
        len +%= 16;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, dynamic_linker.ptr, dynamic_linker.len);
        len +%= dynamic_linker.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.sysroot) |sysroot| {
        @ptrCast(*[9]u8, buf + len).* = "--sysroot".*;
        len +%= 9;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, sysroot.ptr, sysroot.len);
        len +%= sysroot.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.entry) |entry| {
        @ptrCast(*[7]u8, buf + len).* = "--entry".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, entry.ptr, entry.len);
        len +%= entry.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            @ptrCast(*[5]u8, buf + len).* = "-fLLD".*;
            len +%= 5;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[8]u8, buf + len).* = "-fno-LLD".*;
            len +%= 8;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            @ptrCast(*[13]u8, buf + len).* = "-fcompiler-rt".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "-fno-compiler-rt".*;
            len +%= 16;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.rpath) |rpath| {
        @ptrCast(*[6]u8, buf + len).* = "-rpath".*;
        len +%= 6;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, rpath.ptr, rpath.len);
        len +%= rpath.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            @ptrCast(*[16]u8, buf + len).* = "-feach-lib-rpath".*;
            len +%= 16;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[19]u8, buf + len).* = "-fno-each-lib-rpath".*;
            len +%= 19;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            @ptrCast(*[23]u8, buf + len).* = "-fallow-shlib-undefined".*;
            len +%= 23;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[26]u8, buf + len).* = "-fno-allow-shlib-undefined".*;
            len +%= 26;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            @ptrCast(*[10]u8, buf + len).* = "-fbuild-id".*;
            len +%= 10;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[13]u8, buf + len).* = "-fno-build-id".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            @ptrCast(*[30]u8, buf + len).* = "--compress-debug-sections=zlib".*;
            len +%= 30;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[30]u8, buf + len).* = "--compress-debug-sections=none".*;
            len +%= 30;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            @ptrCast(*[13]u8, buf + len).* = "--gc-sections".*;
            len +%= 13;
            buf[len] = 0;
            len +%= 1;
        } else {
            @ptrCast(*[16]u8, buf + len).* = "--no-gc-sections".*;
            len +%= 16;
            buf[len] = 0;
            len +%= 1;
        }
    }
    if (cmd.stack) |stack| {
        @ptrCast(*[7]u8, buf + len).* = "--stack".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
        const s: []const u8 = builtin.fmt.ud64(stack).readAll();
        mach.memcpy(buf + len, s.ptr, s.len);
        len = len + s.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        @ptrCast(*[12]u8, buf + len).* = "--image-base".*;
        len +%= 12;
        buf[len] = 0;
        len +%= 1;
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
        @ptrCast(*[3]u8, buf + len).* = "-lc".*;
        len +%= 3;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.rdynamic) {
        @ptrCast(*[9]u8, buf + len).* = "-rdynamic".*;
        len +%= 9;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.dynamic) {
        @ptrCast(*[8]u8, buf + len).* = "-dynamic".*;
        len +%= 8;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.static) {
        @ptrCast(*[7]u8, buf + len).* = "-static".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.symbolic) {
        @ptrCast(*[10]u8, buf + len).* = "-Bsymbolic".*;
        len +%= 10;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            @ptrCast(*[2]u8, buf + len).* = "-z".*;
            len +%= 2;
            buf[len] = 0;
            len +%= 1;
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
        @ptrCast(*[7]u8, buf + len).* = "--color".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len +%= @tagName(color).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.time_report) {
        @ptrCast(*[13]u8, buf + len).* = "-ftime-report".*;
        len +%= 13;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.stack_report) {
        @ptrCast(*[14]u8, buf + len).* = "-fstack-report".*;
        len +%= 14;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_link) {
        @ptrCast(*[14]u8, buf + len).* = "--verbose-link".*;
        len +%= 14;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_cc) {
        @ptrCast(*[12]u8, buf + len).* = "--verbose-cc".*;
        len +%= 12;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_air) {
        @ptrCast(*[13]u8, buf + len).* = "--verbose-air".*;
        len +%= 13;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_mir) {
        @ptrCast(*[13]u8, buf + len).* = "--verbose-mir".*;
        len +%= 13;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_llvm_ir) {
        @ptrCast(*[17]u8, buf + len).* = "--verbose-llvm-ir".*;
        len +%= 17;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_cimport) {
        @ptrCast(*[17]u8, buf + len).* = "--verbose-cimport".*;
        len +%= 17;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.verbose_llvm_cpu_features) {
        @ptrCast(*[27]u8, buf + len).* = "--verbose-llvm-cpu-features".*;
        len +%= 27;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.debug_log) |debug_log| {
        @ptrCast(*[11]u8, buf + len).* = "--debug-log".*;
        len +%= 11;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, debug_log.ptr, debug_log.len);
        len +%= debug_log.len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.debug_compiler_errors) {
        @ptrCast(*[22]u8, buf + len).* = "--debug-compile-errors".*;
        len +%= 22;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.debug_link_snapshot) {
        @ptrCast(*[21]u8, buf + len).* = "--debug-link-snapshot".*;
        len +%= 21;
        buf[len] = 0;
        len +%= 1;
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
                    len +%= 10;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 10;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 13;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_asm) |emit_asm| {
        switch (emit_asm) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 10;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 10;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 13;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_llvm_ir) |emit_llvm_ir| {
        switch (emit_llvm_ir) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 14;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 14;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 17;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_llvm_bc) |emit_llvm_bc| {
        switch (emit_llvm_bc) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 14;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 14;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 17;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_h) |emit_h| {
        switch (emit_h) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 8;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 8;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 11;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_docs) |emit_docs| {
        switch (emit_docs) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 11;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 11;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 14;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_analysis) |emit_analysis| {
        switch (emit_analysis) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 15;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 15;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 18;
                len +%= 1;
            },
        }
    }
    if (cmd.emit_implib) |emit_implib| {
        switch (emit_implib) {
            .yes => |yes| {
                if (yes) |arg| {
                    len +%= 13;
                    len +%= 1;
                    len +%= arg.formatLength();
                } else {
                    len +%= 13;
                    len +%= 1;
                }
            },
            .no => {
                len +%= 16;
                len +%= 1;
            },
        }
    }
    if (cmd.cache_root) |cache_root| {
        len +%= 11;
        len +%= 1;
        len +%= cache_root.len;
        len +%= 1;
    }
    if (cmd.global_cache_root) |global_cache_root| {
        len +%= 18;
        len +%= 1;
        len +%= global_cache_root.len;
        len +%= 1;
    }
    if (cmd.zig_lib_root) |zig_lib_root| {
        len +%= 13;
        len +%= 1;
        len +%= zig_lib_root.len;
        len +%= 1;
    }
    if (cmd.listen) |listen| {
        len +%= 8;
        len +%= 1;
        len +%= @tagName(listen).len;
        len +%= 1;
    }
    if (cmd.target) |target| {
        len +%= 7;
        len +%= 1;
        len +%= target.len;
        len +%= 1;
    }
    if (cmd.cpu) |cpu| {
        len +%= 5;
        len +%= 1;
        len +%= cpu.len;
        len +%= 1;
    }
    if (cmd.code_model) |code_model| {
        len +%= 8;
        len +%= 1;
        len +%= @tagName(code_model).len;
        len +%= 1;
    }
    if (cmd.red_zone) |red_zone| {
        if (red_zone) {
            len +%= 10;
            len +%= 1;
        } else {
            len +%= 13;
            len +%= 1;
        }
    }
    if (cmd.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            len +%= 20;
            len +%= 1;
        } else {
            len +%= 23;
            len +%= 1;
        }
    }
    if (cmd.exec_model) |exec_model| {
        len +%= 12;
        len +%= 1;
        len +%= exec_model.len;
        len +%= 1;
    }
    if (cmd.name) |name| {
        len +%= 6;
        len +%= 1;
        len +%= name.len;
        len +%= 1;
    }
    if (cmd.soname) |soname| {
        switch (soname) {
            .yes => |arg| {
                len +%= 8;
                len +%= 1;
                len +%= arg.len;
                len +%= 1;
            },
            .no => {
                len +%= 11;
                len +%= 1;
            },
        }
    }
    if (cmd.mode) |mode| {
        len +%= 2;
        len +%= 1;
        len +%= @tagName(mode).len;
        len +%= 1;
    }
    if (cmd.main_pkg_path) |main_pkg_path| {
        len +%= 15;
        len +%= 1;
        len +%= main_pkg_path.len;
        len +%= 1;
    }
    if (cmd.pic) |pic| {
        if (pic) {
            len +%= 5;
            len +%= 1;
        } else {
            len +%= 8;
            len +%= 1;
        }
    }
    if (cmd.pie) |pie| {
        if (pie) {
            len +%= 5;
            len +%= 1;
        } else {
            len +%= 8;
            len +%= 1;
        }
    }
    if (cmd.lto) |lto| {
        if (lto) {
            len +%= 5;
            len +%= 1;
        } else {
            len +%= 8;
            len +%= 1;
        }
    }
    if (cmd.stack_check) |stack_check| {
        if (stack_check) {
            len +%= 13;
            len +%= 1;
        } else {
            len +%= 16;
            len +%= 1;
        }
    }
    if (cmd.stack_protector) |stack_protector| {
        if (stack_protector) {
            len +%= 13;
            len +%= 1;
        } else {
            len +%= 20;
            len +%= 1;
        }
    }
    if (cmd.sanitize_c) |sanitize_c| {
        if (sanitize_c) {
            len +%= 12;
            len +%= 1;
        } else {
            len +%= 15;
            len +%= 1;
        }
    }
    if (cmd.valgrind) |valgrind| {
        if (valgrind) {
            len +%= 10;
            len +%= 1;
        } else {
            len +%= 13;
            len +%= 1;
        }
    }
    if (cmd.sanitize_thread) |sanitize_thread| {
        if (sanitize_thread) {
            len +%= 17;
            len +%= 1;
        } else {
            len +%= 20;
            len +%= 1;
        }
    }
    if (cmd.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            len +%= 15;
            len +%= 1;
        } else {
            len +%= 18;
            len +%= 1;
        }
    }
    if (cmd.llvm) |llvm| {
        if (llvm) {
            len +%= 6;
            len +%= 1;
        } else {
            len +%= 9;
            len +%= 1;
        }
    }
    if (cmd.clang) |clang| {
        if (clang) {
            len +%= 7;
            len +%= 1;
        } else {
            len +%= 10;
            len +%= 1;
        }
    }
    if (cmd.reference_trace) |reference_trace| {
        if (reference_trace) {
            len +%= 17;
            len +%= 1;
        } else {
            len +%= 20;
            len +%= 1;
        }
    }
    if (cmd.error_tracing) |error_tracing| {
        if (error_tracing) {
            len +%= 15;
            len +%= 1;
        } else {
            len +%= 18;
            len +%= 1;
        }
    }
    if (cmd.single_threaded) |single_threaded| {
        if (single_threaded) {
            len +%= 17;
            len +%= 1;
        } else {
            len +%= 20;
            len +%= 1;
        }
    }
    if (cmd.function_sections) |function_sections| {
        if (function_sections) {
            len +%= 19;
            len +%= 1;
        } else {
            len +%= 22;
            len +%= 1;
        }
    }
    if (cmd.strip) |strip| {
        if (strip) {
            len +%= 7;
            len +%= 1;
        } else {
            len +%= 10;
            len +%= 1;
        }
    }
    if (cmd.formatted_panics) |formatted_panics| {
        if (formatted_panics) {
            len +%= 18;
            len +%= 1;
        } else {
            len +%= 21;
            len +%= 1;
        }
    }
    if (cmd.format) |format| {
        len +%= 5;
        len +%= 1;
        len +%= @tagName(format).len;
        len +%= 1;
    }
    if (cmd.dirafter) |dirafter| {
        len +%= 10;
        len +%= 1;
        len +%= dirafter.len;
        len +%= 1;
    }
    if (cmd.system) |system| {
        len +%= 8;
        len +%= 1;
        len +%= system.len;
        len +%= 1;
    }
    if (cmd.include) |include| {
        len +%= 2;
        len +%= 1;
        len +%= include.len;
        len +%= 1;
    }
    if (cmd.libc) |libc| {
        len +%= 6;
        len +%= 1;
        len +%= libc.len;
        len +%= 1;
    }
    if (cmd.library) |library| {
        len +%= 9;
        len +%= 1;
        len +%= library.len;
        len +%= 1;
    }
    if (cmd.needed_library) |needed_library| {
        for (needed_library) |value| {
            len +%= 16;
            len +%= 1;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.library_directory) |library_directory| {
        for (library_directory) |value| {
            len +%= 19;
            len +%= 1;
            len +%= value.len;
            len +%= 1;
        }
    }
    if (cmd.link_script) |link_script| {
        len +%= 8;
        len +%= 1;
        len +%= link_script.len;
        len +%= 1;
    }
    if (cmd.version_script) |version_script| {
        len +%= 16;
        len +%= 1;
        len +%= version_script.len;
        len +%= 1;
    }
    if (cmd.dynamic_linker) |dynamic_linker| {
        len +%= 16;
        len +%= 1;
        len +%= dynamic_linker.len;
        len +%= 1;
    }
    if (cmd.sysroot) |sysroot| {
        len +%= 9;
        len +%= 1;
        len +%= sysroot.len;
        len +%= 1;
    }
    if (cmd.entry) |entry| {
        len +%= 7;
        len +%= 1;
        len +%= entry.len;
        len +%= 1;
    }
    if (cmd.lld) |lld| {
        if (lld) {
            len +%= 5;
            len +%= 1;
        } else {
            len +%= 8;
            len +%= 1;
        }
    }
    if (cmd.compiler_rt) |compiler_rt| {
        if (compiler_rt) {
            len +%= 13;
            len +%= 1;
        } else {
            len +%= 16;
            len +%= 1;
        }
    }
    if (cmd.rpath) |rpath| {
        len +%= 6;
        len +%= 1;
        len +%= rpath.len;
        len +%= 1;
    }
    if (cmd.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            len +%= 16;
            len +%= 1;
        } else {
            len +%= 19;
            len +%= 1;
        }
    }
    if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
        if (allow_shlib_undefined) {
            len +%= 23;
            len +%= 1;
        } else {
            len +%= 26;
            len +%= 1;
        }
    }
    if (cmd.build_id) |build_id| {
        if (build_id) {
            len +%= 10;
            len +%= 1;
        } else {
            len +%= 13;
            len +%= 1;
        }
    }
    if (cmd.compress_debug_sections) |compress_debug_sections| {
        if (compress_debug_sections) {
            len +%= 30;
            len +%= 1;
        } else {
            len +%= 30;
            len +%= 1;
        }
    }
    if (cmd.gc_sections) |gc_sections| {
        if (gc_sections) {
            len +%= 13;
            len +%= 1;
        } else {
            len +%= 16;
            len +%= 1;
        }
    }
    if (cmd.stack) |stack| {
        len +%= 7;
        len +%= 1;
        len +%= builtin.fmt.ud64(stack).readAll().len;
        len +%= 1;
    }
    if (cmd.image_base) |image_base| {
        len +%= 12;
        len +%= 1;
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
        len +%= 3;
        len +%= 1;
    }
    if (cmd.rdynamic) {
        len +%= 9;
        len +%= 1;
    }
    if (cmd.dynamic) {
        len +%= 8;
        len +%= 1;
    }
    if (cmd.static) {
        len +%= 7;
        len +%= 1;
    }
    if (cmd.symbolic) {
        len +%= 10;
        len +%= 1;
    }
    if (cmd.z) |z| {
        for (z) |value| {
            len +%= 2;
            len +%= 1;
            len +%= @tagName(value).len;
            len +%= 1;
        }
    }
    if (cmd.files) |files| {
        len +%= formatMap(files).formatLength();
    }
    if (cmd.color) |color| {
        len +%= 7;
        len +%= 1;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.time_report) {
        len +%= 13;
        len +%= 1;
    }
    if (cmd.stack_report) {
        len +%= 14;
        len +%= 1;
    }
    if (cmd.verbose_link) {
        len +%= 14;
        len +%= 1;
    }
    if (cmd.verbose_cc) {
        len +%= 12;
        len +%= 1;
    }
    if (cmd.verbose_air) {
        len +%= 13;
        len +%= 1;
    }
    if (cmd.verbose_mir) {
        len +%= 13;
        len +%= 1;
    }
    if (cmd.verbose_llvm_ir) {
        len +%= 17;
        len +%= 1;
    }
    if (cmd.verbose_cimport) {
        len +%= 17;
        len +%= 1;
    }
    if (cmd.verbose_llvm_cpu_features) {
        len +%= 27;
        len +%= 1;
    }
    if (cmd.debug_log) |debug_log| {
        len +%= 11;
        len +%= 1;
        len +%= debug_log.len;
        len +%= 1;
    }
    if (cmd.debug_compiler_errors) {
        len +%= 22;
        len +%= 1;
    }
    if (cmd.debug_link_snapshot) {
        len +%= 21;
        len +%= 1;
    }
    return len +% root_path.formatLength() +% 1;
}
pub fn formatWriteBuf(cmd: *const tasks.FormatCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
    @setRuntimeSafety(false);
    mach.memcpy(buf, zig_exe.ptr, zig_exe.len);
    var len: u64 = zig_exe.len;
    buf[len] = 0;
    len +%= 1;
    mach.memcpy(buf + len, "fmt\x00", 4);
    len +%= 4;
    if (cmd.color) |color| {
        @ptrCast(*[7]u8, buf + len).* = "--color".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
        mach.memcpy(buf + len, @tagName(color).ptr, @tagName(color).len);
        len +%= @tagName(color).len;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.stdin) {
        @ptrCast(*[7]u8, buf + len).* = "--stdin".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.check) {
        @ptrCast(*[7]u8, buf + len).* = "--check".*;
        len +%= 7;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.ast_check) {
        @ptrCast(*[11]u8, buf + len).* = "--ast-check".*;
        len +%= 11;
        buf[len] = 0;
        len +%= 1;
    }
    if (cmd.exclude) |exclude| {
        @ptrCast(*[9]u8, buf + len).* = "--exclude".*;
        len +%= 9;
        buf[len] = 0;
        len +%= 1;
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
    @setRuntimeSafety(false);
    var len: u64 = zig_exe.len +% 5;
    if (cmd.color) |color| {
        len +%= 7;
        len +%= 1;
        len +%= @tagName(color).len;
        len +%= 1;
    }
    if (cmd.stdin) {
        len +%= 7;
        len +%= 1;
    }
    if (cmd.check) {
        len +%= 7;
        len +%= 1;
    }
    if (cmd.ast_check) {
        len +%= 11;
        len +%= 1;
    }
    if (cmd.exclude) |exclude| {
        len +%= 9;
        len +%= 1;
        len +%= exclude.len;
        len +%= 1;
    }
    return len +% root_path.formatLength() +% 1;
}
