const zl = @import("zig_lib");
pub fn Slices(
    comptime T: type,
    comptime size: zl.builtin.Type.Pointer.Size,
    comptime src_sent_opt: ?T,
    comptime dest_sent_opt: ?T,
    comptime max_len: comptime_int,
    comptime splat: T,
) type {
    const Array = if (src_sent_opt) |s| [max_len:s]T else [max_len]T;
    return if (dest_sent_opt) |t| struct {
        pub const Runtime = struct {
            var array: Array = .{splat} ** max_len;
            const buf: switch (size) {
                .One => if (src_sent_opt) |s| *[max_len:s]T else *[max_len]T,
                .Slice => if (src_sent_opt) |s| [:s]T else []T,
                .Many => if (src_sent_opt) |s| [*:s]T else [*]T,
                .C => [*c]T,
            } = &array;
            pub fn sliceStart(start: anytype) void {
                _ = buf[start.. :t];
            }
            pub fn sliceEnd(start: anytype, end: anytype) void {
                _ = buf[start..end :t];
            }
            pub fn sliceLength(start: anytype, len: anytype) void {
                _ = buf[start..][0..len :t];
            }
        };
        pub const Comptime = struct {
            const array: Array = .{splat} ** max_len;
            const buf: switch (size) {
                .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                .C => [*c]const T,
            } = &array;
            pub fn sliceStart(start: anytype) void {
                _ = buf[start.. :t];
            }
            pub fn sliceEnd(start: anytype, end: anytype) void {
                _ = buf[start..end :t];
            }
            pub fn sliceLength(start: anytype, len: anytype) void {
                _ = buf[start..][0..len :t];
            }
        };
    } else struct {
        pub const Runtime = struct {
            var array: Array = .{splat} ** max_len;
            const buf: switch (size) {
                .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                .C => [*c]const T,
            } = &array;
            pub fn sliceLength(start: anytype, len: anytype) void {
                _ = buf[start..][0..len];
            }
            pub fn sliceStart(start: anytype) void {
                _ = buf[start..];
            }
            pub fn sliceEnd(start: anytype, end: anytype) void {
                _ = buf[start..end];
            }
        };
        pub const Comptime = struct {
            const array: Array = .{splat} ** max_len;
            const buf: switch (size) {
                .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                .C => [*c]const T,
            } = &array;
            pub fn sliceLength(start: anytype, len: anytype) void {
                _ = buf[start..][0..len];
            }
            pub fn sliceStart(start: anytype) void {
                _ = buf[start..];
            }
            pub fn sliceEnd(start: anytype, end: anytype) void {
                _ = buf[start..end];
            }
        };
    };
}
