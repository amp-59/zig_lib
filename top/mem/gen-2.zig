//! This stage generates reference implementations
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const gen = struct {
    usingnamespace @import("./gen-0.zig");
    usingnamespace @import("./gen-1.zig");
    const type_spec = @import("./type_spec.zig").type_spec;
    const impl_details = @import("./impl_details.zig").impl_details;
};
const Array = mem.StaticString(65536 * 2);
const ImplFnInfo = struct {
    tag: FnTag,
    val: Value,
    loc: Location,
    mut: Mutability,
    const FnTag = enum {
        define,
        seek,
        undefine,
        tell,
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
    };
    const Value = enum {
        Address,
        Offset,
    };
    const Location = enum {
        Relative,
        Absolute,
    };
    const Mutability = enum {
        Mutable,
        Immutable,
    };
    fn fnName(impl_fn_info: *const ImplFnInfo) []const u8 {
        return @tagName(impl_fn_info.tag);
    }
};
// zig fmt: off
const key: [18]ImplFnInfo = .{
    .{ .tag = .define,                      .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .seek,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .undefine,                    .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .tell,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .allocated_byte_address,      .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_address,        .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_address,     .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .undefined_byte_address,      .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unwritable_byte_address,     .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unallocated_byte_address,    .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .allocated_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .streamed_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_count,       .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .writable_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .undefined_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .defined_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .alignment,                   .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
};
// zig fmt: on

const impl_name: [:0]const u8 = "impl";
const impl_type_name: [:0]const u8 = "Implementation";
const impl_ptr_type_name: [:0]const u8 = "*" ++ impl_type_name;
const impl_const_ptr_type_name: [:0]const u8 = "*const " ++ impl_type_name;
const impl_param: [:0]const u8 = impl_name ++ ": " ++ impl_ptr_type_name;
const impl_const_param: [:0]const u8 = impl_name ++ ": " ++ impl_const_ptr_type_name;

const slave_name: [:0]const u8 = "allocator";
const slave_type_name: [:0]const u8 = "Allocator";
const slave_param: [:0]const u8 = slave_name ++ ": " ++ slave_type_name;

fn writeComma(array: *Array) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, ", ", array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(", ");
    }
}
fn writeArgument(array: *Array, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}

fn hasCapability(impl_detail: *const gen.Detail, fn_info: *const ImplFnInfo) bool {
    return switch (fn_info.tag) {
        .define,
        .undefine,
        .undefined_byte_address,
        .defined_byte_count,
        => impl_detail.modes.resize,
        .seek,
        .tell,
        .unstreamed_byte_address,
        .streamed_byte_count,
        => impl_detail.modes.stream,
        .alignment => !impl_detail.kind.automatic,
        else => true,
    };
}

fn writeFnSignatureAllocatedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUnstreamedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureAlignedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUndefinedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUnwritableByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUnallocatedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureAllocatedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureAlignedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureWritableByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureStreamedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUnstreamedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureUndefinedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureDefinedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnSignatureAlignment(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyAllocatedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUnstreamedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyAlignedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUndefinedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUnwritableByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUnallocatedByteAddress(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyAllocatedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyAlignedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyWritableByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyStreamedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUnstreamedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyUndefinedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyDefinedByteCount(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}
fn writeFnBodyAlignment(array: *Array, impl_detail: *const gen.Detail) void {
    _ = impl_detail;
    _ = array;
}

fn writeFnSignatureGeneric(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const ImplFnInfo) void {
    array.writeMany("inline fn ");
    array.writeMany(impl_fn_info.fnName());
    array.writeMany("(");
    if (impl_fn_info.mut == .Mutable) {
        writeArgument(array, impl_param);
        array.writeMany(") void {}\n");
    } else if (impl_detail.kind.parametric) {
        if (impl_fn_info.loc == .Absolute) {
            if (impl_fn_info.val == .Address) {
                writeArgument(array, slave_param);
            }
            if (impl_fn_info.val == .Offset) {
                writeArgument(array, impl_const_param);
                writeArgument(array, slave_param);
            }
        }
        if (impl_fn_info.mut == .Mutable) {
            array.writeMany(") void {}\n");
        } else {
            array.writeMany(") u64 {}\n");
        }
    } else {
        writeArgument(array, impl_const_param);
        array.writeMany(") u64 {}\n");
    }
}
fn writeFn(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const ImplFnInfo) void {
    if (!hasCapability(impl_detail, impl_fn_info)) {
        return;
    }
    writeFnSignatureGeneric(array, impl_detail, impl_fn_info);
}
pub fn generateFnDefinitions() void {
    @setEvalBranchQuota(~@as(u32, 0));
    var array: Array = .{};
    for (gen.impl_details) |impl_detail| {
        inline for (key) |impl_fn_info| {
            writeFn(&array, &impl_detail, &impl_fn_info);
        }
    }
    file.noexcept.write(2, array.readAll());
}
