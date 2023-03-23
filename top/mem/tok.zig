const config = @import("./config.zig");

// Basic
pub const word_type_name: [:0]const u8 = @typeName(config.word_size_type);
pub const counts_type_name: [:0]const u8 = "u16";
pub const type_type_name: [:0]const u8 = "type";
pub const generic_type_name: [:0]const u8 = "anytype";

// Namespace
pub const builtin_namespace: [:0]const u8 = "builtin";
pub const reference_namespace: [:0]const u8 = "reference";
pub const container_namespace: [:0]const u8 = "container";
pub const mach_namespace: [:0]const u8 = "mach";
pub const meta_namespace: [:0]const u8 = "meta";

// Feature
pub const addressable_byte_address_name: [:0]const u8 = "addressable_byte_address"; // noref
pub const aligned_byte_address_name: [:0]const u8 = "aligned_byte_address";
pub const allocated_byte_address_name: [:0]const u8 = "allocated_byte_address";
pub const mapped_byte_address_name: [:0]const u8 = "mapped_byte_address"; // noref
pub const unaddressable_byte_address_name: [:0]const u8 = "unaddressable_byte_address"; // noref
pub const unallocated_byte_address_name: [:0]const u8 = "unallocated_byte_address";
pub const undefined_byte_address_name: [:0]const u8 = "undefined_byte_address";
pub const unmapped_byte_address_name: [:0]const u8 = "unmapped_byte_address";
pub const unstreamed_byte_address_name: [:0]const u8 = "unstreamed_byte_address";
pub const unwritable_byte_address_name: [:0]const u8 = "unwritable_byte_address";

// Derived
pub const alignment_name: [:0]const u8 = "alignment";
pub const aligned_byte_count_name: [:0]const u8 = "aligned_byte_count";
pub const allocated_byte_count_name: [:0]const u8 = "allocated_byte_count";
pub const writable_byte_count_name: [:0]const u8 = "writable_byte_count";

// Implementation
pub const impl_name: [:0]const u8 = "impl";
pub const impl_type_name: [:0]const u8 = "Implementation";
pub const slave_fn_type_name: [:0]const u8 = "Slave";
pub const static_fn_type_name: [:0]const u8 = "Static";
pub const impl_ptr_type_name: [:0]const u8 = pointerTo(impl_type_name);
pub const impl_const_ptr_type_name: [:0]const u8 = constPointerTo(impl_type_name);
pub const impl_param: [:0]const u8 = paramDecl(impl_name, impl_ptr_type_name);
pub const impl_field: [:0]const u8 = paramDecl(impl_name, impl_type_name);
pub const impl_const_param: [:0]const u8 = paramDecl(impl_name, impl_const_ptr_type_name);
pub const spec_name: [:0]const u8 = "spec";
pub const generic_spec_type_name: [:0]const u8 = "Specification";
pub const low_alignment_name: [:0]const u8 = "low_alignment";
pub const high_alignment_name: [:0]const u8 = "high_alignment";
pub const unit_alignment_name: [:0]const u8 = "unit_alignment";
pub const auto_alignment_name: [:0]const u8 = "auto_alignment";
pub const sentinel_ptr_name: [:0]const u8 = "sentinel";

pub const parametric_type_name: []const u8 = "Parametric";
pub const automatic_type_name: []const u8 = "Automatic";
pub const dynamic_type_name: []const u8 = "Dynamic";
pub const static_type_name: []const u8 = "Static";
pub const structured_type_name: []const u8 = "Structured";
pub const unstructured_type_name: []const u8 = "Unstructured";
pub const read_write_type_name: []const u8 = "ReadWrite";
pub const stream_type_name: []const u8 = "Stream";
pub const resize_type_name: []const u8 = "Resize";
pub const arena_type_name: []const u8 = "Arena";
pub const sentinel_type_name: []const u8 = "Sentinel";
pub const lazy_alignment_type_name: []const u8 = "LazyAlignment";
pub const unit_alignment_type_name: []const u8 = "UnitAlignment";
pub const disjunct_alignment_type_name: []const u8 = "DisjunctAlignment";
pub const double_packed_approximate_capacity_type_name: []const u8 = "DoublePackedApproximateCapacity";
pub const single_packed_approximate_capacity_type_name: []const u8 = "SinglePackedApproximateCapacity";

pub const sentinel_specifier_name: [:0]const u8 = fieldAccess(spec_name, sentinel_ptr_name);
pub const arena_specifier_name: [:0]const u8 = fieldAccess(spec_name, "arena");
pub const count_specifier_name: [:0]const u8 = fieldAccess(spec_name, "count");
pub const low_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, low_alignment_name);
pub const high_alignment_specifier_name: [:0]const u8 = fieldAccess(spec_name, high_alignment_name);
pub const child_specifier_name: [:0]const u8 = fieldAccess(spec_name, child_type_name);
pub const slave_specifier_name: [:0]const u8 = "allocator";
pub const slave_specifier_type_name: [:0]const u8 = fieldAccess(spec_name, "Allocator");
pub const slave_specifier_ptr_type_name: [:0]const u8 = pointerTo(slave_specifier_type_name);
pub const slave_specifier_const_ptr_type_name: [:0]const u8 = constPointerTo(slave_specifier_type_name);
pub const slave_specifier_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_type_name);
pub const slave_specifier_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_ptr_type_name);
pub const slave_specifier_const_ptr_param: [:0]const u8 = paramDecl(slave_specifier_name, slave_specifier_const_ptr_type_name);
pub const slave_specifier_call_unallocated_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, unallocated_byte_address_name));
pub const slave_specifier_call_unmapped_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, unmapped_byte_address_name));
pub const slave_specifier_call_unaddressable_byte_address: [:0]const u8 = callSimple(fieldAccess(slave_specifier_name, unaddressable_byte_address_name));
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
pub const call_sizeof_child: [:0]const u8 = callSizeOf(child_type_name);
pub const call_sizeof_child_specifier: [:0]const u8 = callSizeOf(child_specifier_name);
pub const offset_of_automatic_storage: [:0]const u8 = callOffsetOf(impl_type_name, automatic_storage_field_name);

// Container
pub const array_name: [:0]const u8 = "array";
pub const array_impl: [:0]const u8 = fieldAccess(array_name, impl_name);
pub const array_type_name: [:0]const u8 = "Array";
pub const array_ptr_type_name: [:0]const u8 = pointerTo(array_type_name);
pub const array_const_ptr_type_name: [:0]const u8 = constPointerTo(array_type_name);
pub const array_param: [:0]const u8 = paramDecl(array_name, array_type_name);
pub const array_ptr_param: [:0]const u8 = paramDecl(array_name, array_ptr_type_name);
pub const array_const_ptr_param: [:0]const u8 = paramDecl(array_name, array_const_ptr_type_name);
pub const void_type_name: [:0]const u8 = "void";
pub const child_type_name: [:0]const u8 = "child";
pub const child_param: [:0]const u8 = comptimeParamDecl(child_type_name, type_type_name);
pub const child_size_name: [:0]const u8 = child_type_name ++ "_size";
pub const child_ptr_type_name: [:0]const u8 = pointerTo(child_type_name);
pub const child_array_ptr_type_name: [:0]const u8 = pointerTo(arrayType(child_type_name, count_name, null));
pub const child_array_ptr_with_sentinel_type_name: [:0]const u8 = pointerTo(arrayType(child_type_name, count_name, sentinel_name));
pub const child_slice_type_name: [:0]const u8 = sliceType(child_type_name, null);
pub const child_slice_with_sentinel_type_name: [:0]const u8 = sliceType(child_type_name, sentinel_name);
pub const child_array_type_name: [:0]const u8 = arrayType(child_type_name, count_name, null);
pub const child_array_with_sentinel_type_name: [:0]const u8 = arrayType(child_type_name, count_name, sentinel_name);
pub const child_const_slice_type_name: [:0]const u8 = constSliceType(child_type_name, null);
pub const child_const_slice_with_sentinel_type_name: [:0]const u8 = constSliceType(child_type_name, sentinel_name);
pub const allocator_name: [:0]const u8 = "allocator";
pub const allocator_type_name: [:0]const u8 = "Allocator";
pub const allocator_ptr_type_name: [:0]const u8 = pointerTo(allocator_type_name);
pub const allocator_const_ptr_type_name: [:0]const u8 = constPointerTo(allocator_type_name);
pub const allocator_param: [:0]const u8 = paramDecl(allocator_name, allocator_type_name);
pub const allocator_ptr_param: [:0]const u8 = paramDecl(allocator_name, allocator_ptr_type_name);
pub const allocator_const_ptr_param: [:0]const u8 = paramDecl(allocator_name, allocator_const_ptr_type_name);
pub const allocator_void_type_name: [:0]const u8 = fieldAccess(allocator_type_name, "allocate_void");
pub const target_holder_type_name: [:0]const u8 = "t_holder_type";
pub const target_static_type_name: [:0]const u8 = "t_static_type";
pub const target_dynamic_type_name: [:0]const u8 = "t_dynamic_type";
pub const holder_impl_type_name: [:0]const u8 = fieldAccess(target_holder_type_name, impl_type_name);
pub const static_impl_type_name: [:0]const u8 = fieldAccess(target_static_type_name, impl_type_name);
pub const dynamic_impl_type_name: [:0]const u8 = fieldAccess(target_dynamic_type_name, impl_type_name);
pub const reinterpret_spec_name: [:0]const u8 = "write_spec";
pub const reinterpret_spec_type_name: [:0]const u8 = "ReinterpretSpec";
pub const reinterpret_spec_param: [:0]const u8 = comptimeParamDecl(reinterpret_spec_name, reinterpret_spec_type_name);

pub const offset_name: [:0]const u8 = "offset";
pub const count_name: [:0]const u8 = "count";
pub const amount_name: [:0]const u8 = "amount";
pub const init_count_name: [:0]const u8 = "init_count";
pub const init_amount_name: [:0]const u8 = "init_amount";
pub const init_offset_name: [:0]const u8 = "init_offset";
pub const new_count_name: [:0]const u8 = "new_count";
pub const new_amount_name: [:0]const u8 = "new_amount";
pub const new_offset_name: [:0]const u8 = "new_offset";
pub const amount_type_name: [:0]const u8 = "Amount";
pub const count_param: [:0]const u8 = paramDecl(count_name, word_type_name);
pub const static_count_param: [:0]const u8 = comptimeParamDecl(count_name, word_type_name);
pub const offset_word_param: [:0]const u8 = paramDecl(offset_name, word_type_name);
pub const offset_amount_param: [:0]const u8 = paramDecl(offset_name, amount_type_name);
pub const init_count_param: [:0]const u8 = paramDecl(init_count_name, word_type_name);
pub const init_amount_param: [:0]const u8 = paramDecl(init_amount_name, amount_type_name);
pub const init_offset_param: [:0]const u8 = paramDecl(init_offset_name, word_type_name);
pub const new_count_param: [:0]const u8 = paramDecl(new_count_name, word_type_name);
pub const new_amount_param: [:0]const u8 = paramDecl(new_amount_name, amount_type_name);
pub const new_offset_param: [:0]const u8 = paramDecl(new_offset_name, word_type_name);
pub const write_count_param: [:0]const u8 = comptimeParamDecl(count_name, word_type_name);
pub const read_count_param: [:0]const u8 = comptimeParamDecl(count_name, word_type_name);
pub const read_many_param: [:0]const u8 = paramDecl(count_name, word_type_name);
pub const amount_zero: [:0]const u8 = "Amount.zero";
pub const amount_one: [:0]const u8 = "Amount.one";
pub const amount_none: [:0]const u8 = "Amount.none";
pub const amount_unit: [:0]const u8 = "Amount.unit";
pub const any_name: [:0]const u8 = "any";
pub const args_name: [:0]const u8 = "args";
pub const fields_name: [:0]const u8 = "fields";
pub const format_name: [:0]const u8 = "format";
pub const value_name: [:0]const u8 = "value";
pub const value_param: [:0]const u8 = paramDecl(value_name, child_type_name);
pub const count_values_name: [:0]const u8 = "values";
pub const count_values_param: [:0]const u8 = paramDecl(count_values_name, arrayType(child_type_name, count_name, null));
pub const many_values_name: [:0]const u8 = "values";
pub const many_values_param: [:0]const u8 = paramDecl(many_values_name, constSliceType(child_type_name, null));
pub const many_values_len: [:0]const u8 = fieldAccess(many_values_name, "len");
pub const sentinel_name: [:0]const u8 = "sentinel_value";
pub const loop_payload_name: [:0]const u8 = value_name;
pub const loop_index_name: [:0]const u8 = "i";
pub const amount_param: [:0]const u8 = paramDecl(amount_name, amount_type_name);
pub const any_param: [:0]const u8 = paramDecl(any_name, generic_type_name);
pub const args_param: [:0]const u8 = paramDecl(args_name, generic_type_name);
pub const format_param: [:0]const u8 = paramDecl(format_name, generic_type_name);
pub const fields_param: [:0]const u8 = paramDecl(fields_name, generic_type_name);
pub const s_sentinel_param: [:0]const u8 = comptimeParamDecl(sentinel_name, child_type_name);
pub const u_sentinel_param: [:0]const u8 = comptimeParamDecl(sentinel_name, child_type_name);
pub const holder_type_param: [:0]const u8 = comptimeParamDecl(target_holder_type_name, type_type_name);
pub const static_type_param: [:0]const u8 = comptimeParamDecl(target_static_type_name, type_type_name);
pub const dynamic_type_param: [:0]const u8 = comptimeParamDecl(target_dynamic_type_name, type_type_name);

// Allocator
pub const source_impl_type_name: [:0]const u8 = "s_impl_type";
pub const target_impl_type_name: [:0]const u8 = "t_impl_type";
pub const source_impl_name: [:0]const u8 = "s_impl";
pub const target_impl_name: [:0]const u8 = "t_impl";
pub const source_impl_ptr_name: [:0]const u8 = "s_impl_ptr";
pub const target_impl_ptre_name: [:0]const u8 = "t_impl_ptr";
pub const input_amount_name: [:0]const u8 = "n_amt";
pub const source_amount_name: [:0]const u8 = "s_amt";
pub const option_amount_name: [:0]const u8 = "o_amt";
pub const extra_amount_name: [:0]const u8 = "x_amt";
pub const target_amount_name: [:0]const u8 = "t_amt";
pub const input_bytes_name: [:0]const u8 = "n_bytes";
pub const source_bytes_name: [:0]const u8 = "s_bytes";
pub const option_bytes_name: [:0]const u8 = "o_bytes";
pub const offset_bytes_name: [:0]const u8 = "x_bytes";
pub const target_bytes_name: [:0]const u8 = "t_bytes";
pub const input_count_name: [:0]const u8 = "n_count";
pub const source_count_name: [:0]const u8 = "s_count";
pub const option_count_name: [:0]const u8 = "o_count";
pub const offset_count_name: [:0]const u8 = "x_count";
pub const target_count_name: [:0]const u8 = "t_count";
pub const input_aligned_bytes_name: [:0]const u8 = "n_aligned_bytes";
pub const source_aligned_bytes_name: [:0]const u8 = "s_aligned_bytes";
pub const option_aligned_bytes_name: [:0]const u8 = "o_aligned_bytes";
pub const offset_aligned_bytes_name: [:0]const u8 = "x_aligned_bytes";
pub const target_aligned_bytes_name: [:0]const u8 = "t_aligned_bytes";
pub const source_allocated_byte_address_name: [:0]const u8 = "s_lb_addr";
pub const target_allocated_byte_address_name: [:0]const u8 = "t_lb_addr";
pub const source_unstreamed_byte_address_name: [:0]const u8 = "s_ss_addr";
pub const target_unstreamed_byte_address_name: [:0]const u8 = "t_ss_addr";
pub const source_aligned_byte_address_name: [:0]const u8 = "s_ab_addr";
pub const target_aligned_byte_address_name: [:0]const u8 = "t_ab_addr";
pub const source_undefined_byte_address_name: [:0]const u8 = "s_ub_addr";
pub const target_undefined_byte_address_name: [:0]const u8 = "t_ub_addr";
pub const source_unallocated_byte_address_name: [:0]const u8 = "s_up_addr";
pub const target_unallocated_byte_address_name: [:0]const u8 = "t_up_addr";
pub const source_single_approximation_counts_name: [:0]const u8 = "s_lb_counts";
pub const source_double_approximation_counts_name: [:0]const u8 = "s_ub_counts";
pub const target_single_approximation_counts_name: [:0]const u8 = "t_lb_counts";
pub const target_double_approximation_counts_name: [:0]const u8 = "t_ub_counts";
pub const source_impl_type_param: [:0]const u8 = paramDecl(source_impl_type_name, word_type_name);
pub const target_impl_type_param: [:0]const u8 = paramDecl(target_impl_type_name, word_type_name);
pub const source_impl_param: [:0]const u8 = paramDecl(source_impl_name, word_type_name);
pub const target_impl_param: [:0]const u8 = paramDecl(target_impl_name, word_type_name);
pub const source_impl_ptr_param: [:0]const u8 = paramDecl(source_impl_ptr_name, word_type_name);
pub const target_impl_ptre_param: [:0]const u8 = paramDecl(target_impl_ptre_name, word_type_name);
pub const input_amount_param: [:0]const u8 = paramDecl(input_amount_name, word_type_name);
pub const source_amount_param: [:0]const u8 = paramDecl(source_amount_name, amount_type_name);
pub const option_amount_param: [:0]const u8 = paramDecl(option_amount_name, amount_type_name);
pub const extra_amount_param: [:0]const u8 = paramDecl(extra_amount_name, amount_type_name);
pub const target_amount_param: [:0]const u8 = paramDecl(target_amount_name, amount_type_name);
pub const input_bytes_param: [:0]const u8 = paramDecl(input_bytes_name, word_type_name);
pub const source_bytes_param: [:0]const u8 = paramDecl(source_bytes_name, word_type_name);
pub const option_bytes_param: [:0]const u8 = paramDecl(option_bytes_name, word_type_name);
pub const offset_bytes_param: [:0]const u8 = paramDecl(offset_bytes_name, word_type_name);
pub const target_bytes_param: [:0]const u8 = paramDecl(target_bytes_name, word_type_name);
pub const input_count_param: [:0]const u8 = paramDecl(input_count_name, word_type_name);
pub const source_count_param: [:0]const u8 = paramDecl(source_count_name, word_type_name);
pub const option_count_param: [:0]const u8 = paramDecl(option_count_name, word_type_name);
pub const offset_count_param: [:0]const u8 = paramDecl(offset_count_name, word_type_name);
pub const target_count_param: [:0]const u8 = paramDecl(target_count_name, word_type_name);
pub const input_aligned_bytes_param: [:0]const u8 = paramDecl(input_aligned_bytes_name, word_type_name);
pub const source_aligned_bytes_param: [:0]const u8 = paramDecl(source_aligned_bytes_name, word_type_name);
pub const option_aligned_bytes_param: [:0]const u8 = paramDecl(option_aligned_bytes_name, word_type_name);
pub const offset_aligned_bytes_param: [:0]const u8 = paramDecl(offset_aligned_bytes_name, word_type_name);
pub const target_aligned_bytes_param: [:0]const u8 = paramDecl(target_aligned_bytes_name, word_type_name);
pub const source_allocated_byte_address_param: [:0]const u8 = paramDecl(source_allocated_byte_address_name, word_type_name);
pub const target_allocated_byte_address_param: [:0]const u8 = paramDecl(target_allocated_byte_address_name, word_type_name);
pub const source_unstreamed_byte_address_param: [:0]const u8 = paramDecl(source_unstreamed_byte_address_name, word_type_name);
pub const target_unstreamed_byte_address_param: [:0]const u8 = paramDecl(target_unstreamed_byte_address_name, word_type_name);
pub const source_aligned_byte_address_param: [:0]const u8 = paramDecl(source_aligned_byte_address_name, word_type_name);
pub const target_aligned_byte_address_param: [:0]const u8 = paramDecl(target_aligned_byte_address_name, word_type_name);
pub const source_undefined_byte_address_param: [:0]const u8 = paramDecl(source_undefined_byte_address_name, word_type_name);
pub const target_undefined_byte_address_param: [:0]const u8 = paramDecl(target_undefined_byte_address_name, word_type_name);
pub const source_unallocated_byte_address_param: [:0]const u8 = paramDecl(source_unallocated_byte_address_name, word_type_name);
pub const target_unallocated_byte_address_param: [:0]const u8 = paramDecl(target_unallocated_byte_address_name, word_type_name);
pub const source_single_approximation_counts_param: [:0]const u8 = paramDecl(source_single_approximation_counts_name, counts_type_name);
pub const source_double_approximation_counts_param: [:0]const u8 = paramDecl(source_double_approximation_counts_name, counts_type_name);
pub const target_single_approximation_counts_param: [:0]const u8 = paramDecl(target_single_approximation_counts_name, counts_type_name);
pub const target_double_approximation_counts_param: [:0]const u8 = paramDecl(target_double_approximation_counts_name, counts_type_name);

// Functions

pub const wrap_fn_name: [:0]const u8 = metaFnName("wrap");
pub const add_equ_fn_name: [:0]const u8 = machFnName("addEqu");
pub const sub_equ_fn_name: [:0]const u8 = machFnName("subEqu");
pub const add_fn_name: [:0]const u8 = machFnName("add");
pub const sub_fn_name: [:0]const u8 = machFnName("sub");
pub const aligna_fn_name: [:0]const u8 = machFnName("alignA");
pub const alignb_fn_name: [:0]const u8 = machFnName("alignB");
pub const div_trunc_fn_name: [:0]const u8 = machFnName("divT");
pub const div_exact_fn_name: [:0]const u8 = machFnName("divX");
pub const and_fn_name: [:0]const u8 = machFnName("and");
pub const and_not_fn_name: [:0]const u8 = machFnName("andn");
pub const cmov_fn_name: [:0]const u8 = machFnName("cmov");
pub const mul_fn_name: [:0]const u8 = machFnName("mul");
pub const or_fn_name: [:0]const u8 = machFnName("or");
pub const shl_fn_name: [:0]const u8 = machFnName("shl");
pub const shr_fn_name: [:0]const u8 = machFnName("shr");
pub const shl_or_fn_name: [:0]const u8 = machFnName("shlOr");
pub const sub_or_fn_name: [:0]const u8 = machFnName("subOr");
pub const mul_add_fn_name: [:0]const u8 = machFnName("mulAdd");
pub const mul_sub_fn_name: [:0]const u8 = machFnName("mulSub");
pub const unpack_single_fn_name: [:0]const u8 = if (config.packed_capacity_low) "algo.unpackSingleApproxB" else "algo.unpackSingleApproxA";
pub const unpack_double_fn_name: [:0]const u8 = if (config.packed_capacity_low) "algo.unpackDoubleApproxS" else "algo.unpackDoubleApproxH";
pub const partial_unpack_single_fn_name: [:0]const u8 = "algo.partialUnpackSingleApprox";
pub const partial_unpack_double_fn_name: [:0]const u8 = "algo.partialUnpackDoubleApprox";
pub const partial_pack_single_fn_name: [:0]const u8 = "algo.partialPackSingleApprox";
pub const partial_pack_double_fn_name: [:0]const u8 = "algo.partialPackDoubleApprox";
pub const amount_of_type_to_bytes_fn_name: [:0]const u8 = "amountOfTypeToBytes";
pub const amount_of_length_to_bytes_fn_name: [:0]const u8 = "amountOfLengthToBytes";
pub const amount_to_count_of_type_name: [:0]const u8 = "amountToCountOfType";
pub const amount_to_count_of_length_fn_name: [:0]const u8 = "amountToCountOfLength";
pub const amount_reserved_to_count_fn_name: [:0]const u8 = "amountReservedToCount";
pub const amount_reserved_to_bytes_fn_name: [:0]const u8 = "amountReservedToBytes";
pub const amount_of_type_to_bytes_short_fn_name: [:0]const u8 = "amtT2B";
pub const amount_of_length_to_bytes_short_fn_name: [:0]const u8 = "amtL2B";
pub const amount_to_count_of_short_type_name: [:0]const u8 = "amtT2C";
pub const amount_to_count_of_length_short_fn_name: [:0]const u8 = "amtL2C";
pub const amount_reserved_to_bytes_short_fn_name: [:0]const u8 = "amtR2B";
pub const amount_reserved_to_count_short_fn_name: [:0]const u8 = "amtR2C";
pub const write_one_impl_fn_name: [:0]const u8 = "writeOneInternal";
pub const write_count_impl_fn_name: [:0]const u8 = "writeCountInternal";
pub const write_many_impl_fn_name: [:0]const u8 = "writeManyInternal";
pub const pointer_opaque_fn_name: [:0]const u8 = "pointerOpaque";
pub const pointer_one_fn_name: [:0]const u8 = "pointerOne";
pub const pointer_many_fn_name: [:0]const u8 = "pointerMany";
pub const pointer_many_with_sentinel_fn_name: [:0]const u8 = "pointerManyWithSentinel";
pub const pointer_slice_fn_name: [:0]const u8 = "pointerSlice";
pub const pointer_slice_with_sentinel_fn_name: [:0]const u8 = "pointerSliceWithSentinel";
pub const pointer_count_fn_name: [:0]const u8 = "pointerCount";
pub const pointer_count_with_sentinel_fn_name: [:0]const u8 = "pointerCountWithSentinel";
pub const intr_pointer_opaque_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_opaque_fn_name);
pub const intr_pointer_one_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_one_fn_name);
pub const intr_pointer_slice_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_slice_fn_name);
pub const intr_pointer_slice_with_sentinel_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_slice_with_sentinel_fn_name);
pub const intr_pointer_count_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_count_fn_name);
pub const intr_pointer_count_with_sentinel_fn_name: [:0]const u8 = fieldAccess(reference_namespace, pointer_count_with_sentinel_fn_name);
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
pub const copy_fn_name: [:0]const u8 = "copy";

pub const slave_fn_type_decl_spec: [:0]const u8 = "fn(" ++ slave_specifier_const_ptr_type_name ++ ")callconv(.Inline)" ++ word_type_name;
pub const static_fn_type_decl_spec: [:0]const u8 = "fn()callconv(.Inline)" ++ word_type_name;

pub const call_this: [:0]const u8 = "@This()";

pub const comptime_keyword: [:0]const u8 = "comptime ";
pub const const_keyword: [:0]const u8 = "const ";
pub const return_keyword: [:0]const u8 = "return ";
pub const var_keyword: [:0]const u8 = "var ";

pub const colon_operator: [:0]const u8 = ":";
pub const period_operator: [:0]const u8 = ".";
pub const equal_operator: [:0]const u8 = "=";
pub const period_asterisk_operator: [:0]const u8 = ".*";
pub const period_open_brace_operator: [:0]const u8 = ".{";
pub const open_brace_operator: [:0]const u8 = "{";
pub const close_brace_operator: [:0]const u8 = "}";

pub const end_expr: [:0]const u8 = ";\n";
pub const end_elem: [:0]const u8 = ",";
pub const discard: [:0]const u8 = "_=";

pub const const_bytes_0: [:0]const u8 = amountBytes("0");
pub const const_bytes_1: [:0]const u8 = amountBytes("1");
pub const const_amount_0: [:0]const u8 = amountCount("0");
pub const const_amount_1: [:0]const u8 = amountCount("1");

const KV = struct { name: []const u8, symbol: [:0]const u8 };
pub const list: []const KV = blk: {
    var res: []const KV = &.{};
    inline for (@typeInfo(@This()).Struct.decls) |decl| {
        if (decl.name.len == 4 and
            decl.name[0] == 'l' and
            decl.name[1] == 'i' and
            decl.name[2] == 's' and
            decl.name[3] == 't') continue;
        if (decl.is_pub) {
            const value = @field(@This(), decl.name);
            if (@TypeOf(value) == [:0]const u8) {
                res = res ++ [1]KV{.{ .name = decl.name, .symbol = value }};
            }
        }
    }
    break :blk res;
};

fn metaFnName(comptime name: [:0]const u8) [:0]const u8 {
    return fieldAccess(meta_namespace, name);
}
fn machFnName(comptime name: [:0]const u8) [:0]const u8 {
    return fieldAccess(mach_namespace, name ++ word_type_name[1..]);
}
fn referenceFnName(comptime name: [:0]const u8) [:0]const u8 {
    return fieldAccess(reference_namespace, name);
}
fn containerFnName(comptime name: [:0]const u8) [:0]const u8 {
    return fieldAccess(container_namespace, name);
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
fn amountCount(comptime symbol: [:0]const u8) [:0]const u8 {
    return ".{.count=" ++ symbol ++ "}";
}
fn amountBytes(comptime symbol: [:0]const u8) [:0]const u8 {
    return ".{.bytes=" ++ symbol ++ "}";
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
    return "@offsetOf(" ++ type_name ++ ",\"" ++ field_name ++ "\")";
}
fn callPtrToInt(comptime symbol_ptr: [:0]const u8) [:0]const u8 {
    return "@ptrToInt(" ++ symbol_ptr ++ ")";
}
fn callSizeOf(comptime type_name: [:0]const u8) [:0]const u8 {
    return "@sizeOf(" ++ type_name ++ ")";
}
pub fn symbolName(symbol: [:0]const u8) ?[]const u8 {
    inline for (@typeInfo(@This()).Struct.decls) |decl| {
        const value = @field(@This(), decl.name);
        if (@TypeOf(value) == [:0]const u8) {
            if (decl.is_pub and symbol.ptr == value.ptr) {
                return decl.name;
            }
        }
    }
    return null;
}
