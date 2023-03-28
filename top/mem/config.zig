//! Control various aspects of `memgen`
const mem = @import("../mem.zig");
const preset = @import("../preset.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");

pub const word_size_type: type = u64;

pub const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.fast,
});
pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_offset = 0x40000000,
    .divisions = 128,
    .logging = preset.address_space.logging.silent,
    .errors = preset.address_space.errors.noexcept,
});
pub const serial_spec: serial.SerialSpec = .{
    .Allocator = Allocator,
    .logging = preset.serializer.logging.silent,
    .errors = preset.serializer.errors.noexcept,
};

pub const prefer_operator_wrapper: bool = true;
/// If `true` approximate length counts are stored in the least significant
/// bits. This makes finding the length more efficient. The efficiency of
/// finding addresses on the same word is theoretically unchanged.
pub const packed_capacity_low: bool = true;
pub const minimise_indirection: bool = true;
/// Omit declarations within containers which are not strictly necessary.
/// Increases node count while decreasing line count.
pub const minimise_declaration: bool = true;
pub const show_eliminated_options: bool = false;
/// Improved binary size when multiple types of container are used. Slightly
/// worse binary size if only one is used.
pub const implement_write_inline: bool = true;
pub const implement_count_as_one: bool = false;
/// If enabled functions returning slices accept an additional parameter to
/// define the length of the returned pointer.
pub const user_defined_length: bool = true;

pub const debug_argument_substitution_match_fail: bool = false;

/// Auxiliary products of memory implementation generator go here. These are
/// generated source files (src) or serialised data (bin). They exist to speed
/// subsequent steps and will be replaced whenever missing.
pub const zig_out_dir: [:0]const u8 = builtin.buildRoot() ++ "/top/mem/zig-out";
pub const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";
pub const zig_out_bin_dir: [:0]const u8 = zig_out_dir ++ "/bin";

/// Currently all containers are written to this file. Later, each container
/// will be given its own file.
pub const container_path: [:0]const u8 = primarySourceFile("container.zig");

/// Currently all references are written to this file. Later, each specification
/// group will be given its own file.
pub const reference_path: [:0]const u8 = primarySourceFile("reference.zig");
/// Contains the hand-written part of the container end-product.
pub const container_template_path: [:0]const u8 = primarySourceFile("container-template.zig");
/// Contains the hand-written part of the reference end-product.
pub const reference_template_path: [:0]const u8 = primarySourceFile("reference-template.zig");
/// Contains the hand-written part of the allocator end-product.
pub const allocator_template_path: [:0]const u8 = primarySourceFile("allocator-template.zig");

pub const container_kinds_path: [:0]const u8 = auxiliarySourceFile("container_kinds.zig");
pub const reference_kinds_path: [:0]const u8 = auxiliarySourceFile("reference_kinds.zig");
pub const spec_sets_path: [:0]const u8 = auxiliaryDataFile("spec_sets");
pub const tech_sets_path: [:0]const u8 = auxiliaryDataFile("tech_sets");
pub const abstract_specs_path: [:0]const u8 = auxiliaryDataFile("abstract_specs");
pub const params_path: [:0]const u8 = auxiliaryDataFile("params");
pub const options_path: [:0]const u8 = auxiliaryDataFile("options");
pub const impl_detail_path: [:0]const u8 = auxiliaryDataFile("impl_detail");
pub const ctn_detail_path: [:0]const u8 = auxiliaryDataFile("ctn_detail");

pub fn primarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') builtin.buildRoot() ++ "/top/mem/" ++ name else name;
}
pub fn auxiliarySourceFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
pub fn auxiliaryDataFile(comptime name: [:0]const u8) [:0]const u8 {
    return if (name[0] != '/') zig_out_src_dir ++ "/" ++ name else name;
}
