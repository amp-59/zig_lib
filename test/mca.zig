const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const fmt = srg.fmt;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const builtin = srg.builtin;
const opts = @import("./opts.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = false;

pub const input_open_spec: file.OpenSpec = .{
    .options = .{
        .read = true,
        .write = null,
    },
};
pub const input_close_spec: file.CloseSpec = .{
    .errors = null,
};
pub const output_file_spec: file.CreateSpec = .{
    .options = .{
        .read = false,
        .write = .truncate,
        .exclusive = false,
    },
};
pub const output_close_spec: file.CloseSpec = .{
    .errors = null,
};
pub const Stdio = enum(u2) {
    stdin = 0,
    stdout = 1,
    stderr = 2,
};
pub const strict_write_spec: mem.WriteSpec = .{
    .integral = .{},
    .symbol = null,
    .aggregate = null,
    .composite = .{},
    .reference = null,
};
const prune_weak: bool = false;
const prune_fmt: bool = true;
const prune_std: bool = true;
pub const Data = union(enum) {
    stdio: Stdio,
    filesystem: File,
    pub fn fd(data: Data) u64 {
        return switch (data) {
            .filesystem => |fs| fs.fd.?,
            .stdio => |stdio| @enumToInt(stdio),
        };
    }
    pub fn open(data: *Data, comptime open_spec: file.OpenSpec) !void {
        if (data.* == .filesystem) {
            try data.filesystem.open(open_spec);
        }
    }
    pub fn create(data: *Data, comptime file_spec: file.CreateSpec) !void {
        if (data.* == .filesystem) {
            try data.filesystem.create(file_spec);
        }
    }
    pub fn close(data: *Data, comptime close_spec: file.CloseSpec) void {
        if (data.* == .filesystem) {
            data.filesystem.close(close_spec);
        }
    }
};
pub const File = struct {
    pathname: [:0]const u8,
    fd: ?u64 = null,
    pub fn open(filesystem: *File, comptime open_spec: file.OpenSpec) !void {
        filesystem.fd = try file.open(open_spec, filesystem.pathname);
    }
    pub fn create(filesystem: *File, comptime file_spec: file.CreateSpec) !void {
        filesystem.fd = try file.create(file_spec, filesystem.pathname);
    }
    pub fn close(filesystem: *File, comptime close_spec: file.CloseSpec) void {
        if (filesystem.fd) |fd| {
            file.close(close_spec, fd);
            filesystem.fd = null;
        }
    }
};
pub const Argv = Allocator.StructuredVectorLowAligned([:0]u8, 8);
pub const Job = struct {
    input: Data,
    output: Data,
};
pub const Jobs = mem.XorLinkedListAdv(.{
    .child = Job,
    .low_alignment = 8,
    .Allocator = Allocator,
});
pub const String = Allocator.StructuredHolder(u8);
pub const FixedString = Allocator.StructuredVector(u8);
pub const SmallString = Allocator.StructuredHolder(u8);
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
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
const Exports = mem.XorLinkedListAdv(.{
    .child = Export,
    .low_alignment = 8,
    .Allocator = Allocator,
});
const exports_mem_spec: mem.MemorySpec = .{ .allocated = .{
    .Allocator = Allocator,
    .initial_count = 16,
} };
fn printFound(name: []const u8) void {
    file.noexcept.write(2, "found: ");
    file.noexcept.write(2, name);
    file.noexcept.write(2, "\n");
}
fn printPruned(name: []const u8) void {
    file.noexcept.write(2, "pruned: ");
    file.noexcept.write(2, name);
    file.noexcept.write(2, "\n");
}
fn printPassed(name: []const u8) void {
    file.noexcept.write(2, "passed: ");
    file.noexcept.write(2, name);
    file.noexcept.write(2, "\n");
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
            switch (buf[idx_0]) {
                '.' => {
                    if (idx_0 + 9 < buf_len) {
                        if (mem.testEqualManyFront(u8, lfunc_end_s, buf[idx_0 + 1 .. buf.len])) {
                            printFound(file_buf.readAll()[begin.name..begin.body]);
                            try exports.append(allocator_0, .{
                                .body = .{
                                    .begin = begin.name,
                                    .mid = begin.body,
                                    .end = idx_0,
                                },
                                .jumps = if (jumps) |*list| try list.dynamic(allocator_0, FixedJumpList) else null,
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
                },
                else => {},
            }
        }
    }
    return exports;
}
fn writeOutputInnerLoop(fd: u64, file_buf: FixedString, x: Export, name: []const u8) anyerror!void {
    var name_buf: ExportName = .{};
    if (x.jumps) |jumps| {
        var begin: u64 = x.body.begin;
        for (jumps.readAll()) |idx_1, j| {
            if (j == 0) {
                name_buf.undefineAll();
                name_buf.writeAny(mem.ptr_wr_spec, .{ mca_begin_s.*, name, '\n' });
                try file.write(fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len - 5];
                }
                try file.write(fd, section_text);
            } else {
                const sub_region: [*:':']const u8 = file_buf.readManyWithSentinelAt(begin + 1, ':').ptr;
                name_buf.undefineAll();
                name_buf.writeAny(mem.ptr_wr_spec, .{ mca_begin_s.*, sub_region, '\n' });
                try file.write(fd, name_buf.readAll());
                var section_text: []const u8 = file_buf.readAll()[begin..idx_1];
                if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
                    section_text = section_text[0 .. section_text.len - 5];
                }
                try file.write(fd, section_text);
                name_buf.undefineAll();
                name_buf.writeAny(mem.ptr_wr_spec, .{ mca_end_s.*, sub_region, '\n' });
                try file.write(fd, name_buf.readAll());
            }
            begin = idx_1;
        }
        const sub_region: [*:':']const u8 = file_buf.readManyWithSentinelAt(begin + 1, ':').ptr;
        name_buf.undefineAll();
        name_buf.writeAny(mem.ptr_wr_spec, .{ mca_begin_s.*, sub_region, '\n' });
        try file.write(fd, name_buf.readAll());
        var section_text: []const u8 = file_buf.readAll()[begin..x.body.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len - 5];
        }
        try file.write(fd, section_text);
        name_buf.undefineAll();
        name_buf.writeAny(mem.ptr_wr_spec, .{ mca_end_s.*, sub_region, '\n', mca_end_s.*, name, '\n' });
        try file.write(fd, name_buf.readAll());
    } else {
        name_buf.undefineAll();
        name_buf.writeAny(mem.ptr_wr_spec, .{ mca_begin_s.*, name, '\n' });
        try file.write(fd, name_buf.readAll());
        var section_text: []const u8 = file_buf.readAll()[x.body.begin..x.body.end];
        if (mem.testEqualManyBack(u8, "ret\n", section_text)) {
            section_text = section_text[0 .. section_text.len - 5];
        }
        try file.write(fd, section_text);
        name_buf.undefineAll();
        name_buf.writeAny(mem.ptr_wr_spec, .{ mca_end_s.*, name, '\n' });
        try file.write(fd, name_buf.readAll());
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
    try file.write(fd, preamble);
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
fn fileBuf(allocator_0: *Allocator, file_arg: *Job) !FixedString {
    var file_buf: String = String.init(allocator_0);
    try file_arg.input.open(input_open_spec);
    defer file_arg.input.close(input_close_spec);
    const fd: u64 = file_arg.input.fd();
    var st: file.Stat = try file.fstat(.{}, fd);
    try file_buf.increment(allocator_0, st.size + 1);
    file_buf.impl.define(try file.read(fd, file_buf.referAllUndefined(allocator_0.*), st.size));
    file_buf.writeOne('\n');
    return file_buf.dynamic(allocator_0, FixedString);
}
fn processRequest(allocator_0: *Allocator, file_arg: *Job) anyerror!void {
    var file_buf: FixedString = try fileBuf(allocator_0, file_arg);
    var exports = try parseInput(allocator_0, file_buf);
    {
        try file_arg.output.create(output_file_spec);
        const fd: u64 = file_arg.output.fd();
        defer file_arg.output.close(output_close_spec);
        try writeOutput(allocator_0, fd, file_buf, &exports);
    }
    exports.deinit(allocator_0);
    file_buf.deinit(allocator_0);
}
fn printHelpText() void {
    file.noexcept.write(2, "usage:\tasm_sections [options] <asm_file>\n");
    file.noexcept.write(2, "\t-o\t\t[=pathname], output sections to file\n");
    file.noexcept.write(2, "\t--help\t\tprint this text and exit\n");
}
const Options = struct {
    output: ?[:0]const u8 = null,
};
pub fn main(args_in: [][*:0]u8) anyerror!void {
    if (args_in.len == 1) {
        return printHelpText();
    }

    var address_space: mem.AddressSpace = .{};
    var allocator_0: Allocator = try Allocator.init(&address_space);
    defer allocator_0.deinit(&address_space);
    var args: Argv = try Argv.init(&allocator_0, args_in.len);
    defer args.deinit(&allocator_0);
    for (args_in[1..]) |arg| {
        args.writeOne(meta.manyToSlice(arg));
    }
    if (args.len() == 0) {
        return printHelpText();
    }
    var output: Data = .{ .stdio = .stdout };
    var jobs: Jobs = try Jobs.init(&allocator_0);
    defer jobs.deinit(&allocator_0);
    var parse_options: bool = true;
    for (args.readAll()) |arg| {
        if (parse_options) {
            if (mem.testEqualMany(u8, "--help", arg)) {
                return printHelpText();
            }
            if (mem.testEqualManyFront(u8, "-o=", arg)) {
                output = .{ .filesystem = .{ .pathname = arg[3..] } };
                continue;
            }
            if (mem.testEqualMany(u8, "--", arg)) {
                parse_options = false;
                continue;
            }
            if (mem.testEqualMany(u8, "-", arg)) {
                try jobs.append(&allocator_0, .{
                    .input = .{ .stdio = .stdin },
                    .output = output,
                });
                continue;
            }
        }
        if (mem.testEqualManyBack(u8, ".zig", arg)) {
            continue;
        }
        if (mem.testEqualManyBack(u8, ".s", arg)) {
            try jobs.append(&allocator_0, .{
                .input = .{ .filesystem = .{ .pathname = arg } },
                .output = output,
            });
        }
    }
    if (jobs.count == 0) {
        return printHelpText();
    }
    var i: u64 = 0;
    while (i != jobs.count) : (i += 1) {
        const arg = try jobs.at(i);
        arg.output = output;
        try processRequest(&allocator_0, arg);
    }
}
