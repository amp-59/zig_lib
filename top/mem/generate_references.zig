//! This stage generates reference impls
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const mach = @import("./../mach.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");
const config = @import("./config.zig");
const gen = @import("./gen.zig");

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/memgen_options.zig");
    usingnamespace @import("./zig-out/src/memgen_type_spec.zig");
    usingnamespace @import("./zig-out/src/memgen_variants.zig");
    usingnamespace @import("./zig-out/src/memgen_canonical.zig");
    usingnamespace @import("./zig-out/src/memgen_canonicals.zig");
    usingnamespace @import("./zig-out/src/memgen_specifications.zig");
};

const Args = mem.StaticArray([:0]const u8, 8);

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
const word_type_name: [:0]const u8 = "u64";
const impl_name: [:0]const u8 = "impl";
const impl_type_name: [:0]const u8 = "Implementation";
const impl_ptr_type_name: [:0]const u8 = pointerTo(impl_type_name);
const impl_const_ptr_type_name: [:0]const u8 = constPointerTo(impl_type_name);
const impl_param: [:0]const u8 = paramDecl(impl_name, impl_ptr_type_name);
const impl_const_param: [:0]const u8 = paramDecl(impl_name, impl_const_ptr_type_name);
const spec_name: [:0]const u8 = "spec";
const generic_spec_type_name: [:0]const u8 = "Specification";
const sentinel_specifier_name: [:0]const u8 = fieldAccess(spec_name, "sentinel");
const arena_specifier_name: [:0]const u8 = fieldAccess(spec_name, "arena");
const count_specifier_name: [:0]const u8 = fieldAccess(spec_name, "count");
const low_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, "low_alignment");
const high_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, "high_alignment");
const child_specifier_name: [:0]const u8 = fieldAccess(spec_name, "child");
const slave_specifier_name: [:0]const u8 = "allocator";
const slave_specifier_type_name: [:0]const u8 = fieldAccess(spec_name, "Allocator");
const slave_specifier_ptr_type_name: [:0]const u8 = pointerTo(slave_specifier_type_name);
const slave_specifier_const_ptr_type_name: [:0]const u8 = constPointerTo(slave_specifier_type_name);
const slave_specifier_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_type_name);
const slave_specifier_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_ptr_type_name);
const slave_specifier_const_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_const_ptr_type_name);
const slave_specifier_call_unallocated_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unallocated_byte_address"));
const slave_specifier_call_unmapped_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unmapped_byte_address"));
const slave_specifier_call_unaddressable_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unaddressable_byte_address"));
const offset_bytes_name: [:0]const u8 = "x_bytes";
const offset_bytes_param: [:0]const u8 = paramDecl(offset_bytes_name, word_type_name);
const automatic_storage_type_name: [:0]const u8 = arrayType(child_specifier_name, count_specifier_name, null);
const automatic_storage_with_sentinel_type_name: [:0]const u8 = arrayType(child_specifier_name, count_specifier_name, sentinel_specifier_name);
const automatic_storage_field_name: [:0]const u8 = "auto";
const automatic_storage_access: [:0]const u8 = fieldAccess(impl_name, automatic_storage_field_name);
const automatic_storage_ptr: [:0]const u8 = impl_name ++ addressOf(automatic_storage_access);
const automatic_storage_field: [:0]const u8 = paramDecl(automatic_storage_field_name, automatic_storage_type_name);
const automatic_storage_with_sentinel_field: [:0]const u8 = paramDecl(automatic_storage_field_name, automatic_storage_with_sentinel_type_name);
const allocated_byte_address_word_field_name: [:0]const u8 = "lb_word";
const allocated_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, allocated_byte_address_word_field_name);
const allocated_byte_address_word_ptr: [:0]const u8 = addressOf(allocated_byte_address_word_access);
const allocated_byte_address_word_field: [:0]const u8 = paramDecl(allocated_byte_address_word_field_name, word_type_name);
const unstreamed_byte_address_word_field_name: [:0]const u8 = "ss_word";
const unstreamed_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, unstreamed_byte_address_word_field_name);
const unstreamed_byte_address_word_ptr: [:0]const u8 = addressOf(unstreamed_byte_address_word_access);
const unstreamed_byte_address_word_field: [:0]const u8 = paramDecl(unstreamed_byte_address_word_field_name, word_type_name);
const undefined_byte_address_word_field_name: [:0]const u8 = "ub_word";
const undefined_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, undefined_byte_address_word_field_name);
const undefined_byte_address_word_ptr: [:0]const u8 = addressOf(undefined_byte_address_word_access);
const undefined_byte_address_word_field: [:0]const u8 = paramDecl(undefined_byte_address_word_field_name, word_type_name);
const unallocated_byte_address_word_field_name: [:0]const u8 = "up_word";
const unallocated_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, unallocated_byte_address_word_field_name);
const unallocated_byte_address_word_ptr: [:0]const u8 = addressOf(unallocated_byte_address_word_access);
const unallocated_byte_address_word_field: [:0]const u8 = paramDecl(unallocated_byte_address_word_field_name, word_type_name);
const return_keyword: [:0]const u8 = "return ";
const end_expression: [:0]const u8 = ";\n";
const end_item: [:0]const u8 = ",\n";
const address_of_impl: [:0]const u8 = callPtrToInt(impl_name);
const offset_of_automatic_storage: [:0]const u8 = callOffsetOf(impl_type_name, automatic_storage_field_name);
fn arrayType(
    comptime type_name: [:0]const u8,
    comptime count_symbol: [:0]const u8,
    comptime sentinel_symbol_opt: ?[:0]const u8,
) [:0]const u8 {
    if (sentinel_symbol_opt) |sentinel_symbol| {
        return "[" ++ count_symbol ++ ":" ++ sentinel_symbol ++ "]" ++ type_name;
    } else {
        return "[" ++ count_symbol ++ "]" ++ type_name;
    }
}
fn fieldAccess(comptime symbol: [:0]const u8, field_name: [:0]const u8) [:0]const u8 {
    return symbol ++ "." ++ field_name;
}
fn callSimple(comptime symbol: [:0]const u8) [:0]const u8 {
    return symbol ++ "()";
}
fn addressOf(comptime symbol: [:0]const u8) [:0]const u8 {
    return "&" ++ symbol;
}
fn pointerTo(comptime type_name: [:0]const u8) [:0]const u8 {
    return "*" ++ type_name;
}
fn constPointerTo(comptime type_name: [:0]const u8) [:0]const u8 {
    return "*const " ++ type_name;
}
fn paramDecl(comptime symbol: [:0]const u8, type_name: [:0]const u8) [:0]const u8 {
    return symbol ++ ": " ++ type_name;
}
fn callOffsetOf(comptime type_name: [:0]const u8, comptime field_name: [:0]const u8) [:0]const u8 {
    return "@offsetOf(" ++ type_name ++ ", \"" ++ field_name ++ "\")";
}
fn callPtrToInt(comptime symbol_ptr: [:0]const u8) [:0]const u8 {
    return "@ptrToInt(" ++ symbol_ptr ++ ")";
}
fn callSizeOf(comptime type_name: [:0]const u8) [:0]const u8 {
    return "@sizeOf(" ++ type_name ++ ")";
}
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
inline fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
        unreachable;
    }
}
const Operand = union(enum) {
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
    array.writeCount(2, ", ".*);
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
const AssignmentOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(" = ");
        array.writeFormat(format.op2);
    }
};
fn assignmentOp(op1: anytype, op2: anytype) AssignmentOp {
    return .{
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
const DereferenceOp = struct {
    op1: Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(".*");
    }
};
fn dereferenceOp(op1: anytype) DereferenceOp {
    return .{ .op1 = Operand.init(op1) };
}
const FnCall2 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,

    const Format = @This();
    const add_equ_fn_name: [:0]const u8 = "mach.addEqu64";
    const subtract_equ_fn_name: [:0]const u8 = "mach.subEqu64";
    const add_fn_name: [:0]const u8 = "mach.add64";
    const subtract_fn_name: [:0]const u8 = "mach.sub64";
    const align_above_fn_name: [:0]const u8 = "mach.alignA64";
    const align_below_fn_name: [:0]const u8 = "mach.alignB64";
    const and_fn_name: [:0]const u8 = "mach.and64";
    const and_not_fn_name: [:0]const u8 = "mach.andn64";
    const conditional_move_fn_name: [:0]const u8 = "mach.cmov64";
    const multiply_fn_name: [:0]const u8 = "mach.mul64";
    const or_fn_name: [:0]const u8 = "mach.or64";
    const shift_left_fn_name: [:0]const u8 = "mach.shl64";
    const shift_right_fn_name: [:0]const u8 = "mach.shr64";
    const unpack_double_fn_name: [:0]const u8 = if (config.packed_capacity_low)
        "algo.unpackDoubleApproxS"
    else
        "algo.unpackDoubleApproxH";
    const pointer_opaque_fn_name: [:0]const u8 = "pointerOpaque";
    const pointer_one_fn_name: [:0]const u8 = "pointerOne";
    pub fn formatWrite(format: Format, array: anytype) void {
        formatWriteCall2(format.op1, format.op2, array, format.symbol);
    }
};
inline fn addEqualOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.add_equ_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn subtractEqualOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.subtract_equ_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn addOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.add_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn alignAboveOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.subtract_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn alignBelowOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.align_below_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn andOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.and_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn andNotOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.and_not_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn conditionalMoveOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.conditional_move_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn multiplyOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.multiply_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn orOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.or_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn shiftLeftOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.shift_left_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn shiftRightOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.shift_right_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn subtractOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.subtract_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn unpackDoubleApproxOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.unpack_double_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn pointerOpaqueOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.pointer_opaque_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
inline fn pointerOneOp(op1: anytype, op2: anytype) FnCall2 {
    return .{
        .symbol = FnCall2.pointer_one_fn_name,
        .op1 = Operand.init(op1),
        .op2 = Operand.init(op2),
    };
}
const FnCall1 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    const Format = @This();
    const unpack_single_fn_name: [:0]const u8 = if (config.packed_capacity_low)
        "algo.unpackSingleApproxB"
    else
        "algo.unpackSingleApproxA";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        formatWriteCall1(format.op1, array, format.symbol);
    }
};
const FnCall = struct {
    impl_variant: *const out.DetailMore,
    impl_fn_info: *const Fn,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        writeFnSignatureOrCall(array, format.impl_variant, format.impl_fn_info, false);
    }
};
fn writeComma(array: *gen.String) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, ", ", array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(", ");
    }
}
fn writeArgument(array: *gen.String, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
fn writeFnCallGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_variant, impl_fn_info, false);
}
fn writeFnSignatureGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_variant, impl_fn_info, true);
}
const Info = struct {
    start: u64,
    alias: ?*const Fn = null,
    fn setAlias(info: *Info, impl_fn_info: *const Fn) void {
        info.alias = impl_fn_info;
    }
};
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
        .symbol = FnCall2.subtract_fn_name,
        .op1 = .{ .symbol = low_alignment_specifier_name },
        .op2 = .{ .constant = 1 },
    };
    const shift_left_op_65535_48: FnCall2 = .{
        .symbol = FnCall2.shift_left_fn_name,
        .op1 = .{ .constant = 65535 },
        .op2 = .{ .constant = 48 },
    };
    const shift_right_op_lb_16: FnCall2 = .{
        .symbol = FnCall2.shift_right_fn_name,
        .op1 = .{ .symbol = allocated_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const shift_right_op_ub_16: FnCall2 = .{
        .symbol = FnCall2.shift_right_fn_name,
        .op1 = .{ .symbol = undefined_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const or_op_1_65535_48: FnCall2 = .{
        .symbol = FnCall2.or_fn_name,
        .op1 = .{ .call2 = &subtract_op_1 },
        .op2 = .{ .call2 = &shift_left_op_65535_48 },
    };
    const unpck1x_op: FnCall1 = .{
        .symbol = FnCall1.unpack_single_fn_name,
        .op1 = .{ .symbol = allocated_byte_address_word_access },
    };
    const unpck2x_op: FnCall2 = .{
        .symbol = FnCall2.unpack_double_fn_name,
        .op1 = .{ .symbol = allocated_byte_address_word_access },
        .op2 = .{ .symbol = undefined_byte_address_word_access },
    };
    const sentinel_ptr_op: FnCall2 = .{
        .symbol = FnCall2.pointer_opaque_fn_name,
        .op1 = .{ .symbol = child_specifier_name },
        .op2 = .{ .symbol = sentinel_specifier_name },
    };
    const undefined_child_ptr_op: FnCall2 = .{
        .symbol = FnCall2.pointer_one_fn_name,
        .op1 = .{ .symbol = child_specifier_name },
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
            array.writeFormat(addEqualOp(undefined_byte_address_word_ptr, offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(end_expression);
                array.writeFormat(assignmentOp(&undefined_child_ptr_deref_op, &sentinel_ptr_deref_op));
            }
            return array.writeMany(end_expression);
        },
        .undefine => {
            array.writeFormat(subtractEqualOp(undefined_byte_address_word_ptr, offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(end_expression);
                array.writeFormat(assignmentOp(&undefined_child_ptr_deref_op, &sentinel_ptr_deref_op));
            }
            return array.writeMany(end_expression);
        },
        .seek => {
            array.writeFormat(addEqualOp(unstreamed_byte_address_word_ptr, offset_bytes_name));
            return array.writeMany(end_expression);
        },
        .tell => {
            array.writeFormat(subtractEqualOp(unstreamed_byte_address_word_ptr, offset_bytes_name));
            return array.writeMany(end_expression);
        },
        .allocated_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(address_of_impl, offset_of_automatic_storage));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.parametric) {
                array.writeMany(slave_specifier_call_unallocated_byte_address);
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity or
                impl_variant.techs.single_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_op_lb_16);
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(allocated_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(subtractOp(&aligned_byte_address, &alignment));
                return array.writeMany(end_expression);
            }
            array.writeMany(allocated_byte_address_word_access);
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
                    array.writeFormat(andNotOp(allocated_byte_address_word_access, &or_op_1_65535_48));
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(allocated_byte_address_word_access, &subtract_op_1));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(alignAboveOp(slave_specifier_call_unallocated_byte_address, low_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                return info.setAlias(allocated_byte_address.impl_fn_info);
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(alignAboveOp(&allocated_byte_address, low_alignment_specifier_name));
                return array.writeMany(end_expression);
            }
        },
        .unstreamed_byte_address => {
            array.writeMany(return_keyword);
            array.writeMany(unstreamed_byte_address_word_access);
            return array.writeMany(end_expression);
        },
        .undefined_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_op_ub_16);
                    return array.writeMany(end_expression);
                }
                array.writeFormat(andNotOp(undefined_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(&allocated_byte_address, undefined_byte_address_word_access));
                return array.writeMany(end_expression);
            }
            array.writeMany(undefined_byte_address_word_access);
            return array.writeMany(end_expression);
        },
        .unallocated_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.fields.unallocated_byte_address) {
                array.writeMany(unallocated_byte_address_word_access);
                return array.writeMany(end_expression);
            }
            if (has_static_maximum_length or
                has_packed_approximate_capacity)
            {
                array.writeFormat(addOp(&allocated_byte_address, &allocated_byte_count));
                return array.writeMany(end_expression);
            }
            array.writeMany(slave_specifier_call_unmapped_byte_address);
            return array.writeMany(end_expression);
        },
        .unwritable_byte_address => {
            array.writeMany(return_keyword);
            if (impl_variant.kinds.parametric) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(&unallocated_byte_address, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                return info.setAlias(unallocated_byte_address.impl_fn_info);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(unallocated_byte_address_word_access, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
                array.writeMany(unallocated_byte_address_word_access);
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
                array.writeFormat(addOp(&writable_byte_count, high_alignment_specifier_name));
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
                array.writeFormat(multiplyOp(count_specifier_name, callSizeOf(child_specifier_name)));
                return array.writeMany(end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: FnCall2 = alignBelowOp(&unpck2x_op, high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck2x_op, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: FnCall2 = alignBelowOp(&unpck1x_op, high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck1x_op, high_alignment_specifier_name));
                    return array.writeMany(end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const subtract_op: FnCall2 = subtractOp(&allocated_byte_count, high_alignment_specifier_name);
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
                    array.writeFormat(andOp(allocated_byte_address_word_access, &subtract_op_1));
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
        return array.writeMany("const Slave = fn (" ++ slave_specifier_const_ptr_type_name ++ ") callconv(.Inline) u64;\n");
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
        array.writeMany("comptime ");
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Static = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(",\n");
    }
    if (args.len() == 1 and
        args.readOneAt(0).ptr == slave_specifier_name.ptr)
    {
        array.writeMany("comptime ");
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Slave = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(",\n");
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
            array.writeMany(automatic_storage_with_sentinel_field);
        } else {
            array.writeMany(automatic_storage_field);
        }
        array.writeMany(", ");
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(allocated_byte_address_word_field);
        array.writeMany(", ");
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(unstreamed_byte_address_word_field);
        array.writeMany(", ");
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(undefined_byte_address_word_field);
        array.writeMany(", ");
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(unallocated_byte_address_word_field);
        array.writeMany(", ");
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
        array.writeOne(mach.cmovx(sign, impl_param, impl_name));
        array.writeOne(mach.cmovx(sign, offset_bytes_param, offset_bytes_name));
    } else if (impl_variant.kinds.parametric) {
        if (impl_fn_info.val == .Address) {
            if (impl_fn_info.loc == .Absolute) {
                array.writeOne(mach.cmovx(sign, slave_specifier_const_ptr_param, slave_specifier_name));
            } else {
                array.writeOne(mach.cmovx(sign, impl_const_param, impl_name));
            }
        } else if (impl_fn_info.val == .Offset) {
            if (impl_fn_info.tag == .unstreamed_byte_count and
                impl_variant.fields.undefined_byte_address)
            {
                array.writeOne(mach.cmovx(sign, impl_const_param, impl_name));
            } else if (impl_fn_info.loc == .Relative) {
                array.writeOne(mach.cmovx(sign, impl_const_param, impl_name));
                array.writeOne(mach.cmovx(sign, slave_specifier_const_ptr_param, slave_specifier_name));
            } else {
                array.writeOne(mach.cmovx(sign, slave_specifier_const_ptr_param, slave_specifier_name));
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
            array.writeOne(mach.cmovx(sign, impl_const_param, impl_name));
        }
    } else {
        array.writeOne(mach.cmovx(sign, impl_const_param, impl_name));
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
fn writeFile(array: *gen.String) void {
    const fd: u64 = gen.create(builtin.build_root.? ++ "/top/mem/reference.zig");
    defer gen.close(fd);
    gen.write(fd, array.readAll());
}
fn hasCapability(impl_variant: *const out.DetailMore, fn_info: *const Fn) bool {
    return switch (fn_info.tag) {
        .define,
        .undefine,
        .undefined_byte_address,
        .defined_byte_count,
        .undefined_byte_count,
        => impl_variant.modes.resize,
        .seek,
        .tell,
        .unstreamed_byte_address,
        .streamed_byte_count,
        .unstreamed_byte_count,
        => impl_variant.modes.stream,
        .alignment => !impl_variant.kinds.automatic and
            !impl_variant.techs.unit_alignment,
        else => true,
    };
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
fn writeReturnImplementation(array: *gen.String, impl_detail: *const out.DetailMore) void {
    const endl: bool = mem.testEqualManyBack(u8, " => ", array.readAll());
    array.writeMany(return_keyword);
    writeImplementationName(array, impl_detail);
    array.writeMany("(spec)");
    if (endl) {
        array.writeMany(end_item);
    } else {
        array.writeMany(end_expression);
    }
}

const Filtered = struct {
    []const *const out.DetailMore,
    []const *const out.DetailMore,
};
fn filterTechnique(
    impl_groups: []const *const out.DetailMore,
    buf: []*const out.DetailMore,
    comptime field_name: []const u8,
) Filtered {
    if (!@hasField(gen.Techniques, field_name)) {
        builtin.debug.logFault(field_name);
    }
    var t_len: u64 = 0;
    var f_idx: u64 = buf.len;
    for (impl_groups) |impl_variant| {
        if (@field(impl_variant.techs, field_name)) {
            buf[t_len] = impl_variant;
            t_len +%= 1;
        } else {
            f_idx -%= 1;
            buf[f_idx] = impl_variant;
        }
    }
    const f: []*const out.DetailMore = buf[f_idx..];
    f_idx = 0;
    while (f_idx != f.len) : (f_idx +%= 1) {
        const a: *const out.DetailMore = f[f_idx];
        f[f_idx] = f[f.len -% (1 +% f_idx)];
        f[f.len -% (1 +% f_idx)] = a;
    }
    return .{ f, buf[0..t_len] };
}

// TODO: constant maximum largest impl group
// TODO: constant field names

fn writeDeductionTestBoolean(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
    comptime field_names: []const []const u8,
) void {
    if (field_names.len == 0) {
        if (impl_group.len == 1) {
            return writeReturnImplementation(array, impl_group[0]);
        } else {
            return writeDeduction(allocator, array, toplevel_impl_group, impl_group, options[1..]);
        }
    }
    var buf: []*const out.DetailMore = allocator.allocate(*const out.DetailMore, impl_group.len);
    const filtered: Filtered = filterTechnique(impl_group, buf, field_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (options." ++ field_names[0] ++ ") {\n");
        if (filtered[1].len == 1) {
            return writeReturnImplementation(array, filtered[1][0]);
        } else {
            writeDeduction(allocator, array, toplevel_impl_group, filtered[1], options[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) array.writeMany("} else {\n");
        if (filtered[0].len == 1) {
            return writeReturnImplementation(array, filtered[0][0]);
        } else {
            writeDeductionTestBoolean(allocator, array, toplevel_impl_group, filtered[0], options, field_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeDeductionCompareEnumerationInternal(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
    comptime field_index: usize,
) ?[]const *const out.DetailMore {
    if (field_index == options[0].info.field_field_names.len and options.len != 1) {
        return impl_group;
    }
    if (field_index == options[0].info.field_field_names.len and options.len == 1) {
        for (impl_group) |impl_detail| {
            writeReturnImplementation(array, impl_detail);
        }
        return null;
    }
    var buf: []*const out.DetailMore = allocator.allocate(*const out.DetailMore, impl_group.len);
    const filtered: Filtered = filterTechnique(impl_group, buf, options[0].info.field_field_names[field_index]);
    if (filtered[1].len != 0) {
        array.writeMany("." ++ comptime options[0].tagName(field_index) ++ " => ");
        if (filtered[1].len == 1) {
            writeReturnImplementation(array, filtered[1][0]);
        } else {
            array.writeMany("{\n");
            writeDeduction(allocator, array, toplevel_impl_group, filtered[1], options[1..]);
            array.writeMany("},\n");
        }
    }
    if (filtered[0].len != 0) {
        return writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, filtered[0], options, field_index + 1);
    }
    return null;
}
fn writeDeductionCompareEnumeration(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("switch (options." ++ options[0].info.field_name ++ ") {\n");
    const rem: ?[]const *const out.DetailMore =
        writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n");
    writeDeduction(allocator, array, toplevel_impl_group, rem orelse return, options[1..]);
}
fn writeDeductionCompareOptionalEnumeration(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    const save: gen.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    array.writeMany("if (options." ++ options[0].info.field_name ++ ") |" ++
        options[0].info.field_name ++ "| {\nswitch (" ++
        options[0].info.field_name ++ ") {\n");
    const rem: ?[]const *const out.DetailMore =
        writeDeductionCompareEnumerationInternal(allocator, array, toplevel_impl_group, impl_group, options, 0);
    array.writeMany("}\n}\n");
    writeDeduction(allocator, array, toplevel_impl_group, rem orelse return, options[1..]);
}
fn writeDeduction(
    allocator: *gen.Allocator,
    array: *gen.String,
    toplevel_impl_group: []const *const out.DetailMore,
    impl_group: []const *const out.DetailMore,
    comptime options: []const gen.Option,
) void {
    if (options.len == 0) {
        if (impl_group.len == 1) {
            return writeReturnImplementation(array, impl_group[0]);
        }
    } else {
        const tag = options[0].usage(out.DetailMore, toplevel_impl_group);
        switch (tag) {
            .eliminate_boolean_false,
            .eliminate_boolean_true,
            => {
                return writeDeduction(allocator, array, toplevel_impl_group, impl_group, options[1..]);
            },
            .test_boolean => {
                return writeDeductionTestBoolean(allocator, array, toplevel_impl_group, impl_group, options, options[0].info.field_field_names);
            },
            .compare_enumeration => {
                return writeDeductionCompareEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
            },
            .compare_optional_enumeration => {
                return writeDeductionCompareOptionalEnumeration(allocator, array, toplevel_impl_group, impl_group, options);
            },
        }
    }
}
pub fn generateReferences() void {
    var allocator: gen.Allocator = gen.Allocator.init();
    var array: gen.String = gen.String.init(allocator.allocate(u8, 1024 * 1024));
    gen.writeImports(&array, @src(), &.{
        .{ .name = "mach", .path = "../mach.zig" },
        .{ .name = "algo", .path = "../algo.zig" },
    });
    var ctn_index: u16 = 0;
    var spec_index: u16 = 0;
    var impl_index: u16 = 0;

    for (out.specifications) |ctn_group| {
        defer ctn_index +%= 1;
        for (ctn_group) |spec_group| {
            defer spec_index +%= 1;
            if (spec_group.len == 0) {
                continue;
            }
            array.writeMany("pub const Specification");
            gen.writeIndex(&array, spec_index);
            array.writeMany(" = struct {\n");
            array.writeMany("const Specification = @This();\n");
            if (spec_group.len == 1) {
                array.writeMany("pub fn Implementation(comptime spec: Specification) type {\n");
                writeReturnImplementation(&array, &out.variants[spec_group[0]]);
                array.writeMany("}\n");
            } else {
                const save: gen.Allocator.Save = allocator.save();
                defer allocator.restore(save);
                const buf: []*const out.DetailMore = allocator.allocate(*const out.DetailMore, spec_group.len);
                for (spec_group) |var_index, ptr_index| buf[ptr_index] = &out.variants[var_index];
                array.writeMany("pub fn Implementation(comptime spec: Specification, comptime options: anytype) type {\n");
                writeDeduction(&allocator, &array, buf, buf, &out.options);
                array.writeMany("}\n");
            }
            array.writeMany("};\n");
        }
    }
    ctn_index = 0;
    spec_index = 0;
    for (out.specifications) |ctn_group| {
        defer ctn_index +%= 1;
        for (ctn_group) |spec_group| {
            defer spec_index +%= 1;
            for (spec_group) |var_index| {
                defer impl_index +%= 1;
                array.writeMany("inline fn ");
                writeImplementationName(&array, &out.variants[var_index]);
                array.writeMany("(comptime " ++ spec_name ++ ": " ++ generic_spec_type_name);
                gen.writeIndex(&array, spec_index);
                array.writeMany(") type {\nreturn (struct {\n");
                writeFields(&array, &out.variants[var_index]);
                array.writeMany("const " ++ impl_type_name ++ " = @This();\n");
                writeDecls(&array, &out.variants[var_index]);
                for (key) |impl_fn_info| writeFn(&array, &out.variants[var_index], &impl_fn_info);
                array.writeMany("});\n}\n");
                impl_index +%= 1;
            }
        }
    }

    writeFile(&array);
}
pub const main = generateReferences;
