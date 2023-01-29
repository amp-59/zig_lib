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
};

const type_spec = @import("./type_spec.zig").type_spec;
const impl_details = @import("./impl_details.zig").impl_details;

const Array = mem.StaticString(65536);

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
fn writeFns(array: *Array, impl_detail: *const gen.Detail) void {
    if (impl_detail.modes.stream) {
        writeFnSignatureStreamedByteCount(array, impl_detail);
        writeFnBodyStreamedByteCount(array, impl_detail);
        writeFnSignatureStreamedByteCount(array, impl_detail);
        writeFnBodyStreamedByteCount(array, impl_detail);
    }
    if (impl_detail.modes.resize) {
        writeFnSignatureDefinedByteCount(array, impl_detail);
        writeFnBodyDefinedByteCount(array, impl_detail);
        writeFnSignatureUndefinedByteCount(array, impl_detail);
        writeFnBodyUndefinedByteCount(array, impl_detail);
    }
}
pub fn generateFnDefinitions() void {
    var array: Array = .{};
    inline for (impl_details) |impl_detail| {
        writeFns(&array, &impl_detail);
    }
}
