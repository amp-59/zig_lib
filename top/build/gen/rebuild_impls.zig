const root = @import("@build");

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

const parse = build.parse;
pub usingnamespace zl.start;

pub const want_regen_metadata: bool = true;
pub const runtime_assertions: bool = false;
pub const logging_override: debug.Logging.Override = .{
    .Attempt = null,
    .Success = null,
    .Acquire = false,
    .Release = false,
    .Error = null,
    .Fault = null,
};
const Array = mem.StaticString(64 * 1024 * 1024);
const Array2 = mem.StaticString(64 * 1024);
const Node = @typeInfo(@typeInfo(@TypeOf(root.buildMain)).Fn.params[1].type.?).Pointer.child;
const Task = @TypeOf(@as(Node, undefined).task.cmd);
const BuildCommands = GenericCommand(build.BuildCommand, "build");
const FormatCommands = GenericCommand(build.FormatCommand, "format");
const ObjcopyCommands = GenericCommand(build.ObjcopyCommand, "objcopy");
const ArchiveCommands = GenericCommand(build.ArchiveCommand, "archive");
extern fn fieldEditDistanceObjcopy(args: *const struct {
    s_cmd: *build.ObjcopyCommand,
    t_cmd: *build.ObjcopyCommand,
}) usize;
extern fn writeFieldEditsObjcopy(args: *const struct {
    buf: [*]u8,
    node_name: []const u8,
    s_cmd: *build.ObjcopyCommand,
    t_cmd: *build.ObjcopyCommand,
    commit: bool,
}) usize;
extern fn indexOfCommonLeastDifferenceObjcopy(args: *const struct {
    allocator: *build.Allocator,
    buf: []*build.ObjcopyCommand,
}) usize;
extern fn fieldEditDistanceArchive(args: *const struct {
    s_cmd: *build.ArchiveCommand,
    t_cmd: *build.ArchiveCommand,
}) usize;
extern fn writeFieldEditsArchive(args: *const struct {
    buf: [*]u8,
    node_name: []const u8,
    s_cmd: *build.ArchiveCommand,
    t_cmd: *build.ArchiveCommand,
    commit: bool,
}) usize;
extern fn indexOfCommonLeastDifferenceArchive(args: *const struct {
    allocator: *build.Allocator,
    buf: []*build.ArchiveCommand,
}) usize;
extern fn fieldEditDistanceFormat(args: *const struct {
    s_cmd: *build.FormatCommand,
    t_cmd: *build.FormatCommand,
}) usize;
extern fn writeFieldEditsFormat(args: *const struct {
    buf: [*]u8,
    node_name: []const u8,
    s_cmd: *build.FormatCommand,
    t_cmd: *build.FormatCommand,
    commit: bool,
}) usize;
extern fn indexOfCommonLeastDifferenceFormat(args: *const struct {
    allocator: *build.Allocator,
    buf: []*build.FormatCommand,
}) usize;
extern fn fieldEditDistanceBuild(args: *const struct {
    s_cmd: *build.BuildCommand,
    t_cmd: *build.BuildCommand,
}) usize;
extern fn writeFieldEditsBuild(args: *const struct {
    buf: [*]u8,
    node_name: []const u8,
    s_cmd: *build.BuildCommand,
    t_cmd: *build.BuildCommand,
    commit: bool,
}) usize;
extern fn indexOfCommonLeastDifferenceBuild(args: *const struct {
    allocator: *build.Allocator,
    buf: []*build.BuildCommand,
}) usize;
extern fn formatWriteBuf(build_cmd: *const build.BuildCommand, buf: [*]u8) usize;
extern fn formatWriteBufBuildCommand(build_cmd: *const build.BuildCommand, buf: [*]u8) usize;
extern fn formatWriteBufFormatCommand(format_cmd: *const build.FormatCommand, buf: [*]u8) usize;
extern fn formatWriteBufArchiveCommand(ar_cmd: *const build.ArchiveCommand, buf: [*]u8) usize;
extern fn formatWriteBufObjcopyCommand(objcopy_cmd: *const build.ObjcopyCommand, buf: [*]u8) usize;
extern fn formatWriteBufBuilderSpecOptions(options: *const build.BuilderSpec.Options, buf: [*]u8) usize;
fn GenericCommand(comptime Command: type, comptime field_name: []const u8) type {
    return struct {
        const tag = @field(build.Task, field_name);
        fn commandsLength(node: *Node) usize {
            @setRuntimeSafety(false);
            var len: usize = 0;
            for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
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
            for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
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
        @setRuntimeSafety(false);
        const save: usize = allocator.next;
        defer allocator.next = save;
        var ret: CommandState = .{};
        const build_cmd_buf: []*build.BuildCommand = BuildCommands.commands(allocator, node);
        const format_cmd_buf: []*build.FormatCommand = FormatCommands.commands(allocator, node);
        const objcopy_cmd_buf: []*build.ObjcopyCommand = ObjcopyCommands.commands(allocator, node);
        const archive_cmd_buf: []*build.ArchiveCommand = ArchiveCommands.commands(allocator, node);
        if (build_cmd_buf.len != 0) {
            const ld_idx: usize = indexOfCommonLeastDifferenceBuild(&.{
                .allocator = allocator,
                .buf = build_cmd_buf,
            });
            ret.build_cmd = build_cmd_buf[ld_idx].*;
        }
        if (format_cmd_buf.len != 0) {
            const ld_idx: usize = indexOfCommonLeastDifferenceFormat(&.{
                .allocator = allocator,
                .buf = format_cmd_buf,
            });
            ret.format_cmd = format_cmd_buf[ld_idx].*;
        }
        if (objcopy_cmd_buf.len != 0) {
            const ld_idx: usize = indexOfCommonLeastDifferenceObjcopy(&.{
                .allocator = allocator,
                .buf = objcopy_cmd_buf,
            });
            ret.objcopy_cmd = objcopy_cmd_buf[ld_idx].*;
        }
        if (archive_cmd_buf.len != 0) {
            const ld_idx: usize = indexOfCommonLeastDifferenceArchive(&.{
                .allocator = allocator,
                .buf = archive_cmd_buf,
            });
            ret.archive_cmd = archive_cmd_buf[ld_idx].*;
        }
        return ret;
    }
};
const Generic = struct {
    fn nodes(node: *Node) []*Node {
        return node.impl.nodes[0..node.impl.nodes_len];
    }
    fn dependencies(node: *Node) []Node.Dependency {
        return node.impl.deps[0..node.impl.deps_len];
    }
    fn paths(node: *Node) []build.Path {
        return node.impl.paths[0..node.impl.paths_len];
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
};
fn isHidden(node: *Node) bool {
    return node.name[0] == '_' or node.flags.is_hidden;
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
fn nextWorker(group: *Node, cmd_state: *CommandState) ?*Node {
    var ret: ?*Node = null;
    var min_edit_dist: usize = ~@as(usize, 0);
    for (Generic.nodes(group)) |node| {
        if (node.tag != .worker) {
            continue;
        }
        if (!node.flags.do_regenerate) {
            continue;
        }
        const edit_dist: usize = switch (node.task.tag) {
            .build => fieldEditDistanceBuild(&.{
                .s_cmd = &cmd_state.build_cmd.?,
                .t_cmd = node.task.cmd.build,
            }),
            .format => fieldEditDistanceFormat(&.{
                .s_cmd = &cmd_state.format_cmd.?,
                .t_cmd = node.task.cmd.format,
            }),
            .objcopy => fieldEditDistanceObjcopy(&.{
                .s_cmd = &cmd_state.objcopy_cmd.?,
                .t_cmd = node.task.cmd.objcopy,
            }),
            .archive => fieldEditDistanceArchive(&.{
                .s_cmd = &cmd_state.archive_cmd.?,
                .t_cmd = node.task.cmd.archive,
            }),
            else => unreachable,
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
fn writeWorkerCommandFieldEdits(array: *Array, group: *Node, cmd_state: *CommandState, node: *Node) void {
    switch (node.task.tag) {
        .build => if (cmd_state.build_cmd) |*local_build_cmd| {
            array.define(writeFieldEditsBuild(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = group.name,
                .s_cmd = local_build_cmd,
                .t_cmd = node.task.cmd.build,
                .commit = true,
            }));
        },
        .format => if (cmd_state.format_cmd) |*local_format_cmd| {
            array.define(writeFieldEditsFormat(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = group.name,
                .s_cmd = local_format_cmd,
                .t_cmd = node.task.cmd.format,
                .commit = true,
            }));
        },
        .objcopy => if (cmd_state.objcopy_cmd) |*local_objcopy_cmd| {
            array.define(writeFieldEditsObjcopy(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = group.name,
                .s_cmd = local_objcopy_cmd,
                .t_cmd = node.task.cmd.objcopy,
                .commit = true,
            }));
        },
        .archive => if (cmd_state.archive_cmd) |*local_archive_cmd| {
            array.define(writeFieldEditsArchive(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = group.name,
                .s_cmd = local_archive_cmd,
                .t_cmd = node.task.cmd.archive,
                .commit = true,
            }));
        },
        else => {},
    }
}
fn writeWorkerCommandSymbol(array: *Array, group: *Node, tag: build.Task) void {
    array.writeMany(group.name);
    array.writeOne('_');
    array.writeMany(@tagName(tag));
    array.writeMany("_cmd");
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
    array.define(formatWriteBufBuildCommand(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeConstTagCmd(array: *Array, tag: build.Task) void {
    array.writeMany("const ");
    array.writeMany(@tagName(tag));
    array.writeMany("_cmd:");
}
fn writeDeclareWorkerFormatCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(formatWriteBufFormatCommand(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDeclareWorkerArchiveCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(formatWriteBufArchiveCommand(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDeclareWorkerObjcopyCommand(array: *Array, tag: build.Task, cmd: anytype) void {
    writeConstTagCmd(array, tag);
    writeWorkerCommandType(array, tag);
    array.writeOne('=');
    array.define(formatWriteBufObjcopyCommand(&cmd, array.referAllUndefined().ptr));
    array.writeMany(";\n");
}
fn writeDescribeNode(array: *Array, node: *Node) void {
    array.writeFormat(fmt.identifier(node.name));
    array.writeMany(".descr=\"");
    if (node.descr.len != 0) {
        writeStringLiteral(array, node.descr);
    }
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
        else => {},
    }
    allocator.next = save;
}
fn writeAddWorker(allocator: *build.Allocator, array: *Array, group: *Node, cmd_state: *CommandState, node: *Node) void {
    //if (!node.flags.do_regenerate) {
    //    return;
    //}
    writeWorkerCommandFieldEdits(array, group, cmd_state, node);
    array.writeMany("const ");
    array.writeFormat(fmt.identifier(node.name));
    array.writeMany(":*Node=");
    array.writeFormat(fmt.identifier(group.name));
    switch (node.task.tag) {
        .build => array.writeMany(".addBuild("),
        .archive => array.writeMany(".addArchive("),
        .objcopy => array.writeMany(".addObjcopy("),
        .format => array.writeMany(".addFormat("),
        else => {},
    }
    array.writeMany("allocator,");
    writeWorkerCommandSymbol(array, group, node.task.tag);
    array.writeMany(",\"");
    array.writeMany(node.name);
    array.writeMany("\"");
    writeAddWorkerExtra(allocator, array, group, node);
    array.writeMany(");\n");
}
// dependOnObject = If depend on node (build, build) + dep is object + has dep binary path
fn writeDependOn(array: *Array, node: *Node, dep: Node.Dependency) void {
    array.writeFormat(fmt.identifier(node.name));
    array.writeMany(".dependOnFull(allocator,.");
    array.writeMany(@tagName(dep.task));
    array.writeOne(',');
    array.writeFormat(fmt.identifier(dep.on_node.name));
    array.writeMany(",.");
    array.writeMany(@tagName(dep.on_task));
    array.writeMany(");\n");
}
fn writeDependencies(array: *Array, node: *Node) void {
    for (Generic.dependencies(node)) |dep| {
        writeDependOn(array, node, dep);
    }
}
fn writeSubGroups(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .group and !isHidden(sub_node)) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
}
fn writeHiddenSubGroups(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .group and isHidden(sub_node)) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
}
fn writeWorkers(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .group and isHidden(sub_node)) {
            writeDeclareGroup(allocator, array, node, sub_node);
        }
    }
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .worker) {
            writeAddWorker(allocator, array, sub_node);
        }
    }
}
fn writeGroupDependencies(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .group and isHidden(sub_node)) {
            writeGroupDependencies(allocator, array, sub_node);
        }
    }
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .worker) {
            writeDependencies(array, sub_node);
        }
    }
}
fn writeGroupDescriptions(allocator: *build.Allocator, array: *Array, node: *Node) void {
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.tag == .group and isHidden(sub_node)) {
            writeGroupDescriptions(allocator, array, sub_node);
        }
    }
    for (Generic.nodes(node)) |sub_node| {
        if (sub_node.descr.len != 0) {
            writeDescribeNode(array, sub_node);
        }
    }
}
fn writeFunctionSignature(array: *Array, node: *Node) void {
    array.writeMany("pub fn @\"");
    array.writeMany(node.name);
    array.writeMany("Group\"(allocator:*build.Allocator,");
    array.writeFormat(fmt.identifier(node.name));
    array.writeMany(":*Node)void{\n");
}
fn writeDeclareGroup(allocator: *build.Allocator, array: *Array, toplevel: *Node, node: *Node) void {
    if (!node.flags.do_regenerate) {
        return;
    }
    var cmd_state: CommandState = CommandState.init(allocator, node);
    const save: usize = allocator.next;
    defer allocator.next = save;
    writeSubGroups(allocator, array, node);
    if (isHidden(node)) {
        writeAddHiddenGroup(array, toplevel, node);
    } else {
        writeFunctionSignature(array, node);
        writeDescribeNode(array, node);
        array.writeMany("const save:usize=allocator.next;\n");
    }
    if (cmd_state.build_cmd) |*local_build_cmd| {
        if (Generic.countTask(node, .build) != 0) {
            array.writeMany("var @\"");
            array.writeMany(node.name);
            array.writeMany("_build_cmd\":build.BuildCommand=build_cmd;\n");
            array.define(writeFieldEditsBuild(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = node.name,
                .s_cmd = &CommandState.toplevel.build_cmd.?,
                .t_cmd = local_build_cmd,
                .commit = false,
            }));
        }
    }
    if (cmd_state.format_cmd) |*local_format_cmd| {
        if (Generic.countTask(node, .format) != 0) {
            array.writeMany("var @\"");
            array.writeMany(node.name);
            array.writeMany("_format_cmd\":build.FormatCommand=format_cmd;\n");
            array.define(writeFieldEditsFormat(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = node.name,
                .s_cmd = &CommandState.toplevel.format_cmd.?,
                .t_cmd = local_format_cmd,
                .commit = false,
            }));
        }
    }
    if (cmd_state.objcopy_cmd) |*local_objcopy_cmd| {
        if (Generic.countTask(node, .objcopy) != 0) {
            array.writeMany("var @\"");
            array.writeMany(node.name);
            array.writeMany("_objcopy_cmd\":build.objcopyCommand=objcopy_cmd;\n");
            array.define(writeFieldEditsObjcopy(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = node.name,
                .s_cmd = &CommandState.toplevel.objcopy_cmd.?,
                .t_cmd = local_objcopy_cmd,
                .commit = false,
            }));
        }
    }
    if (cmd_state.archive_cmd) |*local_archive_cmd| {
        if (Generic.countTask(node, .objcopy) != 0) {
            array.writeMany("var @\"");
            array.writeMany(node.name);
            array.writeMany("_archive_cmd\":build.archiveCommand=archive_cmd;\n");
            array.define(writeFieldEditsArchive(&.{
                .buf = array.referAllUndefined().ptr,
                .node_name = node.name,
                .s_cmd = &CommandState.toplevel.archive_cmd.?,
                .t_cmd = local_archive_cmd,
                .commit = false,
            }));
        }
    }
    writeHiddenSubGroups(allocator, array, node);
    while (nextWorker(node, &cmd_state)) |sub_node| {
        writeAddWorker(allocator, array, node, &cmd_state, sub_node);
    }
    if (isHidden(node)) {
        return;
    }
    writeGroupDescriptions(allocator, array, node);
    writeGroupDependencies(allocator, array, node);
    array.writeMany("debug.assertAboveOrEqual(usize, allocator.next, save);");
    writeIfClose(array);
}
fn writeAddHiddenGroup(array: *Array, toplevel: *Node, node: *Node) void {
    array.writeMany("const ");
    array.writeFormat(fmt.identifier(node.name));
    array.writeMany("=");
    array.writeMany(toplevel.name);
    array.writeMany(".addGroup(allocator,\"");
    writeStringLiteral(array, node.name);
    array.writeMany("\");\n");
}
fn writeAddGroup(array: *Array, toplevel: *Node, node: *Node) void {
    if (!node.flags.do_regenerate) {
        return;
    }
    array.writeMany("@\"");
    array.writeMany(node.name);
    array.writeMany("Group\"(allocator,");
    array.writeMany(toplevel.name);
    array.writeMany(".addGroup(allocator,\"");
    array.writeMany(node.name);
    array.writeMany("\"));\n");
}
fn writeBuildMain(allocator: *build.Allocator, array: *Array, toplevel: *Node) void {
    array.writeMany("pub const zl=@import(\"../../zig_lib.zig\");\n");
    array.writeMany("const proc=zl.proc;\n");
    array.writeMany("const spec=zl.spec;\n");
    array.writeMany("const build=zl.build;\n");
    array.writeMany("const debug=zl.debug;\n");
    array.writeMany("const builtin=zl.builtin;\n");
    array.writeMany(comptime "const Node = build.GenericNode(.{.errors=" ++ fmt.eval(.{ .infer_type_names = true }, Node.specification.errors) ++ "," ++
        ".logging=" ++ fmt.eval(.{ .infer_type_names = true }, Node.specification.errors) ++ "," ++
        ".types=" ++ fmt.eval(.{ .infer_type_names = true }, Node.specification.errors) ++ "," ++
        ".options=");
    array.define(formatWriteBufBuilderSpecOptions(&Node.specification.options, array.referAllUndefined().ptr));
    array.writeMany("});\n");
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
    for (Generic.nodes(toplevel)) |sub_node| {
        if (sub_node.tag == .group) {
            writeDeclareGroup(allocator, array, toplevel, sub_node);
        }
    }
    array.writeMany("pub fn buildMain(allocator:*build.Allocator,toplevel:*Node)void{\n");
    array.writeMany("const save:usize=allocator.next;\n");
    writeDescribeNode(array, toplevel);
    for (Generic.nodes(toplevel)) |sub_node| {
        if (sub_node.tag == .group) {
            writeAddGroup(array, toplevel, sub_node);
        }
    }
    array.writeMany("debug.assertAboveOrEqual(usize, allocator.next, save);");
    array.writeMany("}\n");
}
fn buildRunnerInit(args: [][*:0]u8, vars: [][*:0]u8, allocator: *build.Allocator) *Node {
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    try meta.wrap(
        Node.initState(args, vars),
    );
    const toplevel = try meta.wrap(Node.init(allocator));
    Node.initSpecialNodes(allocator, @ptrCast(toplevel));
    try meta.wrap(
        root.buildMain(allocator, @ptrCast(toplevel)),
    );
    if (args.len > 5) {
        parseCommands(allocator, toplevel, args[5..]);
    }
    return toplevel;
}
fn resolveNode(group: *Node, name: []const u8) ?*Node {
    @setRuntimeSafety(false);
    var idx: usize = 0;
    while (idx != name.len) : (idx +%= 1) {
        if (name[idx] == '.') {
            break;
        }
    } else {
        idx = 0;
        while (idx != group.impl.nodes_len) : (idx +%= 1) {
            if (mem.testEqualString(name, group.impl.nodes[idx].name)) {
                return group.impl.nodes[idx];
            }
        }
        return null;
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
            return resolveNode(group.impl.nodes[idx], sub_name);
        }
    }
    return null;
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
            return resolveNode(group.impl.nodes[idx], sub_name);
        }
    }
    return null;
}
fn checkDuplicateName(node: *Node, name: []const u8) void {
    for (Generic.nodes(node)) |sub_node| {
        if (mem.testEqualString(sub_node.name, name)) {
            @panic("node already exists in group");
        }
    }
}
fn addGroup(allocator: *build.Allocator, toplevel: *Node, args: [][*:0]u8) void {
    const name = mem.terminate(args[0], 0);
    if (resolveNode(toplevel, name)) |_| {
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
    if (resolveNode(toplevel, name)) |node| {
        _ = node;
        about.invalidNodeNameError();
    }
    if (resolveGroup(toplevel, name)) |group| {
        var basename: []const u8 = mem.readAfterLastEqualOne(u8, '.', name) orelse name;
        var new_build_cmd: build.BuildCommand = .{ .kind = kind };
        parse.build(&new_build_cmd, allocator, args.ptr, args.len);
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
        if (resolveNode(toplevel, mem.terminate(args[args_idx], 0))) |node| {
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
    var build_allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
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
        for (Generic.nodes(node)) |sub_node| {
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
