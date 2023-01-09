const srg = @import("zig_lib");
const lit = srg.lit;
const sys = srg.sys;
const fmt = srg.fmt;
const zig = srg.zig;
const mem = srg.mem;
const mach = srg.mach;
const time = srg.time;
const file = srg.file;
const meta = srg.meta;
const proc = srg.proc;
const preset = srg.preset;
const thread = srg.thread;
const builtin = srg.builtin;
const abstract = srg.abstract;

const opts = @import("./opts.zig");

const std = @import("std");

pub usingnamespace proc.start;

pub const is_correct: bool = false;
pub const is_verbose: bool = false;

const map_spec: thread.MapSpec = .{ .options = .{} };
const thread_spec = proc.CloneSpec{
    .errors = null,
    .return_type = u64,
    .options = .{
        .set_thread_local_storage = true,
        .set_parent_thread_id = true,
        .set_child_thread_id = true,
        .clear_child_thread_id = true,
        .address_space = true,
        .thread = true,
        .file_system = true,
        .files = true,
        .signal_handlers = true,
        .sysvsem = true,
        .io = false,
    },
};
const wait_spec: proc.WaitIdSpec = .{
    .id_type = .{ .tag = .all },
    .options = .{
        .continued = false,
        .no_thread = false,
        .clone = false,
        .exited = true,
        .stopped = false,
        .all = true,
    },
};
const Allocator0 = mem.GenericArenaAllocator(.{
    .arena_index = 32,
    .options = .{
        .count_allocations = true,
        .require_filo_free = false,
        .require_geometric_growth = true,
        .trace_state = false,
        .count_branches = false,
    },
    .logging = preset.allocator.logging.silent,
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .arena_index = 40,
    .options = .{
        .count_allocations = false,
        .require_filo_free = true,
        .require_geometric_growth = true,
        .trace_state = false,
        .count_branches = false,
    },
    .logging = preset.allocator.logging.silent,
});

const test_subject_name: []const u8 = builtin.config("test_subject", []const u8, "lib");
const test_standard: bool = mem.testEqualMany(u8, "std", test_subject_name);
const print_times: bool = false;

const Ast: type = if (test_standard) std.zig.Ast else abstract.SyntaxTree;

const Root = struct {
    ts: time.TimeSpec = .{},
    name: mem.StaticString(128) = .{},
    ast: Ast = undefined,
};
const SyntaxTreeArray = Allocator1.StructuredHolder(Root);

const DirStream = file.DirStreamBlock(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = .{},
});
const Names = mem.StructuredAutomaticVector([:0]const u8, null, 128, 8, .{});
const PrintArray = mem.StaticString(4096);
const Filter = meta.EnumBitField(file.Kind);

const open_spec: file.OpenSpec = .{
    .options = .{
        .read = true,
        .write = null,
    },
};
const close_spec: file.CloseSpec = .{
    .errors = null,
};
const stat_spec: file.StatSpec = .{};

fn fileBuf(allocator: *zig.Allocator.Node, dir_fd: u64, name: [:0]const u8) !zig.SourceArray {
    const fd: u64 = try file.openAt(open_spec, dir_fd, name);
    defer file.close(close_spec, fd);
    const st: file.Stat = try file.fstat(stat_spec, fd);
    var file_buf: zig.SourceArray = try zig.SourceArray.init(allocator, st.size);
    builtin.assertEqual(u64, st.size, try file.read(fd, file_buf.referAllDefined(), st.size));
    return file_buf;
}

noinline fn parseAndWalkInternal(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    allocator_n: *zig.Allocator.Node,
    allocator_e: if (test_standard)
        std.mem.Allocator
    else
        *zig.Allocator.Error,
    allocator_x: *zig.Allocator.Extra,
    allocator_s: *zig.Allocator.State,
    array: *SyntaxTreeArray,
    dirfd: ?u64,
    name: [:0]const u8,
) anyerror!void {
    var dir: DirStream = try DirStream.initAt(allocator_0, dirfd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (index != list.count) : (index += 1) {
        const entry: *DirStream.Entry = list.at(index) catch break;
        const base_name: [:0]const u8 = entry.name();
        switch (entry.kind) {
            .directory => {
                @call(.auto, parseAndWalkInternal, .{
                    allocator_0, allocator_1, allocator_n, allocator_e, allocator_x, allocator_s,
                    array,       dir.fd,      base_name,
                }) catch |walk_error| {
                    if (walk_error != error.PermissionDenied) {
                        return walk_error;
                    }
                };
            },
            .regular => {
                if (mem.testEqualManyBack(u8, ".zig", base_name)) {
                    try array.appendOne(allocator_1, undefined);
                    const source: zig.SourceArray = try fileBuf(allocator_n, dir.fd, base_name);
                    array.referOneBack().name.writeMany(base_name);
                    const t0: time.TimeSpec = try time.realClock(null);
                    array.referOneBack().ast = if (test_standard)
                        try std.zig.parse(allocator_e, source.readAllWithSentinel(0))
                    else
                        try abstract.SyntaxTree.init(
                            allocator_n,
                            allocator_e,
                            allocator_x,
                            allocator_s,
                            source,
                        );
                    const t1: time.TimeSpec = try time.realClock(null);
                    array.referOneBack().ts = time.diff(t1, t0);
                }
            },
            else => {},
        }
    }
}

fn countLines(source: []const u8) u64 {
    var count: u64 = 0;
    var index: u64 = 0;
    while (index != source.len) : (index += 1) {
        count += builtin.int(u64, source[index] == '\n');
    }
    return count;
}
const Test = struct {
    const sample_size: u64 = 100;
    var sample: u64 = 0;
};
fn parseAndWalk(address_space: *builtin.AddressSpace, arg: [:0]const u8) !u64 {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    var allocator_0: Allocator0 = try Allocator0.init(address_space);
    var allocator_1: Allocator1 = try Allocator1.init(address_space);
    var allocator_n: zig.Allocator.Node = try zig.Allocator.Node.init(address_space);
    var allocator_e = if (test_standard) gpa.allocator() else try zig.Allocator.Error.init(address_space);
    var allocator_x: zig.Allocator.Extra = if (!test_standard) try zig.Allocator.Extra.init(address_space) else undefined;
    var allocator_s: zig.Allocator.State = if (!test_standard) try zig.Allocator.State.init(address_space) else undefined;
    defer allocator_0.deinit(address_space);
    defer allocator_1.deinit(address_space);
    defer allocator_n.deinit(address_space);
    defer if (!test_standard) allocator_e.deinit(address_space);
    defer allocator_x.deinit(address_space);
    defer allocator_s.deinit(address_space);
    var ast_array: SyntaxTreeArray = SyntaxTreeArray.init(&allocator_1);
    defer ast_array.deinit(&allocator_1);
    const allocator = if (test_standard) allocator_e else &allocator_e;
    try allocator_0.map(4096);
    try allocator_1.map(4096);
    try @call(.auto, parseAndWalkInternal, .{
        &allocator_0, &allocator_1, &allocator_n, allocator, &allocator_x, &allocator_s,
        &ast_array,   null,         arg,
    });
    var nanos: u64 = 0;
    var print_array: PrintArray = .{};
    for (ast_array.referAllDefined(allocator_1)) |*root| {
        if (test_standard) {
            const lines: u64 = countLines(root.ast.source);
            print_array.writeAny(mem.fmt_wr_spec, .{
                "path: '",   root.name.readAll(),   "', bytes: ", fmt.udh(root.ast.source.len),
                ", lines: ", fmt.udh(lines),        ", nodes: ",  fmt.udh(root.ast.nodes.len),
                ", nanos: ", fmt.udh(root.ts.nsec), '\n',
            });
            root.ast.deinit(allocator_e);
        } else {
            const lines: u64 = countLines(root.ast.source.readAll());
            print_array.writeAny(mem.fmt_wr_spec, .{
                "path: '",   root.name.readAll(),   "', bytes: ", fmt.udh(root.ast.source.len()),
                ", lines: ", fmt.udh(lines),        ", nodes: ",  fmt.udh(root.ast.nodes.len()),
                ", nanos: ", fmt.udh(root.ts.nsec), '\n',
            });
            root.ast.deinit(&allocator_n, &allocator_e, &allocator_x);
        }
        nanos += root.ts.nsec;
        if (print_times) {
            file.noexcept.write(2, print_array.readAll());
        }
        print_array.undefineAll();
    }
    print_array.writeAny(mem.fmt_wr_spec, .{
        lit.position.save,
        .{ if (test_standard) "standard " else "library ", "nanos: ", fmt.udh(nanos), ", " },
        .{ fmt.ud(Test.sample), '/', fmt.ud(Test.sample_size) },
        lit.position.restore,
    });
    file.noexcept.write(2, print_array.readAll());
    return nanos;
}

pub fn threadMain(address_space: *builtin.AddressSpace, args_in: [][*:0]u8) !void {
    if (builtin.is_debug) {
        return;
    }
    var args: [][*:0]u8 = args_in;
    var names: Names = .{};
    var i: u64 = 1;
    while (i != args.len) : (i += 1) {
        names.writeOne(meta.manyToSlice(args[i]));
    }
    if (names.len() == 0) {
        names.writeOne(".");
    }
    var sum: u64 = 0;
    while (Test.sample <= Test.sample_size) : (Test.sample += 1) {
        for (names.readAll()) |arg| {
            sum += try parseAndWalk(address_space, arg);
        }
    }
    var print_array: PrintArray = .{};
    print_array.writeAny(mem.fmt_wr_spec, .{
        "\naverage for ", @typeName(Ast),
        ": ",             fmt.udh(sum / Test.sample_size),
        '\n',
    });
    file.noexcept.write(2, print_array.readAll());
}
pub fn main(args: [][*:0]u8, _: [][*:0]u8) !void {
    var address_space: builtin.AddressSpace = .{};
    try threadMain(&address_space, args);
}
