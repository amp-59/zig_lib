const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const detail = @import("./detail.zig");

pub const key = blk: {
    var res: [@typeInfo(Fn).Enum.fields.len]Fn = undefined;
    for (@typeInfo(Fn).Enum.fields, 0..) |field, index| {
        res[index] = @intToEnum(Fn, field.value);
    }
    break :blk res;
};
// zig fmt: on
pub fn get(comptime tag: Fn) *const Fn {
    comptime {
        for (key) |val| {
            if (val == tag) return &val;
        }
    }
}

pub const Fn = enum(u16) {
    allocate,
    deallocate,
    reallocate,
    resizeAbove,
    resizeBelow,
    resizeIncrement,
    resizeDecrement,

    pub fn hasCapability(alloc_fn_info: Fn, impl_variant: *const detail.More) bool {
        switch (alloc_fn_info) {
            .allocate, .deallocate => {
                return impl_variant.managers.allocatable;
            },
            .reallocate => {
                return impl_variant.managers.reallocatable;
            },
            .resizeAbove, .resizeBelow, .resizeIncrement, .resizeDecrement => {
                return impl_variant.managers.resizable;
            },
        }
    }
};
