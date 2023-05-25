const fmt = @import("../../fmt.zig");
pub const Variant = enum(u1) {
    length,
    write,
};
pub const Attributes = struct {
    /// Name of task command data structure
    type_name: []const u8,
    /// Name of command line function
    fn_name: []const u8,
    /// Function call
    params: []const ParamSpec,
};
pub const ProtoTypeDescr = fmt.GenericTypeDescrFormat(.{
    .options = .{
        .default_field_values = true,
        .identifier_name = true,
    },
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
pub const ParamInfo = struct {
    /// Describes how the argument should be written to the command line buffer
    tag: Tag = .boolean_field,
    /// Describes how the field type should be written to the command struct
    type: ProtoTypeDescr = ProtoTypeDescr.init(bool),
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    const Tag = enum(u8) {
        boolean_field = 0,
        symbol_field,
        string_field,
        tag_field,
        integer_field,
        formatter_field,
        mapped_field,
        optional_boolean_field,
        optional_string_field,
        optional_tag_field,
        optional_integer_field,
        optional_formatter_field,
        optional_mapped_field,
        repeatable_string_field,
        repeatable_tag_field,

        string_param,
        formatter_param,
        mapped_param,

        integer_literal,
        string_literal,
    };
    pub const immediate: u8 = 255;
    pub fn isField(param_info: ParamInfo) bool {
        return !param_info.isFnParam() and !param_info.isLiteral();
    }
    pub fn isLiteral(param_info: ParamInfo) bool {
        switch (param_info.tag) {
            .string_literal, .integer_literal => {
                return true;
            },
            else => return false,
        }
    }
    pub fn isFnParam(param_info: ParamInfo) bool {
        switch (param_info.tag) {
            .string_param, .formatter_param, .mapped_param => {
                return true;
            },
            else => return false,
        }
    }
};
pub const ParamSpec = struct {
    /// Command struct field name
    name: []const u8 = &.{},
    /// Command line flag/switch
    string: []const u8 = &.{},
    /// Simple argument type
    info: ParamInfo = .{},
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?InverseParamSpec = null,
    /// Maybe define default value of this field. Should be false or null, but
    /// allow the exception.
    default_value: ?[]const u8 = null,
    /// Description to be inserted above the field as documentation comment
    descr: []const []const u8 = &.{},
};
pub const InverseParamSpec = struct {
    /// Command line flag/switch
    string: []const u8 = &.{},
    /// Simple argument type
    info: ParamInfo = .{},
};
