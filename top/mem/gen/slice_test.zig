const zl = @import("../../../zig_lib.zig");
const types = @import("types.zig");
const config = @import("config.zig");
pub usingnamespace zl.start;
const Values = struct {
    start: isize = 1,
    len: isize = 1,
    end: isize = 2,
    max: isize = 4,
    sentinel: isize = 0,
};
/// Undefined behaviour checks. These are the checks that might appear at
/// runtime or compile time.
const Checks = packed struct(u8) {
    ///  [0] start < max    ;; slice_start
    ///                     ;; `start` or `max` are runtime-known
    start_lt_max: types.State3 = .unknown,
    ///  [1] start <= end   ;; slice_end
    ///                     ;; `start` or `end` are runtime-known
    start_le_end: types.State3 = .unknown,
    ///  [2] end <= max     ;; slice_end, slice_length
    ///                     ;; `end` or `max` are runtime-known
    end_le_max: types.State3 = .unknown,
    eq_sentinel: types.State3 = .unknown,
};
fn writeSEML(buf: [*]u8, perm: *types.Slice) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, @tagName(perm.op));
    ptr[0] = '_';
    ptr += 1;
    switch (perm.op) {
        .slice_start => {
            ptr = writeStartAbbrev(ptr, perm.args.slice_start.start);
            ptr = writeMaxAbbrev(ptr, perm.args.slice_start.max);
        },
        .slice_end => {
            ptr = writeStartAbbrev(ptr, perm.args.slice_end.start);
            ptr = writeEndAbbrev(ptr, perm.args.slice_end.end);
            ptr = writeMaxAbbrev(ptr, perm.args.slice_end.max);
        },
        .slice_sentinel => {
            ptr = writeStartAbbrev(ptr, perm.args.slice_end.start);
            ptr = writeEndAbbrev(ptr, perm.args.slice_end.end);
            ptr = writeMaxAbbrev(ptr, perm.args.slice_end.max);
            ptr = writeSentAbbrev(ptr, .known);
        },
        .slice_length => {
            ptr = writeStartAbbrev(ptr, perm.args.slice_length.start);
            ptr = writeLenAbbrev(ptr, perm.args.slice_length.len);
            ptr = writeMaxAbbrev(ptr, perm.args.slice_length.max);
            ptr = writeSentAbbrev(ptr, perm.args.slice_length.sent);
        },
    }
    return ptr;
}

fn writeStartAbbrev(buf: [*]u8, start: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    buf[0] = switch (start) {
        .known => 'S',
        .variable => 's',
    };
    return buf + 1;
}
fn writeSentAbbrev(buf: [*]u8, start: types.State2) [*]u8 {
    @setRuntimeSafety(false);
    buf[0] = switch (start) {
        .known => 'Z',
        .unknown => return buf,
    };
    return buf + 1;
}
fn writeLenAbbrev(buf: [*]u8, len: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    buf[0] = switch (len) {
        .known => 'L',
        .variable => 'l',
    };
    return buf + 1;
}
fn writeEndAbbrev(buf: [*]u8, end: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    buf[0] = switch (end) {
        .known => 'E',
        .variable => 'e',
    };
    return buf + 1;
}
fn writeMaxAbbrev(buf: [*]u8, max: anytype) [*]u8 {
    @setRuntimeSafety(false);
    buf[0] = switch (max) {
        .known => 'M',
        .variable => 'm',
        .unknown => return buf,
    };
    return buf + 1;
}
fn writePtr(buf: [*]u8, mem: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (mem) {
        .known => ptr = zl.fmt.strcpyEqu(ptr, "const buf:[Ns.max_init]Ns.T=.{0}**Ns.max_init;\n"),
        .variable => ptr = zl.fmt.strcpyEqu(ptr, "var buf:[Ns.max_init]Ns.T=.{0}**Ns.max_init;\n"),
    }
    return ptr;
}
fn writeMax(buf: [*]u8, max: types.State3) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (max) {
        .known => ptr = zl.fmt.strcpyEqu(ptr, "const ptr:*const [Ns.max_init]Ns.T=&buf;\n"),
        .variable => ptr = zl.fmt.strcpyEqu(ptr, "const ptr:[]const Ns.T=&buf;\n"),
        .unknown => ptr = zl.fmt.strcpyEqu(ptr, "const ptr:[*]const Ns.T=&buf;\n"),
    }
    return ptr;
}
fn writeEnd(buf: [*]u8, end: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (end) {
        .known => {
            ptr = zl.fmt.strcpyEqu(ptr, "const end:comptime_int=Ns.end_init;\n");
        },
        .variable => {
            ptr = zl.fmt.strcpyEqu(ptr, "var end:usize=0;\n");
            ptr = zl.fmt.strcpyEqu(ptr, "end+%=Ns.end_init;\n");
        },
    }
    return ptr;
}
fn writeStart(buf: [*]u8, start: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (start) {
        .known => {
            ptr = zl.fmt.strcpyEqu(ptr, "const start:comptime_int=Ns.start_init;\n");
        },
        .variable => {
            ptr = zl.fmt.strcpyEqu(ptr, "var start:usize=0;\n");
            ptr = zl.fmt.strcpyEqu(ptr, "start+%=Ns.start_init;\n");
        },
    }
    return ptr;
}
fn writeLen(buf: [*]u8, len: types.State1) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (len) {
        .known => {
            ptr = zl.fmt.strcpyEqu(ptr, "const len:comptime_int=Ns.len_init;\n");
        },
        .variable => {
            ptr = zl.fmt.strcpyEqu(ptr, "var len:usize=0;\n");
            ptr = zl.fmt.strcpyEqu(ptr, "len+%=Ns.len_init;\n");
        },
    }
    return ptr;
}
fn writeFnSig(buf: [*]u8, perm: *types.Slice) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr[0..7].* = "pub fn ".*;
    ptr += 7;
    ptr = writeFunctionName(ptr, perm);
    ptr[0..25].* = "(comptime Ns: type)void{\n".*;
    ptr += 25;
    return ptr;
}
fn writeOp(buf: [*]u8, perm: *types.Slice) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    switch (perm.op) {
        .slice_start => {
            ptr = zl.fmt.strcpyEqu(ptr, "_=ptr[start..];\n");
        },
        .slice_end => {
            ptr = zl.fmt.strcpyEqu(ptr, "_=ptr[start..end];\n");
        },
        .slice_sentinel => {
            ptr = zl.fmt.strcpyEqu(ptr, "_=ptr[start..end:Ns.sentinel];\n");
        },
        .slice_length => {
            if (perm.args.slice_length.sent != .unknown) {
                ptr = zl.fmt.strcpyEqu(ptr, "_=ptr[start..][0..len:Ns.sentinel];\n");
            } else {
                ptr = zl.fmt.strcpyEqu(ptr, "_=ptr[start..][0..len];\n");
            }
        },
    }
    return ptr;
}
fn writeFunctionName(buf: [*]u8, perm: *types.Slice) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, if (perm.ptr == .known) "comptime_" else "runtime_");
    return writeSEML(ptr, perm);
}
fn writeFileName(buf: [*]u8, perm: *types.Slice, case: []const u8) [:0]const u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, config.test_safety_slice_dir);
    ptr[0] = '/';
    ptr = writeFunctionName(ptr + 1, perm);
    ptr = zl.fmt.strcpyEqu(ptr, case);
    ptr = zl.fmt.strcpyEqu(ptr, ".zig");
    ptr[0] = 0;
    return zl.mem.terminate(buf, 0);
}
fn writeSlice(buf: [*]u8, perm: *types.Slice) !void {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr = writeFnSig(ptr, perm);
    switch (perm.op) {
        .slice_start => {
            ptr = writePtr(ptr, perm.ptr);
            ptr = writeMax(ptr, perm.args.slice_start.max);
            ptr = writeStart(ptr, perm.args.slice_start.start);
        },
        .slice_end => {
            ptr = writePtr(ptr, perm.ptr);
            ptr = writeMax(ptr, perm.args.slice_end.max);
            ptr = writeStart(ptr, perm.args.slice_end.start);
            ptr = writeEnd(ptr, perm.args.slice_end.end);
        },
        .slice_sentinel => {
            ptr = writePtr(ptr, perm.ptr);
            ptr = writeMax(ptr, perm.args.slice_sentinel.max);
            ptr = writeStart(ptr, perm.args.slice_sentinel.start);
            ptr = writeEnd(ptr, perm.args.slice_sentinel.end);
        },
        .slice_length => {
            ptr = writePtr(ptr, perm.ptr);
            ptr = writeMax(ptr, perm.args.slice_length.max);
            ptr = writeStart(ptr, perm.args.slice_length.start);
            ptr = writeLen(ptr, perm.args.slice_length.len);
        },
    }
    ptr = writeOp(ptr, perm);
    ptr[0..2].* = "}\n".*;
    ptr += 2;
    try zl.gen.appendFile(.{}, config.test_safety_slice_common_path, zl.fmt.slice(ptr, buf));
    var checks: Checks = .{};
    var buf1: [4096]u8 = undefined;
    var buf2: [4096]u8 = undefined;
    ptr = &buf2;
    switch (perm.op) {
        .slice_start => {
            checks.start_lt_max = cmb(perm.args.slice_start.max, perm.args.slice_start.start);
        },
        .slice_end => {
            checks.start_le_end = cmb(perm.args.slice_end.start, perm.args.slice_end.end);
            checks.end_le_max = cmb(perm.args.slice_end.end, perm.args.slice_end.max);
        },
        .slice_sentinel => {
            checks.start_le_end = cmb(perm.args.slice_sentinel.start, perm.args.slice_sentinel.end);
            checks.end_le_max = cmb(perm.args.slice_sentinel.end, perm.args.slice_sentinel.max);
            checks.eq_sentinel = cmb(perm.ptr, perm.args.slice_sentinel.end);
        },
        .slice_length => {
            const end: types.State3 = cmb(perm.args.slice_length.start, perm.args.slice_length.len);
            const mem: types.State3 = cmb(perm.ptr, perm.args.slice_length.sent);
            checks.end_le_max = cmb(end, perm.args.slice_length.max);
            checks.eq_sentinel = cmb(end, mem);
        },
    }
    switch (checks.start_lt_max) {
        .known => {
            ptr = try writeVals(ptr, .{ .start = 5, .max = 4 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "comptime{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = zl.fmt.strcpyEqu(ptr, "(@This());}\n");
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_start_not_below_max_compile_error");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .variable => if (perm.ptr != .known) {
            ptr = try writeVals(ptr, .{ .start = 5, .max = 4 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "pub usingnamespace common.panic_fn(.accessed_out_of_bounds);\n");
            ptr = zl.fmt.strcpyEqu(ptr, "pub fn main()void{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = writeTestFailed(ptr);
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_start_not_below_max_panic");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .unknown => {},
    }
    switch (checks.end_le_max) {
        .known => {
            ptr = try writeVals(ptr, .{ .max = 4, .end = 5 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "comptime{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = zl.fmt.strcpyEqu(ptr, "(@This());}\n");
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_end_above_max_compile_error");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .variable => {
            ptr = try writeVals(ptr, .{ .max = 4, .end = 5 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "pub usingnamespace common.panic_fn(.accessed_out_of_bounds);\n");
            ptr = zl.fmt.strcpyEqu(ptr, "pub fn main()void{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = writeTestFailed(ptr);
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_end_above_max_panic");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .unknown => {},
    }
    switch (checks.start_le_end) {
        .known => {
            ptr = try writeVals(ptr, .{ .start = 3, .end = 2 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "comptime{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = zl.fmt.strcpyEqu(ptr, "(@This());}\n");
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_start_above_end_compile_error");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .variable => {
            ptr = try writeVals(ptr, .{ .start = 3, .end = 2 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "pub usingnamespace common.panic_fn(.accessed_out_of_order);\n");
            ptr = zl.fmt.strcpyEqu(ptr, "pub fn main()void{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = writeTestFailed(ptr);
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_start_above_end_panic");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .unknown => {},
    }
    switch (checks.eq_sentinel) {
        .known => {
            ptr = try writeVals(ptr, .{ .sentinel = 1 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "comptime{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = zl.fmt.strcpyEqu(ptr, "(@This());}\n");
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_start_above_end_compile_error");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .variable => {
            ptr = try writeVals(ptr, .{ .sentinel = 1 });
            ptr = writeImports(ptr);
            ptr = zl.fmt.strcpyEqu(ptr, "pub usingnamespace common.panic_fn(.mismatched_sentinel);\n");
            ptr = zl.fmt.strcpyEqu(ptr, "pub fn main()void{\ntests.");
            ptr = writeFunctionName(ptr, perm);
            ptr = writeTestFailed(ptr);
            const pathname: [:0]const u8 = writeFileName(&buf1, perm, "_sentinel_not_equal_panic");
            try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, &buf2));
            ptr = &buf2;
        },
        .unknown => {},
    }
}
fn writeImports(buf: [*]u8) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "const std=@import(\"std\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const common=@import(\"../common.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const tests=@import(\"common.zig\");\n");
    return ptr;
}
fn writeTestFailed(buf: [*]u8) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "(@This());\n");
    ptr = zl.fmt.strcpyEqu(ptr, "std.debug.print(\"FAILED\\n\",.{});\n");
    ptr = zl.fmt.strcpyEqu(ptr, "std.process.exit(1);\n");
    ptr = zl.fmt.strcpyEqu(ptr, "}\n");
    return ptr;
}
fn writeVals(buf: [*]u8, in: Values) ![*]u8 {
    var vals: Values = in;
    vals.len = in.end -% in.start;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "pub const T = usize;\n");
    ptr[0..21].* = "pub const start_init=".*;
    ptr = zl.fmt.Idsize.write(ptr + 21, vals.start);
    ptr[0..2].* = ";\n".*;
    ptr[2..21].* = "pub const end_init=".*;
    ptr = zl.fmt.Idsize.write(ptr + 21, vals.end);
    ptr[0..2].* = ";\n".*;
    ptr[2..21].* = "pub const len_init=".*;
    ptr = zl.fmt.Idsize.write(ptr + 21, vals.len);
    ptr[0..2].* = ";\n".*;
    ptr[2..21].* = "pub const max_init=".*;
    ptr = zl.fmt.Idsize.write(ptr + 21, vals.max);
    ptr[0..2].* = ";\n".*;
    ptr[2..21].* = "pub const sentinel=".*;
    ptr = zl.fmt.Idsize.write(ptr + 21, vals.sentinel);
    ptr[0..2].* = ";\n".*;
    return ptr + 2;
}
fn cmb(any1: anytype, any2: anytype) types.State3 {
    return combined(
        @enumFromInt(@intFromEnum(any1)),
        @enumFromInt(@intFromEnum(any2)),
    );
}
fn combined(arg1: types.State3, arg2: types.State3) types.State3 {
    if (arg1 == .known and arg2 == .known) {
        return .known;
    }
    if ((arg1 == .variable and arg2 != .unknown) or
        (arg2 == .variable and arg1 != .unknown))
    {
        return .variable;
    }
    return .unknown;
}
fn writeSlices(
    buf: [*]u8,
    _: *zl.mem.SimpleAllocator,
    comptime T: type,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..7].* = "Slices(".*;
    ptr = zl.fmt.strcpyEqu2(ptr + 7, @typeName(T));
    ptr[0] = ',';
    ptr = zl.fmt.AnyFormat(.{}, zl.builtin.Type.Pointer.Size).write(ptr + 1, size);
    ptr[0] = ',';
    ptr = zl.fmt.OptionalFormat(.{}, ?T).write(ptr + 1, src_sent_opt);
    ptr[0] = ',';
    ptr = zl.fmt.OptionalFormat(.{}, ?T).write(ptr + 1, dest_sent_opt);
    ptr[0] = ',';
    ptr = zl.fmt.Udsize.write(ptr + 1, max);
    ptr[0] = ',';
    ptr = zl.fmt.AnyFormat(.{}, T).write(ptr + 1, splat);
    ptr[0..2].* = ").".*;
    return zl.fmt.strcpyEqu(ptr + 2, time);
}
fn writeAs(buf: [*]u8, any: anytype) [*]u8 {
    var ptr: [*]u8 = buf;
    if (@TypeOf(any) == comptime_int) {
        return zl.fmt.Udsize.write(ptr, any);
    } else {
        ptr[0..4].* = "@as(".*;
        ptr = zl.fmt.strcpyEqu2(ptr + 4, @typeName(@TypeOf(any)));
        ptr[0] = ',';
        ptr = zl.fmt.Udsize.write(ptr + 1, any);
        ptr[0] = ')';
        return ptr + 1;
    }
}
fn writeSliceStart(
    buf: [*]u8,
    start: anytype,
) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..12].* = ".sliceStart(".*;
    ptr = writeAs(ptr + 12, start);
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeSliceLength(
    buf: [*]u8,
    start: anytype,
    len: anytype,
) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..13].* = ".sliceLength(".*;
    ptr = writeAs(ptr + 13, start);
    ptr[0] = ',';
    ptr = writeAs(ptr + 1, len);
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeSliceEnd(
    buf: [*]u8,
    start: anytype,
    end: anytype,
) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..10].* = ".sliceEnd(".*;
    ptr = writeAs(ptr + 10, start);
    ptr[0] = ',';
    ptr = writeAs(ptr + 1, end);
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn createFile(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    time: []const u8,
    case_no: usize,
    res: Result,
) [:0]const u8 {
    const buf: *[4096]u8 = allocator.create([4096]u8);
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, config.test_safety_slice_dir);
    ptr[0] = '/';
    ptr = zl.fmt.strcpyEqu(ptr + 1, time);
    ptr = zl.fmt.strcpyEqu(ptr, "_slice_");
    ptr = zl.fmt.Udsize.write(ptr, case_no);
    ptr = zl.fmt.strcpyEqu(ptr, ".zig");
    const len: usize = zl.fmt.strlen(ptr, buf);
    buf[len] = 0;
    files.ptr[files.len] = .{ .pathname = buf[0..len :0], .res = res };
    files.len +%= 1;
    return buf[0..len :0];
}
fn writeImports2(buf: [*]u8) [*]u8 {
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "const std=@import(\"std\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const common=@import(\"common.zig\");\n");
    return zl.fmt.strcpyEqu(ptr, "const Slices=common.Slices;\n");
}
fn writeCompileErrorFileStart(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr1: [*]u8 = buf1;
    ptr1 = writeImports2(ptr1);
    if (zl.mem.testEqualString("Comptime", time)) {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "comptime {\n");
    } else {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "export fn entry()void{\n");
    }
    ptr1 = writeSlices(ptr1, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr1 = writeSliceStart(ptr1, start);
    ptr1 = zl.fmt.strcpyEqu(ptr1, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr1, buf1));
}
fn writeRuntimeSafetyPanicFileStart(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf2: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr2: [*]u8 = buf2;
    ptr2 = writeImports2(ptr2);
    ptr2 = writeExpectPanicCause(ptr2, res.RuntimeSafetyPanic);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "pub fn main()void{\n");
    ptr2 = writeSlices(ptr2, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr2 = writeSliceStart(ptr2, start);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr2, buf2));
}
fn writeCompileErrorFileEnd(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
    end: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr1: [*]u8 = buf1;
    ptr1 = writeImports2(ptr1);
    if (zl.mem.testEqualString("Comptime", time)) {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "comptime {\n");
    } else {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "export fn entry()void{\n");
    }
    ptr1 = writeSlices(ptr1, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr1 = writeSliceEnd(ptr1, start, end);
    ptr1 = zl.fmt.strcpyEqu(ptr1, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr1, buf1));
}
fn writeRuntimeSafetyPanicFileEnd(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
    end: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf2: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr2: [*]u8 = buf2;
    ptr2 = writeImports2(ptr2);
    ptr2 = writeExpectPanicCause(ptr2, res.RuntimeSafetyPanic);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "pub fn main()void{\n");
    ptr2 = writeSlices(ptr2, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr2 = writeSliceEnd(ptr2, start, end);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr2, buf2));
}
fn writeCompileErrorFileLength(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
    len: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr1: [*]u8 = buf1;
    ptr1 = writeImports2(ptr1);
    if (zl.mem.testEqualString("Comptime", time)) {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "comptime {\n");
    } else {
        ptr1 = zl.fmt.strcpyEqu(ptr1, "export fn entry()void{\n");
    }
    ptr1 = writeSlices(ptr1, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr1 = writeSliceLength(ptr1, start, len);
    ptr1 = zl.fmt.strcpyEqu(ptr1, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr1, buf1));
}
fn writeRuntimeSafetyPanicFileLength(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
    comptime T: type,
    case_no: usize,
    size: zl.builtin.Type.Pointer.Size,
    src_sent_opt: ?T,
    dest_sent_opt: ?T,
    max: usize,
    splat: T,
    time: []const u8,
    res: Result,
    start: anytype,
    len: anytype,
) !void {
    const pathname: [:0]const u8 = createFile(allocator, files, time, case_no, res);
    const buf2: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    var ptr2: [*]u8 = buf2;
    ptr2 = writeImports2(ptr2);
    ptr2 = writeExpectPanicCause(ptr2, res.RuntimeSafetyPanic);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "pub fn main()void{\n");
    ptr2 = writeSlices(ptr2, allocator, T, size, src_sent_opt, dest_sent_opt, max, splat, time);
    ptr2 = writeSliceLength(ptr2, start, len);
    ptr2 = zl.fmt.strcpyEqu(ptr2, "}\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr2, buf2));
}
fn writeExpectPanicCause(buf: [*]u8, panic_id: zl.builtin.PanicId) [*]u8 {
    if (false) {
        var ptr: [*]u8 = zl.fmt.strcpyEqu(
            \\pub fn panicNew(comptime cause:std.builtin.PanicCause,_:std.builtin.PanicData(cause))noreturn{
            \\if (cause==
        );
        ptr = zl.fmt.EnumFormat(.{}, zl.builtin.PanicId).write(ptr, panic_id);
        ptr = zl.fmt.strcpyEqu(ptr,
            \\){
            \\std.process.exit(0);
            \\}
            \\std.process.exit(1);
            \\}
            \\
        );
        return ptr;
    } else {
        var ptr: [*]u8 = zl.fmt.strcpyEqu(buf,
            \\const zl = @import("zig_lib");
            \\pub usingnamespace zl.start2;
            \\pub const panic_return_value = 0;
            \\pub fn panicNew(comptime cause:zl.builtin.PanicCause,_:zl.builtin.PanicData(cause))noreturn{
            \\if (cause==
        );
        ptr = zl.fmt.EnumFormat(.{}, zl.builtin.PanicId).write(ptr, panic_id);
        ptr = zl.fmt.strcpyEqu(ptr,
            \\){
            \\zl.proc.exit(0);
            \\}
            \\zl.proc.exit(1);
            \\}
            \\
        );
        return ptr;
    }
}
fn regulateName(
    allocator: *zl.mem.SimpleAllocator,
    buf_in: []const u8,
) []u8 {
    const buf: []const u8 = zl.mem.readAfterFirstEqualManyOrElse(u8, "zig-build/build_root/test/safety", buf_in);

    var ret: [*]u8 = @ptrFromInt(allocator.allocateRaw(buf.len, 1));
    var len: usize = buf.len;
    for (buf, 0..) |val, idx| ret[idx] = val;

    var idx: usize = 0;
    while (idx != buf.len) : (idx +%= 1) {
        if (zl.fmt.ascii.isUpper(ret[idx])) {
            ret[idx] = zl.fmt.ascii.toLower(ret[idx]);
        }
    }
    idx = 0;
    while (idx != len) : (idx +%= 1) {
        if (zl.fmt.ascii.isDigit(ret[idx])) {
            continue;
        }
        if (zl.fmt.ascii.isAlphabetic(ret[idx])) {
            continue;
        }
        ret[idx] = '_';
    }
    idx = 0;
    var y: bool = ret[0] == '_';
    var r_idx: usize = 0;
    var w_idx: usize = 0;
    while (r_idx < buf.len) : (r_idx +%= 1) {
        const x: bool = ret[r_idx] == '_';
        if (!y or !x) {
            ret[w_idx] = ret[r_idx];
            w_idx +%= 1;
        } else {
            len -%= 1;
        }
        y = x;
    }
    len -%= @intFromBool(ret[len -% 1] == '_');
    return ret[0..len];
}

const Result = union(enum) {
    Success,
    RuntimeSafetyPanic: zl.builtin.PanicId,
    CompileError: zl.builtin.PanicId,
};
pub fn Slices(
    comptime T: type,
    comptime size: zl.builtin.Type.Pointer.Size,
    comptime src_sent_opt: ?T,
    comptime dest_sent_opt: ?T,
    comptime max_len: comptime_int,
    comptime splat: T,
) type {
    return struct {
        const Slices = @This();
        const Array = if (src_sent_opt) |s| [max_len:s]T else [max_len]T;

        inline fn isComptime(any: anytype) bool {
            return @typeInfo(@TypeOf(.{any})).Struct.fields[0].is_comptime;
        }
        inline fn endCmp(end: anytype, max: anytype) ?@typeInfo(Result).Union.tag_type.? {
            if (dest_sent_opt != null and
                src_sent_opt == null)
            {
                return panicCond(end >= max);
            }
            return panicCond(end > max);
        }
        inline fn panicCond(any: anytype) ?@typeInfo(Result).Union.tag_type.? {
            if (any) {
                return if (isComptime(any)) .CompileError else .RuntimeSafetyPanic;
            }
            return null;
        }
        inline fn makePanic(any: anytype, comptime id: zl.builtin.PanicId) Result {
            if (any == .RuntimeSafetyPanic) {
                return .{ .RuntimeSafetyPanic = id };
            }
            return .{ .CompileError = id };
        }
        pub usingnamespace if (dest_sent_opt) |t| struct {
            const Runtime = struct {
                var array: Array = .{splat} ** max_len;
                const buf: switch (size) {
                    .One => if (src_sent_opt) |s| *[max_len:s]T else *[max_len]T,
                    .Slice => if (src_sent_opt) |s| [:s]T else []T,
                    .Many => if (src_sent_opt) |s| [*:s]T else [*]T,
                    .C => [*c]T,
                } = &array;
                fn sliceStart(start: anytype) Result {
                    if (src_sent_opt == null) {
                        return .{ .CompileError = .accessed_out_of_bounds };
                    }
                    if (size != .C and size != .Many) {
                        if (panicCond(start >= buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    _ = buf[start.. :t];
                    return .Success;
                }
                fn sliceEnd(start: anytype, end: anytype) Result {
                    if (panicCond(start > end)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    if (size != .C and size != .Many) {
                        if (endCmp(end, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (panicCond(buf[end] != t)) |ret| {
                        return makePanic(ret, .mismatched_sentinel);
                    }
                    _ = buf[start..end :t];
                    return .Success;
                }
                fn sliceLength(start: anytype, len: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (panicCond(start >= buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (size != .C and size != .Many) {
                        if (endCmp(start +% len, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (panicCond(buf[start +% len] != t)) |ret| {
                        return makePanic(ret, .mismatched_sentinel);
                    }
                    _ = buf[start..][0..len :t];
                    return .Success;
                }
            };
            const Comptime = struct {
                const array: Array = .{splat} ** max_len;
                const buf: switch (size) {
                    .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                    .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                    .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                    .C => [*c]const T,
                } = &array;
                fn sliceStart(start: anytype) Result {
                    if (src_sent_opt == null) {
                        return .{ .CompileError = .accessed_out_of_bounds };
                    }
                    if (panicCond(start >= max_len)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    if (size != .C and size != .Many) {
                        if (panicCond(buf[buf.len] != t)) |ret| {
                            return makePanic(ret, .mismatched_sentinel);
                        }
                    }
                    _ = buf[start.. :t];
                    return .Success;
                }
                fn sliceEnd(start: anytype, end: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (endCmp(end, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(end, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (panicCond(start > end)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    if (panicCond(buf[end] != t)) |ret| {
                        return makePanic(ret, .mismatched_sentinel);
                    }
                    _ = buf[start..end :t];
                    return .Success;
                }
                fn sliceLength(start: anytype, len: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (endCmp(start +% len, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(start +% len, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (panicCond(buf[start +% len] != t)) |ret| {
                        return makePanic(ret, .mismatched_sentinel);
                    }
                    _ = buf[start..][0..len :t];
                    return .Success;
                }
            };
        } else struct {
            const Runtime = struct {
                var array: Array = .{splat} ** max_len;
                const buf: switch (size) {
                    .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                    .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                    .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                    .C => [*c]const T,
                } = &array;
                fn sliceLength(start: anytype, len: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (endCmp(start +% len, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(start +% len, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }

                    _ = buf[start..][0..len];
                    return .Success;
                }
                fn sliceStart(start: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (panicCond(start >= buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    _ = buf[start..];
                    return .Success;
                }
                fn sliceEnd(start: anytype, end: anytype) Result {
                    if (panicCond(start > end)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    if (size != .C and size != .Many) {
                        if (endCmp(end, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(end, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    _ = buf[start..end];
                    return .Success;
                }
            };
            const Comptime = struct {
                const array: Array = .{splat} ** max_len;
                const buf: switch (size) {
                    .One => if (src_sent_opt) |s| *const [max_len:s]T else *const [max_len]T,
                    .Slice => if (src_sent_opt) |s| [:s]const T else []const T,
                    .Many => if (src_sent_opt) |s| [*:s]const T else [*]const T,
                    .C => [*c]const T,
                } = &array;
                fn sliceLength(start: anytype, len: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (endCmp(start +% len, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(start +% len, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    _ = buf[start..][0..len];
                    return .Success;
                }
                fn sliceStart(start: anytype) Result {
                    if (size != .C and size != .Many) {
                        if (panicCond(start < buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    if (panicCond(start >= max_len)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    _ = buf[start..];
                    return .Success;
                }
                fn sliceEnd(start: anytype, end: anytype) Result {
                    if (panicCond(start > end)) |ret| {
                        return makePanic(ret, .accessed_out_of_order);
                    }
                    if (size != .C and size != .Many) {
                        if (endCmp(end, buf.len)) |ret| {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    } else if (endCmp(end, max_len)) |ret| {
                        if (ret == .CompileError) {
                            return makePanic(ret, .accessed_out_of_bounds);
                        }
                    }
                    _ = buf[start..end];
                    return .Success;
                }
            };
        };
    };
}
fn writeBuildGroupFunctionBody(
    allocator: *zl.mem.SimpleAllocator,
    files: *FileInfoArray,
) !void {
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 * 1024, 1));
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "const zl=@import(\"zig_lib.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr,
        \\pub fn test_slices(
        \\allocator:*zl.builder.types.Allocator,
        \\build_cmd:zl.builder.BuildCommand,
        \\group:anytype)void{
        \\
    );
    ptr = zl.fmt.strcpyEqu(ptr, "var build_obj_cmd=build_cmd;\n");
    ptr = zl.fmt.strcpyEqu(ptr, "build_obj_cmd.kind=.obj;\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const build_exe_cmd=build_cmd;\n");
    for (files.ptr[0..files.len]) |info| {
        if (info.res == .CompileError) {
            ptr = zl.fmt.strcpyEqu(ptr, "group.addBuild(allocator,build_obj_cmd,");
            ptr = zl.fmt.StringLiteralFormat.write(ptr, regulateName(allocator, zl.mem.readBeforeFirstEqualManyOrElse(u8, ".zig", info.pathname)));
            ptr[0] = ',';
            ptr = zl.fmt.StringLiteralFormat.write(ptr + 1, info.pathname);
            ptr = zl.fmt.strcpyEqu(ptr, ")\n.extra.expect_res=.{.server=2};\n");
        } else {
            ptr = zl.fmt.strcpyEqu(ptr, "_=group.addBuild(allocator,build_exe_cmd,");
            ptr = zl.fmt.StringLiteralFormat.write(ptr, regulateName(allocator, zl.mem.readBeforeFirstEqualManyOrElse(u8, ".zig", info.pathname)));
            ptr[0] = ',';
            ptr = zl.fmt.StringLiteralFormat.write(ptr + 1, info.pathname);
            ptr[0..3].* = ");\n".*;
            ptr += 3;
        }
    }
    ptr = zl.fmt.strcpyEqu(ptr, "}\n");
    try zl.gen.truncateFile(.{}, config.test_safety_slice_group_path, zl.fmt.slice(ptr, buf));
}

const FileInfo = struct { pathname: [:0]const u8, res: Result };

const FileInfoArray = struct {
    ptr: [*]FileInfo,
    len: usize,
};

pub fn main() !void {
    @setEvalBranchQuota(~@as(u32, 0));
    @setRuntimeSafety(true);
    var runtime_dest_start: usize = 0;
    var runtime_dest_end: usize = 0;
    runtime_dest_start += 2;
    runtime_dest_end += 5;
    var allocator: zl.mem.SimpleAllocator = .{};

    var files: FileInfoArray = .{
        .ptr = @as([*]FileInfo, @ptrFromInt(allocator.allocateRaw(1024 * 1024, 8))),
        .len = 0,
    };

    files.ptr[0] = .{ .pathname = config.test_safety_slice_common_path, .res = .Success };
    files.len +%= 1;

    const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 * 1024, 1));
    var ptr0: [*]u8 = zl.fmt.strcpyEqu(buf0,
        \\pub usingnamespace zl.start;
        \\pub fn main() void {
        \\@setEvalBranchQuota(~@as(u32, 0));
        \\
    );
    const TT = usize;
    const max: comptime_int = 8;
    const splat: TT = 0;
    var case_no: usize = 0;
    inline for ([_]?TT{ null, 0 }) |src_sent_opt| {
        inline for ([_]?TT{ null, 0, 1 }) |dest_sent_opt| {
            inline for (.{
                max -% 3,
                runtime_dest_end,
                max,
                max +% 1,
            }) |end| {
                inline for (.{
                    2,
                    runtime_dest_start,
                    end +% 1,
                }) |start| {
                    inline for (.{
                        end -% start,
                        max -% start,
                        max,
                    }) |len| {
                        if (end < 0) continue;
                        if (start < 0) continue;
                        if (len < 0) continue;
                        inline for (.{ .One, .Slice, .Many, .C }) |size| {
                            var res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Runtime.sliceStart(start);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime");
                                    ptr0 = writeSliceStart(ptr0, start);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileStart(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileStart(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start);
                                    case_no +%= 1;
                                },
                            }
                            res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Runtime.sliceEnd(start, end);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime");
                                    ptr0 = writeSliceEnd(ptr0, start, end);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileEnd(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start, end);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileEnd(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start, end);
                                    case_no +%= 1;
                                },
                            }
                            res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Runtime.sliceLength(start, len);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime");
                                    ptr0 = writeSliceLength(ptr0, start, len);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileLength(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start, len);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileLength(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Runtime", res, start, len);
                                    case_no +%= 1;
                                },
                            }
                            res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Comptime.sliceStart(start);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime");
                                    ptr0 = writeSliceStart(ptr0, start);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileStart(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileStart(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start);
                                    case_no +%= 1;
                                },
                            }
                            res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Comptime.sliceEnd(start, end);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime");
                                    ptr0 = writeSliceEnd(ptr0, start, end);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileEnd(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start, end);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileEnd(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start, end);
                                    case_no +%= 1;
                                },
                            }
                            res = Slices(TT, size, src_sent_opt, dest_sent_opt, max, splat).Comptime.sliceLength(start, len);
                            switch (res) {
                                .Success => {
                                    ptr0 = writeSlices(ptr0, &allocator, TT, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime");
                                    ptr0 = writeSliceLength(ptr0, start, len);
                                },
                                .CompileError => {
                                    try writeCompileErrorFileLength(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start, len);
                                    case_no +%= 1;
                                },
                                .RuntimeSafetyPanic => {
                                    try writeRuntimeSafetyPanicFileLength(&allocator, &files, TT, case_no, size, src_sent_opt, dest_sent_opt, max, splat, "Comptime", res, start, len);
                                    case_no +%= 1;
                                },
                            }
                        }
                    }
                }
            }
        }
    }
    ptr0 = zl.fmt.strcpyEqu(ptr0,
        \\}
        \\
    );

    try zl.gen.truncateFile(.{}, config.test_safety_slice_common_path, @embedFile("slices-template.zig"));
    try zl.gen.appendFile(.{}, config.test_safety_slice_common_path, zl.fmt.slice(ptr0, buf0));

    try writeBuildGroupFunctionBody(&allocator, &files);
}
