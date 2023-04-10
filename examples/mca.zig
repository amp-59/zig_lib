const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const fmt = srg.fmt;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const build = srg.build;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
pub const AddressSpace = spec.address_space.regular_128;

const prune_weak: bool = false;
const prune_fmt: bool = true;
const prune_std: bool = true;
const input_open_spec: file.OpenSpec = .{
    .options = .{
        .read = true,
        .write = null,
    },
};
const input_close_spec: file.CloseSpec = .{
    .errors = .{},
};
const output_file_spec: file.CreateSpec = .{
    .options = .{
        .read = false,
        .write = .truncate,
        .exclusive = false,
    },
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
            .stdio => |stdio| @enumToInt(stdio),
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
        filesystem.fd = try file.create(file_spec, filesystem.pathname, file.file_mode);
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
const JumpList = Allocator.StructuredHolderLowAligned(Jump, 4);
const FixedJumpList = Allocator.StructuredVectorLowAligned(Jump, 4);
const Span = struct {
    begin: u32,
    mid: u32,
    end: u32,
};
const ExportName = mem.StaticString(4096);
const Export = struct {
    body: Span,
    jumps: ?FixedJumpList,
};
const Exports = mem.GenericLinkedList(.{
    .child = Export,
    .low_alignment = 8,
    .Allocator = Allocator,
});
const exports_mem_spec: mem.MemorySpec = .{ .allocated = .{
    .Allocator = Allocator,
    .initial_count = 16,
} };
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
fn parseInput(allocator_0: *Allocator, file_buf: FixedString) anyerror!Exports {
    var exports: Exports = try Exports.init(allocator_0);
    const buf: []const u8 = file_buf.readAll();
    const buf_len: u64 = buf.len;
    var idx_0: u32 = 0;
    var found_line_feed: bool = true;
    var found_horizontal_tab: bool = false;
    var begin: struct { name: u32 = 0, body: u32 = 0 } = .{};
    var jumps: ?JumpList = null;
    while (idx_0 < buf_len) : (idx_0 += 1) {
        found_line_feed = buf[idx_0] == '\n';
        idx_0 += builtin.int2a(u32, found_line_feed, idx_0 != buf_len - 1);
        found_horizontal_tab = buf[idx_0] == '\t';
        idx_0 += builtin.int2a(u32, found_horizontal_tab, idx_0 != buf_len - 1);
        if (builtin.int2a(bool, found_line_feed, found_horizontal_tab)) {
            if (mem.testEqualManyFront(u8, type_s, buf[idx_0..buf_len])) {
                idx_0 += 6;
                var idx_1: u32 = idx_0;
                while (buf[idx_1] != '\n') idx_1 += 1;
                if (mem.testEqualManyBack(u8, function_s, buf[idx_0..idx_1])) {
                    idx_1 += 1;
                    begin.name = idx_1;
                    while (buf[idx_1] != '\n') idx_1 += 1;
                    idx_0 = idx_1;
                    begin.body = idx_0;
                }
            }
        } else if (found_line_feed) {
            if (builtin.int2a(bool, buf[idx_0] == '.', idx_0 + 9 < buf_len)) {
                if (mem.testEqualManyFront(u8, lfunc_end_s, buf[idx_0 + 1 .. buf.len])) {
                    printFound(file_buf.readAll()[begin.name..begin.body]);
                    try exports.append(allocator_0, .{
                        .body = .{
                            .begin = begin.name,
                            .mid = begin.body,
                            .end = idx_0,
                        },
                        .jumps = if (jumps) |*list|
                            try list.dynamic(allocator_0, FixedJumpList)
                        else
                            null,
                    });
                    jumps = null;
                    idx_0 += 10;
                } else if (mem.testEqualManyFront(u8, lbb_section_s, buf[idx_0 + 1 .. buf.len])) {
                    if (jumps == null) {
                        jumps = JumpList.init(allocator_0);
                    }
                    try jumps.?.appendOne(allocator_0, idx_0);
                    idx_0 += 4;
                }
            }
        }
    }
    return exports;
}
fn writeOutputInnerLoop(fd: u64, file_buf: FixedString, x: Export, name: []const u8) anyerror!void {
    var name_buf: ExportName = .{};
    if (x.jumps) |jumps| {
        var begin: u64 = x.body.begin;
        for (jumps.readAll(), 0..) |idx_1, j| {
            if (j == 0) {
                name_buf.undefineAll();
                name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, '\n' });
                try file.write(.{}, fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len - 5];
                }
                try file.write(.{}, fd, section_text);
            } else {
                const sub_region: []const u8 = file_buf.readManyAt(begin + 1);
                name_buf.undefineAll();
                if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
                    name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, "_", sub_region[0..colon], "\n" });
                }
                try file.write(.{}, fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len - 5];
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
        const sub_region: []const u8 = file_buf.readManyAt(begin + 1);
        name_buf.undefineAll();
        if (mem.indexOfFirstEqualOne(u8, ':', sub_region)) |colon| {
            name_buf.writeAny(spec.reinterpret.ptr, .{ mca_begin_s.*, name, "_", sub_region[0..colon], '\n' });
        }
        try file.write(.{}, fd, name_buf.readAll());
        var section_text: []const u8 = file_buf.readAll()[begin..x.body.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len - 5];
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
        var section_text: []const u8 = file_buf.readAll()[x.body.begin..x.body.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len - 5];
        }
        try file.write(.{}, fd, section_text);
        name_buf.undefineAll();
        name_buf.writeAny(spec.reinterpret.ptr, .{ mca_end_s.*, name, '\n' });
        try file.write(.{}, fd, name_buf.readAll());
    }
}
fn pruneSectionsOuterLoop(allocator_0: *Allocator, file_buf: FixedString, exports: *Exports, next: Exports) anyerror!void {
    const x: *Export = exports.this();
    const name: []const u8 = file_buf.readAll()[x.body.begin..x.body.mid];
    if (prune_fmt and mem.indexOfFirstEqualMany(u8, "fmt.", name) != null) {
        if (x.jumps) |*jump| {
            jump.deinit(allocator_0);
        }
        printPruned(name);
        return exports.delete(null);
    }
    if (prune_weak and mem.testEqualManyFront(u8, "\"", name)) {
        if (x.jumps) |*jump| {
            jump.deinit(allocator_0);
        }
        printPruned(name);
        return exports.delete(null);
    }
    if (prune_std and mem.testEqualManyFront(u8, "std", name)) {
        if (x.jumps) |*jump| {
            jump.deinit(allocator_0);
        }
        printPruned(name);
        return exports.delete(null);
    }
    printPassed(name);
    exports.* = next;
}
fn writeOutputOuterLoop(allocator_0: *Allocator, fd: u64, file_buf: FixedString, exports: *Exports) anyerror!void {
    const x: *Export = exports.this();
    const name: []const u8 = file_buf.readAll()[x.body.begin..x.body.mid];
    try writeOutputInnerLoop(fd, file_buf, x.*, name);
    if (x.jumps) |*jump| jump.deinit(allocator_0);
}
fn writeOutput(allocator_0: *Allocator, fd: u64, file_buf: FixedString, exports: *Exports) anyerror!void {
    try file.write(.{}, fd, preamble);
    exports.goToHead();
    while (exports.next()) |next| {
        try pruneSectionsOuterLoop(allocator_0, file_buf, exports, next);
    } else {
        try pruneSectionsOuterLoop(allocator_0, file_buf, exports, exports.*);
        exports.goToHead();
    }
    while (exports.next()) |next| {
        try writeOutputOuterLoop(allocator_0, fd, file_buf, exports);
        exports.* = next;
    } else {
        try writeOutputOuterLoop(allocator_0, fd, file_buf, exports);
        exports.goToHead();
    }
}
fn fileBuf(allocator_0: *Allocator, name: [:0]const u8) !FixedString {
    var file_buf: String = String.init(allocator_0);
    const fd: u64 = try file.open(input_open_spec, name);
    defer file.close(input_close_spec, fd);
    var st: file.Status = try file.status(.{}, fd);
    try file_buf.increment(allocator_0, st.size + 1);
    file_buf.impl.define(try file.read(.{}, fd, file_buf.referAllUndefined(allocator_0.*), st.size));
    file_buf.writeOne('\n');
    return file_buf.dynamic(allocator_0, FixedString);
}
fn processRequest(options: *const Options, allocator_0: *Allocator, name: [:0]const u8) anyerror!void {
    var file_buf: FixedString = try fileBuf(allocator_0, name);
    var exports = try parseInput(allocator_0, file_buf);

    const fd: u64 = if (options.output) |output| try file.create(output_file_spec, output, file.file_mode) else 1;
    defer if (options.output != null) file.close(output_close_spec, fd);
    try writeOutput(allocator_0, fd, file_buf, &exports);
    exports.deinit(allocator_0);
    file_buf.deinit(allocator_0);
}
const Options = struct {
    output: ?[:0]const u8 = null,

    pub const Map = proc.GenericOptions(Options);

    const about_output_s: []const u8 = "write output to pathname";
};
const opt_map: []const Options.Map = meta.slice(Options.Map, .{
    .{ .field_name = "output", .long = "--output", .short = "-o", .assign = .{ .argument = "pathname" }, .descr = Options.about_output_s },
});

pub fn main(args_in: [][*:0]u8) anyerror!void {
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opt_map);
    var address_space: AddressSpace = .{};
    var allocator_0: Allocator = try Allocator.init(&address_space);
    defer allocator_0.deinit(&address_space);
    for (args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualManyBack(u8, ".zig", name)) {
            continue;
        }
        if (mem.testEqualManyBack(u8, ".s", name)) {
            try processRequest(&options, &allocator_0, name);
        }
    }
}
