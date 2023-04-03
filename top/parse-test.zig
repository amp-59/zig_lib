const mem = @import("./mem.zig");
const zig = @import("./zig.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
const mach = @import("./mach.zig");
const parse = @import("./parse.zig");
const spec = @import("./spec.zig");
const testing = @import("./testing.zig");
const builtin = @import("./builtin.zig");
const abstract = @import("./abstract.zig");
const tokenizer = @import("./tokenizer.zig");

pub usingnamespace proc.start;

// Just this once.
const std = @import("std");

pub const AddressSpace = spec.address_space.regular_128;
pub const runtime_assertions: bool = false;
pub const is_verbose: bool = false;

const PrintArray = mem.StaticString(4096);

pub const input_open_spec: file.OpenSpec = .{ .errors = .{}, .options = .{ .read = true, .write = null } };
pub const input_close_spec: file.CloseSpec = .{ .errors = .{} };

const targets: [8][:0]const u8 = .{
    builtin.lib_build_root ++ "/top/parse-test.zig",
    builtin.lib_build_root ++ "/top/mach.zig",
    builtin.lib_build_root ++ "/top/tokenizer.zig",
    builtin.lib_build_root ++ "/top/abstract.zig",
    builtin.lib_build_root ++ "/top/parse.zig",
    builtin.lib_build_root ++ "/top/sys.zig",
    builtin.lib_build_root ++ "/top/allocator.zig",
    builtin.lib_build_root ++ "/top/reference.zig",
};
fn debug(any: anytype) void {
    var array: mem.StaticString(16384) = .{};
    array.writeAny(spec.reinterpret.fmt, any);
    builtin.debug.write(array.readAll());
}
fn fileBuf(allocator: *zig.Allocator.Node, pathname: [:0]const u8) !zig.SourceArray {
    const fd: u64 = file.open(input_open_spec, pathname);
    defer file.close(input_close_spec, fd);
    const st: file.Stat = try file.fstat(.{}, fd);
    var file_buf: zig.SourceArray = try zig.SourceArray.init(allocator, st.size);
    builtin.assertEqual(u64, st.size, try file.read(.{}, fd, file_buf.referAllDefined(), st.size));
    return file_buf;
}
const StdResults = struct { ast: std.zig.Ast, ts: time.TimeSpec };
pub fn timeStd(target: [:0]const u8) !StdResults {
    const GPA: type = std.heap.GeneralPurposeAllocator(.{});
    const t0: time.TimeSpec = try time.realClock(null);
    var gpa: GPA = .{};
    const fd: std.fs.File = try std.fs.openFileAbsolute(target, .{});
    var buf: [:0]u8 = try gpa.allocator().allocSentinel(u8, (try fd.stat()).size, 0);
    buf = buf[0..try fd.readAll(buf) :0];
    var gpa_allocator: std.mem.Allocator = gpa.allocator();
    const ast = try std.zig.parse(gpa_allocator, buf);
    const t1: time.TimeSpec = try time.realClock(null);
    return .{ .ast = ast, .ts = time.diff(t1, t0) };
}
const LibResults = struct { ast: abstract.SyntaxTree, ts: time.TimeSpec };
fn timeLib(
    target: [:0]const u8,
    allocator_n: *zig.Allocator.Node,
    allocator_e: *zig.Allocator.Error,
    allocator_x: *zig.Allocator.Extra,
    allocator_s: *zig.Allocator.State,
) !LibResults {
    const t0: time.TimeSpec = try time.realClock(null);
    const lib_ast: abstract.SyntaxTree = try abstract.SyntaxTree.init(
        allocator_n,
        allocator_e,
        allocator_x,
        allocator_s,
        try fileBuf(allocator_n, target),
    );
    const t1: time.TimeSpec = try time.realClock(null);
    return .{ .ast = lib_ast, .ts = time.diff(t1, t0) };
}
fn mainBoth() !void {
    for (targets) |target| {
        var address_space: builtin.AddressSpace = .{};
        var allocator_n = try zig.Allocator.Node.init(&address_space);
        var allocator_e = try zig.Allocator.Error.init(&address_space);
        var allocator_x = try zig.Allocator.Extra.init(&address_space);
        var allocator_s = try zig.Allocator.State.init(&address_space);
        defer {
            allocator_n.deinit(&address_space);
            allocator_e.deinit(&address_space);
            allocator_x.deinit(&address_space);
            allocator_s.deinit(&address_space);
        }
        const std_res: StdResults = try timeStd(target);
        const lib_res: LibResults = try timeLib(target, &allocator_n, &allocator_e, &allocator_x, &allocator_s);
        for (lib_res.ast.nodes.readAll(), 0..) |node, i| {
            const lib_tag: []const u8 = @tagName(node.tag);
            const std_tag: []const u8 = @tagName(std_res.ast.nodes.items(.tag)[i]);
            const std_main: u32 = std_res.ast.nodes.items(.main_token)[i];
            const lib_main: u32 = node.main_token;
            const std_lhs: u32 = std_res.ast.nodes.items(.data)[i].lhs;
            const lib_lhs: u32 = node.data.lhs;
            const std_rhs: u32 = std_res.ast.nodes.items(.data)[i].rhs;
            const lib_rhs: u32 = node.data.rhs;
            if (builtin.is_debug) {
                if (std_main != lib_main) {
                    debug(.{ "idx: ", fmt.ud64(i), ", lib_main: ", fmt.ud32(lib_main), ", std_main: ", fmt.ud32(std_main), '\n' });
                }
                if (std_lhs != lib_lhs) {
                    debug(.{ "idx: ", fmt.ud64(i), ", lib_lhs: ", fmt.ud32(lib_lhs), ", std_lhs: ", fmt.ud32(std_lhs), '\n' });
                }
                if (std_rhs != lib_rhs) {
                    debug(.{ "idx: ", fmt.ud64(i), ", lib_rhs: ", fmt.ud32(lib_lhs), ", std_rhs: ", fmt.ud32(std_rhs), '\n' });
                }
            }
            try testing.expectEqualMany(u8, lib_tag, std_tag);
        }
        const source: [:0]const u8 = lib_res.ast.source.readAllWithSentinel(0);
        const lines: u64 = blk: {
            var count: u64 = 0;
            var index: u64 = 0;
            while (index != source.len) : (index += 1) {
                count += builtin.int(u64, source[index] == '\n');
            }
            break :blk count;
        };
        debug(.{ "bytes: ", fmt.udh(source.len), ", lines: ", fmt.udh(lines), ", path: '.", target[builtin.build_root.?.len..], "\n" });
        debug(.{ "lib: ", fmt.any(lib_res.ts), ", nodes: ", fmt.udh(lib_res.ast.nodes.len()), '\n' });
        debug(.{ "std: ", fmt.any(std_res.ts), ", nodes: ", fmt.udh(std_res.ast.nodes.len), '\n' });
        var node_index: u32 = 0;
        const node_count: u64 = lib_res.ast.nodes.len();
        while (node_index != node_count) : (node_index += 1) {
            const x: []const u8 = lib_res.ast.getNodeSource(node_index);
            const y: []const u8 = std_res.ast.getNodeSource(node_index);
            try testing.expectEqualMany(u8, y, x);
            _ = switch (lib_res.ast.nodes.readOneAt(node_index).tag) {
                .if_simple => lib_res.ast.ifSimple(node_index),
                .@"if" => lib_res.ast.ifFull(node_index),
                .switch_case_inline_one,
                .switch_case_inline,
                .switch_range,
                .switch_case_one,
                => lib_res.ast.switchCaseOne(node_index),
                .switch_case => lib_res.ast.switchCase(node_index),
                .while_simple => lib_res.ast.whileSimple(node_index),
                .while_cont => lib_res.ast.whileCont(node_index),
                .@"while" => lib_res.ast.whileFull(node_index),
                .for_simple => lib_res.ast.forSimple(node_index),
                .@"for" => lib_res.ast.forFull(node_index),
                .@"asm" => lib_res.ast.asmFull(node_index),
                else => {},
            };
        }
    }
}

pub fn main(args: [][*:0]u8) !void {
    const show_duplicates: bool = false;
    const show_time: bool = true;
    const show_nodes_count: bool = true;

    var address_space: AddressSpace = .{};
    if (args.len > 1) {
        const t0: time.TimeSpec = try time.get(.{}, .realtime);
        for (args[1..]) |arg| {
            var allocator_n = try zig.Allocator.Node.init(&address_space);
            defer allocator_n.deinit(&address_space);
            var allocator_e = try zig.Allocator.Error.init(&address_space);
            defer allocator_e.deinit(&address_space);
            var allocator_x = try zig.Allocator.Extra.init(&address_space);
            defer allocator_x.deinit(&address_space);
            var allocator_s = try zig.Allocator.State.init(&address_space);
            defer allocator_s.deinit(&address_space);
            const ast: abstract.SyntaxTree = try abstract.SyntaxTree.init(
                &allocator_n,
                &allocator_e,
                &allocator_x,
                &allocator_s,
                try fileBuf(&allocator_n, meta.manyToSlice(arg)),
            );
            if (show_nodes_count) {
                testing.print(.{ "nodes: ", fmt.udh(ast.nodes.len()), '\n' });
            }
            if (show_time) {
                testing.print(.{fmt.udh(time.diff(try time.get(.{}, .realtime), t0).nsec)});
            }
            if (show_duplicates) {
                const Duplicate = mem.StaticArray(u32, 32);
                const DuplicateIndices = zig.Allocator.Node.StructuredVector(Duplicate);
                var duplicates: DuplicateIndices = try DuplicateIndices.init(&allocator_n, 128);
                defer duplicates.deinit(&allocator_n);
                var l_index: u32 = 0;
                while (l_index != ast.nodes.len()) : (l_index += 1) {
                    var ptr: ?*Duplicate = null;
                    const l_node: zig.AstNode = ast.nodes.readOneAt(l_index);
                    if (l_node.tag == .fn_decl) {
                        var r_index: u32 = l_index + 1;
                        lo: while (r_index != ast.nodes.len()) : (r_index += 1) {
                            const r_node: zig.AstNode = ast.nodes.readOneAt(r_index);
                            if (r_node.tag == .fn_decl) {
                                for (duplicates.readAll()) |indices| {
                                    for (indices.readAll()) |index| {
                                        if (r_index == index) {
                                            break :lo;
                                        }
                                    }
                                }
                                const l_source: []const u8 = ast.getNodeSource(l_index);
                                const r_source: []const u8 = ast.getNodeSource(r_index);
                                if (mem.testEqualMany(u8, l_source, r_source)) {
                                    if (ptr) |indices| {
                                        indices.writeOne(r_index);
                                    } else {
                                        try duplicates.appendOne(&allocator_n, .{});
                                        const indices: *Duplicate = duplicates.referOneBack();
                                        indices.writeCount(2, .{ l_index, r_index });
                                        ptr = indices;
                                    }
                                }
                            }
                        }
                    }
                }
                for (duplicates.readAll()) |indices| {
                    for (indices.readAll()) |index| {
                        const loc: abstract.SyntaxTree.Location = ast.tokenLocation(0, ast.firstToken(index));
                        var array: PrintArray = .{};
                        array.writeAny(spec.reinterpret.fmt, .{ '\n', arg, ": line: ", fmt.ud(loc.line), ", column: ", fmt.ud(loc.column), '\n' });
                        builtin.debug.write(array.readAll());
                        builtin.debug.write(ast.getNodeSource(index));
                    }
                }
            }
        }
    }
}
