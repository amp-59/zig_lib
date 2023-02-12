const config = @import("./config.zig");

// Basic
pub const word_type_name: [:0]const u8 = @typeName(config.word_size_type);
pub const type_type_name: [:0]const u8 = "type";
pub const generic_type_name: [:0]const u8 = "anytype";

// Implementation
pub const impl_name: [:0]const u8 = "impl";
pub const impl_type_name: [:0]const u8 = "Implementation";
pub const impl_ptr_type_name: [:0]const u8 = pointerTo(impl_type_name);
pub const impl_const_ptr_type_name: [:0]const u8 = constPointerTo(impl_type_name);
pub const impl_param: [:0]const u8 = paramDecl(impl_name, impl_ptr_type_name);
pub const impl_field: [:0]const u8 = paramDecl(impl_name, impl_type_name);
pub const impl_const_param: [:0]const u8 = paramDecl(impl_name, impl_const_ptr_type_name);
pub const spec_name: [:0]const u8 = "spec";
pub const generic_spec_type_name: [:0]const u8 = "Specification";
pub const sentinel_specifier_name: [:0]const u8 = fieldAccess(spec_name, "sentinel");
pub const arena_specifier_name: [:0]const u8 = fieldAccess(spec_name, "arena");
pub const count_specifier_name: [:0]const u8 = fieldAccess(spec_name, "count");
pub const low_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, "low_alignment");
pub const high_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, "high_alignment");
pub const child_specifier_name: [:0]const u8 = fieldAccess(spec_name, "child");
pub const slave_specifier_name: [:0]const u8 = "allocator";
pub const slave_specifier_type_name: [:0]const u8 = fieldAccess(spec_name, "Allocator");
pub const slave_specifier_ptr_type_name: [:0]const u8 = pointerTo(slave_specifier_type_name);
pub const slave_specifier_const_ptr_type_name: [:0]const u8 = constPointerTo(slave_specifier_type_name);
pub const slave_specifier_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_type_name);
pub const slave_specifier_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_ptr_type_name);
pub const slave_specifier_const_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_const_ptr_type_name);
pub const slave_specifier_call_unallocated_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unallocated_byte_address"));
pub const slave_specifier_call_unmapped_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unmapped_byte_address"));
pub const slave_specifier_call_unaddressable_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, "unaddressable_byte_address"));
pub const offset_bytes_name: [:0]const u8 = "x_bytes";
pub const offset_bytes_param: [:0]const u8 = paramDecl(offset_bytes_name, word_type_name);
pub const automatic_storage_type_name: [:0]const u8 = arrayType(child_specifier_name, count_specifier_name, null);
pub const automatic_storage_with_sentinel_type_name: [:0]const u8 = arrayType(child_specifier_name, count_specifier_name, sentinel_specifier_name);
pub const automatic_storage_field_name: [:0]const u8 = "auto";
pub const automatic_storage_access: [:0]const u8 = fieldAccess(impl_name, automatic_storage_field_name);
pub const automatic_storage_ptr: [:0]const u8 = impl_name ++ addressOf(automatic_storage_access);
pub const automatic_storage_field: [:0]const u8 = paramDecl(automatic_storage_field_name, automatic_storage_type_name);
pub const automatic_storage_with_sentinel_field: [:0]const u8 = paramDecl(automatic_storage_field_name, automatic_storage_with_sentinel_type_name);
pub const allocated_byte_address_word_field_name: [:0]const u8 = "lb_word";
pub const allocated_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, allocated_byte_address_word_field_name);
pub const allocated_byte_address_word_ptr: [:0]const u8 = addressOf(allocated_byte_address_word_access);
pub const allocated_byte_address_word_field: [:0]const u8 = paramDecl(allocated_byte_address_word_field_name, word_type_name);
pub const unstreamed_byte_address_word_field_name: [:0]const u8 = "ss_word";
pub const unstreamed_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, unstreamed_byte_address_word_field_name);
pub const unstreamed_byte_address_word_ptr: [:0]const u8 = addressOf(unstreamed_byte_address_word_access);
pub const unstreamed_byte_address_word_field: [:0]const u8 = paramDecl(unstreamed_byte_address_word_field_name, word_type_name);
pub const undefined_byte_address_word_field_name: [:0]const u8 = "ub_word";
pub const undefined_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, undefined_byte_address_word_field_name);
pub const undefined_byte_address_word_ptr: [:0]const u8 = addressOf(undefined_byte_address_word_access);
pub const undefined_byte_address_word_field: [:0]const u8 = paramDecl(undefined_byte_address_word_field_name, word_type_name);
pub const unallocated_byte_address_word_field_name: [:0]const u8 = "up_word";
pub const unallocated_byte_address_word_access: [:0]const u8 = fieldAccess(impl_name, unallocated_byte_address_word_field_name);
pub const unallocated_byte_address_word_ptr: [:0]const u8 = addressOf(unallocated_byte_address_word_access);
pub const unallocated_byte_address_word_field: [:0]const u8 = paramDecl(unallocated_byte_address_word_field_name, word_type_name);
pub const address_of_impl: [:0]const u8 = callPtrToInt(impl_name);
pub const call_sizeof_child: [:0]const u8 = callSizeOf(child_specifier_name);
pub const offset_of_automatic_storage: [:0]const u8 = callOffsetOf(impl_type_name, automatic_storage_field_name);

// Container
pub const array_name: [:0]const u8 = "array";
pub const array_type_name: [:0]const u8 = "Array";
pub const array_ptr_type_name: [:0]const u8 = pointerTo(array_type_name);
pub const array_const_ptr_type_name: [:0]const u8 = constPointerTo(array_type_name);
pub const array_param: [:0]const u8 = paramDecl(array_name, array_type_name);
pub const array_ptr_param: [:0]const u8 = paramDecl(array_name, array_ptr_type_name);
pub const array_const_ptr_param: [:0]const u8 = paramDecl(array_name, array_const_ptr_type_name);
pub const allocator_name: [:0]const u8 = "allocator";
pub const allocator_type_name: [:0]const u8 = "Allocator";
pub const allocator_ptr_type_name: [:0]const u8 = pointerTo(allocator_type_name);
pub const allocator_const_ptr_type_name: [:0]const u8 = constPointerTo(allocator_type_name);
pub const allocator_param: [:0]const u8 = paramDecl(allocator_name, allocator_type_name);
pub const allocator_ptr_param: [:0]const u8 = paramDecl(allocator_name, allocator_ptr_type_name);
pub const allocator_const_ptr_param: [:0]const u8 = paramDecl(allocator_name, allocator_const_ptr_type_name);
pub const child_name: [:0]const u8 = "child";
pub const child_param: [:0]const u8 = comptimeParamDecl(child_name, type_type_name);
pub const child_size_name: [:0]const u8 = child_name ++ "_size";
pub const holder_type_name: [:0]const u8 = "Holder";
pub const static_type_name: [:0]const u8 = "Static";
pub const dynamic_type_name: [:0]const u8 = "Dynamic";
pub const holder_impl_type_name: [:0]const u8 = fieldAccess(holder_type_name, impl_type_name);
pub const static_impl_type_name: [:0]const u8 = fieldAccess(static_type_name, impl_type_name);
pub const dynamic_impl_type_name: [:0]const u8 = fieldAccess(dynamic_type_name, impl_type_name);
pub const offset_int_param: [:0]const u8 = paramDecl(offset_name, word_type_name);
pub const offset_amt_param: [:0]const u8 = paramDecl(offset_name, amount_type_name);
pub const reinterpret_spec_name: [:0]const u8 = "write_spec";
pub const reinterpret_spec_type_name: [:0]const u8 = "ReinterpretSpec";
pub const reinterpret_spec_param: [:0]const u8 = comptimeParamDecl(reinterpret_spec_name, reinterpret_spec_type_name);
pub const count_name: [:0]const u8 = "count";
pub const amount_name: [:0]const u8 = "amount";
pub const offset_name: [:0]const u8 = "offset";
pub const amount_type_name: [:0]const u8 = "Amount";
pub const write_count_name: [:0]const u8 = "write_" ++ count_name;
pub const write_count_param: [:0]const u8 = comptimeParamDecl(write_count_name, word_type_name);
pub const read_count_name: [:0]const u8 = "read_" ++ count_name;
pub const read_count_param: [:0]const u8 = comptimeParamDecl(read_count_name, word_type_name);
pub const define_count_name: [:0]const u8 = "define_" ++ count_name;
pub const define_count_param: [:0]const u8 = paramDecl(define_count_name, word_type_name);
pub const undefine_count_name: [:0]const u8 = "undefine_" ++ count_name;
pub const undefine_count_param: [:0]const u8 = paramDecl(undefine_count_name, word_type_name);
pub const stream_count_name: [:0]const u8 = "stream_" ++ count_name;
pub const stream_count_param: [:0]const u8 = paramDecl(stream_count_name, word_type_name);
pub const unstream_count_name: [:0]const u8 = "unstream_" ++ count_name;
pub const unstream_count_param: [:0]const u8 = paramDecl(unstream_count_name, word_type_name);
pub const write_amount_name: [:0]const u8 = "write_" ++ amount_name;
pub const write_amount_param: [:0]const u8 = comptimeParamDecl(write_amount_name, amount_type_name);
pub const read_amount_name: [:0]const u8 = "read_" ++ amount_name;
pub const read_amount_param: [:0]const u8 = comptimeParamDecl(read_amount_name, amount_type_name);
pub const define_amount_name: [:0]const u8 = "define_" ++ amount_name;
pub const define_amount_param: [:0]const u8 = comptimeParamDecl(define_amount_name, amount_type_name);
pub const undefine_amount_name: [:0]const u8 = "undefine_" ++ amount_name;
pub const undefine_amount_param: [:0]const u8 = comptimeParamDecl(undefine_amount_name, amount_type_name);
pub const stream_amount_name: [:0]const u8 = "stream_" ++ amount_name;
pub const stream_amount_param: [:0]const u8 = comptimeParamDecl(stream_amount_name, amount_type_name);
pub const unstream_amount_name: [:0]const u8 = "unstream_" ++ amount_name;
pub const unstream_amount_param: [:0]const u8 = comptimeParamDecl(unstream_amount_name, amount_type_name);
pub const zero_amount_name: [:0]const u8 = "_0";
pub const unit_amount_name: [:0]const u8 = "_1";
pub const any_name: [:0]const u8 = "any";
pub const args_name: [:0]const u8 = "args";
pub const fields_name: [:0]const u8 = "fields";
pub const format_name: [:0]const u8 = "format";
pub const value_name: [:0]const u8 = "value";
pub const value_param: [:0]const u8 = value_name ++ ": " ++ child_name;
pub const count_values_name: [:0]const u8 = "values";
pub const count_values_param: [:0]const u8 = paramDecl(count_values_name, arrayType(child_name, write_count_name, null));
pub const many_values_name: [:0]const u8 = "values";
pub const many_values_param: [:0]const u8 = paramDecl(many_values_name, constSliceType(child_name, null));
pub const sentinel_name: [:0]const u8 = "sentinel_value";
pub const loop_payload_name: [:0]const u8 = value_name;
pub const loop_index_name: [:0]const u8 = "i";
pub const amount_param: [:0]const u8 = paramDecl(amount_name, amount_type_name);
pub const any_param: [:0]const u8 = paramDecl(any_name, generic_type_name);
pub const args_param: [:0]const u8 = paramDecl(args_name, generic_type_name);
pub const format_param: [:0]const u8 = paramDecl(format_name, generic_type_name);
pub const fields_param: [:0]const u8 = paramDecl(fields_name, generic_type_name);
pub const s_sentinel_param: [:0]const u8 = comptimeParamDecl(sentinel_name, child_name);
pub const u_sentinel_param: [:0]const u8 = comptimeParamDecl(sentinel_name, child_name);
pub const holder_type_param: [:0]const u8 = comptimeParamDecl(holder_type_name, type_type_name);
pub const static_type_param: [:0]const u8 = comptimeParamDecl(static_type_name, type_type_name);
pub const dynamic_type_param: [:0]const u8 = comptimeParamDecl(dynamic_type_name, type_type_name);

// Functions
pub const add_equ_fn_name: [:0]const u8 = machFnName("addEqu");
pub const subtract_equ_fn_name: [:0]const u8 = machFnName("subEqu");
pub const add_fn_name: [:0]const u8 = machFnName("add");
pub const subtract_fn_name: [:0]const u8 = machFnName("sub");
pub const align_above_fn_name: [:0]const u8 = machFnName("alignA");
pub const align_below_fn_name: [:0]const u8 = machFnName("alignB");
pub const and_fn_name: [:0]const u8 = machFnName("and");
pub const and_not_fn_name: [:0]const u8 = machFnName("andn");
pub const conditional_move_fn_name: [:0]const u8 = machFnName("cmov");
pub const multiply_fn_name: [:0]const u8 = machFnName("mul");
pub const or_fn_name: [:0]const u8 = machFnName("or");
pub const shift_left_fn_name: [:0]const u8 = machFnName("shl");
pub const shift_right_fn_name: [:0]const u8 = machFnName("shr");
pub const unpack_single_fn_name: [:0]const u8 = if (config.packed_capacity_low) "algo.unpackSingleApproxB" else "algo.unpackSingleApproxA";
pub const unpack_double_fn_name: [:0]const u8 = if (config.packed_capacity_low) "algo.unpackDoubleApproxS" else "algo.unpackDoubleApproxH";
pub const write_one_impl_fn_name: [:0]const u8 = "writeOneInternal";
pub const write_count_impl_fn_name: [:0]const u8 = "writeCountInternal";
pub const write_many_impl_fn_name: [:0]const u8 = "writeManyInternal";
pub const pointer_opaque_fn_name: [:0]const u8 = "pointerOpaque";
pub const pointer_one_fn_name: [:0]const u8 = "pointerOne";
pub const pointer_many_fn_name: [:0]const u8 = "pointerMany";
pub const pointer_many_with_sentinel_fn_name: [:0]const u8 = "pointerManyWithSentinel";
pub const pointer_count_fn_name: [:0]const u8 = "pointerCount";
pub const pointer_count_with_sentinel_fn_name: [:0]const u8 = "pointerCountWithSentinel";
pub const length_format_fn_name: [:0]const u8 = fieldAccess("reinterpret", "lengthFormat");
pub const length_args_fn_name: [:0]const u8 = fieldAccess("reinterpret", "lengthArgs");
pub const length_fields_fn_name: [:0]const u8 = fieldAccess("reinterpret", "lengthFields");
pub const length_any_fn_name: [:0]const u8 = fieldAccess("reinterpret", "lengthAny");
pub const write_format_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeFormat");
pub const write_fields_structured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeFieldsStructured");
pub const write_fields_unstructured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeFieldsUnstructured");
pub const write_args_structured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeArgsStructured");
pub const write_args_unstructured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeArgsUnstructured");
pub const write_any_structured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeAnyStructured");
pub const write_any_unstructured_fn_name: [:0]const u8 = fieldAccess("reinterpret", "writeAnyUnstructured");

fn machFnName(comptime name: [:0]const u8) [:0]const u8 {
    return "mach." ++ name ++ word_type_name[1..];
}
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
fn constSliceType(
    comptime type_name: [:0]const u8,
    comptime sentinel_symbol_opt: ?[:0]const u8,
) [:0]const u8 {
    if (sentinel_symbol_opt) |sentinel_symbol| {
        return "[:" ++ sentinel_symbol ++ "]const " ++ type_name;
    } else {
        return "[]const " ++ type_name;
    }
}
fn sliceType(
    comptime type_name: [:0]const u8,
    comptime sentinel_symbol_opt: ?[:0]const u8,
) [:0]const u8 {
    if (sentinel_symbol_opt) |sentinel_symbol| {
        return "[:" ++ sentinel_symbol ++ "]" ++ type_name;
    } else {
        return "[]" ++ type_name;
    }
}
fn fieldAccess(comptime symbol: [:0]const u8, field_name: [:0]const u8) [:0]const u8 {
    return symbol ++ period_operator ++ field_name;
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
    return "*" ++ const_keyword ++ type_name;
}
fn paramDecl(comptime symbol: [:0]const u8, type_name: [:0]const u8) [:0]const u8 {
    return symbol ++ colon_operator ++ type_name;
}
fn comptimeParamDecl(comptime symbol: [:0]const u8, type_name: [:0]const u8) [:0]const u8 {
    return comptime_keyword ++ symbol ++ colon_operator ++ type_name;
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

pub const comptime_keyword: [:0]const u8 = "comptime ";
pub const const_keyword: [:0]const u8 = "const ";
pub const return_keyword: [:0]const u8 = "return ";
pub const var_keyword: [:0]const u8 = "var ";

pub const colon_operator: [:0]const u8 = ": ";
pub const period_operator: [:0]const u8 = ".";
pub const equal_operator: [:0]const u8 = " = ";
pub const period_asterisk_operator: [:0]const u8 = ".*";

pub const end_expression: [:0]const u8 = ";\n";
pub const end_item: [:0]const u8 = ",\n";
pub const end_small_item: [:0]const u8 = ", ";
