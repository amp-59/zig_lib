//! This stage generates reference impls
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const mach = @import("./../mach.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen.zig");
const sym = @import("./sym.zig");
const config = @import("./config.zig");

pub usingnamespace proc.start;

const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/memgen_options.zig");
    usingnamespace @import("./zig-out/src/memgen_type_spec.zig");
    usingnamespace @import("./zig-out/src/memgen_variants.zig");
    usingnamespace @import("./zig-out/src/memgen_canonical.zig");
    usingnamespace @import("./zig-out/src/memgen_canonicals.zig");
    usingnamespace @import("./zig-out/src/memgen_container_specifications.zig");
};

const Args = mem.StaticArray([:0]const u8, 8);

const comptime_keyword: [:0]const u8 = "comptime ";
const return_keyword: [:0]const u8 = "return ";
const end_expression: [:0]const u8 = ";\n";
const end_item: [:0]const u8 = ",\n";
const end_small_item: [:0]const u8 = ", ";

// zig fmt: off
const key: [18]Fn = .{
    .{ .tag = .allocated_byte_address,      .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_address,        .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_address,     .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .undefined_byte_address,      .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .unwritable_byte_address,     .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unallocated_byte_address,    .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .allocated_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .streamed_byte_count,         .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_count,       .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .writable_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .undefined_byte_count,        .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .defined_byte_count,          .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .alignment,                   .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .define,                      .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .undefine,                    .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .seek,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .tell,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
};
// zig fmt: on

const Fn = packed struct {
    tag: Tag,
    val: Value,
    loc: Location,
    mut: Mutability,
    const Tag = enum(u5) {
        allocated_byte_address,
        aligned_byte_address,
        unstreamed_byte_address,
        undefined_byte_address,
        unwritable_byte_address,
        unallocated_byte_address,
        allocated_byte_count,
        aligned_byte_count,
        streamed_byte_count,
        unstreamed_byte_count,
        writable_byte_count,
        undefined_byte_count,
        defined_byte_count,
        alignment,
        define,
        undefine,
        seek,
        tell,
    };
    const Value = enum(u1) { Address, Offset };
    const Location = enum(u1) { Relative, Absolute };
    const Mutability = enum(u1) { Mutable, Immutable };
    inline fn fnName(impl_fn_info: *const Fn) []const u8 {
        return @tagName(impl_fn_info.tag);
    }
};
const Info = struct {
    start: u64,
    alias: ?*const Fn = null,
    fn setAlias(info: *Info, impl_fn_info: *const Fn) void {
        info.alias = impl_fn_info;
    }
};
inline fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
        unreachable;
    }
}

pub const Operand = union(enum) {
    call2: *const FnCall2,
    call1: *const FnCall1,
    call: *const FnCall,
    deref: *const DereferenceOp,
    constant: usize,
    symbol: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format) {
            .symbol => |symbol| array.writeMany(symbol),
            .constant => |constant| array.writeFormat(fmt.ud64(constant)),
            inline else => |op| op.formatWrite(array),
        }
    }
    fn init(any: anytype) Operand {
        inline for (@typeInfo(Operand).Union.fields) |field| {
            if (field.type == @TypeOf(any)) {
                return @unionInit(Operand, field.name, any);
            }
        }
        @compileError(@typeName(@TypeOf(any)));
    }
};
pub fn formatWriteCall1(op1: Operand, array: anytype, fn_token: [:0]const u8) void {
    array.writeMany(fn_token);
    array.writeOne('(');
    array.writeFormat(op1);
    array.writeOne(')');
}
pub fn formatWriteCall2(op1: Operand, op2: Operand, array: anytype, fn_token: [:0]const u8) void {
    array.writeMany(fn_token);
    array.writeOne('(');
    array.writeFormat(op1);
    array.writeMany(end_small_item);
    array.writeFormat(op2);
    array.writeOne(')');
}
pub inline fn GenericFnCall1Format(comptime Format: type) type {
    return (struct {
        fn exec(array: anytype, op1: anytype) void {
            array.writeFormat(Format{ .op1 = Operand.init(op1) });
        }
        fn make(op1: anytype) Format {
            return .{ .op1 = Operand.init(op1) };
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            return formatWriteCall1(format.op1, array, Format.fn_token);
        }
    });
}
pub inline fn GenericFnCall2Format(comptime Format: type) type {
    return (struct {
        fn exec(array: anytype, op1: anytype, op2: anytype) void {
            array.writeFormat(make(op1, op2));
        }
        fn make(op1: anytype, op2: anytype) Format {
            return .{ .op1 = Operand.init(op1), .op2 = Operand.init(op2) };
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            return formatWriteCall2(format.op1, format.op2, array, Format.fn_token);
        }
    });
}
pub const AssignmentOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(" = ");
        array.writeFormat(format.op2);
    }
};
pub fn assignmentOp(op1: anytype, op2: anytype) AssignmentOp {
    return .{
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub const DereferenceOp = struct {
    op1: Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(".*");
    }
};
pub fn dereferenceOp(op1: anytype) DereferenceOp {
    return .{ .op1 = Operand.init(op1) };
}
pub const FnCall2 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        formatWriteCall2(format.op1, format.op2, array, format.symbol);
    }
};
pub inline fn addEqualOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.add_equ_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn subtractEqualOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.subtract_equ_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn addOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.add_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn alignAboveOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.subtract_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn alignBelowOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.align_below_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn andOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.and_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn andNotOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.and_not_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn conditionalMoveOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.conditional_move_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn multiplyOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.multiply_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn orOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.or_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn shiftLeftOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.shift_left_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn shiftRightOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.shift_right_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn subtractOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.subtract_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn unpackDoubleApproxOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.unpack_double_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn pointerOpaqueOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.pointer_opaque_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub inline fn pointerOneOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = sym.pointer_one_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
pub const FnCall1 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        formatWriteCall1(format.op1, array, format.symbol);
    }
};
pub const FnCall = struct {
    impl_variant: *const out.DetailMore,
    impl_fn_info: *const Fn,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        writeFnSignatureOrCall(array, format.impl_variant, format.impl_fn_info, false);
    }
};
pub fn writeComma(array: *gen.String) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, end_small_item, array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(end_small_item);
    }
}
pub fn writeArgument(array: *gen.String, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
pub fn writeFnCallGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_variant, impl_fn_info, false);
}
pub fn writeFnSignatureGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_variant, impl_fn_info, true);
}

fn writeFnBodyGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, info: *Info) void {
    // Should the reader find inconsistencies in the following logical
    // structures (such as duplicating write operating in an inner scope, when
    // that write would have identical semantics and result in fewer lines of
    // code if moved to an outer scope), the reason is simple: at the time of
    // writing, the chosen method resulted in a smaller binary.
    const allocated_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.allocated_byte_address),
    };
    const aligned_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.aligned_byte_address),
    };
    const unstreamed_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.unstreamed_byte_address),
    };
    const undefined_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.undefined_byte_address),
    };
    const unwritable_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.unwritable_byte_address),
    };
    const unallocated_byte_address: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.unallocated_byte_address),
    };
    const allocated_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.allocated_byte_count),
    };
    const aligned_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.aligned_byte_count),
    };
    const streamed_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.streamed_byte_count),
    };
    _ = streamed_byte_count;
    const unstreamed_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.unstreamed_byte_count),
    };
    _ = unstreamed_byte_count;
    const writable_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.writable_byte_count),
    };
    const undefined_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.undefined_byte_count),
    };
    _ = undefined_byte_count;
    const defined_byte_count: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.defined_byte_count),
    };
    _ = defined_byte_count;
    const alignment: FnCall = .{
        .impl_variant = impl_variant,
        .impl_fn_info = get(.alignment),
    };
    const subtract_op_1: FnCall2 = .{
        .symbol = sym.subtract_fn_name,
        .op1 = .{ .symbol = sym.low_alignment_specifier_name },
        .op2 = .{ .constant = 1 },
    };
    const shift_left_op_65535_48: FnCall2 = .{
        .symbol = sym.shift_left_fn_name,
        .op1 = .{ .constant = 65535 },
        .op2 = .{ .constant = 48 },
    };
    const shift_right_op_lb_16: FnCall2 = .{
        .symbol = sym.shift_right_fn_name,
        .op1 = .{ .symbol = sym.allocated_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const shift_right_op_ub_16: FnCall2 = .{
        .symbol = sym.shift_right_fn_name,
        .op1 = .{ .symbol = sym.undefined_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const or_op_1_65535_48: FnCall2 = .{
        .symbol = sym.or_fn_name,
        .op1 = .{ .call2 = &subtract_op_1 },
        .op2 = .{ .call2 = &shift_left_op_65535_48 },
    };
    const unpck1x_op: FnCall1 = .{
        .symbol = sym.unpack_single_fn_name,
        .op1 = .{ .symbol = sym.allocated_byte_address_word_access },
    };
    const unpck2x_op: FnCall2 = .{
        .symbol = sym.unpack_double_fn_name,
        .op1 = .{ .symbol = sym.allocated_byte_address_word_access },
        .op2 = .{ .symbol = sym.undefined_byte_address_word_access },
    };
    const sentinel_ptr_op: FnCall2 = .{
        .symbol = sym.pointer_opaque_fn_name,
        .op1 = .{ .symbol = sym.child_specifier_name },
        .op2 = .{ .symbol = sym.sentinel_specifier_name },
    };
    const undefined_child_ptr_op: FnCall2 = .{
        .symbol = sym.pointer_one_fn_name,
        .op1 = .{ .symbol = sym.child_specifier_name },
        .op2 = .{ .call = &undefined_byte_address },
    };
    const sentinel_ptr_deref_op: DereferenceOp = .{
        .op1 = .{ .call2 = &sentinel_ptr_op },
    };
    const undefined_child_ptr_deref_op: DereferenceOp = .{
        .op1 = .{ .call2 = &undefined_child_ptr_op },
    };
    const has_static_maximum_length: bool =
        impl_variant.kinds.automatic or
        impl_variant.kinds.static;
    const has_packed_approximate_capacity: bool =
        impl_variant.techs.single_packed_approximate_capacity or
        impl_variant.techs.double_packed_approximate_capacity;
    const has_unit_alignment: bool =
        impl_variant.techs.auto_alignment or
        impl_variant.techs.unit_alignment;

    switch (impl_fn_info.tag) {
        .define => {
            array.writeFormat(addEqualOp(sym.undefined_byte_address_word_ptr, sym.offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(end_expression);
                array.writeFormat(assignmentOp(&undefined_child_ptr_deref_op, &sentinel_ptr_deref_op));
            }
            return array.writeMany(end_expression);
        },
        .undefine => {
            array.writeFormat(subtractEqualOp(sym.undefined_byte_address_word_ptr, sym.offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(end_expression);
                array.writeFormat(assignmentOp(&undefined_child_ptr_deref_op, &sentinel_ptr_deref_op));
            }
            return array.writeMany(end_expression);
        },
        .seek => {
            array.writeFormat(addEqualOp(sym.unstreamed_byte_address_word_ptr, sym.offset_bytes_name));
            return array.writeMany(end_expression);
        },
        .tell => {
            array.writeFormat(subtractEqualOp(sym.unstreamed_byte_address_word_ptr, sym.offset_bytes_name));
            return array.writeMany(end_expression);
        },
        .allocated_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(sym.address_of_impl, sym.offset_of_automatic_storage));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.parametric) {
                array.writeMany(sym.slave_specifier_call_unallocated_byte_address);
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity or
                impl_variant.techs.single_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_op_lb_16);
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(sym.allocated_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(subtractOp(&aligned_byte_address, &alignment));
                return array.writeMany(end_expression);
            }
            array.writeMany(sym.allocated_byte_address_word_access);
            return array.writeMany(end_expression);
        },
        .aligned_byte_address => {
            array.writeMany(return_keyword);
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_address.impl_fn_info);
            }
            if (impl_variant.techs.disjunct_alignment) {
                if (has_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        array.writeFormat(andNotOp(&shift_right_op_lb_16, &subtract_op_1));
                        return array.writeMany(end_expression);
                    }
                    array.writeFormat(andNotOp(sym.allocated_byte_address_word_access, &or_op_1_65535_48));
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(sym.allocated_byte_address_word_access, &subtract_op_1));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(alignAboveOp(sym.slave_specifier_call_unallocated_byte_address, sym.low_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                return info.setAlias(allocated_byte_address.impl_fn_info);
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(alignAboveOp(&allocated_byte_address, sym.low_alignment_specifier_name));
                return array.writeMany(end_expression);
            }
        },
        .unstreamed_byte_address => {
            array.writeMany(return_keyword);
            array.writeMany(sym.unstreamed_byte_address_word_access);
            return array.writeMany(end_expression);
        },
        .undefined_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_op_ub_16);
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(sym.undefined_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(&allocated_byte_address, sym.undefined_byte_address_word_access));
                return array.writeMany(end_expression);
            }
            array.writeMany(sym.undefined_byte_address_word_access);
            return array.writeMany(end_expression);
        },
        .unallocated_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.fields.unallocated_byte_address) {
                array.writeMany(sym.unallocated_byte_address_word_access);
                return array.writeMany(end_expression);
            }
            if (has_static_maximum_length or
                has_packed_approximate_capacity)
            {
                array.writeFormat(addOp(&allocated_byte_address, &allocated_byte_count));
                return array.writeMany(end_expression);
            }
            array.writeMany(sym.slave_specifier_call_unmapped_byte_address);
            return array.writeMany(end_expression);
        },
        .unwritable_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.kinds.parametric) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(&unallocated_byte_address, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                return info.setAlias(unallocated_byte_address.impl_fn_info);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(sym.unallocated_byte_address_word_access, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                array.writeMany(sym.unallocated_byte_address_word_access);
                return array.writeMany(end_expression);
            }
            array.writeFormat(addOp(&aligned_byte_address, &writable_byte_count));
            return array.writeMany(end_expression);
        },
        .allocated_byte_count => {
            array.writeMany(return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count.impl_fn_info);
                } else {
                    array.writeFormat(addOp(&alignment, &aligned_byte_count));
                    return array.writeMany(end_expression);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count.impl_fn_info);
                } else {
                    array.writeFormat(addOp(&alignment, &aligned_byte_count));
                    return array.writeMany(end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(writable_byte_count.impl_fn_info);
            }
            array.writeFormat(subtractOp(&unallocated_byte_address, &allocated_byte_address));
            return array.writeMany(end_expression);
        },
        .aligned_byte_count => {
            array.writeMany(return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                array.writeFormat(unpck1x_op);
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                array.writeFormat(unpck2x_op);
                return array.writeMany(end_expression);
            }
            if (impl_variant.specs.sentinel) {
                array.writeFormat(addOp(&writable_byte_count, sym.high_alignment_specifier_name));
                return array.writeMany(end_expression);
            }
            return info.setAlias(writable_byte_count.impl_fn_info);
        },
        .writable_byte_count => {
            array.writeMany(return_keyword);
            if (impl_variant.kinds.parametric) {
                array.writeFormat(subtractOp(&unwritable_byte_address, &aligned_byte_address));
                return array.writeMany(end_expression);
            }
            if (has_static_maximum_length) {
                array.writeFormat(multiplyOp(sym.count_specifier_name, sym.call_sizeof_child));
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: FnCall2 = alignBelowOp(&unpck2x_op, sym.high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck2x_op, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: FnCall2 = alignBelowOp(&unpck1x_op, sym.high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck1x_op, sym.high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const subtract_op: FnCall2 = subtractOp(&allocated_byte_count, sym.high_alignment_specifier_name);
                if (has_unit_alignment) {
                    array.writeFormat(subtract_op);
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(subtractOp(&subtract_op, &alignment));
                    return array.writeMany(end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_count.impl_fn_info);
            } else {
                array.writeFormat(subtractOp(&allocated_byte_count, &alignment));
                return array.writeMany(end_expression);
            }
        },
        .defined_byte_count => {
            array.writeMany(return_keyword);
            if (has_unit_alignment) {
                array.writeFormat(subtractOp(&undefined_byte_address, &allocated_byte_address));
                return array.writeMany(end_expression);
            } else {
                array.writeFormat(subtractOp(&undefined_byte_address, &aligned_byte_address));
                return array.writeMany(end_expression);
            }
        },
        .undefined_byte_count => {
            array.writeMany(return_keyword);
            array.writeFormat(subtractOp(&unwritable_byte_address, &undefined_byte_address));
            return array.writeMany(end_expression);
        },
        .streamed_byte_count => {
            array.writeMany(return_keyword);
            array.writeFormat(subtractOp(&unstreamed_byte_address, &aligned_byte_address));
            return array.writeMany(end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(return_keyword);
            if (impl_variant.modes.resize) {
                array.writeFormat(subtractOp(&undefined_byte_address, &unstreamed_byte_address));
                return array.writeMany(end_expression);
            } else {
                array.writeFormat(subtractOp(&unwritable_byte_address, &unstreamed_byte_address));
                return array.writeMany(end_expression);
            }
        },
        .alignment => {
            array.writeMany(return_keyword);
            if (impl_variant.techs.disjunct_alignment and
                has_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(andOp(&shift_right_op_lb_16, &subtract_op_1));
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(andOp(sym.allocated_byte_address_word_access, &subtract_op_1));
                    return array.writeMany(end_expression);
                }
            } else {
                array.writeFormat(subtractOp(&aligned_byte_address, &allocated_byte_address));
                return array.writeMany(end_expression);
            }
        },
    }
}
fn writeFn(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    if (hasCapability(impl_variant, impl_fn_info)) {
        var info: Info = .{ .start = array.len() };
        writeFnSignatureGeneric(array, impl_variant, impl_fn_info);
        array.writeMany("{\n");
        writeFnBodyGeneric(array, impl_variant, impl_fn_info, &info);
        array.writeMany("}\n");
        writeSimpleRedecl(array, impl_fn_info, &info);
    }
}
fn writeDecls(array: *gen.String, impl_variant: *const out.DetailMore) void {
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        return array.writeMany("const Static = fn () callconv(.Inline) u64;\n");
    }
    if (impl_variant.kinds.parametric) {
        return array.writeMany("const Slave = fn (" ++ sym.slave_specifier_const_ptr_type_name ++ ") callconv(.Inline) u64;\n");
    }
    if (impl_variant.techs.unit_alignment) {
        return array.writeMany("pub const unit_alignment: usize = spec.unit_alignment;\n");
    }
    if (impl_variant.techs.auto_alignment) {
        return array.writeMany("pub const auto_alignment: usize = spec.low_alignment;\n");
    }
}
fn writeSimpleRedecl(array: *gen.String, impl_fn_info: *const Fn, info: *Info) void {
    if (info.alias) |impl_fn_alias_info| {
        array.undefine(array.len() - info.start);
        array.writeMany("pub const ");
        array.writeMany(@tagName(impl_fn_info.tag));
        array.writeMany(" = ");
        array.writeMany(@tagName(impl_fn_alias_info.tag));
        array.writeMany(";\n");
        info.alias = null;
    }
}
fn writeComptimeFieldInternal(array: *gen.String, fn_tag: Fn.Tag, args: *const Args) void {
    if (args.len() == 0) {
        array.writeMany(comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Static = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(end_item);
    }
    if (args.len() == 1 and
        args.readOneAt(0).ptr == sym.slave_specifier_name.ptr)
    {
        array.writeMany(comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Slave = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(end_item);
    }
}
inline fn writeComptimeField(array: *gen.String, impl_variant: *const out.DetailMore, comptime fn_tag: Fn.Tag) void {
    const args: Args = getArgList(impl_variant, get(fn_tag), false);
    writeComptimeFieldInternal(array, fn_tag, &args);
}
inline fn writeFields(array: *gen.String, impl_variant: *const out.DetailMore) void {
    writeComptimeField(array, impl_variant, .allocated_byte_address);
    writeComptimeField(array, impl_variant, .aligned_byte_address);
    writeComptimeField(array, impl_variant, .unallocated_byte_address);
    if (impl_variant.fields.automatic_storage) {
        if (impl_variant.specs.sentinel) {
            array.writeMany(sym.automatic_storage_with_sentinel_field);
        } else {
            array.writeMany(sym.automatic_storage_field);
        }
        array.writeMany(end_small_item);
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(sym.allocated_byte_address_word_field);
        array.writeMany(end_small_item);
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(sym.unstreamed_byte_address_word_field);
        array.writeMany(end_small_item);
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(sym.undefined_byte_address_word_field);
        array.writeMany(end_small_item);
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(sym.unallocated_byte_address_word_field);
        array.writeMany(end_small_item);
    }
    writeComptimeField(array, impl_variant, .unwritable_byte_address);
    writeComptimeField(array, impl_variant, .allocated_byte_count);
    writeComptimeField(array, impl_variant, .writable_byte_count);
    writeComptimeField(array, impl_variant, .aligned_byte_count);
}
fn getArgList(impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, sign: bool) Args {
    var array: Args = undefined;
    array.undefineAll();
    if (impl_fn_info.mut == .Mutable) {
        array.writeOne(mach.cmovx(
            sign,
            sym.impl_param,
            sym.impl_name,
        ));
        array.writeOne(mach.cmovx(
            sign,
            sym.offset_bytes_param,
            sym.offset_bytes_name,
        ));
    } else //
    if (impl_variant.kinds.parametric) {
        if (impl_fn_info.val == .Address) {
            if (impl_fn_info.loc == .Absolute) {
                array.writeOne(mach.cmovx(
                    sign,
                    sym.slave_specifier_const_ptr_param,
                    sym.slave_specifier_name,
                ));
            } else {
                array.writeOne(mach.cmovx(
                    sign,
                    sym.impl_const_param,
                    sym.impl_name,
                ));
            }
        } else if (impl_fn_info.val == .Offset) {
            if (impl_fn_info.tag == .unstreamed_byte_count and
                impl_variant.fields.undefined_byte_address)
            {
                array.writeOne(mach.cmovx(
                    sign,
                    sym.impl_const_param,
                    sym.impl_name,
                ));
            } else if (impl_fn_info.loc == .Relative) {
                array.writeOne(mach.cmovx(
                    sign,
                    sym.impl_const_param,
                    sym.impl_name,
                ));
                array.writeOne(mach.cmovx(
                    sign,
                    sym.slave_specifier_const_ptr_param,
                    sym.slave_specifier_name,
                ));
            } else {
                array.writeOne(mach.cmovx(
                    sign,
                    sym.slave_specifier_const_ptr_param,
                    sym.slave_specifier_name,
                ));
            }
        }
    } else //
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        const has_unit_alignment: bool =
            impl_variant.techs.auto_alignment or
            impl_variant.techs.unit_alignment;
        const criteria_full: bool =
            impl_fn_info.tag == .writable_byte_count or
            impl_fn_info.tag == .aligned_byte_count or
            impl_fn_info.tag == .allocated_byte_count and has_unit_alignment;
        if (!criteria_full) {
            array.writeOne(mach.cmovx(
                sign,
                sym.impl_const_param,
                sym.impl_name,
            ));
        }
    } else {
        array.writeOne(mach.cmovx(
            sign,
            sym.impl_const_param,
            sym.impl_name,
        ));
    }
    return array;
}
fn writeFnSignatureOrCall(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, sign: bool) void {
    const list: Args = getArgList(impl_variant, impl_fn_info, sign);
    if (sign) array.writeMany("pub inline fn ");
    array.writeMany(impl_fn_info.fnName());
    array.writeMany("(");
    for (list.readAll()) |arg| writeArgument(array, arg);
    if (impl_fn_info.mut == .Mutable) {
        array.writeMany(builtin.cmov([]const u8, sign, ") void ", ")"));
    } else {
        array.writeMany(builtin.cmov([]const u8, sign, ") u64 ", ")"));
    }
}
fn printFunctionsInTagOrder() void {
    var fn_index: usize = 0;
    while (fn_index <= ~@as(meta.Child(Fn.Tag), 0)) : (fn_index +%= 1) {
        const tag: Fn.Tag = @intToEnum(Fn.Tag, fn_index);
        for (key) |fn_info| {
            if (fn_info.tag == tag) {
                testing.printN(4096, .{ fmt.any(fn_info), '\n' });
            }
        }
    }
}
fn hasCapability(impl_variant: *const out.DetailMore, fn_info: *const Fn) bool {
    switch (fn_info.tag) {
        .alignment => return !(impl_variant.kinds.automatic or impl_variant.techs.unit_alignment),
        .define,
        .undefine,
        .undefined_byte_address,
        .defined_byte_count,
        .undefined_byte_count,
        => return impl_variant.modes.resize,
        .seek,
        .tell,
        .unstreamed_byte_address,
        .streamed_byte_count,
        .unstreamed_byte_count,
        => return impl_variant.modes.stream,
        else => return true,
    }
}
fn writeImplementationName(array: *gen.String, impl_detail: *const out.DetailMore) void {
    inline for (@typeInfo(gen.Layouts).Struct.fields) |field| {
        if (@field(impl_detail.layouts, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
    inline for (@typeInfo(gen.Modes).Struct.fields) |field| {
        if (@field(impl_detail.modes, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
    inline for (@typeInfo(gen.Kinds).Struct.fields) |field| {
        if (@field(impl_detail.kinds, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
    inline for (@typeInfo(gen.Techniques).Struct.fields) |field| {
        if (@field(impl_detail.techs, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
    inline for (@typeInfo(out.Specifiers).Struct.fields) |field| {
        if (@field(impl_detail.specs, field.name)) {
            array.writeMany(comptime fmt.toTitlecase(field.name));
        }
    }
}
pub fn generateReferences() void {
    var allocator: gen.Allocator = gen.Allocator.init();
    var array: gen.String = gen.String.init(allocator.allocate(u8, 1024 * 1024));
    var accm_spec_index: u16 = 0;
    var ctn_index: u16 = 0;
    while (ctn_index != out.container_specifications.len) : (ctn_index +%= 1) {
        const ctn_group: []const []const u16 = out.container_specifications[ctn_index];
        var spec_index: u16 = 0;
        while (spec_index != ctn_group.len) : (spec_index +%= 1) {
            defer accm_spec_index +%= 1;
            const spec_group: []const u16 = ctn_group[spec_index];
            var impl_index: u16 = 0;
            while (impl_index != spec_group.len) : (impl_index +%= 1) {
                if (spec_group.len == 0) {
                    continue;
                }
                const impl_variant: *const out.DetailMore = &out.variants[spec_group[impl_index]];
                array.writeMany("fn ");
                writeImplementationName(&array, impl_variant);
                array.writeMany("(comptime " ++ sym.spec_name ++ ": " ++ sym.generic_spec_type_name);
                gen.writeIndex(&array, accm_spec_index);
                array.writeMany(") type {\nreturn (struct {\n");
                writeFields(&array, impl_variant);
                array.writeMany("const " ++ sym.impl_type_name ++ " = @This();\n");
                writeDecls(&array, impl_variant);
                for (key) |impl_fn_info| writeFn(&array, impl_variant, &impl_fn_info);
                array.writeMany("});\n}\n");
            }
        }
    }
    gen.appendSourceFile(&array, "reference.zig");
}
pub const main = generateReferences;
