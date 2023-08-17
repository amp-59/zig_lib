const root = @import("@build");
const cmds = struct {
    const build = @import("../build.h.zig");
    const format = @import("../format.h.zig");
    const archive = @import("../archive.h.zig");
    const objcopy = @import("../objcopy.h.zig");
};
const zl = root.zl;
const mem = zl.mem;
const fmt = zl.fmt;
const gen = zl.gen;
const elf = zl.elf;
const spec = zl.spec;
const proc = zl.proc;
const meta = zl.meta;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
pub usingnamespace zl.start;
pub const exec_mode: build.ExecMode = .Regenerate;
pub const want_regen_metadata: bool = true;
pub const runtime_assertions: bool = false;
pub const logging_override: debug.Logging.Override = .{
    .Attempt = true,
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
const Array = mem.StaticString(64 * 1024 * 1024);
const Array2 = mem.StaticString(64 * 1024);
const Node = @typeInfo(@typeInfo(@TypeOf(root.buildMain)).Fn.params[1].type.?).Pointer.child;
const Task = @TypeOf(@as(Node, undefined).task.cmd);
const Flags = @TypeOf(@as(Node, undefined).flags);
fn GenericCommand(comptime Command: type, comptime field_name: []const u8) type {
    return struct {
        const tag = @field(build.Task, field_name);
        fn commandsLength(node: *Node) usize {
            @setRuntimeSafety(false);
            var len: usize = 0;
            for (node.impl.nodes[1..node.impl.nodes_len]) |sub_node| {
                if (sub_node.tag == .group) {
                    len +%= commandsLength(sub_node);
                }
                if (sub_node.tag == .worker and
                    sub_node.task.tag == tag and
                    !sub_node.flags.is_special)
                {
                    len +%= 1;
                }
            }
            return len;
        }
        fn commandsWriteBuf(node: *Node, buf: [*]*Command) usize {
            @setRuntimeSafety(false);
            var len: usize = 0;
            for (node.impl.nodes[1..node.impl.nodes_len]) |sub_node| {
                if (sub_node.tag == .group) {
                    len +%= commandsWriteBuf(sub_node, buf + len);
                }
                if (sub_node.tag == .worker and
                    sub_node.task.tag == tag and
                    !sub_node.flags.is_special)
                {
                    buf[len] = @field(sub_node.task.cmd, field_name);
                    len +%= 1;
                }
            }
            return len;
        }
        fn commands(allocator: *build.Allocator, node: *Node) []*Command {
            const buf: []*Command = allocator.allocate(*Command, commandsLength(node));
            return buf[0..commandsWriteBuf(node, buf.ptr)];
        }
    };
}
const CommandState = struct {
    build_cmd: ?build.BuildCommand = null,
    format_cmd: ?build.FormatCommand = null,
    objcopy_cmd: ?build.ObjcopyCommand = null,
    archive_cmd: ?build.ArchiveCommand = null,
    var toplevel: CommandState = undefined;
    fn init(allocator: *build.Allocator, node: *Node) CommandState {
        @setRuntimeSafety(builtin.is_safe);
        const save: usize = allocator.next;
        defer allocator.next = save;
        var ret: CommandState = .{};
        const build_cmd_buf: []*build.BuildCommand = GenericCommand(build.BuildCommand, "build").commands(allocator, node);
        const format_cmd_buf: []*build.FormatCommand = GenericCommand(build.FormatCommand, "format").commands(allocator, node);
        const objcopy_cmd_buf: []*build.ObjcopyCommand = GenericCommand(build.ObjcopyCommand, "objcopy").commands(allocator, node);
        const archive_cmd_buf: []*build.ArchiveCommand = GenericCommand(build.ArchiveCommand, "archive").commands(allocator, node);
        if (build_cmd_buf.len != 0) {
            const ld_idx: usize = cmds.build.indexOfCommonLeastDifference(allocator, build_cmd_buf);
            ret.build_cmd = build_cmd_buf[ld_idx].*;
        }
        if (format_cmd_buf.len != 0) {
            const ld_idx: usize = cmds.format.indexOfCommonLeastDifference(allocator, format_cmd_buf);
            ret.format_cmd = format_cmd_buf[ld_idx].*;
        }
        if (objcopy_cmd_buf.len != 0) {
            const ld_idx: usize = cmds.objcopy.indexOfCommonLeastDifference(allocator, objcopy_cmd_buf);
            ret.objcopy_cmd = objcopy_cmd_buf[ld_idx].*;
        }
        if (archive_cmd_buf.len != 0) {
            const ld_idx: usize = cmds.archive.indexOfCommonLeastDifference(allocator, archive_cmd_buf);
            ret.archive_cmd = archive_cmd_buf[ld_idx].*;
        }
        return ret;
    }
};

fn nodes(node: *Node) []*Node {
    return node.impl.nodes[1..node.impl.nodes_len];
}
fn dependencies(node: *Node) []Node.Dependency {
    return node.impl.deps[0..node.impl.deps_len];
}
fn paths(node: *Node) []build.Path {
    return node.impl.paths[0..node.impl.paths_len];
}
fn localGroup(node: *Node) *Node {
    if (node.tag == .group and !node.flags.is_hidden) {
        return node;
    }
    return localGroup(node.impl.nodes[0]);
}
fn countNode(node: *Node, node_tag: build.Node) usize {
    @setRuntimeSafety(false);
    var ret: usize = 0;
    var sn_idx: usize = 0;
    while (sn_idx != node.impl.nodes_len) : (sn_idx +%= 1) {
        ret +%= @intFromBool(node.impl.nodes[sn_idx].tag == node_tag);
    }
    return ret;
}
fn countTask(node: *Node, task_tag: build.Task) usize {
    @setRuntimeSafety(false);
    var ret: usize = 0;
    var sn_idx: usize = 0;
    while (sn_idx != node.impl.nodes_len) : (sn_idx +%= 1) {
        ret +%= @intFromBool(node.impl.nodes[sn_idx].task.tag == task_tag);
    }
    return ret;
}
fn nextWorker(group: *Node, cmd_state: *CommandState) ?*Node {
    @setRuntimeSafety(builtin.is_safe);
    var ret: ?*Node = null;
    var min_edit_dist: usize = ~@as(usize, 0);
    for (nodes(group)) |node| {
        if (node.tag != .worker) {
            continue;
        }
        if (!node.flags.do_regenerate) {
            continue;
        }
        const edit_dist: usize = switch (node.task.tag) {
            .build => cmds.build.fieldEditDistance(&cmd_state.build_cmd.?, node.task.cmd.build),
            .format => cmds.format.fieldEditDistance(&cmd_state.format_cmd.?, node.task.cmd.format),
            .objcopy => cmds.objcopy.fieldEditDistance(&cmd_state.objcopy_cmd.?, node.task.cmd.objcopy),
            .archive => cmds.archive.fieldEditDistance(&cmd_state.archive_cmd.?, node.task.cmd.archive),
            .run => 0,
            else => @panic(@tagName(node.task.tag)),
        };
        if (edit_dist == 0) {
            node.flags.do_regenerate = false;
            return node;
        }
        if (edit_dist < min_edit_dist) {
            min_edit_dist = edit_dist;
            ret = node;
        }
    }
    if (ret) |node| {
        node.flags.do_regenerate = false;
    }
    return ret;
}
fn isToplevel(node: *Node) bool {
    return node.tag == .group and node == node.impl.nodes[0];
}
fn isInlinedGroup(node: *Node) bool {
    return node.tag == .group and node.flags.is_hidden;
}
fn isInlined(node: *Node) bool {
    if (node.tag == .group) {
        return node.flags.is_hidden;
    }
    return isInlined(node.impl.nodes[0]);
}
fn detectToplevelArgs(node: *Node) bool {
    if (node.impl.args_len > 3) {
        return node.impl.args[0] == node.zigExe().ptr and
            node.impl.args[1] == node.buildRoot().ptr and
            node.impl.args[2] == node.cacheRoot().ptr and
            node.impl.args[3] == node.globalCacheRoot().ptr;
    }
    return false;
}
fn writeConstTagCmd(array: *Array, tag: build.Task) void {
    array.writeMany("const ");
    array.writeMany(@tagName(tag));
    array.writeMany("_cmd:");
}
fn writeWorkerCommandSymbol(allocator: *build.Allocator, array: *Array, group: *Node, tag: build.Task) void {
    array.writeFormat(fmt.identifier(localCommandName(allocator, localName(allocator, group), tag)));
}
fn writeStringLiteral(array: *Array, string: []const u8) void {
    for (string) |byte| {
        array.writeMany(fmt.stringLiteralChar(byte));
    }
}
fn writeRelativePath(allocator: *build.Allocator, array: *Array, path: build.Path) void {
    const pathname: []const u8 = path.concatenate(allocator);
    if (mem.testEqualManyFront(u8, builtin.root.build_root, pathname)) {
        writeStringLiteral(array, pathname[builtin.root.build_root.len + 1 ..]);
    } else {
        writeStringLiteral(array, pathname);
    }
}
fn writeDeclareWorkerBuildCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(cmds.build.renderWriteBuf(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDeclareWorkerFormatCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(cmds.format.renderWriteBuf(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDeclareWorkerArchiveCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(cmds.archive.renderWriteBuf(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDeclareWorkerObjcopyCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(cmds.objcopy.renderWriteBuf(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDescribeNode(allocator: *build.Allocator, array: *Array, node: *Node) void {
    if (node.descr.len == 0) {
        return;
    }
    writeLocalName(allocator, array, node);
    array.writeMany(".descr=\"");
    writeStringLiteral(array, node.descr);
    array.writeMany("\";\n");
}
fn writeAddWorkerExtra(allocator: *build.Allocator, array: *Array, _: *Node, node: *Node) void {
    const save: usize = allocator.next;
    switch (node.task.tag) {
        .build => {
            array.writeMany(",\"");
            writeRelativePath(allocator, array, node.impl.paths[1]);
            array.writeMany("\"");
        },
        .format => {
            array.writeMany(",\"");
            writeRelativePath(allocator, array, node.impl.paths[0]);
            array.writeMany("\"");
        },
        .run => {},
        else => {},
    }
    allocator.next = save;
}
fn writeAddWorker(allocator: *build.Allocator, array: *Array, group: *Node, cmd_state: *CommandState, node: *Node) void {
    const save: usize = allocator.next;
    defer allocator.next = save;
    writeWorkerCommandFieldEdits(allocator, array, group, cmd_state, node);
    array.writeMany("const ");
    writeLocalName(allocator, array, node);
    array.writeMany(":*Node=");
    writeLocalName(allocator, array, group);
    switch (node.task.tag) {
        .build => array.writeMany(".addBuild("),
        .archive => array.writeMany(".addArchive("),
        .objcopy => array.writeMany(".addObjcopy("),
        .format => array.writeMany(".addFormat("),
        .run => array.writeMany(".addRun("),
        else => {},
    }
    array.writeMany("allocator,");
    if (node.task.tag != .run) {
        writeWorkerCommandSymbol(allocator, array, group, node.task.tag);
        array.writeOne(',');
    }
    array.writeMany("\"");
    array.writeMany(node.name);
    array.writeMany("\"");
    writeAddWorkerExtra(allocator, array, group, node);
    array.writeMany(");\n");
}
fn writeNodeNameLocal(buf: [*]u8, node: *const Node, sep: u8) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = buf;
    if (node.tag == .group) {
        if (node.flags.is_hidden) {
            if (node.impl.nodes[0].flags.is_hidden) {
                ptr += writeNodeNameLocal(buf, node.impl.nodes[0], '_');
            }
            if (ptr != buf) {
                ptr[0] = sep;
                ptr += 1;
            }
            @memcpy(ptr, node.name);
            ptr += node.name.len;
        } else {
            if (node.flags.is_toplevel) {
                ptr[0..8].* = "toplevel".*;
                ptr += 8;
            } else {
                ptr[0..5].* = "group".*;
                ptr += 5;
            }
        }
    } else {
        if (node.impl.nodes[0].flags.is_hidden) {
            ptr += writeNodeNameLocal(buf, node.impl.nodes[0], '_');
        }
        if (ptr != buf) {
            ptr[0] = sep;
            ptr += 1;
        }
        @memcpy(ptr, node.name);
        ptr += node.name.len;
    }

    return @intFromPtr(ptr) -% @intFromPtr(buf);
}
fn lengthNodeNameLocal(node: *const Node) usize {
    @setRuntimeSafety(builtin.is_safe);
    var len: usize = 0;
    if (node.tag == .group) {
        if (node.flags.is_hidden) {
            if (node.impl.nodes[0].flags.is_hidden) {
                len +%= lengthNodeNameLocal(node.impl.nodes[0]);
            }
            len +%= @intFromBool(len != 0);
            len +%= node.name.len;
        } else {
            if (node.flags.is_toplevel) len +%= 8 else len +%= 5;
        }
    } else {
        if (node.impl.nodes[0].flags.is_hidden) {
            len +%= lengthNodeNameLocal(node.impl.nodes[0]);
        }
        len +%= @intFromBool(len != 0);
        len +%= node.name.len;
    }
    return len;
}
fn localFlags(allocator: *build.Allocator, node: *Node) []const u8 {
    @setRuntimeSafety(builtin.is_safe);
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(lengthNodeNameLocal(node) +% 6, 1));
    const len: usize = writeNodeNameLocal(buf, node, '_');
    @as(*[6]u8, @ptrCast(buf + len)).* = ".flags".*;
    return buf[0 .. len +% 6];
}
fn localCommandName(allocator: *build.Allocator, local_name: []const u8, tag: build.Task) []const u8 {
    @setRuntimeSafety(builtin.is_safe);
    const len: usize = local_name.len +% 1 +% @tagName(tag).len +% 4;
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len, 1));
    var ptr: [*]u8 = buf;
    @memcpy(ptr, local_name);
    ptr += local_name.len;
    ptr[0] = '_';
    ptr += 1;
    @memcpy(ptr, @tagName(tag));
    ptr += @tagName(tag).len;
    ptr[0..4].* = "_cmd".*;
    return buf[0..len];
}
fn localName(allocator: *build.Allocator, node: *Node) []const u8 {
    @setRuntimeSafety(builtin.is_safe);
    const ptr: [*]u8 = @ptrFromInt(allocator.allocateRaw(lengthNodeNameLocal(node), 1));
    return ptr[0..writeNodeNameLocal(ptr, node, '_')];
}
fn writeLocalName(allocator: *build.Allocator, array: *Array, node: *Node) void {
    const save: usize = allocator.next;
    defer allocator.next = save;
    array.writeFormat(fmt.identifier(localName(allocator, node)));
}
fn writeIfClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeWorkerCommandType(array: *Array, tag: build.Task) void {
    switch (tag) {
        .build => array.writeMany("build.BuildCommand"),
        .archive => array.writeMany("build.ArchiveCommand"),
        .objcopy => array.writeMany("build.ObjcopyCommand"),
        .format => array.writeMany("build.FormatCommand"),
        else => {},
    }
}
fn writeWorkerCommandFieldEdits(allocator: *build.Allocator, array: *Array, group: *Node, cmd_state: *CommandState, node: *Node) void {
    const local_name = localName(allocator, group);
    const cmd_name = localCommandName(allocator, local_name, node.task.tag);
    switch (node.task.tag) {
        .build => if (cmd_state.build_cmd) |*local_build_cmd| {
            array.define(cmds.build.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, local_build_cmd, node.task.cmd.build, true));
        },
        .format => if (cmd_state.format_cmd) |*local_format_cmd| {
            array.define(cmds.format.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, local_format_cmd, node.task.cmd.format, true));
        },
        .objcopy => if (cmd_state.objcopy_cmd) |*local_objcopy_cmd| {
            array.define(cmds.objcopy.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, local_objcopy_cmd, node.task.cmd.objcopy, true));
        },
        .archive => if (cmd_state.archive_cmd) |*local_archive_cmd| {
            array.define(cmds.archive.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, local_archive_cmd, node.task.cmd.archive, true));
        },
        else => {},
    }
}
fn detectImplicitDependency(node: *Node, dep: Node.Dependency) bool {
    return node.task.tag == dep.task and dep.on_task == dep.on_node.task.tag;
}
fn writeDependOn(allocator: *build.Allocator, array: *Array, node: *Node, dep: Node.Dependency) void {
    writeLocalName(allocator, array, node);
    if (detectImplicitDependency(node, dep)) {
        array.writeMany(".dependOn(allocator,");
        if (dep.on_node.flags.is_special) {
            array.writeMany("Node.special.");
        }
        writeLocalName(allocator, array, dep.on_node);
    } else {
        array.writeMany(".dependOnFull(allocator,.");
        array.writeMany(@tagName(dep.task));
        array.writeOne(',');
        if (dep.on_node.flags.is_special) {
            array.writeMany("Node.special.");
        }
        writeLocalName(allocator, array, dep.on_node);
        array.writeMany(",.");
        array.writeMany(@tagName(dep.on_task));
    }
    array.writeMany(");\n");
}
fn writeAddToplevelArgs(allocator: *build.Allocator, array: *Array, node: *Node) void {
    writeLocalName(allocator, array, node);
    array.writeMany(".addToplevelArgs(allocator);\n");
}
fn writeDependencies(allocator: *build.Allocator, array: *Array, node: *Node) void {
    if (detectToplevelArgs(node)) {
        writeAddToplevelArgs(allocator, array, node);
    }
    for (dependencies(node)) |dep| {
        writeDependOn(allocator, array, node, dep);
    }
}
fn writeSubGroups(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and !sub_node.flags.is_hidden) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
}
fn writeHiddenSubGroups(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and sub_node.flags.is_hidden) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
}
fn writeWorkers(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and sub_node.flags.is_hidden) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .worker) {
            writeAddWorker(allocator, array, sub_node);
        }
    }
}
fn writeGroupDependencies(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and sub_node.flags.is_hidden) {
            writeGroupDependencies(allocator, array, sub_node);
        }
    }
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .worker) {
            writeDependencies(allocator, array, sub_node);
        }
    }
}
fn writeGroupDescriptions(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and sub_node.flags.is_hidden) {
            writeGroupDescriptions(allocator, array, sub_node);
        }
    }
    for (nodes(node)) |sub_node| {
        if (sub_node.descr.len != 0) {
            writeDescribeNode(allocator, array, sub_node);
        }
    }
}
fn writeFunctionSignature(array: *Array, node: *Node) void {
    if (node.impl.nodes_len == 0) {
        array.writeMany("pub fn @\"");
        array.writeMany(node.name);
        array.writeMany("Group\"(_:*build.Allocator,_:*Node)void{\n");
    } else {
        array.writeMany("pub fn @\"");
        array.writeMany(node.name);
        array.writeMany("Group\"(allocator:*build.Allocator,group:*Node)void{\n");
    }
}
fn writeDeclareGroup(allocator: *build.Allocator, array: *Array, toplevel: *Node, node: *Node) void {
    if (!node.flags.do_regenerate or
        node.flags.is_special)
    {
        return;
    }
    var cmd_state: CommandState = CommandState.init(allocator, node);
    const save: usize = allocator.next;
    defer allocator.next = save;
    writeSubGroups(allocator, array, node);

    if (node.flags.is_hidden) {
        writeAddHiddenGroup(allocator, array, toplevel, node);
    } else {
        writeFunctionSignature(array, node);
        writeDescribeNode(allocator, array, node);
    }
    const local_name = localName(allocator, node);
    if (cmd_state.build_cmd) |*local_build_cmd| {
        if (countTask(node, .build) != 0) {
            const cmd_name = localCommandName(allocator, local_name, .build);
            array.writeMany("var ");
            array.writeFormat(fmt.identifier(cmd_name));
            array.writeMany(":build.BuildCommand=build_cmd;\n");
            if (CommandState.toplevel.build_cmd) |*build_cmd| {
                array.define(cmds.build.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, build_cmd, local_build_cmd, false));
            }
        }
    }
    if (cmd_state.format_cmd) |*local_format_cmd| {
        if (countTask(node, .format) != 0) {
            const cmd_name = localCommandName(allocator, local_name, .format);
            array.writeMany("var ");
            array.writeFormat(fmt.identifier(cmd_name));
            array.writeMany(":build.FormatCommand=format_cmd;\n");
            if (CommandState.toplevel.format_cmd) |*format_cmd| {
                array.define(cmds.format.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, format_cmd, local_format_cmd, false));
            }
        }
    }
    if (cmd_state.objcopy_cmd) |*local_objcopy_cmd| {
        if (countTask(node, .objcopy) != 0) {
            const cmd_name = localCommandName(allocator, local_name, .objcopy);
            array.writeMany("var ");
            array.writeFormat(fmt.identifier(cmd_name));
            array.writeMany(":build.objcopyCommand=objcopy_cmd;\n");
            if (CommandState.toplevel.objcopy_cmd) |*objcopy_cmd| {
                array.define(cmds.objcopy.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, objcopy_cmd, local_objcopy_cmd, false));
            }
        }
    }
    if (cmd_state.archive_cmd) |*local_archive_cmd| {
        if (countTask(node, .objcopy) != 0) {
            const cmd_name = localCommandName(allocator, local_name, .archive);
            array.writeMany("var ");
            array.writeFormat(fmt.identifier(cmd_name));
            array.writeMany(":build.archiveCommand=archive_cmd;\n");
            if (CommandState.toplevel.archive_cmd) |*archive_cmd| {
                array.define(cmds.archive.writeFieldEditDistance(array.referAllUndefined().ptr, cmd_name, archive_cmd, local_archive_cmd, false));
            }
        }
    }
    writeHiddenSubGroups(allocator, array, node);
    while (nextWorker(node, &cmd_state)) |sub_node| {
        writeAddWorker(allocator, array, node, &cmd_state, sub_node);
    }
    if (node.flags.is_hidden) {
        return;
    }
    for (nodes(node)) |sub_node| {
        if (sub_node.tag == .group and !sub_node.flags.is_hidden) {
            writeAddGroup(allocator, array, node, sub_node);
        }
    }
    writeGroupDescriptions(allocator, array, node);
    writeGroupDependencies(allocator, array, node);
    writeIfClose(array);
}
fn writeAddHiddenGroup(allocator: *build.Allocator, array: *Array, group: *Node, node: *Node) void {
    array.writeMany("const ");
    writeLocalName(allocator, array, node);
    array.writeMany("=");
    writeLocalName(allocator, array, group);
    if (node.task.tag != .any) {
        array.writeMany(".addGroupWithTask(allocator,\"");
        writeStringLiteral(array, node.name);
        array.writeMany("\",.");
        array.writeMany(@tagName(node.task.tag));
        array.writeMany(");\n");
    } else {
        array.writeMany(".addGroup(allocator,\"");
        writeStringLiteral(array, node.name);
        array.writeMany("\");\n");
    }
}
fn writeAddGroup(allocator: *build.Allocator, array: *Array, group: *Node, node: *Node) void {
    if (!node.flags.do_regenerate or
        node.flags.is_special)
    {
        return;
    }
    array.writeMany("@\"");
    array.writeMany(node.name);
    array.writeMany("Group\"(allocator,");
    writeLocalName(allocator, array, group);
    if (node.task.tag != .any) {
        array.writeMany(".addGroupWithTask(allocator,\"");
        writeStringLiteral(array, node.name);
        array.writeMany("\",.");
        array.writeMany(@tagName(node.task.tag));
        array.writeMany("));\n");
    } else {
        array.writeMany(".addGroup(allocator,\"");
        writeStringLiteral(array, node.name);
        array.writeMany("\"));\n");
    }
}
fn writeBuildMain(allocator: *build.Allocator, array: *Array, toplevel: *Node) void {
    array.writeMany("pub const zl=@import(\"../../zig_lib.zig\");\n");
    array.writeMany("const spec=zl.spec;\n");
    array.writeMany("const build=zl.build;\n");
    array.writeMany("const Node = build.GenericNode(");
    array.writeMany(comptime fmt.eval(.{ .infer_type_names = true }, Node.specification));
    array.writeMany(");\n");
    if (CommandState.toplevel.build_cmd) |toplevel_build_cmd| {
        writeDeclareWorkerBuildCommand(array, .build, toplevel_build_cmd);
    }
    if (CommandState.toplevel.format_cmd) |toplevel_format_cmd| {
        writeDeclareWorkerFormatCommand(array, .format, toplevel_format_cmd);
    }
    if (CommandState.toplevel.objcopy_cmd) |toplevel_objcopy_cmd| {
        writeDeclareWorkerObjcopyCommand(array, .objcopy, toplevel_objcopy_cmd);
    }
    if (CommandState.toplevel.archive_cmd) |toplevel_archive_cmd| {
        writeDeclareWorkerArchiveCommand(array, .archive, toplevel_archive_cmd);
    }
    for (nodes(toplevel)) |sub_node| {
        if (sub_node.tag == .group) {
            writeDeclareGroup(allocator, array, toplevel, sub_node);
        }
    }
    if (nodes(toplevel).len == 0) {
        array.writeMany("pub fn buildMain(_:*build.Allocator,_:*Node)void{\n");
    } else {
        array.writeMany("pub fn buildMain(allocator:*build.Allocator,toplevel:*Node)void{\n");
    }
    writeDescribeNode(allocator, array, toplevel);
    for (nodes(toplevel)) |sub_node| {
        if (sub_node.tag == .group) {
            writeAddGroup(allocator, array, toplevel, sub_node);
        }
    }
    writeIfClose(array);
}
fn buildRunnerInit(args: [][*:0]u8, vars: [][*:0]u8, allocator: *build.Allocator) *Node {
    @setRuntimeSafety(builtin.is_safe);
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const group: *Node = try meta.wrap(Node.init(allocator, args, vars));
    group.addSpecialNodes(allocator);
    try meta.wrap(
        root.buildMain(allocator, group),
    );
    if (args.len > 5) {
        parseCommands(allocator, group, args[5..]);
    }
    return group;
}
fn resolveGroup(group: *Node, name: []const u8) ?*Node {
    @setRuntimeSafety(false);
    var idx: usize = 0;
    while (idx != name.len) : (idx +%= 1) {
        if (name[idx] == '.') {
            break;
        }
    } else {
        idx = 0;
        while (idx != group.impl.nodes_len) : (idx +%= 1) {
            if (group.impl.nodes[idx].tag == .group and
                mem.testEqualString(name, group.impl.nodes[idx].name))
            {
                return group.impl.nodes[idx];
            }
        }
        return group;
    }
    const sub_name: []const u8 = name[0..idx];
    idx +%= 1;
    if (idx == name.len) {
        return null;
    }
    idx = 0;
    while (idx != group.impl.nodes_len) : (idx +%= 1) {
        if (group.impl.nodes[idx].tag == .group and
            mem.testEqualString(sub_name, group.impl.nodes[idx].name))
        {
            return group.impl.nodes[idx].find(sub_name);
        }
    }
    return null;
}
fn addGroup(allocator: *build.Allocator, toplevel: *Node, args: [][*:0]u8) void {
    const name = mem.terminate(args[0], 0);
    if (toplevel.find(name)) |_| {
        about.invalidNodeNameError();
    }
    if (resolveGroup(toplevel, name)) |group| {
        var basename: []const u8 = mem.readAfterLastEqualOne(u8, '.', name) orelse name;
        const node: *Node = group.addGroup(allocator, basename);
        node.descr = "<description>";
    }
}
fn addBuild(allocator: *build.Allocator, kind: build.OutputMode, toplevel: *Node, args: [][*:0]u8) void {
    const name = mem.terminate(args[0], 0);

    if (resolveGroup(toplevel, name)) |group| {
        var basename: []const u8 = mem.readAfterLastEqualOne(u8, '.', name) orelse name;
        var new_build_cmd: build.BuildCommand = .{ .kind = kind };
        cmds.build.formatParseArgs(&new_build_cmd, allocator, args);
        const node: *Node = group.addBuild(allocator, new_build_cmd, basename, "here.zig");
        node.descr = "<description>";
    }
}
fn addFormat(_: *build.Allocator, _: *Node, _: [][*:0]u8) void {}
fn addObjcopy(_: *build.Allocator, _: *Node, _: [][*:0]u8) void {}
fn addArchive(_: *build.Allocator, _: *Node, _: [][*:0]u8) void {}
fn parseCommands(allocator: *build.Allocator, toplevel: *Node, args: [][*:0]u8) void {
    var args_idx: usize = 0;
    var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
    if (mem.testEqualString(arg, "rm")) {
        args_idx +%= 1;
        if (args_idx == args.len) {
            about.missingTaskInformationError();
        }
        if (toplevel.find(mem.terminate(args[args_idx], 0))) |node| {
            about.aboutRemovedNodeNotice(node);
            node.flags.do_regenerate = false;
        }
    } else if (mem.testEqualString(arg, "add")) {
        args_idx +%= 1;
        if (args_idx == args.len) {
            about.missingTaskInformationError();
        }
        arg = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString(arg, "group")) {
            args_idx +%= 1;
            if (args_idx == args.len) {
                about.aboutListGroups(toplevel);
                about.missingGroupInfoError();
            }
            addGroup(allocator, toplevel, args[args_idx..]);
        } else if (mem.testEqualString(arg, "build")) {
            args_idx +%= 1;
            if (args_idx == args.len) {
                about.missingBuildTaskInfoError();
            }
            arg = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString(arg, "exe")) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    about.missingBuildExeTaskInfoError();
                }
                addBuild(allocator, .exe, toplevel, args[args_idx..]);
            } else if (mem.testEqualString(arg, "obj")) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    about.missingBuildObjTaskInfoError();
                }
                addBuild(allocator, .obj, toplevel, args[args_idx..]);
            } else if (mem.testEqualString(arg, "lib")) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    about.missingBuildLibTaskInfoError();
                }
                addBuild(allocator, .lib, toplevel, args[args_idx..]);
            } else {
                about.invalidBuildKindError();
            }
        } else if (mem.testEqualString(arg, "format")) {
            addFormat(allocator, toplevel, args[args_idx..]);
        } else if (mem.testEqualString(arg, "archive")) {
            addArchive(allocator, toplevel, args[args_idx..]);
        } else if (mem.testEqualString(arg, "objcopy")) {
            addObjcopy(allocator, toplevel, args[args_idx..]);
        }
    }
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var build_allocator: build.Allocator = build.Allocator.init_arena(
        Node.AddressSpace.arena(Node.specification.options.max_thread_count),
    );
    const toplevel: *Node = buildRunnerInit(args, vars, &build_allocator);
    var allocator: build.Allocator = .{};
    var array: *Array = allocator.create(Array);
    CommandState.toplevel = CommandState.init(&allocator, toplevel);
    writeBuildMain(&allocator, array, toplevel);
    try gen.truncateFile(.{}, builtin.root.build_root ++ "/top/build/rebuild.zig", array.readAll());
}
const about = struct {
    fn aboutResolvedGroupNotice(node: *Node) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..16].* = "resolved group: ".*;
        ptr = ptr + 16;
        @memcpy(ptr, node.name);
        ptr = ptr + node.name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
    }
    fn aboutRemovedNodeNotice(node: *Node) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr[0..14].* = "removed node: ".*;
        ptr = ptr + 14;
        @memcpy(ptr, node.name);
        ptr = ptr + node.name.len;
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
    }
    fn aboutListGroupsInternal(buf: [*]u8, node: *Node) usize {
        var ptr: [*]u8 = buf;
        for (nodes(node)) |sub_node| {
            if (sub_node.tag == .group) {
                @memcpy(ptr, sub_node.name);
                ptr = ptr + sub_node.name.len;
                ptr[0] = '\n';
                ptr = ptr + 1;
                ptr = ptr + aboutListGroupsInternal(ptr, sub_node);
            }
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    fn aboutListGroups(toplevel: *Node) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = &buf;
        ptr = ptr + aboutListGroupsInternal(ptr, toplevel);
        debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
    }
    fn invalidNodeNameError() noreturn {
        @panic("invalid node name");
    }
    fn missingGroupInfoError() void {
        @panic("missing group information");
    }
    fn missingBuildTaskInfoError() void {
        @panic("missing build task information");
    }
    fn missingBuildExeTaskInfoError() void {
        @panic("missing build-exe task information");
    }
    fn missingBuildObjTaskInfoError() void {
        @panic("missing build-obj task information");
    }
    fn missingBuildLibTaskInfoError() void {
        @panic("missing build-lib task information");
    }
    fn invalidBuildKindError() void {
        @panic("invalid build kind");
    }
    fn missingTaskInformationError() void {
        @panic("missing task information");
    }
    fn requestedNameIsGroupInNodeError() void {
        @panic("requested name is existing group node");
    }
    fn requestedNameIsWorkerInNodeError() void {
        @panic("requested name is existing worker");
    }
};
