const builtin = @import("../builtin.zig");

/// Auxiliary products of builder implementation generator go here. These are
/// generated source files (src) or serialised data (bin). They exist to speed
/// subsequent steps and will be replaced whenever missing.
pub const zig_out_dir: [:0]const u8 = builtin.buildRoot() ++ "/top/mem/zig-out";
pub const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
pub const zig_out_bin_dir: [:0]const u8 = zig_out_dir ++ "/bin";

pub const build_command_options_path: [:0]const u8 = auxiliaryDataFile("build_command_options");
pub const format_command_options_path: [:0]const u8 = auxiliaryDataFile("format_command_options");

pub const command_line_path: [:0]const u8 = primarySourceFile("command_line3.zig");
pub const command_line_template_path: [:0]const u8 = primarySourceFile("command_line-template.zig");

pub const tasks_path: [:0]const u8 = primarySourceFile("tasks3.zig");
pub const tasks_template_path: [:0]const u8 = primarySourceFile("tasks-template.zig");

pub fn primarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') builtin.buildRoot() ++ "/top/build/" ++ name else name;
}
pub fn auxiliarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub fn auxiliaryDataFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
