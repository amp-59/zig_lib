const mem = @import("./mem.zig");
const zig = @import("./zig.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
const mach = @import("./mach.zig");
const parse = @import("./parse.zig");
const testing = @import("./testing.zig");
const builtin = @import("./builtin.zig");
const abstract = @import("./abstract.zig");
const tokenizer = @import("./tokenizer.zig");

// Just this once.
const std = @import("std");

pub const is_correct: bool = false;
pub const is_verbose: bool = false;

pub const input_open_spec: file.OpenSpec = .{ .errors = null, .options = .{ .read = true, .write = null } };
pub const input_close_spec: file.CloseSpec = .{ .errors = null };

const targets: [7][:0]const u8 = .{
    builtin.lib_build_root ++ "/top/parse-test.zig",
    builtin.lib_build_root ++ "/top/mach.zig",
    builtin.lib_build_root ++ "/top/tokenizer.zig",
    builtin.lib_build_root ++ "/top/abstract.zig",
    builtin.lib_build_root ++ "/top/parse.zig",
    builtin.lib_build_root ++ "/top/allocator.zig",
    builtin.lib_build_root ++ "/top/reference.zig",
};
fn debug(any: anytype) void {
    var array: mem.StaticString(16384) = .{};
    array.writeAny(mem.fmt_wr_spec, any);
    file.noexcept.write(2, array.readAll());
}
fn fileBuf(allocator: *zig.Allocator.Node, pathname: [:0]const u8) !zig.SourceArray {
    const fd: u64 = file.open(input_open_spec, pathname);
    defer file.close(input_close_spec, fd);
    const st: file.Stat = try file.fstat(.{}, fd);
    var file_buf: zig.SourceArray = try zig.SourceArray.init(allocator, st.size);
    builtin.assertEqual(u64, st.size, try file.read(fd, file_buf.referAllDefined(), st.size));
    return file_buf;
}
const StdResults = struct { ast: std.zig.Ast, t: u64 };
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
    const std_nsec = t1.nsec - t0.nsec;
    return .{ .ast = ast, .t = std_nsec };
}
const LibResults = struct { ast: abstract.SyntaxTree, t: u64 };
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
    const lib_nsec: u64 = t1.nsec - t0.nsec;
    return .{ .ast = lib_ast, .t = lib_nsec };
}
fn mainBoth() !void {
    for (targets) |target| {
        var address_space: mem.AddressSpace = .{};
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
        for (lib_res.ast.nodes.readAll(allocator_n)) |node, i| {
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
        const source: [:0]const u8 = lib_res.ast.source;
        const lines: u64 = blk: {
            var count: u64 = 0;
            var index: u64 = 0;
            while (index != source.len) : (index += 1) {
                count += builtin.int(u64, source[index] == '\n');
            }
            break :blk count;
        };
        debug(.{ "bytes: ", fmt.udh(source.len), ", lines: ", fmt.udh(lines), ", path: '.", target[builtin.build_root.?.len..], "\n" });
        debug(.{ "lib: ", fmt.udh(lib_res.t), ", nodes: ", fmt.udh(lib_res.ast.nodes.len(allocator_n)), '\n' });
        debug(.{ "std: ", fmt.udh(std_res.t), ", nodes: ", fmt.udh(std_res.ast.nodes.len), '\n' });
        var node_index: u32 = 0;
        const node_count: u64 = lib_res.ast.nodes.len(allocator_n);
        while (node_index != node_count) : (node_index += 1) {
            const n: zig.AstNode = lib_res.ast.nodes.readOneAt(allocator_n, node_index);
            if (n.tag == .fn_decl) {
                const x: []const u8 = lib_res.ast.getNodeSource(&allocator_n, &allocator_x, node_index);
                const y: []const u8 = std_res.ast.getNodeSource(node_index);
                try testing.expectEqualMany(u8, y, x);
            }
        }
    }
}
pub const main = mainBoth;
