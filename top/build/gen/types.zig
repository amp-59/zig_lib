const fmt = @import("../../fmt.zig");
const mem = @import("../../mem.zig");
const config = @import("config.zig");
pub const Array = mem.array.StaticString(64 * 1024 * 1024);
pub const Array2 = mem.array.StaticString(64 * 1024);
pub const Array256 = mem.array.StaticString(256);
pub const Extra = struct {
    function: Function = .write,
    language: Language = .Zig,
    notation: Notation = .slice,
    ptr_name: []const u8 = "cmd",
    len: Length = .{},
    flags: Flags = .{},
    comptime memcpy: Memcpy = .fmt,
    pub const Language = enum { C, Zig };
    pub const Memcpy = enum { builtin, fmt };
    pub const Function = enum {
        length,
        write,
        /// Legacy
        formatWrite,
    };
    pub const Notation = enum {
        slice,
        ptrcast,
        memcpy,
    };
    pub const Length = struct {
        strings: Array2 = .{},
        val: usize = 0,
        decl: bool = false,
    };
    pub const Flags = struct {
        want_fn_intro: bool = true,
        want_fn_body: bool = true,
        want_fn_exit: bool = true,
    };
};
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
pub const SpecialDefn = struct {
    store: ?*const fn (*Array, ParamSpec, *Extra) void = null,
    parse: ?*const fn (*Array, ParamSpec, *Extra) void = null,
    write: ?*const fn (*Array, ParamSpec, *Extra) void = null,
};
pub const boolean: BGTypeDescr = BGTypeDescr.init(bool);
const Tag = union(enum) {
    field: union(enum) {
        string,
        tag,
        boolean,
        integer,
        formatter,
        mapped,
        repeatable_task: *const Attributes,
    },
    optional_field: union(enum) {
        string,
        tag,
        boolean,
        integer,
        formatter,
        mapped,
        repeatable_string,
        repeatable_tag,
        repeatable_formatter,
        repeatable_task: *const Attributes,
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
    /// Bespoke writer functions for either writing, parsing, or struct definition.
    special: SpecialDefn = .{},
    /// Specifies whether option arguments are separated with '\x00' or '='
    /// If `null` the separator is determined by context
    /// If `immediate` (255) no separator is written
    char: ?u8 = null,
    /// Miscellaneous controls
    flags: packed struct {
        /// Include in task struct definitions or writer functions
        do_write: bool = true,
        /// Include in parser functions
        do_parse: bool = true,
    } = .{},
    default: ?[]const u8 = null,
    pub const immediate: u8 = 255;
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
