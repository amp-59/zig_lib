const builtin = @import("../../builtin.zig");

/// Auxiliary products of builder implementation generator go here. These are
/// generated source files (src) or serialised data (bin). They exist to speed
/// subsequent steps and will be replaced whenever missing.
pub const zig_out_dir: [:0]const u8 = builtin.buildRoot() ++ "/top/mem/gen/zig-out";
pub const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
pub const zig_out_bin_dir: [:0]const u8 = zig_out_dir ++ "/bin";

pub const build_command_options_path: [:0]const u8 = auxiliaryDataFile("build_command_options");
pub const format_command_options_path: [:0]const u8 = auxiliaryDataFile("format_command_options");

pub const cmdline_path: [:0]const u8 = primarySourceFile("cmdline.zig");
pub const abstract_cmdline_path: [:0]const u8 = primarySourceFile("abstract_cmdline.zig");
pub const cmdline_template_path: [:0]const u8 = primarySourceFile("cmdline-template.zig");

pub const tasks_path: [:0]const u8 = primarySourceFile("tasks.zig");
pub const tasks_template_path: [:0]const u8 = builtin.root.build_root ++ "/top/build/gen/tasks-template.zig";
pub const hist_tasks_path: [:0]const u8 = primarySourceFile("hist_tasks.zig");
pub const hist_tasks_template_path: [:0]const u8 = builtin.root.build_root ++ "/top/build/gen/hist_tasks-template.zig";
pub const parsers_path: [:0]const u8 = primarySourceFile("parsers.zig");
pub const parsers_tasks_template_path: [:0]const u8 = builtin.root.build_root ++ "/top/build/gen/parsers-template.zig";

pub fn primarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') builtin.root.build_root ++ "/top/build/" ++ name else name;
}
pub fn auxiliarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub fn auxiliaryDataFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub const declare_task_field_types: bool = false;
pub const allow_comptime_configure_parser: bool = false;
