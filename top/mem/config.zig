//! Control various aspects of `memgen`

pub const word_size_type: type = u64;

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
pub const implement_write_inline: bool = false;
pub const implement_count_as_one: bool = false;
/// If enabled functions returning slices accept an additional parameter to
/// define the length of the returned pointer.
pub const user_defined_length: bool = true;
