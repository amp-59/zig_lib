const tasks = @import("./tasks.zig");
const safety: bool = false;
pub const BuildCommand = packed struct {
    key: Key,
    val: Val,
    const undef: tasks.BuildCommand = undefined;
    const Key = packed struct {
        listen: bool = false,
        code_model: bool = false,
        red_zone: bool = false,
        implicit_builtins: bool = false,
        omit_frame_pointer: bool = false,
        mode: bool = false,
        pic: bool = false,
        pie: bool = false,
        lto: bool = false,
        stack_check: bool = false,
        stack_protector: bool = false,
        sanitize_c: bool = false,
        valgrind: bool = false,
        sanitize_thread: bool = false,
        unwind_tables: bool = false,
        llvm: bool = false,
        clang: bool = false,
        reference_trace: bool = false,
        error_tracing: bool = false,
        single_threaded: bool = false,
        function_sections: bool = false,
        strip: bool = false,
        formatted_panics: bool = false,
        format: bool = false,
        lld: bool = false,
        compiler_rt: bool = false,
        each_lib_rpath: bool = false,
        allow_shlib_undefined: bool = false,
        build_id: bool = false,
        gc_sections: bool = false,
        color: bool = false,
    };
    const Val = packed struct {
        listen: @typeInfo(@TypeOf(@field(undef, "listen"))).Optional.child = undefined,
        code_model: @typeInfo(@TypeOf(@field(undef, "code_model"))).Optional.child = undefined,
        red_zone: bool = undefined,
        implicit_builtins: bool = undefined,
        omit_frame_pointer: bool = undefined,
        mode: @typeInfo(@TypeOf(@field(undef, "mode"))).Optional.child = undefined,
        pic: bool = undefined,
        pie: bool = undefined,
        lto: bool = undefined,
        stack_check: bool = undefined,
        stack_protector: bool = undefined,
        sanitize_c: bool = undefined,
        valgrind: bool = undefined,
        sanitize_thread: bool = undefined,
        unwind_tables: bool = undefined,
        llvm: bool = undefined,
        clang: bool = undefined,
        reference_trace: bool = undefined,
        error_tracing: bool = undefined,
        single_threaded: bool = undefined,
        function_sections: bool = undefined,
        strip: bool = undefined,
        formatted_panics: bool = undefined,
        format: @typeInfo(@TypeOf(@field(undef, "format"))).Optional.child = undefined,
        lld: bool = undefined,
        compiler_rt: bool = undefined,
        each_lib_rpath: bool = undefined,
        allow_shlib_undefined: bool = undefined,
        build_id: @typeInfo(@TypeOf(@field(undef, "build_id"))).Optional.child = undefined,
        gc_sections: bool = undefined,
        color: @typeInfo(@TypeOf(@field(undef, "color"))).Optional.child = undefined,
    };
    pub fn convert(cmd: *tasks.BuildCommand) BuildCommand {
        @setRuntimeSafety(false);
        var ret: BuildCommand = undefined;
        ret.key.listen = cmd.listen != null;
        ret.val.listen = cmd.listen.?;
        ret.key.code_model = cmd.code_model != null;
        ret.val.code_model = cmd.code_model.?;
        ret.key.red_zone = cmd.red_zone != null;
        ret.val.red_zone = cmd.red_zone.?;
        ret.key.implicit_builtins = cmd.implicit_builtins != null;
        ret.val.implicit_builtins = cmd.implicit_builtins.?;
        ret.key.omit_frame_pointer = cmd.omit_frame_pointer != null;
        ret.val.omit_frame_pointer = cmd.omit_frame_pointer.?;
        ret.key.mode = cmd.mode != null;
        ret.val.mode = cmd.mode.?;
        ret.key.pic = cmd.pic != null;
        ret.val.pic = cmd.pic.?;
        ret.key.pie = cmd.pie != null;
        ret.val.pie = cmd.pie.?;
        ret.key.lto = cmd.lto != null;
        ret.val.lto = cmd.lto.?;
        ret.key.stack_check = cmd.stack_check != null;
        ret.val.stack_check = cmd.stack_check.?;
        ret.key.stack_protector = cmd.stack_protector != null;
        ret.val.stack_protector = cmd.stack_protector.?;
        ret.key.sanitize_c = cmd.sanitize_c != null;
        ret.val.sanitize_c = cmd.sanitize_c.?;
        ret.key.valgrind = cmd.valgrind != null;
        ret.val.valgrind = cmd.valgrind.?;
        ret.key.sanitize_thread = cmd.sanitize_thread != null;
        ret.val.sanitize_thread = cmd.sanitize_thread.?;
        ret.key.unwind_tables = cmd.unwind_tables != null;
        ret.val.unwind_tables = cmd.unwind_tables.?;
        ret.key.llvm = cmd.llvm != null;
        ret.val.llvm = cmd.llvm.?;
        ret.key.clang = cmd.clang != null;
        ret.val.clang = cmd.clang.?;
        ret.key.reference_trace = cmd.reference_trace != null;
        ret.val.reference_trace = cmd.reference_trace.?;
        ret.key.error_tracing = cmd.error_tracing != null;
        ret.val.error_tracing = cmd.error_tracing.?;
        ret.key.single_threaded = cmd.single_threaded != null;
        ret.val.single_threaded = cmd.single_threaded.?;
        ret.key.function_sections = cmd.function_sections != null;
        ret.val.function_sections = cmd.function_sections.?;
        ret.key.strip = cmd.strip != null;
        ret.val.strip = cmd.strip.?;
        ret.key.formatted_panics = cmd.formatted_panics != null;
        ret.val.formatted_panics = cmd.formatted_panics.?;
        ret.key.format = cmd.format != null;
        ret.val.format = cmd.format.?;
        ret.key.lld = cmd.lld != null;
        ret.val.lld = cmd.lld.?;
        ret.key.compiler_rt = cmd.compiler_rt != null;
        ret.val.compiler_rt = cmd.compiler_rt.?;
        ret.key.each_lib_rpath = cmd.each_lib_rpath != null;
        ret.val.each_lib_rpath = cmd.each_lib_rpath.?;
        ret.key.allow_shlib_undefined = cmd.allow_shlib_undefined != null;
        ret.val.allow_shlib_undefined = cmd.allow_shlib_undefined.?;
        ret.key.build_id = cmd.build_id != null;
        ret.val.build_id = cmd.build_id.?;
        ret.key.gc_sections = cmd.gc_sections != null;
        ret.val.gc_sections = cmd.gc_sections.?;
        ret.key.color = cmd.color != null;
        ret.val.color = cmd.color.?;
        return ret;
    }
};
pub const FormatCommand = packed struct {
    key: Key,
    val: Val,
    const undef: tasks.FormatCommand = undefined;
    const Key = packed struct {
        color: bool = false,
    };
    const Val = packed struct {
        color: @typeInfo(@TypeOf(@field(undef, "color"))).Optional.child = undefined,
    };
    pub fn convert(cmd: *tasks.FormatCommand) FormatCommand {
        @setRuntimeSafety(false);
        var ret: FormatCommand = undefined;
        ret.key.color = cmd.color != null;
        ret.val.color = cmd.color.?;
        return ret;
    }
};
pub const ArchiveCommand = packed struct {
    key: Key,
    val: Val,
    const undef: tasks.ArchiveCommand = undefined;
    const Key = packed struct {
        format: bool = false,
    };
    const Val = packed struct {
        format: @typeInfo(@TypeOf(@field(undef, "format"))).Optional.child = undefined,
    };
    pub fn convert(cmd: *tasks.ArchiveCommand) ArchiveCommand {
        @setRuntimeSafety(false);
        var ret: ArchiveCommand = undefined;
        ret.key.format = cmd.format != null;
        ret.val.format = cmd.format.?;
        return ret;
    }
};
pub const TableGenCommand = packed struct {
    key: Key,
    val: Val,
    const undef: tasks.TableGenCommand = undefined;
    const Key = packed struct {
        color: bool = false,
    };
    const Val = packed struct {
        color: @typeInfo(@TypeOf(@field(undef, "color"))).Optional.child = undefined,
    };
    pub fn convert(cmd: *tasks.TableGenCommand) TableGenCommand {
        @setRuntimeSafety(false);
        var ret: TableGenCommand = undefined;
        ret.key.color = cmd.color != null;
        ret.val.color = cmd.color.?;
        return ret;
    }
};
