const fmt = @import("../../fmt.zig");
pub const Variant = enum(u1) {
    length,
    write,
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
pub const ArgInfo = struct {
    /// Describes how the argument should be written to the command line buffer
    tag: Tag = .boolean,
    /// Describes how the field type should be written to the command struct
    type: ProtoTypeDescr = ProtoTypeDescr.init(bool),
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    const Tag = enum(u8) {
        boolean = 0,
        string,
        tag,
        integer,
        formatter,
        mapped,
        optional_boolean,
        optional_string,
        optional_tag,
        optional_integer,
        optional_formatter,
        optional_mapped,
        repeatable_string,
        repeatable_tag,
    };
    pub const immediate: u8 = 255;
    fn optionalTypeDescr(any: anytype) ProtoTypeDescr {
        if (@TypeOf(any) == type) {
            return optional(&ProtoTypeDescr.init(any));
        } else {
            return optional(&.{ .type_name = any });
        }
    }
    pub fn string(comptime T: type) ArgInfo {
        return .{ .tag = .string, .type = ProtoTypeDescr.init(T) };
    }
    pub fn tag(comptime T: type) ArgInfo {
        return .{ .tag = .tag, .type = ProtoTypeDescr.init(T) };
    }
    pub fn integer(comptime T: type) ArgInfo {
        return .{ .tag = .integer, .type = ProtoTypeDescr.init(T) };
    }
    pub fn optional(@"type": *const ProtoTypeDescr) ProtoTypeDescr {
        return .{ .type_refer = .{ .spec = "?", .type = @"type" } };
    }
    pub fn formatter(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .formatter, .type = .{ .type_name = type_name } };
    }
    pub fn mapped(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .mapped, .type = .{ .type_name = type_name } };
    }
    pub fn optional_boolean() ArgInfo {
        return .{ .tag = .optional_boolean, .type = optionalTypeDescr(bool) };
    }
    pub fn optional_string(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_string, .type = optionalTypeDescr(any) };
    }
    pub fn optional_tag(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_tag, .type = optionalTypeDescr(any) };
    }
    pub fn optional_integer(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_integer, .type = optionalTypeDescr(any) };
    }
    pub fn optional_formatter(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_formatter, .type = optionalTypeDescr(any) };
    }
    pub fn optional_mapped(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_mapped, .type = optionalTypeDescr(any) };
    }
    pub fn repeatable_string(comptime any: anytype) ArgInfo {
        return .{ .tag = .repeatable_string, .type = optionalTypeDescr(any) };
    }
    pub fn repeatable_tag(comptime any: anytype) ArgInfo {
        return .{ .tag = .repeatable_tag, .type = optionalTypeDescr(any) };
    }
};
pub const OptionSpec = struct {
    /// Command struct field name
    name: []const u8,
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = .{},
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?InverseOptionSpec = null,
    /// Maybe define default value of this field. Should be false or null, but
    /// allow the exception.
    default_value: ?[]const u8 = null,
    /// Description to be inserted above the field as documentation comment
    descr: ?[]const []const u8 = null,
};
pub const InverseOptionSpec = struct {
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = .{},
};
