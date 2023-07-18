const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const sys = zl.sys;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const build = zl.build;
const spec = zl.spec;
const builtin = zl.builtin;

pub usingnamespace zl.start;
pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = .{
    .Attempt = false,
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
pub const AddressSpace = spec.address_space.regular_128;

const input_open_spec: file.OpenSpec = .{};
const input_close_spec: file.CloseSpec = .{
    .errors = .{},
};
const output_file_spec: file.CreateSpec = .{
    .options = .{ .exclusive = false },
};
const output_close_spec: file.CloseSpec = .{
    .errors = .{},
};
const Stdio = enum(u2) {
    stdin = 0,
    stdout = 1,
    stderr = 2,
};
const strict_write_spec: mem.WriteSpec = .{
    .integral = .{},
    .symbol = null,
    .aggregate = null,
    .composite = .{},
    .reference = null,
};
const Data = union(enum) {
    stdio: Stdio,
    filesystem: File,
    fn fd(data: Data) u64 {
        return switch (data) {
            .filesystem => |fs| fs.fd.?,
            .stdio => |stdio| @intFromEnum(stdio),
        };
    }
    fn open(data: *Data, comptime open_spec: file.OpenSpec) !void {
        if (data.* == .filesystem) {
            try data.filesystem.open(open_spec);
        }
    }
    fn create(data: *Data, comptime file_spec: file.CreateSpec) !void {
        if (data.* == .filesystem) {
            try data.filesystem.create(file_spec);
        }
    }
    fn close(data: *Data, comptime close_spec: file.CloseSpec) void {
        if (data.* == .filesystem) {
            data.filesystem.close(close_spec);
        }
    }
};
const File = struct {
    pathname: [:0]const u8,
    fd: ?u64 = null,
    fn open(filesystem: *File, comptime open_spec: file.OpenSpec) !void {
        filesystem.fd = try file.open(open_spec, filesystem.pathname);
    }
    fn create(filesystem: *File, comptime file_spec: file.CreateSpec) !void {
        filesystem.fd = try file.create(file_spec, filesystem.pathname, file.mode.regular);
    }
    fn close(filesystem: *File, comptime close_spec: file.CloseSpec) void {
        if (filesystem.fd) |fd| {
            file.close(close_spec, fd);
            filesystem.fd = null;
        }
    }
};
const String = Allocator.StructuredHolder(u8);
const FixedString = Allocator.StructuredVector(u8);
const SmallString = Allocator.StructuredHolder(u8);
const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = AddressSpace,
    .options = .{
        .count_allocations = true,
        .count_useful_bytes = true,
        .require_filo_free = false,
    },
});
const preamble: []const u8 =
    \\	.text
    \\	.intel_syntax noprefix
    \\
;
const jmp_insn: [11][:0]const u8 = .{
    "ja\t",  "jae\t", "jb\t", "jbe\t",
    "je\t",  "jge\t", "jl\t", "jle\t",
    "jmp\t", "jne\t", "jo\t",
};
const lbb_section_s: [:0]const u8 = "LBB";
const lfunc_end_s: [:0]const u8 = "Lfunc_end";
const type_s: [:0]const u8 = ".type\t";
const function_s: [:0]const u8 = ",@function";
const mca_begin_s: *const [17:0]u8 = "# LLVM-MCA-BEGIN ";
const mca_end_s: *const [15:0]u8 = "# LLVM-MCA-END ";
const Jump = u32;
const JumpList = Allocator.StructuredVectorLowAligned(Jump, 4);
const Span = struct {
    begin: u32 = 0,
    mid: u32 = 0,
    end: u32 = 0,
};
const SegmentName = mem.StaticString(4096);
const Segment = struct {
    span: Span = .{},
    jumps: ?JumpList = null,
};
const Segments = mem.GenericLinkedList(.{
    .child = Segment,
    .low_alignment = 8,
    .Allocator = Allocator,
});
fn printFound(name: []const u8) void {
    builtin.debug.write("found: ");
    builtin.debug.write(name);
    builtin.debug.write("\n");
}
fn printPruned(name: []const u8) void {
    builtin.debug.write("pruned: ");
    builtin.debug.write(name);
    builtin.debug.write("\n");
}
fn printPassed(name: []const u8) void {
    builtin.debug.write("passed: ");
    builtin.debug.write(name);
    builtin.debug.write("\n");
}
fn parseInput(allocator: *Allocator, buf: []const u8) Allocator.allocate_payload(Segments) {
    var segments: Segments = try Segments.init(allocator);
    var found_line_feed: bool = true;
    var found_horizontal_tab: bool = false;
    var segment: Segment = .{};
    while (segment.span.end < buf.len) : (segment.span.end +%= 1) {
        found_line_feed = buf[segment.span.end] == '\n';
        segment.span.end +%= builtin.int2a(u32, found_line_feed, segment.span.end != buf.len -% 1);
        found_horizontal_tab = buf[segment.span.end] == '\t';
        segment.span.end +%= builtin.int2a(u32, found_horizontal_tab, segment.span.end != buf.len -% 1);
        if (builtin.int2a(bool, found_line_feed, found_horizontal_tab)) {
            if (mem.testEqualManyFront(u8, type_s, buf[segment.span.end..buf.len])) {
                segment.span.end +%= 6;
                var idx: u32 = segment.span.end;
                while (buf[idx] != '\n') {
                    idx +%= 1;
                }
                if (mem.testEqualManyBack(u8, function_s, buf[segment.span.end..idx])) {
                    idx +%= 1;
                    segment.span.begin = idx;
                    while (buf[idx] != '\n') {
                        idx +%= 1;
                    }
                    segment.span.end = idx;
                    segment.span.mid = idx;
                }
            }
        } else if (found_line_feed) {
            if (builtin.int2a(bool, buf[segment.span.end] == '.', segment.span.end +% 9 < buf.len)) {
                if (mem.testEqualManyFront(u8, lfunc_end_s, buf[segment.span.end +% 1 .. buf.len])) {
                    printFound(buf[segment.span.begin..segment.span.mid]);
                    try segments.append(allocator, segment);
                    segment.jumps = null;
                    segment.span.end +%= 10;
                } else if (mem.testEqualManyFront(u8, lbb_section_s, buf[segment.span.end +% 1 .. buf.len])) {
                    if (segment.jumps == null) {
                        segment.jumps = try JumpList.init(allocator, 16);
                    }
                    try segment.jumps.?.appendOne(allocator, segment.span.end);
                    segment.span.end +%= 4;
                }
            }
        }
    }
    return segments;
}
fn writeOutputInnerLoop(fd: u64, file_buf: FixedString, segment: Segment, name: []const u8) anyerror!void {
    var name_buf: SegmentName = .{};
    if (segment.jumps) |jumps| {
        var begin: u64 = segment.span.begin;
        for (jumps.readAll(), 0..) |idx_1, j| {
            if (j == 0) {
                name_buf.undefineAll();
                name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, '\n' });
                try file.write(.{}, fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len -% 5];
                }
                try file.write(.{}, fd, section_text);
            } else {
                const sub_region: []const u8 = file_buf.readManyAt(begin +% 1);
                name_buf.undefineAll();
                if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
                    name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, "_", sub_region[0..colon], "\n" });
                }
                try file.write(.{}, fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len -% 5];
                }
                try file.write(.{}, fd, section_text);
                name_buf.undefineAll();

                if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
                    name_buf.writeAny(spec.reinterpret.ptr, .{ mca_end_s.*, name, "_", sub_region[0..colon], '\n' });
                }
                try file.write(.{}, fd, name_buf.readAll());
            }
            begin = idx_1;
        }
        const sub_region: []const u8 = file_buf.readManyAt(begin +% 1);
        name_buf.undefineAll();
        if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
            name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, "_", sub_region[0..colon], '\n' });
        }
        try file.write(.{}, fd, name_buf.readAll());
        var section_text: []const u8 = file_buf.readAll()[begin..segment.span.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len -% 5];
        }
        try file.write(.{}, fd, section_text);
        name_buf.undefineAll();
        if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
            name_buf.writeAny(spec.reinterpret.ptr, .{ mca_end_s.*, name, "_", sub_region[0..colon], '\n', mca_end_s.*, name, '\n' });
        }
        try file.write(.{}, fd, name_buf.readAll());
    } else {
        name_buf.undefineAll();
        name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, '\n' });
        try file.write(.{}, fd, name_buf.readAll());
        var section_text: []const u8 = file_buf.readAll()[segment.span.begin..segment.span.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len -% 5];
        }
        try file.write(.{}, fd, section_text);
        name_buf.undefineAll();
        name_buf.writeAny(spec.reinterpret.ptr, .{ mca_end_s.*, name, '\n' });
        try file.write(.{}, fd, name_buf.readAll());
    }
}
fn pruneSectionsOuterLoop(allocator: *Allocator, file_buf: FixedString, segments: *Segments, next: Segments) anyerror!void {
    _ = allocator;
    const segment: *Segment = segments.this();
    const name: []const u8 = file_buf.readAll()[segment.span.begin..segment.span.mid];
    printPassed(name);
    segments.* = next;
}
fn writeOutputOuterLoop(allocator: *Allocator, fd: u64, file_buf: FixedString, segments: *Segments) anyerror!void {
    const segment: *Segment = segments.this();
    const name: []const u8 = file_buf.readAll()[segment.span.begin..segment.span.mid];
    try writeOutputInnerLoop(fd, file_buf, segment.*, name);
    if (segment.jumps) |*jump| jump.deinit(allocator);
}
fn writeOutput(allocator: *Allocator, fd: u64, file_buf: FixedString, segments: *Segments) anyerror!void {
    try file.write(.{}, fd, preamble);
    segments.goToHead();
    while (segments.next()) |next| {
        try pruneSectionsOuterLoop(allocator, file_buf, segments, next);
    } else {
        try pruneSectionsOuterLoop(allocator, file_buf, segments, segments.*);
        segments.goToHead();
    }
    while (segments.next()) |next| {
        try writeOutputOuterLoop(allocator, fd, file_buf, segments);
        segments.* = next;
    } else {
        try writeOutputOuterLoop(allocator, fd, file_buf, segments);
        segments.goToHead();
    }
}
fn fileBuf(allocator: *Allocator, name: [:0]const u8) !FixedString {
    var file_buf: String = String.init(allocator);
    const fd: u64 = try file.open(input_open_spec, name);
    defer file.close(input_close_spec, fd);
    var st: file.Status = try file.status(.{}, fd);
    try file_buf.increment(allocator, st.size +% 1);
    file_buf.impl.define(try file.read(.{}, fd, file_buf.referAllUndefined(allocator.*)[0..st.size]));
    file_buf.writeOne('\n');
    return file_buf.dynamic(allocator, FixedString);
}
fn processRequest(options: *const Options, allocator: *Allocator, name: [:0]const u8) anyerror!void {
    var file_buf: FixedString = try fileBuf(allocator, name);
    var segments = try parseInput(allocator, file_buf.readAll());

    const fd: u64 = if (options.output) |output| try file.create(output_file_spec, output, file.mode.regular) else 1;
    defer if (options.output != null) file.close(output_close_spec, fd);
    try writeOutput(allocator, fd, file_buf, &segments);
    segments.deinit(allocator);
    file_buf.deinit(allocator);
}
const Options = struct {
    output: ?[:0]const u8 = null,
    pub const Map = proc.GenericOptions(Options);
    const about_output_s: []const u8 = "write output to pathname";
};
const opt_map: []const Options.Map = &[_]Options.Map{
    .{ .field_name = "output", .long = "--output", .short = "-o", .assign = .{ .argument = "pathname" }, .descr = Options.about_output_s },
};

pub fn main(args_in: [][*:0]u8) anyerror!void {
    var args: [][*:0]u8 = args_in;
    const options: Options = Options.Map.getOpts(&args, opt_map);
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    for (args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualManyBack(u8, ".zig", name)) {
            continue;
        }
        if (mem.testEqualManyBack(u8, ".s", name)) {
            try processRequest(&options, &allocator, name);
        }
    }
}
