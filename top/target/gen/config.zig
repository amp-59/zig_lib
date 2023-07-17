const builtin = @import("../../builtin.zig");

/// Auxiliary products of target implementation generator go here. These are
/// generated source files (src) or serialised data (bin). They exist to speed
/// subsequent steps and will be replaced whenever missing.
pub const primary_dir: [:0]const u8 = builtin.root.build_root ++ "/top/target";
pub const zig_out_dir: [:0]const u8 = primary_dir ++ "/zig-out";
pub const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
pub const zig_out_bin_dir: [:0]const u8 = zig_out_dir ++ "/bin";

pub const arch_names: [2]struct { [:0]const u8, [:0]const u8 } = .{
    .{ "aarch64", primarySourceFile("aarch64.zig") },
    .{ "x86", primarySourceFile("x86.zig") },
};
pub const toplevel_source_path: [:0]const u8 = primary_dir ++ ".zig";

pub fn primarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return primary_dir ++ "/" ++ name;
}
pub fn auxiliarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return zig_out_src_dir ++ "/" ++ name;
}
pub fn auxiliaryDataFile(comptime name: [:0]const u8) [:0]const u8 {
    return zig_out_src_dir ++ "/" ++ name;
}
pub const declare_task_field_types: bool = false;
