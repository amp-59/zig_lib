const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

pub const Builder = zl.builder.GenericBuilder(.{
    .options = .{ .extensions_policy = .emergency },
});
const Node = Builder.Node;

const BuildComamnd = zl.gen.StructEditor(.{}, zl.builder.tasks.BuildCommand);
const FormatComamnd = zl.gen.StructEditor(.{}, zl.builder.tasks.FormatCommand);
const ArchiveComamnd = zl.gen.StructEditor(.{}, zl.builder.tasks.ArchiveCommand);
const ObjcopyComamnd = zl.gen.StructEditor(.{}, zl.builder.tasks.ObjcopyCommand);

var build_cmd: zl.builder.tasks.BuildCommand = .{ .kind = .exe };
var format_cmd: zl.builder.tasks.FormatCommand = .{};
var archive_cmd: zl.builder.tasks.ArchiveCommand = .{ .operation = .r };
var objcopy_cmd: zl.builder.tasks.ObjcopyCommand = .{};

pub fn aboutGroupInternal(node: *Builder.Node, cmds: zl.builder.tasks.Command) void {
    var name_buf: [4096]u8 = undefined;
    if (node.flags.is_group) {
        var itr: Node.Iterator = Node.Iterator.init(node);
        for (itr.nodes[1..]) |sub_node| {
            if (sub_node.flags.is_group) {
                var buf: [4096]u8 = undefined;
                var ptr: [*]u8 = &buf;
                ptr[0..6].* = "const ".*;
                ptr += 6;
                ptr = Node.writeNameFull(ptr, sub_node, '_');
                ptr[0] = '=';
                ptr += 1;
                if (node.flags.is_top) {
                    ptr[0..8].* = "toplevel".*;
                    ptr += 8;
                } else {
                    ptr = Node.writeNameFull(ptr, node, '_');
                }
                ptr[0..20].* = ".addGroup(allocator,".*;
                ptr += 20;
                ptr += zl.fmt.stringLiteral(sub_node.name).formatWriteBuf(ptr);
                ptr[0] = ',';
                ptr += 1;
                ptr[0] = '\n';
                ptr += 1;
                zl.debug.write(zl.fmt.slice(ptr, &buf));
            } else if (sub_node.flags.have_task_data) {
                var cmd_buf: [4096]u8 = undefined;
                switch (sub_node.tasks.tag) {
                    .build => {
                        var cmd_ptr: [*]u8 = &cmd_buf;
                        cmd_ptr += BuildComamnd.writeFieldEditDistance(&cmd_buf, "build_cmd", cmds.build, sub_node.tasks.cmd.build, true);
                        cmd_ptr[0..6].* = "const ".*;
                        cmd_ptr += 6;
                        cmd_ptr = Node.writeNameFull(cmd_ptr, sub_node, '_');
                        cmd_ptr[0] = '=';
                        cmd_ptr += 1;
                        if (node.flags.is_top) {
                            cmd_ptr[0..8].* = "toplevel".*;
                            cmd_ptr += 8;
                        } else {
                            cmd_ptr = Node.writeNameFull(cmd_ptr, node, '_');
                        }
                        cmd_ptr[0..20].* = ".addBuild(allocator,".*;
                        cmd_ptr += 20;
                        cmd_ptr = zl.fmt.strcpyEqu(cmd_ptr, "build_cmd");
                        cmd_ptr[0] = ',';
                        cmd_ptr += 1;
                        cmd_ptr += zl.fmt.stringLiteral(sub_node.name).formatWriteBuf(cmd_ptr);
                        if (sub_node.getFile(.{ .flags = .{ .is_source = true, .is_input = true } })) |fs| {
                            if (sub_node.getFilePath(fs)) |cp| {
                                cmd_ptr[0] = ',';
                                cmd_ptr += 1;
                                cmd_ptr = zl.file.CompoundPath.writeDisplay(cmd_ptr, cp.*);
                                cmd_ptr[0..3].* = ");\n".*;
                                cmd_ptr += 3;
                                zl.debug.write(zl.fmt.slice(cmd_ptr, &cmd_buf));
                            }
                        }
                    },
                    .format => {
                        const name_ptr: [*]u8 = zl.fmt.strcpyMultiEqu(&name_buf, &.{ node.name, "_format_cmd" });
                        const len: usize = FormatComamnd.writeFieldEditDistance(&cmd_buf, zl.fmt.slice(name_ptr, &name_buf), cmds.format, sub_node.tasks.cmd.format, true);
                        zl.debug.write(cmd_buf[0..len]);
                    },
                    .objcopy => {
                        const name_ptr: [*]u8 = zl.fmt.strcpyMultiEqu(&name_buf, &.{ node.name, "_objcopy_cmd" });
                        const len: usize = ObjcopyComamnd.writeFieldEditDistance(&cmd_buf, zl.fmt.slice(name_ptr, &name_buf), cmds.objcopy, sub_node.tasks.cmd.objcopy, true);
                        zl.debug.write(cmd_buf[0..len]);
                    },
                    .archive => {
                        const name_ptr: [*]u8 = zl.fmt.strcpyMultiEqu(&name_buf, &.{ node.name, "_archive_cmd" });
                        const len: usize = ArchiveComamnd.writeFieldEditDistance(&cmd_buf, zl.fmt.slice(name_ptr, &name_buf), cmds.archive, sub_node.tasks.cmd.archive, true);
                        zl.debug.write(cmd_buf[0..len]);
                    },
                    else => {},
                }
            }
        }
    }
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) void {
    if (args.len < 5) {
        zl.proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    var allocator: zl.builder.types.Allocator = zl.builder.types.Allocator.fromArena(
        Builder.AddressSpace.arena(Builder.specification.options.max_thread_count),
    );
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    const top: *Builder.Node = Builder.Node.init(&allocator, args, vars);
    top.sh.as.lock = &address_space;
    top.sh.ts.lock = &thread_space;
    const cmds: zl.builder.tasks.Command = .{
        .build = &build_cmd,
        .format = &format_cmd,
        .archive = &archive_cmd,
        .objcopy = &objcopy_cmd,
    };
    aboutGroupInternal(top, cmds);
    allocator.unmapAll();
}
