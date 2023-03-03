pub fn GenericStructOfBool(comptime Struct: type) type {
    return (struct {
        pub fn countTrue(bit_field: Struct) u64 {
            var ret: u64 = 0;
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                ret +%= @boolToInt(@field(bit_field, field.name));
            }
            return ret;
        }
        pub fn formatWrite(format: Struct, array: anytype) void {
            if (countTrue(format) == 0) {
                array.writeMany(".{}");
            } else {
                array.writeMany(".{");
                inline for (@typeInfo(Struct).Struct.fields) |field| {
                    if (@field(format, field.name)) {
                        array.writeMany("." ++ field.name ++ "=true,");
                    }
                }
                array.undefine(1);
                array.writeOne('}');
            }
        }
        pub fn formatLength(format: Struct) u64 {
            var len: u64 = 3;
            if (countTrue(format) != 0) {
                len -%= 1;
                inline for (@typeInfo(Struct).Struct.fields) |field| {
                    if (@field(format, field.name)) {
                        len +%= 1 +% field.name.len +% 6;
                    }
                }
            }
            return len;
        }
    });
}

pub const Fn = struct {
    fn isPrefix(prefix: []const u8, values: []const u8) bool {
        if (prefix.len > values.len) {
            return false;
        }
        return streql(prefix, values[0..prefix.len]);
    }
    fn isSuffix(suffix: []const u8, values: []const u8) bool {
        if (suffix.len > values.len) {
            return false;
        }
        return streql(suffix, values[values.len - suffix.len ..]);
    }
    fn isWithin(within: []const u8, values: []const u8) bool {
        if (within.len > values.len) {
            return false;
        }
        var idx: u64 = 0;
        while (idx != values.len) : (idx +%= 1) {
            if (values.len -% idx == within.len) {
                return streql(within, values[idx..]);
            }
            if (streql(within, values[idx .. idx + within.len])) {
                return true;
            }
        }
        return false;
    }
    fn streql(arg1: []const u8, arg2: []const u8) bool {
        for (arg1, arg2) |x, y| {
            if (x != y) return false;
        }
        return true;
    }

    fn Array(comptime Allocator: type, comptime Tag: type) type {
        return Allocator.StructuredVector(Tag);
    }
    pub fn Pair(comptime Allocator: type, comptime Tag: type) type {
        return struct {
            Allocator.StructuredVector(Tag),
            Allocator.StructuredVector(Tag),
        };
    }
    pub fn prefixSubTag(comptime Tag: type, allocator: anytype, sub_set: anytype, sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isPrefix(sub_tag_name, @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn suffixSubTag(comptime Tag: type, allocator: anytype, sub_set: anytype, sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isSuffix(sub_tag_name, @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn subTag(comptime Tag: type, allocator: anytype, sub_set: anytype, sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        @setEvalBranchQuota(~@as(u32, 0));
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            @TypeOf(sub_set).init(allocator, sub_set.len()),
            @TypeOf(sub_set).init(allocator, sub_set.len()),
        };
        for (sub_set.readAll()) |tag| {
            if (isWithin(sub_tag_name, @tagName(tag))) {
                ret[1].writeOne(tag);
            } else {
                ret[0].writeOne(tag);
            }
        }
        return ret;
    }
    pub fn prefixSubTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isPrefix(sub_tag_name, field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn suffixSubTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isSuffix(sub_tag_name, field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn subTagNew(comptime Tag: type, allocator: anytype, comptime sub_tag_name: []const u8) Pair(@TypeOf(allocator.*), Tag) {
        var ret: Pair(@TypeOf(allocator.*), Tag) = .{
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
            Array(@TypeOf(allocator.*), Tag).init(allocator, @typeInfo(Tag).Enum.fields.len),
        };
        inline for (@typeInfo(Tag).Enum.fields) |field| {
            if (isWithin(sub_tag_name, field.name)) {
                ret[1].writeOne(@field(Tag, field.name));
            } else {
                ret[0].writeOne(@field(Tag, field.name));
            }
        }
        return ret;
    }
    pub fn writeKind(comptime Tag: type, array: anytype, fn_name: [:0]const u8, set: anytype) void {
        array.writeMany("pub fn ");
        array.writeMany(fn_name);
        array.writeMany("(tag: " ++ @typeName(Tag)["top.mem.".len..] ++ ")bool{\nswitch(tag){");
        for (set.readAll()) |elem| {
            array.writeMany(".");
            array.writeMany(@tagName(elem));
            array.writeMany(",");
        }
        array.writeMany("=>return true,else=>return false}\n}\n");
    }
};

pub const Kinds = packed struct {
    automatic: bool = false,
    dynamic: bool = false,
    static: bool = false,
    parametric: bool = false,
    pub usingnamespace GenericStructOfBool(Kinds);
};
pub const Layouts = packed struct {
    structured: bool = false,
    unstructured: bool = false,
    pub usingnamespace GenericStructOfBool(Layouts);
};
pub const Modes = packed struct {
    read_write: bool = false,
    resize: bool = false,
    stream: bool = false,
    pub usingnamespace GenericStructOfBool(Modes);
};
pub const Fields = packed struct {
    automatic_storage: bool = false,
    allocated_byte_address: bool = false,
    undefined_byte_address: bool = false,
    unallocated_byte_address: bool = false,
    unstreamed_byte_address: bool = false,
    pub usingnamespace GenericStructOfBool(Fields);
};
pub const Managers = packed struct {
    allocatable: bool = false,
    reallocatable: bool = false,
    resizable: bool = false,
    movable: bool = false,
    convertible: bool = false,
    pub usingnamespace GenericStructOfBool(Managers);
};
pub const Techniques = packed struct {
    auto_alignment: bool = false,
    lazy_alignment: bool = false,
    unit_alignment: bool = false,
    disjunct_alignment: bool = false,
    single_packed_approximate_capacity: bool = false,
    double_packed_approximate_capacity: bool = false,
    arena_relative: bool = false,
    address_space_relative: bool = false,
    pub const Options = struct {
        capacity: ?enum {
            single_packed_approximate,
            double_packed_approximate,
        },
        alignment: enum {
            auto,
            unit,
            lazy,
            disjunct,
        },
        relative: enum {
            arena,
            address_space,
        },
    };
    pub usingnamespace GenericStructOfBool(Techniques);
};
comptime {
    const attribute_types: [6]type = .{ Modes, Kinds, Layouts, Fields, Managers, Techniques };
    inline for (attribute_types, 0..) |l_struct_of_bool, index| {
        inline for (@typeInfo(l_struct_of_bool).Struct.fields) |field| {
            inline for (attribute_types[index + 1 ..]) |r_struct_of_bool| {
                if (@hasField(r_struct_of_bool, field.name)) {
                    @compileError(@typeName(l_struct_of_bool) ++ ", " ++
                        @typeName(r_struct_of_bool) ++ " share non-unique attribute name: " ++ field.name);
                }
            }
        }
    }
}
pub const Option = struct {
    kind: Option.Kind,
    info: Info,
    pub const Kind = enum {
        standalone,
        mutually_exclusive_optional,
        mutually_exclusive_mandatory,
    };
    pub const Usage = enum {
        eliminate_boolean_false,
        eliminate_boolean_true,
        test_boolean,
        compare_enumeration,
        compare_optional_enumeration,
    };
    pub const Info = struct {
        field_name: []const u8,
        field_field_names: []const []const u8,
    };
    pub fn len(comptime option: Option) u64 {
        return option.info.field_field_names.len;
    }
    pub fn count(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) u64 {
        var ret: u64 = 0;
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        inline for (option.info.field_field_names) |field_name| {
            ret +%= @boolToInt(@field(techs, field_name));
        }
        return ret;
    }
    pub fn names(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail, buf: [][]const u8) []const []const u8 {
        var techs: Techniques = .{};
        inline for (@typeInfo(Techniques).Struct.fields) |field| {
            for (toplevel_impl_group) |impl_variant| {
                if (@field(impl_variant.techs, field.name)) {
                    @field(techs, field.name) = true;
                }
            }
        }
        var idx: u64 = 0;
        inline for (option.info.field_field_names) |field_name| {
            if (@field(techs, field_name)) {
                buf[idx] = field_name;
                idx +%= 1;
            }
        }
        return buf[0..idx];
    }
    pub fn usage(comptime option: Option, comptime Detail: type, toplevel_impl_group: []const Detail) Usage {
        const value: u64 = option.count(Detail, toplevel_impl_group);
        switch (option.kind) {
            .standalone => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => unreachable,
            },
            .mutually_exclusive_optional => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .test_boolean,
                else => return .compare_optional_enumeration,
            },
            .mutually_exclusive_mandatory => switch (value) {
                0 => return .eliminate_boolean_false,
                1 => return .eliminate_boolean_true,
                else => return .compare_enumeration,
            },
        }
    }
    pub fn fieldName(comptime option: Option, comptime index: u64) []const u8 {
        return option.info.field_field_names[index];
    }
    pub fn tagName(comptime option: Option, comptime index: u64) []const u8 {
        return option.fieldName(index)[0 .. option.fieldName(index).len - (option.info.field_name.len + 1)];
    }
};
