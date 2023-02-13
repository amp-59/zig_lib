const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
const expr = @import("./expr.zig");
const config = @import("./config.zig");
const interface = @import("./interface.zig");
const implementation = @import("./implementation.zig");

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = false;
pub const is_silent: bool = false;
pub const runtime_assertions: bool = false;

const Fn = interface.Fn;

pub const AssignmentOp = struct {
    op1: expr.Operand,
    op2: expr.Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op2);
    }
};
pub fn assignmentOp(op1: anytype, op2: anytype) AssignmentOp {
    return .{
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub const FieldAccessOp = struct {
    op1: expr.Operand,
    symbol: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(tok.period_asterisk_operator);
        array.writeMany(format.symbol);
    }
};
pub const ConstDeclOp = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: expr.Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.const_keyword);
        array.writeMany(format.var_name);
        array.writeMany(tok.colon_operator);
        array.writeMany(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op1);
        array.writeMany(tok.end_expression);
    }
};
pub const VarDeclOp = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: expr.Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.var_keyword);
        array.writeFormat(format.var_name);
        array.writeMany(tok.colon_operator);
        array.writeFormat(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op1);
        array.writeMany(tok.end_expression);
    }
};
fn setImplToMember(callable: *expr.Callable) void {
    callable.set("member", true);
    callable.subst(
        .{ .symbol = tok.impl_name },
        .{ .symbol = tok.array_name ++ "." ++ tok.impl_name },
    );
}
fn writeFunctionBodyPrimary(array: *gen.String, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const is_count: bool =
        ctn_fn_info.val == .Count or
        ctn_fn_info.val == .CountWithSentinel;
    const is_many: bool =
        ctn_fn_info.val == .Many or
        ctn_fn_info.val == .ManyWithSentinel;
    const is_write: bool =
        ctn_fn_info.kind == .write or
        ctn_fn_info.kind == .append;
    var __at_fn_call: expr.Callable = expr.Callable.init(ctn_detail, interface.get(.__at));
    var __ad_fn_call: expr.Callable = expr.Callable.init(ctn_detail, interface.get(.__ad));
    var __back_fn_call: expr.Callable = expr.Callable.init(ctn_detail, interface.get(.__back));
    var __behind_fn_call: expr.Callable = expr.Callable.init(ctn_detail, interface.get(.__behind));
    var aligned_byte_address_call: expr.Callable = expr.Callable.init(
        ctn_detail.more(),
        implementation.get(.aligned_byte_address),
    );
    setImplToMember(&aligned_byte_address_call);
    var undefined_byte_address_call: expr.Callable = expr.Callable.init(
        ctn_detail.more(),
        implementation.get(.undefined_byte_address),
    );
    setImplToMember(&undefined_byte_address_call);
    var unstreamed_byte_address_call: expr.Callable = expr.Callable.init(
        ctn_detail.more(),
        implementation.get(.unstreamed_byte_address),
    );
    setImplToMember(&unstreamed_byte_address_call);
    const location_call: *expr.Callable = switch (ctn_fn_info.loc) {
        .AnyDefined => &__at_fn_call,
        .AnyUndefined => &__ad_fn_call,
        .Back => &__back_fn_call,
        .Behind => &__behind_fn_call,
        .AllDefined => &aligned_byte_address_call,
        .AllUndefined => &undefined_byte_address_call,
        .Next => &undefined_byte_address_call,
        .Ahead => &unstreamed_byte_address_call,
    };
    var len_fn_call: expr.Callable =
        expr.Callable.init(ctn_detail, interface.get(.len));
    var avail_fn_call: expr.Callable =
        expr.Callable.init(ctn_detail, interface.get(.avail));
    _ = avail_fn_call;
    var __len_fn_call: expr.Callable =
        expr.Callable.init(ctn_detail, interface.get(.__len));
    _ = __len_fn_call;
    var __rem_fn_call: expr.Callable =
        expr.Callable.init(ctn_detail, interface.get(.__rem));
    _ = __rem_fn_call;

    const length_call: *expr.Callable = &len_fn_call;
    const offset_name_op: expr.Operand = .{ .symbol = tok.offset_name };
    const location_call_op: expr.Operand = location_call.op();
    const length_call_op: expr.Operand = length_call.op();
    const length_op: expr.Operand = blk: {
        if (is_write) {
            if (is_count) {
                break :blk .{ .symbol = tok.write_count_name };
            }
            if (is_many) {
                break :blk .{ .symbol = tok.many_values_len };
            }
        }
        break :blk length_call_op;
    };
    const pointer_one_call: expr.FnCall2 = .{
        .symbol = tok.intr_pointer_one_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = location_call_op,
    };
    const pointer_many_call: expr.FnCall3 = .{
        .symbol = tok.intr_pointer_many_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = location_call_op,
        .op3 = length_op,
    };
    const pointer_count_call: expr.FnCall3 = .{
        .symbol = tok.intr_pointer_count_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = location_call_op,
        .op3 = length_op,
    };
    const pointer_many_with_sentinel_call: expr.FnCall4 = .{
        .symbol = tok.intr_pointer_many_with_sentinel_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = location_call_op,
        .op3 = length_op,
        .op4 = .{ .symbol = tok.sentinel_name },
    };
    const pointer_count_with_sentinel_call: expr.FnCall4 = .{
        .symbol = tok.intr_pointer_count_with_sentinel_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = location_call_op,
        .op3 = length_op,
        .op4 = .{ .symbol = tok.sentinel_name },
    };
    const write_format: expr.FnCall3 = .{
        .symbol = tok.write_format_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = .{ .symbol = tok.array_name },
        .op3 = .{ .symbol = tok.format_name },
    };
    const write_fields: expr.FnCall4 = .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_fields_structured_fn_name
        else
            tok.write_fields_unstructured_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = .{ .symbol = tok.reinterpret_spec_name },
        .op3 = .{ .symbol = tok.array_name },
        .op4 = .{ .symbol = tok.fields_name },
    };
    const write_args: expr.FnCall4 = .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_args_structured_fn_name
        else
            tok.write_args_unstructured_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = .{ .symbol = tok.reinterpret_spec_name },
        .op3 = .{ .symbol = tok.array_name },
        .op4 = .{ .symbol = tok.args_name },
    };
    const write_any: expr.FnCall4 = .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_any_structured_fn_name
        else
            tok.write_any_unstructured_fn_name,
        .op1 = .{ .symbol = tok.child_type_name },
        .op2 = .{ .symbol = tok.reinterpret_spec_name },
        .op3 = .{ .symbol = tok.array_name },
        .op4 = .{ .symbol = tok.any_name },
    };
    switch (ctn_fn_info.kind) {
        .refer => {
            array.writeMany(tok.return_keyword);
            if (ctn_fn_info.val == .One) {
                array.writeFormat(pointer_one_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Many) {
                array.writeFormat(pointer_many_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .ManyWithSentinel) {
                array.writeFormat(pointer_many_with_sentinel_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Count) {
                array.writeFormat(pointer_count_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .CountWithSentinel) {
                array.writeFormat(pointer_count_with_sentinel_call);
                return array.writeMany(tok.end_expression);
            }
        },
        .read => {
            location_call.subst(offset_name_op, switch (ctn_fn_info.val) {
                .One => .{ .constant = 1 },
                else => .{ .symbol = tok.read_count_name },
            });
            array.writeMany(tok.return_keyword);
            const deref_pointer_one_call: expr.Parentheses = .{
                .op = .{ .call2 = &pointer_one_call },
                .rhs = tok.period_asterisk_operator,
            };
            const deref_pointer_count_call: expr.Parentheses = .{
                .op = .{ .call3 = &pointer_count_call },
                .rhs = tok.period_asterisk_operator,
            };
            const deref_pointer_count_with_sentinel_call: expr.Parentheses = .{
                .op = .{ .call4 = &pointer_count_with_sentinel_call },
                .rhs = tok.period_asterisk_operator,
            };
            if (ctn_fn_info.val == .One) {
                array.writeFormat(deref_pointer_one_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Many) {
                array.writeFormat(pointer_many_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .ManyWithSentinel) {
                array.writeFormat(pointer_many_with_sentinel_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Count) {
                array.writeFormat(deref_pointer_count_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .CountWithSentinel) {
                array.writeFormat(deref_pointer_count_with_sentinel_call);
                return array.writeMany(tok.end_expression);
            }
        },
        .append => {
            if (ctn_fn_info.kind == .append) {
                const length_format: expr.FnCall2 = .{
                    .symbol = tok.length_format_fn_name,
                    .op1 = .{ .symbol = tok.child_type_name },
                    .op2 = .{ .symbol = tok.format_name },
                };
                const length_fields: expr.FnCall3 = .{
                    .symbol = tok.length_fields_fn_name,
                    .op1 = .{ .symbol = tok.child_type_name },
                    .op2 = .{ .symbol = tok.reinterpret_spec_name },
                    .op3 = .{ .symbol = tok.fields_name },
                };
                const length_args: expr.FnCall3 = .{
                    .symbol = tok.length_args_fn_name,
                    .op1 = .{ .symbol = tok.child_type_name },
                    .op2 = .{ .symbol = tok.reinterpret_spec_name },
                    .op3 = .{ .symbol = tok.args_name },
                };
                const length_any: expr.FnCall3 = .{
                    .symbol = tok.length_any_fn_name,
                    .op1 = .{ .symbol = tok.child_type_name },
                    .op2 = .{ .symbol = tok.reinterpret_spec_name },
                    .op3 = .{ .symbol = tok.any_name },
                };
                const write_one_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeOne),
                };
                const write_count_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeCount),
                };
                const write_many_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeMany),
                };
                const write_format_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeFormat),
                };
                const write_args_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeArgs),
                };
                const write_fields_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeFields),
                };
                const write_any_intr_call: expr.FnCallIntr = .{
                    .ctn_detail = ctn_detail,
                    .ctn_fn_info = interface.get(.writeAny),
                };
                var increment_fn_call: expr.Callable =
                    expr.Callable.init(ctn_detail, interface.get(.increment));
                if (ctn_fn_info.tag == .appendOne) {
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_one_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendCount) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .symbol = tok.write_count_name },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_count_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendMany) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .symbol = tok.many_values_len },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_many_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendFormat) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .call2 = &length_format },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_format_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendArgs) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .call3 = &length_args },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_args_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendFields) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .call3 = &length_fields },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_fields_intr_call);
                    return array.writeMany(tok.end_expression);
                }
                if (ctn_fn_info.tag == .appendAny) {
                    increment_fn_call.subst(
                        offset_name_op,
                        .{ .call3 = &length_any },
                    );
                    array.writeFormat(increment_fn_call.op());
                    array.writeMany(tok.end_expression);
                    array.writeFormat(write_any_intr_call);
                    return array.writeMany(tok.end_expression);
                }
            }
        },
        .write => {
            if (ctn_fn_info.val == .One) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {
                    array.writeFormat(pointer_one_call);
                    array.writeMany(".* = value");
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeMany(tok.write_one_impl_fn_name ++ "(");
                    gen.writeArgument(array, tok.child_type_name);
                    gen.writeComma(array);
                    array.writeFormat(location_call_op);
                    gen.writeArgument(array, tok.value_name);
                    array.writeMany(")");
                    return array.writeMany(tok.end_expression);
                }
            }
            if (ctn_fn_info.val == .Many) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {
                    array.writeMany("for (" ++ tok.many_values_name ++ ") |" ++ tok.value_name ++ ", " ++ tok.loop_index_name ++ "| ");
                    array.writeFormat(pointer_many_call);
                    array.writeMany(".* = " ++ tok.value_name);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeMany(tok.write_many_impl_fn_name ++ "(");
                    gen.writeArgument(array, tok.child_type_name);
                    gen.writeComma(array);
                    array.writeFormat(location_call_op);
                    gen.writeArgument(array, tok.many_values_name);
                    array.writeMany(")");
                    return array.writeMany(tok.end_expression);
                }
            }
            if (ctn_fn_info.val == .Count) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {
                    array.writeMany("for (" ++ tok.count_values_name ++ ") |" ++ tok.value_name ++ ", " ++ tok.loop_index_name ++ "| ");
                    array.writeFormat(pointer_count_call);
                    array.writeMany(".* = " ++ tok.value_name);
                    return array.writeMany(tok.end_expression);
                } else {
                    if (config.implement_count_as_one) {
                        array.writeMany(tok.write_one_impl_name ++ "([" ++ tok.write_count_name ++ "]");
                        array.writeMany(tok.child_type_name);
                        gen.writeComma(array);
                        array.writeFormat(location_call_op);
                    } else {
                        array.writeMany(tok.write_count_impl_fn_name ++ "(");
                        gen.writeArgument(array, tok.child_type_name);
                        gen.writeComma(array);
                        array.writeFormat(location_call_op);
                        gen.writeArgument(array, tok.write_count_name);
                    }
                    gen.writeArgument(array, tok.count_values_name);
                    array.writeMany(")");
                    return array.writeMany(tok.end_expression);
                }
            }
            if (ctn_fn_info.val == .Format) {
                array.writeFormat(write_format);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Fields) {
                array.writeFormat(write_fields);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Args) {
                array.writeFormat(write_args);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Any) {
                array.writeFormat(write_any);
                return array.writeMany(tok.end_expression);
            }
        },
        else => unreachable,
    }
}
fn functionBodyUndefinedNotice(ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    array.writeMany("function body undefined: ");
    array.writeMany(ctn_fn_info.fnName());
    array.writeOne(' ');
    ctn_detail.writeContainerName(&array);
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn writeFunctionBodyGeneric(array: *gen.String, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const is_read: bool =
        ctn_fn_info.kind == .read or
        ctn_fn_info.kind == .refer;
    const is_write: bool =
        ctn_fn_info.kind == .write or
        ctn_fn_info.kind == .append;
    const is_primary: bool = is_read or is_write;
    if (is_primary) {
        return writeFunctionBodyPrimary(array, ctn_detail, ctn_fn_info);
    }
    // functionBodyUndefinedNotice(ctn_detail, ctn_fn_info);
}
fn writeFunctions(array: *gen.String, ctn_detail: *const out.DetailLess) void {
    for (interface.key) |*ctn_fn_info| {
        if (!ctn_fn_info.hasCapability(ctn_detail)) {
            continue;
        }
        ctn_fn_info.writeSignature(array, ctn_detail);
        array.writeMany(interface.getReturnType(ctn_detail, ctn_fn_info));
        array.writeMany("{\n");
        writeFunctionBodyGeneric(array, ctn_detail, ctn_fn_info);
        array.writeMany("}\n");
    }
}
fn writeDeclarations(array: *gen.String, ctn_detail: *const out.DetailLess) void {
    array.writeMany("const " ++ tok.array_type_name ++ " = @This();\n");
    if (ctn_detail.layouts.structured) {
        array.writeMany("const " ++ tok.child_type_name ++ " = spec." ++ tok.child_type_name ++ ";\n");
    }
    if (ctn_detail.kinds.dynamic or
        ctn_detail.kinds.parametric or
        ctn_detail.kinds.static)
    {
        array.writeMany("const " ++ tok.allocator_type_name ++ " = spec." ++ tok.allocator_type_name ++ ";\n");
    }
    const deduce_impl_type_call: expr.FnCall1 = .{
        .symbol = "spec.deduce",
        .op1 = .{ .symbol = "params.options" },
    };
    const impl_type_decl: ConstDeclOp = .{
        .var_name = tok.impl_type_name,
        .type_name = tok.type_type_name,
        .op1 = .{ .call1 = &deduce_impl_type_call },
    };
    array.writeFormat(impl_type_decl);
}
fn writeComptimeFieldInternal(array: *gen.String, fn_tag: Fn.Tag, args: *const gen.ArgList) void {
    if (args.len() == 0) {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Static = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
    if (args.len() == 1 and
        args.readOneAt(0).ptr == tok.slave_specifier_name.ptr)
    {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Slave = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
}
inline fn writeFields(array: *gen.String) void {
    array.writeMany(tok.impl_field);
    array.writeMany(tok.end_item);
}
inline fn writeTypeFunction(array: *gen.String, ctn_detail: *const out.DetailLess) void {
    array.writeMany("pub fn ");
    ctn_detail.writeContainerName(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ": anytype) type {\nreturn (struct {\n");
    {
        writeFields(array);
        writeDeclarations(array, ctn_detail);
        writeFunctions(array, ctn_detail);
    }
    array.writeMany("});\n}\n");
}

pub fn generateContainers() !void {
    var array: gen.String = undefined;
    array.undefineAll();

    var ctn_index: u16 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const ctn_group: []const u16 = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
        writeTypeFunction(&array, out.impl_variants[ctn_group[0]].less());
    }
    gen.appendSourceFile(&array, "container.zig");
}

pub const main = generateContainers;
