const fmt = @import("../../fmt.zig");
pub const Variant = enum(u2) {
    length,
    write_buf,
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
pub const ProtoTypeDescrMap = [2]ProtoTypeDescr;
pub const boolean: ProtoTypeDescr = ProtoTypeDescr.init(bool);

const Tag = enum {
    boolean_field,
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
pub const ParamSpec = struct {
    /// Command struct field name
    name: []const u8 = &.{},
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?InverseParamSpec = null,
    /// Command line flag/switch for non-mapped parameters.
    string: []const u8 = &.{},
    /// Description to be inserted above the field as documentation comment
    descr: []const []const u8 = &.{},
    /// Describes how the argument should be written to the command line buffer
    tag: Tag = .boolean_field,
    /// Describes how the field type should be written to the command struct,
    /// can be `*const ProtoTypeDescr` or `*const [2]ProtoTypeDescr` depending
    /// on the kind of parameter.
    type: *align(8) const anyopaque = &boolean,
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    pub const immediate: u8 = 255;
    pub fn isField(param_spec: ParamSpec) bool {
        return !param_spec.isFnParam() and !param_spec.isLiteral();
    }
    pub fn isLiteral(param_spec: ParamSpec) bool {
        switch (param_spec.tag) {
            .string_literal, .integer_literal => {
                return true;
            },
            else => return false,
        }
    }
    pub fn isFnParam(param_info: ParamSpec) bool {
        switch (param_info.tag) {
            .string_param, .formatter_param, .mapped_param => {
                return true;
            },
            else => return false,
        }
    }
    pub fn parameter(param_spec: @This()) ProtoTypeDescr {
        return @ptrCast(*const ProtoTypeDescr, param_spec.type).*;
    }
    pub fn formatter(param_spec: @This()) ProtoTypeDescr {
        return @ptrCast(*const ProtoTypeDescrMap, param_spec.type)[1];
    }
};
pub const InverseParamSpec = struct {
    /// Command line flag/switch
    string: []const u8 = &.{},
    /// Describes how the argument should be written to the command line buffer
    tag: Tag = .boolean_field,
    /// Describes how the field type should be written to the command struct
    type: *align(8) const anyopaque = &boolean,
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    pub fn parameter(param_spec: @This()) ProtoTypeDescr {
        return @ptrCast(*const ProtoTypeDescr, param_spec.type).*;
    }
    pub fn formatter(param_spec: @This()) ProtoTypeDescr {
        return @ptrCast(*const [2]ProtoTypeDescrMap, param_spec.type)[1];
    }
};
