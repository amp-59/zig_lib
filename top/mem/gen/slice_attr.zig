const zl = @import("../../../zig_lib.zig");
const types = @import("types.zig");
const config = @import("config.zig");
pub usingnamespace zl.start;
pub const logging_override = zl.debug.spec.logging.override.silent;
fn checkValidEnums(comptime T: type, v: T) bool {
    switch (@typeInfo(T)) {
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                if (!checkValidEnums(field.type, @field(v, field.name))) {
                    return false;
                }
            }
            return true;
        },
        else => {
            return zl.meta.isValidEnum(T, v);
        },
    }
}
fn generateSlices() []const types.Slice {
    @setRuntimeSafety(false);
    @setEvalBranchQuota(~@as(u32, 0));
    var perms: []const types.Slice = &.{};
    for (0..4) |op| {
        const op_tag: types.Slice.Tag = @enumFromInt(op);
        const LHSUInt = @Type(.{ .Int = .{
            .bits = @bitSizeOf(types.Slice.Parameters.SliceStart),
            .signedness = .unsigned,
        } });
        var lhs_int: LHSUInt = 0;
        while (true) {
            if (@addWithOverflow(lhs_int, 1)[1] != 0) break;
            lhs_int = @addWithOverflow(lhs_int, 1)[0];
            if (!zl.meta.isValidEnumInt(types.State1, lhs_int)) {
                continue;
            }
            const ptr: types.State1 = @enumFromInt(lhs_int);
            switch (@as(types.Slice.Tag, @enumFromInt(op))) {
                .slice_start => {
                    const RHSUInt = @Type(.{ .Int = .{
                        .bits = @bitSizeOf(types.Slice.Parameters.SliceStart),
                        .signedness = .unsigned,
                    } });
                    var rhs_int: RHSUInt = 0;
                    while (true) {
                        if (@addWithOverflow(rhs_int, 1)[1] != 0) break;
                        rhs_int = @addWithOverflow(rhs_int, 1)[0];
                        const vals: types.Slice.Parameters.SliceStart = @bitCast(rhs_int);
                        if (!checkValidEnums(types.Slice.Parameters.SliceStart, vals)) {
                            continue;
                        }
                        if (ptr == .known and vals.max == .variable) {
                            continue;
                        }
                        perms = perms ++ .{.{ .op = op_tag, .ptr = ptr, .args = .{ .slice_start = vals } }};
                    }
                },
                .slice_end => {
                    const RHSUInt = @Type(.{ .Int = .{
                        .bits = @bitSizeOf(types.Slice.Parameters.SliceEnd),
                        .signedness = .unsigned,
                    } });
                    var rhs_int: RHSUInt = 0;
                    while (true) {
                        if (@addWithOverflow(rhs_int, 1)[1] != 0) break;
                        rhs_int = @addWithOverflow(rhs_int, 1)[0];
                        const vals: types.Slice.Parameters.SliceEnd = @bitCast(rhs_int);
                        if (!checkValidEnums(types.Slice.Parameters.SliceEnd, vals)) {
                            continue;
                        }
                        if (ptr == .known and vals.max == .variable) {
                            continue;
                        }
                        perms = perms ++ .{.{ .op = op_tag, .ptr = ptr, .args = .{ .slice_end = vals } }};
                    }
                },
                .slice_sentinel => {
                    const RHSUInt = @Type(.{ .Int = .{
                        .bits = @bitSizeOf(types.Slice.Parameters.SliceSentinel),
                        .signedness = .unsigned,
                    } });
                    var rhs_int: RHSUInt = 0;
                    while (true) {
                        if (@addWithOverflow(rhs_int, 1)[1] != 0) break;
                        rhs_int = @addWithOverflow(rhs_int, 1)[0];
                        const vals: types.Slice.Parameters.SliceSentinel = @bitCast(rhs_int);
                        if (!checkValidEnums(types.Slice.Parameters.SliceSentinel, vals)) {
                            continue;
                        }
                        if (ptr == .known and vals.max == .variable) {
                            continue;
                        }
                        perms = perms ++ .{.{ .op = op_tag, .ptr = ptr, .args = .{ .slice_sentinel = vals } }};
                    }
                },
                .slice_length => {
                    const RHSUInt = @Type(.{ .Int = .{
                        .bits = @bitSizeOf(types.Slice.Parameters.SliceLength),
                        .signedness = .unsigned,
                    } });
                    var rhs_int: RHSUInt = 0;
                    while (true) {
                        if (@addWithOverflow(rhs_int, 1)[1] != 0) break;
                        rhs_int = @addWithOverflow(rhs_int, 1)[0];
                        const vals: types.Slice.Parameters.SliceLength = @bitCast(rhs_int);
                        if (!checkValidEnums(types.Slice.Parameters.SliceLength, vals)) {
                            continue;
                        }
                        if (ptr == .known and vals.max == .variable) {
                            continue;
                        }
                        perms = perms ++ .{.{ .op = op_tag, .ptr = ptr, .args = .{ .slice_length = vals } }};
                    }
                },
            }
        }
    }
    return perms;
}
fn writeSlices(buf: [*]u8, perms: []const types.Slice) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..22].* = "pub const slice_perms=".*;
    ptr += 22;
    ptr = types.SlicesFormat.write(ptr, perms);
    ptr[0..2].* = ";\n".*;
    return ptr + 2;
}
pub fn main() !void {
    var allocator: zl.mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    try zl.gen.truncateFile(.{ .child = types.Slice }, config.slice_kinds_path, comptime generateSlices());
}
