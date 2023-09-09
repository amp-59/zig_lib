const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const sys = @import("../sys.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const mach = @import("../mach.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");

const tab = @import("./tab.zig");
const types = @import("./types.zig");

pub fn aboutGroupNotice(allocator: *types.Allocator, node: *types.Node, show_deps: bool) void {
    @setRuntimeSafety(builtin.is_safe);
    if (node.tag == .worker) {
        return aboutGroupNotice(allocator, node.groupNode(), show_deps);
    }
    const save: usize = allocator.save();
    defer allocator.restore(save);
    var name_width: usize = 0;
    var root_width: usize = 0;
    const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    mach.memset(buf0, 'E', 1024 * 1024);
    const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    mach.memset(buf1, 'E', 4096);
    var len0: usize = fmt.strcpy(buf0, node.name);
    lengthToplevelCommandNotice(0, node, show_deps, &name_width, &root_width);
    name_width +%= 4;
    name_width &= ~@as(usize, 3);
    root_width +%= 4;
    root_width &= ~@as(usize, 3);
    len0 +%= writeToplevelCommandNotice(buf0 + len0, buf1, 0, node, show_deps, name_width, root_width);
    buf0[len0] = '\n';
    len0 +%= 1;
    debug.write(buf0[0..len0]);
}
pub fn addNotice(node: *types.Node) void {
    @setRuntimeSafety(builtin.is_safe);
    const task: types.Task = if (node.flags.is_build_command) .build else node.tasks.tag;
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = &buf;
    ptr[0..tab.add_s.len].* = tab.add_s.*;
    ptr += tab.add_s.len;
    ptr = fmt.strcpyEqu(ptr, @tagName(node.tag));
    ptr[0] = '.';
    ptr += 1;
    ptr = fmt.strcpyEqu(ptr, @tagName(task));
    ptr[0..2].* = ", ".*;
    ptr += 2;
    ptr = fmt.strcpyEqu(ptr, node.name);
    ptr[0] = ' ';
    ptr += 1;
    const paths: []types.Path = node.lists.get(.paths);
    switch (task) {
        .build => {
            ptr[0..5].* = "root=".*;
            ptr += 5;
            ptr = fmt.strcpyEqu(ptr, paths[1].names[1]);
            ptr[0..2].* = ", ".*;
            ptr += 2;
            ptr[0..4].* = "bin=".*;
            ptr += 4;
            ptr = fmt.strcpyEqu(ptr, paths[0].names[1]);
        },
        .format => {
            ptr[0..5].* = "path=".*;
            ptr += 5;
            ptr = fmt.strcpyEqu(ptr, paths[0].names[1]);
        },
        .archive => {
            ptr[0..8].* = "archive=".*;
            ptr += 8;
            ptr = fmt.strcpyEqu(ptr, paths[0].names[1]);
        },
        .objcopy => {
            ptr[0..4].* = "bin=".*;
            ptr += 4;
            ptr = fmt.strcpyEqu(ptr, paths[0].names[1]);
        },
        else => {},
    }
    ptr[0] = '\n';
    debug.write(buf[0 .. fmt.strlen(ptr, &buf) +% 1]);
}
pub fn aboutBaseMemoryUsageNotice(allocator: *types.Allocator) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = &buf;
    ptr[0..tab.mem_s.len].* = tab.mem_s.*;
    ptr += tab.mem_s.len;
    ptr += fmt.ud64(allocator.next -% allocator.start).formatWriteBuf(ptr);
    ptr[0..8].* = tab.bytes_s.*;
    ptr += 6;
    ptr[0] = '\n';
    ptr += 1;
    debug.write(buf[0..fmt.strlen(ptr, &buf)]);
}
pub fn aboutProgramSizeNotice() void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4608]u8 = undefined;
    var ptr: [*]u8 = &buf;
    ptr += proc.about.exe(&buf);
    ptr[0] = 0;
    const fd: usize = sys.call_noexcept(.open, usize, .{ @intFromPtr(&buf), sys.O.RDONLY, 0 });
    const size: usize = sys.call_noexcept(.lseek, usize, .{ fd, 0, 2 });
    _ = sys.call_noexcept(.close, usize, .{fd});
    ptr = &buf;
    ptr[0..tab.size_s.len].* = tab.size_s.*;
    ptr += tab.size_s.len;
    ptr += fmt.ud64(size).formatWriteBuf(ptr);
    ptr[0..8].* = tab.bytes_s.*;
    ptr += 6;
    ptr[0] = '\n';
    debug.write(buf[0 .. fmt.strlen(ptr, &buf) +% 1]);
}
pub fn commandLineNotice(node: *types.Node) void {
    @setRuntimeSafety(builtin.is_safe);
    if (node.tag != .group) {
        return commandLineNotice(node.groupNode());
    }
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = &buf;
    const cmd_args: [][*:0]u8 = node.lists.get(.cmd_args);
    if (cmd_args.len != 0) {
        ptr[0..tab.cmd_args_s.len].* = tab.cmd_args_s.*;
        ptr += tab.cmd_args_s.len;
        ptr += file.about.writeArgs(ptr, &.{}, cmd_args);
        ptr[0] = '\n';
        ptr += 1;
    }
    const run_args: [][*:0]u8 = node.lists.get(.run_args);
    if (run_args.len != 0) {
        ptr[0..tab.run_args_s.len].* = tab.run_args_s.*;
        ptr += tab.run_args_s.len;
        ptr += file.about.writeArgs(ptr, &.{}, run_args);
        ptr[0] = '\n';
        ptr += 1;
    }
    debug.write(buf[0..fmt.strlen(ptr, &buf)]);
}
fn wouldSkip(toplevel: *const types.Node, node: *const types.Node) bool {
    return toplevel == node or node.flags.is_hidden or node.flags.is_special;
}
fn lengthAndWalkInternal(len1: usize, node: *const types.Node, name_width: *usize, root_width: *usize) void {
    @setRuntimeSafety(builtin.is_safe);
    const deps: []types.Node.Depn = node.lists.get(.deps);
    const nodes: []*types.Node = node.lists.get(.nodes);
    var last_idx: usize = 0;
    for (deps, 0..) |dep, dep_idx| {
        if (wouldSkip(node, nodes[dep.on_idx])) {
            continue;
        }
        last_idx = dep_idx +% 1;
    }
    for (deps, 0..) |dep, deps_idx| {
        const on_node: *types.Node = nodes[dep.on_idx];
        const paths: []types.Path = on_node.lists.get(.paths);
        if (wouldSkip(node, on_node)) {
            continue;
        }
        if (paths.len != 0) {
            lengthSubNode(len1 +% 2, on_node, name_width, root_width, paths);
        }
        lengthAndWalkInternal(len1 +% 2, on_node, name_width, root_width);
        if (deps_idx == last_idx) {
            break;
        }
    }
}
fn lengthSubNode(len1: usize, sub_node: *const types.Node, name_width: *usize, root_width: *usize, paths: []types.Path) void {
    @setRuntimeSafety(builtin.is_safe);
    name_width.* = @max(name_width.*, sub_node.name.len +% len1);
    const len: usize = primaryInputDisplayName(sub_node, paths).len;
    if (len != 0) {
        if (sub_node.descr.len != 0) {
            root_width.* = @max(root_width.*, len);
        }
    }
}
fn lengthToplevelCommandNotice(len1: usize, node: *const types.Node, show_deps: bool, name_width: *usize, root_width: *usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var paths: []types.Path = node.lists.get(.paths);
    if (paths.len != 0) {
        lengthSubNode(len1, node, name_width, root_width, paths);
    }
    if (show_deps) {
        lengthAndWalkInternal(len1, node, name_width, root_width);
    }
    var last_idx: usize = 0;
    const nodes: []*types.Node = node.lists.get(.nodes);
    for (nodes[1..], 0..) |sub_node, nodes_idx| {
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        last_idx = nodes_idx;
    }
    for (nodes[1..], 0..) |sub_node, nodes_idx| {
        paths = sub_node.lists.get(.paths);
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        if (sub_node.flags.is_hidden and
            paths.len != 0)
        {
            lengthSubNode(len1 +% 4, sub_node, name_width, root_width, paths);
        }
        lengthToplevelCommandNotice(len1 +% 2, sub_node, show_deps, name_width, root_width);
        if (nodes_idx == last_idx) {
            break;
        }
    }
}
fn writeAndWalkInternal(buf: [*]u8, end: [*]u8, tmp: [*]u8, len: usize, node: *const types.Node, name_width: usize, root_width: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    const nodes: []*types.Node = node.lists.get(.nodes);
    const deps: []types.Node.Depn = node.lists.get(.deps);
    var ptr: [*]u8 = end;
    var fin: *u8 = &buf[0];
    var last_idx: usize = 0;
    for (deps, 0..) |dep, dep_idx| {
        if (wouldSkip(node, nodes[dep.on_idx])) {
            continue;
        }
        last_idx = dep_idx;
    }
    for (deps, 0..) |dep, deps_idx| {
        const on_node: *types.Node = nodes[dep.on_idx];
        const on_deps: []types.Node.Depn = on_node.lists.get(.deps);
        const on_paths = on_node.lists.get(.paths);
        if (wouldSkip(node, on_node)) {
            continue;
        }
        (tmp + len)[0..2].* = if (deps_idx == last_idx or len == 0) "  ".* else "| ".*;
        ptr[0] = '\n';
        ptr += 1;
        ptr = fmt.strcpyEqu(ptr, tmp[0..len]);
        fin = &ptr[0];
        ptr[0..2].* = "|-".*;
        ptr += 2;
        ptr[0..2].* = if (on_deps.len == 0) "> ".* else "+ ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, on_node.name);
        if (on_paths.len != 0) {
            ptr += writeSubNode(ptr, len +% 2, on_node, name_width, root_width, on_paths);
        }
        ptr = buf + writeAndWalkInternal(buf, ptr, tmp, len +% 2, on_node, name_width, root_width);
        if (deps_idx == last_idx) {
            break;
        }
    }
    if (fin.* == '|') {
        fin.* = '`';
    }
    return fmt.strlen(ptr, buf);
}
fn primaryInputDisplayName(node: *const types.Node, paths: []types.Path) [:0]const u8 {
    @setRuntimeSafety(builtin.is_safe);
    if (node.tag == .worker) {
        var ret: [:0]const u8 = undefined;
        if (node.tasks.tag == .build or
            node.tasks.tag == .archive)
        {
            ret = paths[1].names[1];
        }
        if (node.tasks.tag == .format) {
            ret = paths[0].names[1];
        }
        if (node.tasks.tag == .run) {
            ret = paths[0].names[1];
        }
        return ret;
    }
    if (node.tag == .group) {
        return node.descr;
    }
    return "(null)";
}
fn primaryInputDisplayNameNoPaths(node: *const types.Node) [:0]const u8 {
    const paths: []types.Path = node.lists.get(.paths);
    @setRuntimeSafety(builtin.is_safe);
    if (node.tag == .worker) {
        var ret: [:0]const u8 = undefined;
        if (node.tasks.tag == .build or
            node.tasks.tag == .archive)
        {
            ret = paths[1].names[1];
        }
        if (node.tasks.tag == .format) {
            ret = paths[0].names[1];
        }
        if (node.tasks.tag == .run) {
            ret = paths[0].names[1];
        }
        return ret;
    }
    if (node.tag == .group) {
        return node.descr;
    }
    return "(null)";
}
fn writeSubNode(buf: [*]u8, len: usize, sub_node: *const types.Node, name_width: usize, root_width: usize, paths: []types.Path) usize {
    @setRuntimeSafety(builtin.is_safe);
    var count: usize = name_width -% (sub_node.name.len +% len);
    count +%= if (len == 0) 2 else 0;
    const input: [:0]const u8 = primaryInputDisplayName(sub_node, paths);
    var ptr: [*]u8 = fmt.strsetEqu(buf, ' ', count);
    ptr = fmt.strcpyEqu(ptr, input);
    if (sub_node.descr.len != 0) {
        count = root_width -% input.len;
        ptr = fmt.strsetEqu(ptr, ' ', count);
        ptr = fmt.strcpyEqu(ptr, sub_node.descr);
    }
    return fmt.strlen(ptr, buf);
}
fn writeToplevelCommandNotice(buf: [*]u8, tmp: [*]u8, len: usize, node: *const types.Node, show_deps: bool, name_width: usize, root_width: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    const nodes: []*types.Node = node.lists.get(.nodes);
    var paths: []types.Path = node.lists.get(.paths);
    var ptr: [*]u8 = buf;
    var fin: *u8 = &buf[0];
    if (paths.len != 0) {
        ptr += writeSubNode(buf, len, node, name_width, root_width, paths);
    }
    if (show_deps) {
        ptr[0..4].* = "\x1b[2m".*;
        ptr += 4;
        ptr = buf + writeAndWalkInternal(buf, ptr, tmp, len, node, name_width, root_width);
        ptr[0..4].* = "\x1b[0m".*;
        ptr += 4;
    }
    var last_idx: usize = 0;
    for (nodes[1..], 0..) |sub_node, node_idx| {
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        last_idx = node_idx;
    }
    for (nodes[1..], 0..) |sub_node, node_idx| {
        const sub_nodes: []*types.Node = sub_node.lists.get(.nodes);
        paths = sub_node.lists.get(.paths);
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        (tmp + len)[0..2].* = if (node_idx == last_idx or len == 0) "  ".* else "| ".*;
        ptr[0] = '\n';
        ptr += 1;
        ptr = fmt.strcpyEqu(ptr, tmp[0..len]);
        fin = &ptr[0];
        ptr[0..2].* = if (len == 0) "  ".* else "|-".*;
        ptr += 2;
        ptr[0..2].* = if (sub_nodes.len == 1) "- ".* else "o ".*;
        ptr += 2;
        if (sub_node.flags.is_hidden and
            paths.len != 0)
        {
            ptr += writeSubNode(ptr, len +% 4, sub_node, name_width, root_width, paths);
        }
        ptr = fmt.strcpyEqu(ptr, sub_node.name);
        ptr += writeToplevelCommandNotice(ptr, tmp, len +% 2, sub_node, show_deps, name_width, root_width);
        if (node_idx == last_idx) {
            break;
        }
    }
    if (fin.* == '|') {
        fin.* = '`';
    }
    return fmt.strlen(ptr, buf);
}
const ColumnWidth = struct {
    name: usize,
    input: usize,
};
const NodeIterator = struct {
    node: *const types.Node,
    idx: usize = 0,
    max_len: usize = 0,
    max_idx: usize = 0,
    nodes: []const *types.Node,
    deps: []const types.Node.Depn,
    fn next(itr: *NodeIterator) ?*types.Node {
        @setRuntimeSafety(false);
        while (itr.idx != itr.max_len) {
            const node_idx: usize = if (itr.node.tag == .group)
                itr.idx
            else
                itr.deps[itr.idx].on_idx;
            const node: *types.Node = itr.nodes[node_idx];
            itr.idx +%= 1;
            if (wouldSkip(itr.node, node)) {
                continue;
            }
            itr.max_idx = @max(itr.max_idx, itr.idx);
            return node;
        }
        return null;
    }
    fn init(node: *const types.Node) NodeIterator {
        @setRuntimeSafety(false);
        var itr: NodeIterator = .{
            .node = node,
            .nodes = node.lists.get(.nodes),
            .deps = node.lists.get(.deps),
        };
        itr.idx = @intFromBool(itr.node.tag == .group);
        itr.max_len = if (node.tag == .group) itr.nodes.len else itr.deps.len;
        while (itr.next()) |_| {}
        itr.idx = @intFromBool(itr.node.tag == .group);
        return itr;
    }
};
fn writeAndWalkColumnWidths(len1: u64, node: *const types.Node, width: *ColumnWidth) void {
    @setRuntimeSafety(false);
    var itr: NodeIterator = NodeIterator.init(node);
    while (itr.next()) |next_node| {
        writeAndWalkColumnWidths(len1 +% 2, next_node, width);
        width.name = @max(width.name, len1 +% 4 +% next_node.name.len);
        width.input = @max(width.input, primaryInputDisplayNameNoPaths(next_node).len);
    }
}
pub fn writeAndWalk(node: *const types.Node) void {
    @setRuntimeSafety(false);
    var buf0: [1024 * 1024]u8 = undefined;
    var buf1: [4096]u8 = undefined;
    var ptr0: [*]u8 = fmt.strcpyEqu(&buf0, node.name);
    ptr0[0] = '\n';
    ptr0 += 1;
    var width: ColumnWidth = .{ .name = 0, .input = 0 };
    writeAndWalkColumnWidths(0, node, &width);
    width.name +%= 4;
    width.name &= ~@as(usize, 3);
    width.input +%= 4;
    width.input &= ~@as(usize, 3);
    debug.write(buf0[0..fmt.strlen(@This().writeAndWalkInternalNew(ptr0, &buf1, 0, node, &width), &buf0)]);
}
fn writeAndWalkInternalNew(buf0: [*]u8, buf1: [*]u8, len1: u64, node: *const types.Node, width: *ColumnWidth) [*]u8 {
    @setRuntimeSafety(false);
    var itr: NodeIterator = NodeIterator.init(node);
    var ptr0: [*]u8 = buf0;
    var ptr1: [*]u8 = buf1 + len1;
    while (itr.next()) |next_node| {
        const input: [:0]const u8 = primaryInputDisplayNameNoPaths(next_node);
        ptr1[0..2].* = if (itr.idx == itr.max_idx) "  ".* else "| ".*;
        ptr0 = fmt.strcpyEqu(ptr0, buf1[0..len1]);
        ptr0[0..2].* = if (itr.idx == itr.max_idx) "`-".* else "|-".*;
        ptr0 += 2;
        ptr0[0..2].* = if (1 == itr.max_idx) "> ".* else "+ ".*;
        ptr0 += 2;
        ptr0 = fmt.strcpyEqu(ptr0, next_node.name);
        ptr0 = fmt.strsetEqu(ptr0, ' ', width.name -% (len1 +% 4 +% next_node.name.len));
        ptr0 = fmt.strcpyEqu(ptr0, input);
        ptr0 = fmt.strsetEqu(ptr0, ' ', width.input -% input.len);
        ptr0 = fmt.strcpyEqu(ptr0, next_node.descr);
        ptr0[0] = '\n';
        ptr0 += 1;
        ptr0 = writeAndWalkInternalNew(ptr0, buf1, len1 +% 2, next_node, width);
    }
    return ptr0;
}
const AboutKind = enum(u8) {
    @"error",
    note,
};
fn writeAbout(buf: [*]u8, kind: AboutKind) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = buf;
    switch (kind) {
        .@"error" => {
            ptr[0..4].* = "\x1b[1m".*;
            ptr += 4;
        },
        .note => {
            ptr[0..15].* = "\x1b[0;38;5;250;1m".*;
            ptr += 15;
        },
    }
    ptr = fmt.strcpyEqu(ptr, @tagName(kind));
    ptr[0..2].* = ": ".*;
    ptr += 2;
    ptr[0..4].* = "\x1b[1m".*;
    ptr += 4;
    return fmt.strlen(ptr, buf);
}
fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) usize {
    @setRuntimeSafety(builtin.is_safe);
    const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
    buf[0..4].* = "\x1b[1m".*;
    var ptr: [*]u8 = buf + 4;
    if (err.src_loc != 0) {
        const src_file: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
        ptr += writeSourceLocation(ptr, src_file, src.line +% 1, src.column +% 1);
        ptr[0..2].* = ": ".*;
        ptr += 2;
    }
    return fmt.strlen(ptr, buf);
}
fn writeError(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind) usize {
    @setRuntimeSafety(builtin.is_safe);
    const err: *types.ErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *types.SourceLocation = @ptrCast(extra + err.src_loc);
    const notes: [*]u32 = extra + err_msg_idx + types.ErrorMessage.len;
    var len: usize = writeTopSrcLoc(buf, extra, bytes, err_msg_idx);
    const pos: u64 = len +% @tagName(kind).len -% 11 -% 2;
    len +%= writeAbout(buf + len, kind);
    len +%= writeMessage(buf + len, bytes, err.start, pos);
    if (err.src_loc == 0) {
        if (err.count != 1)
            len +%= writeTimes(buf + len, err.count);
        for (0..err.notes_len) |idx|
            len +%= writeError(buf + len, extra, bytes, notes[idx], .note);
    } else {
        if (err.count != 1)
            len +%= writeTimes(buf + len, err.count);
        if (src.src_line != 0)
            len +%= writeCaret(buf + len, bytes, src);
        for (0..err.notes_len) |idx|
            len +%= writeError(buf + len, extra, bytes, notes[idx], .note);
        if (src.ref_len != 0)
            len +%= writeTrace(buf + len, extra, bytes, err.src_loc, src.ref_len);
    }
    return len;
}
fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: usize, column: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ud64: fmt.Type.Ud64 = .{ .value = line };
    var ptr: [*]u8 = buf;
    ptr[0..11].* = "\x1b[38;5;247m".*;
    ptr += 11;
    ptr = fmt.strcpyEqu(ptr, pathname);
    ptr[0] = ':';
    ptr += 1;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0] = ':';
    ptr += 1;
    ud64.value = column;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..4].* = tab.reset_s.*;
    return fmt.strlen(ptr, buf) +% 4;
}
fn writeTimes(buf: [*]u8, count: u64) u64 {
    @setRuntimeSafety(builtin.is_safe);
    var ud64: fmt.Type.Ud64 = .{ .value = count };
    var ptr: [*]u8 = buf - 1;
    ptr[0..4].* = tab.faint_s.*;
    ptr += 4;
    ptr[0..2].* = " (".*;
    ptr += 2;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..7].* = " times)".*;
    ptr += 7;
    ptr[0..5].* = tab.new_s.*;
    return fmt.strlen(ptr, buf) +% 5;
}
fn writeCaret(buf: [*]u8, bytes: [*:0]u8, src: *types.SourceLocation) usize {
    @setRuntimeSafety(builtin.is_safe);
    const line: [:0]u8 = mem.terminate(bytes + src.src_line, 0);
    const before_caret: u64 = src.span_main -% src.span_start;
    const indent: u64 = src.column -% before_caret;
    const after_caret: u64 = src.span_end -% src.span_main -| 1;
    var ptr: [*]u8 = fmt.strcpyEqu(buf, line);
    ptr[0] = '\n';
    ptr += 1;
    ptr = fmt.strsetEqu(ptr, ' ', indent);
    ptr[0..10].* = tab.hi_green_s.*;
    ptr += 10;
    ptr = fmt.strsetEqu(ptr, '~', before_caret);
    ptr[0] = '^';
    ptr += 1;
    ptr = fmt.strsetEqu(ptr, '~', after_caret);
    ptr[0..5].* = tab.new_s.*;
    return fmt.strlen(ptr, buf) +% tab.new_s.len;
}
fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: usize, indent: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = buf;
    var next: usize = start;
    var pos: usize = start;
    while (bytes[pos] != 0) : (pos +%= 1) {
        if (bytes[pos] == '\n') {
            const line: []u8 = bytes[next..pos];
            ptr = fmt.strcpyEqu(ptr, line);
            ptr[0] = '\n';
            ptr += 1;
            ptr = fmt.strsetEqu(ptr, ' ', indent);
            next = pos +% 1;
        }
    }
    const line: []u8 = bytes[next..pos];
    ptr = fmt.strcpyEqu(ptr, line);
    ptr[0..5].* = tab.new_s.*;
    return fmt.strlen(ptr, buf) +% tab.new_s.len;
}
fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: usize, ref_len: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ref_idx: usize = start +% types.SourceLocation.len;
    buf[0..11].* = "\x1b[38;5;247m".*;
    var ptr: [*]u8 = buf + 11;
    ptr[0..15].* = "referenced by:\n".*;
    ptr += 15;
    var len: usize = 0;
    while (len != ref_len) : (len +%= 1) {
        const ref_trc: *types.ReferenceTrace = @ptrCast(extra + ref_idx);
        if (ref_trc.src_loc != 0) {
            const ref_src: *types.SourceLocation = @ptrCast(extra + ref_trc.src_loc);
            const src_file: [:0]u8 = mem.terminate(bytes + ref_src.src_path, 0);
            const decl_name: [:0]u8 = mem.terminate(bytes + ref_trc.decl_name, 0);
            @memset(ptr[0..4], ' ');
            ptr += 4;
            ptr = fmt.strcpyEqu(ptr, decl_name);
            ptr[0..2].* = ": ".*;
            ptr += 2;
            ptr += writeSourceLocation(ptr, src_file, ref_src.line +% 1, ref_src.column +% 1);
            ptr[0] = '\n';
            ptr += 1;
        }
        ref_idx +%= types.ReferenceTrace.len;
    }
    ptr[0..5].* = tab.new_s.*;
    return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% 5;
}
pub fn writeErrors(allocator: *types.Allocator, idx: [*]u32) void {
    @setRuntimeSafety(builtin.is_safe);
    const extra: [*]u32 = idx + 2;
    var bytes: [*:0]u8 = @ptrCast(idx);
    bytes += 8 + (idx[0] *% 4);
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
        debug.write(buf[0..writeError(buf, extra, bytes, err_msg_idx, .@"error")]);
    }
    debug.write(mem.terminate(bytes + extra[2], 0));
}
