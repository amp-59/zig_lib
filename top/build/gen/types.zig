const fmt = @import("../../fmt.zig");
const mem = @import("../../mem.zig");
const config = @import("config.zig");
pub const Context = enum { Lib, Exe };
pub const Attributes = struct {
    /// Name of task command data structure
    type_name: []const u8,
    /// Name of command line function
    fn_name: []const u8,
    /// Function call
    params: []const ParamSpec,
    /// Extra function namespace
    type_fn_name: ?[]const u8 = null,
    /// Use these instead of new equivalent types.
    type_decls: []const BGTypeDescr = &.{},
};
pub const BGTypeDescr = fmt.GenericTypeDescrFormat(.{
    .default_field_values = .fast,
    .option_5 = true,
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
pub const BGTypeDescrMap = struct {
    store: *const BGTypeDescr = &boolean,
    write: ?*const BGTypeDescr = null,
    parse: ?*const BGTypeDescr = null,
};
pub const boolean: BGTypeDescr = BGTypeDescr.init(bool);
const Tag = union(enum) {
    field: enum {
        string,
        tag,
        boolean,
        integer,
        formatter,
        mapped,
    },
    optional_field: enum {
        string,
        tag,
        boolean,
        integer,
        formatter,
        mapped,
        repeatable_string,
        repeatable_tag,
        repeatable_formatter,
    },
    param: enum {
        string,
        formatter,
        repeatable_formatter,
    },
    literal: enum {
        string,
        integer,
    },
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
    tag: Tag = .{ .field = .boolean },
    /// Describes how the field type should be written to the command struct,
    /// can be `*const BGTypeDescr` or `*const [2]BGTypeDescr` depending
    /// on the kind of parameter.
    type: BGTypeDescrMap = .{},
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    /// Miscellaneous controls
    flags: packed struct {
        /// Do not include in task struct definitions or writer functions
        do_write: bool = true,
        /// Do not include in parser functions
        do_parse: bool = true,
    } = .{},
    pub const immediate: u8 = 255;
    pub fn isField(param_spec: ParamSpec) bool {
        return param_spec.tag == .field;
    }
    pub fn isLiteral(param_spec: ParamSpec) bool {
        return param_spec.tag == .literal;
    }
    pub fn isFnParam(param_spec: ParamSpec) bool {
        return param_spec.tag == .param;
    }
};
pub const InverseParamSpec = struct {
    /// Command line flag/switch
    string: []const u8 = &.{},
    /// Describes how the argument should be written to the command line buffer
    tag: Tag = .{ .field = .boolean },
    /// Describes how the field type should be written to the command struct
    type: BGTypeDescrMap = .{},
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
};
