const builtin = @import("../../builtin.zig");
pub const runtime_assertions: bool = false;
pub const logging_default = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Attempt = false,
    .Error = true,
    .Fault = true,
};
/// Auxiliary products of builder implementation generator go here. These are
/// generated source files (src) or serialised data (bin). They exist to speed
/// subsequent steps and will be replaced whenever missing.
pub const zig_out_dir: [:0]const u8 = builtin.buildRoot() ++ "/top/sys/gen/zig-out";
pub const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
pub const zig_out_bin_dir: [:0]const u8 = zig_out_dir ++ "/bin";

pub const build_command_options_path: [:0]const u8 = auxiliaryDataFile("build_command_options");
pub const format_command_options_path: [:0]const u8 = auxiliaryDataFile("format_command_options");

pub const flags_path: [:0]const u8 = primarySourceFile("flags.zig");
pub const flags_template_path: [:0]const u8 = builtin.lib_root ++ "/top/sys/gen/flags-template.zig";

pub const decls_path: [:0]const u8 = primarySourceFile("decls.zig");
pub const decls_template_path: [:0]const u8 = builtin.lib_root ++ "/top/sys/gen/decls-template.zig";

pub const extra_path: [:0]const u8 = primarySourceFile("extra.zig");
pub const extra_template_path: [:0]const u8 = builtin.lib_root ++ "/top/sys/gen/extra-template.zig";

pub fn primarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') builtin.lib_root ++ "/top/sys/" ++ name else name;
}
pub fn auxiliarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub fn auxiliaryDataFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub const declare_task_field_types: bool = false;
pub const allow_comptime_configure_parser: bool = false;

pub const commit: bool = true;
