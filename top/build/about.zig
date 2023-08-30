const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const sys = @import("../sys.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");

const tab = @import("./tab.zig");
const types = @import("./types.zig");

pub fn aboutGroupNotice(allocator: *mem.SimpleAllocator, node: *types.Node5, show_deps: bool) void {
    @setRuntimeSafety(builtin.is_safe);
    if (node.tag == .worker) {
        return aboutGroupNotice(allocator, node.groupNode(), show_deps);
    }
    const save: u64 = allocator.next;
    defer allocator.next = save;
    var name_width: u64 = 0;
    var root_width: u64 = 0;
    const buf0: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    @memset(buf0[0 .. 1024 *% 1024], 'E');
    var len0: u64 = node.name.len;
    const buf1: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    @memset(buf1[0..4096], 'E');
    @memcpy(buf0, node.name);
    lengthToplevelCommandNotice(0, node, show_deps, &name_width, &root_width);
    name_width +%= 4;
    name_width &= ~@as(u64, 3);
    root_width +%= 4;
    root_width &= ~@as(u64, 3);
    len0 +%= writeToplevelCommandNotice(buf0 + len0, buf1, 0, node, show_deps, name_width, root_width);
    buf0[len0] = '\n';
    len0 +%= 1;
    debug.write(buf0[0..len0]);
}
pub fn addNotice(node: *types.Node5) void {
    @setRuntimeSafety(builtin.is_safe);
    const task: types.Task = if (node.flags.is_build_command) .build else node.tasks.tag;
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = &buf;
    ptr[0..tab.add_s.len].* = tab.add_s.*;
    ptr += tab.add_s.len;
    @memcpy(ptr, @tagName(node.tag));
    ptr += @tagName(node.tag).len;
    ptr[0] = '.';
    ptr += 1;
    @memcpy(ptr, @tagName(task));
    ptr += @tagName(task).len;
    ptr[0..2].* = ", ".*;
    ptr += 2;
    @memcpy(ptr, node.name);
    ptr += node.name.len;
    ptr[0] = ' ';
    ptr += 1;
    const paths: []types.Path = node.lists.get(.paths);
    switch (task) {
        .build => {
            ptr[0..5].* = "root=".*;
            ptr += 5;
            @memcpy(ptr, paths[1].names[1]);
            ptr += paths[1].names[1].len;
            ptr[0..2].* = ", ".*;
            ptr += 2;
            ptr[0..4].* = "bin=".*;
            ptr += 4;
            @memcpy(ptr, paths[0].names[1]);
            ptr += paths[0].names[1].len;
        },
        .format => {
            ptr[0..5].* = "path=".*;
            ptr += 5;
            @memcpy(ptr, paths[0].names[1]);
            ptr += paths[0].names[1].len;
        },
        .archive => {
            ptr[0..8].* = "archive=".*;
            ptr += 8;
            @memcpy(ptr, paths[0].names[1]);
            ptr += paths[0].names[1].len;
        },
        .objcopy => {
            ptr[0..4].* = "bin=".*;
            ptr += 4;
            @memcpy(ptr, paths[0].names[1]);
            ptr += paths[0].names[1].len;
        },
        else => {},
    }
    ptr[0] = '\n';
    debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
}
pub fn aboutBaseMemoryUsageNotice(allocator: *mem.SimpleAllocator) void {
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
    debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
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
    ptr[0..tab.mem_s.len].* = tab.mem_s.*;
    ptr += tab.mem_s.len;
    ptr += fmt.ud64(size).formatWriteBuf(ptr);
    ptr[0..8].* = tab.bytes_s.*;
    ptr += 6;
    ptr[0] = '\n';
    debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
}
pub fn commandLineNotice(node: *const types.Node5) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = &buf;
    const cmd_args: [][*:0]u8 = node.extra.get(.cmd_args);
    if (cmd_args.len != 0) {
        ptr[0..tab.cmd_args_s.len].* = tab.cmd_args_s.*;
        ptr += tab.cmd_args_s.len;
        ptr += file.about.writeArgs(ptr, &.{}, cmd_args);
        ptr[0] = '\n';
        ptr += 1;
    }
    const run_args: [][*:0]u8 = node.extra.get(.run_args);
    if (run_args.len != 0) {
        ptr[0..tab.run_args_s.len].* = tab.run_args_s.*;
        ptr += tab.run_args_s.len;
        ptr += file.about.writeArgs(ptr, &.{}, run_args);
        ptr[0] = '\n';
        ptr += 1;
    }
    debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
}
fn wouldSkip(toplevel: *const types.Node5, node: *const types.Node5) bool {
    return toplevel == node or node.flags.is_hidden or node.flags.is_special;
}
fn lengthAndWalkInternal(len1: usize, node: *const types.Node5, name_width: *usize, root_width: *usize) void {
    @setRuntimeSafety(builtin.is_safe);
    const deps: []types.Node5.Depn = node.lists.get(.deps);
    const nodes: []*types.Node5 = node.lists.get(.nodes);
    var last_idx: usize = 0;
    for (deps, 0..) |dep, dep_idx| {
        if (wouldSkip(node, nodes[dep.on_idx])) {
            continue;
        }
        last_idx = dep_idx +% 1;
    }
    for (deps, 0..) |dep, deps_idx| {
        const on_node: *types.Node5 = nodes[dep.on_idx];
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
fn lengthSubNode(len1: usize, sub_node: *const types.Node5, name_width: *usize, root_width: *usize, paths: []types.Path) void {
    @setRuntimeSafety(builtin.is_safe);
    name_width.* = @max(name_width.*, sub_node.name.len +% len1);
    const len: usize = primaryInputDisplayName(sub_node, paths).len;
    if (len != 0) {
        if (sub_node.descr.len != 0) {
            root_width.* = @max(root_width.*, len);
        }
    }
}
fn lengthToplevelCommandNotice(len1: usize, node: *const types.Node5, show_deps: bool, name_width: *usize, root_width: *usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var paths: []types.Path = node.lists.get(.paths);
    if (paths.len != 0) {
        lengthSubNode(len1, node, name_width, root_width, paths);
    }
    if (show_deps) {
        lengthAndWalkInternal(len1, node, name_width, root_width);
    }
    var last_idx: usize = 0;
    const nodes: []*types.Node5 = node.lists.get(.nodes);
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
fn writeAndWalkInternal(buf: [*]u8, end: [*]u8, tmp: [*]u8, len: usize, node: *const types.Node5, name_width: usize, root_width: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    const sub_nodes: []*types.Node5 = node.lists.get(.nodes)[1..];
    const deps: []types.Node5.Depn = node.lists.get(.deps);
    var ptr: [*]u8 = end;
    var fin: *u8 = &buf[0];
    var last_idx: usize = 0;
    for (deps, 0..) |dep, dep_idx| {
        if (wouldSkip(node, sub_nodes[dep.on_idx])) {
            continue;
        }
        last_idx = dep_idx;
    }
    for (deps, 0..) |dep, deps_idx| {
        const on_node: *types.Node5 = sub_nodes[dep.on_idx];
        const on_deps: []types.Node5.Depn = on_node.lists.get(.deps);
        const on_paths = on_node.lists.get(.paths);
        if (wouldSkip(node, on_node)) {
            continue;
        }
        (tmp + len)[0..2].* = if (deps_idx == last_idx or len == 0) "  ".* else "| ".*;
        ptr[0] = '\n';
        ptr += 1;
        @memcpy(ptr, tmp[0..len]);
        ptr += len;
        fin = &ptr[0];
        ptr[0..2].* = "|-".*;
        ptr += 2;
        ptr[0..2].* = if (on_deps.len == 0) "> ".* else "+ ".*;
        ptr += 2;
        @memcpy(ptr, on_node.name);
        ptr += on_node.name.len;
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
    return @intFromPtr(ptr - @intFromPtr(buf));
}
fn primaryInputDisplayName(node: *const types.Node5, paths: []types.Path) [:0]const u8 {
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
            if (node.flags.is_build_command) {
                const args: [][*:0]u8 = node.lists.get(.args);
                ret = mem.terminate(args[args.len -% 1], 0);
            } else {
                ret = paths[0].names[1];
            }
        }
        return ret;
    }
    if (node.tag == .group) {
        return node.descr;
    }
    return "(null)";
}
fn writeSubNode(buf: [*]u8, len: usize, sub_node: *const types.Node5, name_width: usize, root_width: usize, paths: []types.Path) usize {
    @setRuntimeSafety(builtin.is_safe);
    var count: usize = name_width -% (sub_node.name.len +% len);
    count +%= if (len == 0) 2 else 0;
    var ptr: [*]u8 = buf;
    const input: [:0]const u8 = primaryInputDisplayName(sub_node, paths);
    if (input.len != 0) {
        @memset(ptr[0..count], ' ');
        ptr += count;
        @memcpy(ptr, input);
        ptr += input.len;
        if (sub_node.descr.len != 0) {
            count = root_width -% input.len;
            @memset(ptr[0..count], ' ');
            ptr += count;
            @memcpy(ptr, sub_node.descr);
            ptr += sub_node.descr.len;
        }
    }
    return @intFromPtr(ptr - @intFromPtr(buf));
}
fn writeToplevelCommandNotice(buf: [*]u8, tmp: [*]u8, len: usize, node: *const types.Node5, show_deps: bool, name_width: usize, root_width: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    const sub_nodes: []*types.Node5 = node.lists.get(.nodes)[1..];
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
    for (sub_nodes, 0..) |sub_node, idx| {
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        last_idx = idx;
    }
    for (sub_nodes, 0..) |sub_node, idx| {
        const sub_sub_nodes: []*types.Node5 = sub_node.lists.get(.nodes)[1..];
        paths = sub_node.lists.get(.paths);
        if (wouldSkip(node, sub_node)) {
            continue;
        }
        (tmp + len)[0..2].* = if (idx == last_idx or len == 0) "  ".* else "| ".*;
        ptr[0] = '\n';
        ptr += 1;
        @memcpy(ptr, tmp[0..len]);
        ptr += len;
        fin = &ptr[0];
        ptr[0..2].* = if (len == 0) "  ".* else "|-".*;
        ptr += 2;
        ptr[0..2].* = if (sub_sub_nodes.len == 1) "- ".* else "o ".*;
        ptr += 2;
        if (sub_node.flags.is_hidden and
            paths.len != 0)
        {
            ptr += writeSubNode(ptr, len +% 4, sub_node, name_width, root_width, paths);
        }
        @memcpy(ptr, sub_node.name);
        ptr += sub_node.name.len;
        ptr += writeToplevelCommandNotice(ptr, tmp, len +% 2, sub_node, show_deps, name_width, root_width);
        if (idx == last_idx) {
            break;
        }
    }
    if (fin.* == '|') {
        fin.* = '`';
    }
    return @intFromPtr(ptr - @intFromPtr(buf));
}
