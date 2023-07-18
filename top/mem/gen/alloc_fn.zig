const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");

const meta = @import("../../meta.zig");
const builtin = @import("../../builtin.zig");

const tok = @import("./tok.zig");
const types = @import("./types.zig");
const ptr_fn = @import("./ptr_fn.zig");

pub fn get(comptime tag: Fn) *const Fn {
    comptime {
        const key = blk: {
            var res: [@typeInfo(Fn).Enum.fields.len]Fn = undefined;
            for (@typeInfo(Fn).Enum.fields, 0..) |field, index| {
                res[index] = @as(Fn, @enumFromInt(field.value));
            }
            break :blk res;
        };
        for (key) |val| {
            if (val == tag) return &val;
        }
    }
}

pub const list = meta.tagList(Fn);

pub const Fn = enum(u16) {
    allocate,
    deallocate,
    reallocate,
    resizeAbove,
    resizeBelow,
    resizeIncrement,
    resizeDecrement,

    pub fn convert(alloc_fn_info: Fn) ptr_fn.Fn {
        switch (alloc_fn_info) {
            .allocate => return .allocate,
            .deallocate => return .deallocate,
            .reallocate => return .reallocate,
            .resizeAbove => return .resize,
            .resizeBelow => return .resize,
            .resizeIncrement => return .resize,
            .resizeDecrement => return .resize,
        }
    }
    pub fn hasCapability(alloc_fn_info: Fn, impl_variant: *const types.Implementation) bool {
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
    pub fn argList(alloc_fn_info: Fn, impl_kind: types.Kind, list_kind: gen.ListKind) gen.ArgList {
        var arg_list: gen.ArgList = .{
            .args = undefined,
            .args_len = 0,
            .kind = list_kind,
            .ret = alloc_fn_info.returnType(impl_kind),
        };
        const impl_type_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.source_impl_type_param,
            .Argument => tok.source_impl_type_name,
        };
        const impl_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.source_impl_ptr_param,
            .Argument => tok.impl_name,
        };
        arg_list.writeOne(impl_type_symbol);
        if (alloc_fn_info != .allocate) {
            arg_list.writeOne(impl_symbol);
        }
        return arg_list;
    }
    pub fn returnType(alloc_fn_info: Fn, impl_kind: types.Kind) [:0]const u8 {
        _ = impl_kind;
        switch (alloc_fn_info) {
            .allocate => return tok.source_impl_type_name,
            .deallocate,
            .reallocate,
            .resizeAbove,
            .resizeBelow,
            .resizeIncrement,
            .resizeDecrement,
            => {
                return tok.void_type_name;
            },
        }
    }
    pub fn writeSignature(alloc_fn_info: Fn, array: anytype, impl_kind: types.Kind) void {
        const arg_list: gen.ArgList = alloc_fn_info.argList(impl_kind, .Parameter);
        array.writeMany("pub inline fn ");
        array.writeMany(@tagName(alloc_fn_info));
        const ptr: *u8 = array.referOneUndefined();
        array.writeMany(@tagName(impl_kind));
        ptr.* -%= 'a' -% 'A';
        array.writeMany("(");
        const args: []const [:0]const u8 = arg_list.readAll();
        for (args) |arg| {
            array.writeMany(arg);
            array.writeMany(",");
        }
        if (args.len != 0) {
            array.undefine(1);
        }
        array.writeMany(")");
        array.writeMany(arg_list.ret);
    }
};

pub fn branchName(comptime any: anytype) []const u8 {
    const type_info: builtin.Type = @typeInfo(@TypeOf(any));
    const name: []const u8 = blk: {
        switch (@tagName(any)[0]) {
            'A'...'Z' => |c| {
                break :blk [1]u8{c + ('a' - 'A')} ++ @tagName(any)[1..];
            },
            else => {
                break :blk @tagName(any);
            },
        }
    };
    if (type_info == .Union) {
        return name ++ "." ++ branchName(@field(any, @tagName(any)));
    }
    if (type_info == .Enum) {
        return name;
    }
    return meta.empty;
}
