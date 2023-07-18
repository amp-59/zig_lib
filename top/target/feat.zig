const target = @import("../target.zig");
pub fn GenericFeatureSet(comptime Feature: type) type {
    const T = struct {
        pub fn featureSet(comptime features: []const Feature) target.Target.Set {
            var ret: target.Target.Set = .{ .ints = .{ 0, 0, 0, 0, 0 } };
            for (features) |feature| {
                ret.ints[@intFromEnum(feature) / @bitSizeOf(usize)] |= 1 << @intFromEnum(feature) % @bitSizeOf(usize);
            }
            return ret;
        }
    };
    return T;
}
