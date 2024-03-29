const zl = @import("zl");
pub usingnamespace zl.start;
pub const logging_default: zl.debug.Logging.Default = zl.debug.spec.logging.default.silent;
pub const signal_handlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .Trap = false,
    .FloatingPointError = false,
};
pub const AddressSpace = zl.mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 32,
    .errors = .{ .acquire = .ignore, .release = .ignore },
});
const Allocator0 = zl.mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = .{
        .check_parametric = false,
        .count_allocations = true,
        .count_branches = false,
        .count_useful_bytes = true,
        .require_all_free_deinit = false,
        .require_filo_free = false,
        .require_geometric_growth = true,
        .require_map = true,
        .require_unmap = true,
        .require_resize = true,
        .prefer_remap = true,
        .require_populate = false,
        .init_commit = 32768,
        .max_commit = null,
        .max_acquire = null,
        .thread_safe = false,
        .unit_alignment = 1,
        .length_alignment = 1,
        .trace_clients = false,
        .trace_state = false,
    },
    .logging = zl.mem.dynamic.spec.logging.silent,
    .errors = zl.mem.dynamic.spec.errors.noexcept,
});
const Allocator1 = zl.mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .options = .{
        .check_parametric = false,
        .count_allocations = false,
        .count_branches = false,
        .count_useful_bytes = false,
        .require_all_free_deinit = false,
        .require_filo_free = false,
        .require_geometric_growth = true,
        .require_map = true,
        .require_unmap = true,
        .require_resize = true,
        .prefer_remap = false,
        .require_populate = false,
        .init_commit = 32768,
        .max_commit = null,
        .max_acquire = null,
        .thread_safe = false,
        .unit_alignment = 1,
        .length_alignment = 1,
        .trace_clients = false,
        .trace_state = false,
    },
    .logging = zl.mem.dynamic.spec.logging.silent,
    .errors = zl.mem.dynamic.spec.errors.noexcept,
});
const PrintArray = zl.mem.array.StaticString(4096);
const Array = Allocator1.StructuredStreamHolder(u8);
const String0 = Allocator0.StructuredHolder(u8);
const DirStream = zl.file.GenericDirStream(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = zl.file.spec.dir.logging.silent,
});
const Filter = zl.meta.EnumBitField(zl.file.Kind);
const Names = zl.mem.array.StaticArray([:0]const u8, max_pathname_args);
const Status = packed struct {
    flag: zl.meta.maybe(print_in_second_thread, u32) = 0,
    file_count: zl.meta.maybe(count_files, usize) = 0,
    dir_count: zl.meta.maybe(count_dirs, usize) = 0,
    link_count: zl.meta.maybe(count_links, usize) = 0,
    max_depth: zl.meta.maybe(track_max_depth, usize) = 0,
    size: zl.meta.maybe(sum_file_size, usize) = 0,
    errors: zl.meta.maybe(count_errors, usize) = 0,
};
fn done(status: *const volatile Status) bool {
    return status.flag != 0;
}
// user config begin
const max_pathname_args: u16 = 128;
const read_link: bool = true;
const count_files: bool = true;
const count_dirs: bool = true;
const count_links: bool = true;
const count_errors: bool = true;
const compact_arrows: bool = true;
const track_max_depth: bool = false;
const sum_file_size: bool = false;
const quit_on_error: bool = false;
const print_in_second_thread: bool = true;

// config constants derived from above options
const what_s: [:0]const u8 = if (compact_arrows) "?" else "???";
const endl_s: [:0]const u8 = "\n";
const del_s: [:0]const u8 = if (compact_arrows) "\x08\x08" else "\x08\x08\x08\x08";
const spc_s: [:0]const u8 = if (compact_arrows) "  " else "    ";
const bar_s: [:0]const u8 = if (compact_arrows) "| " else "|   ";
const links_to_s: [:0]const u8 = if (compact_arrows) " -> " else " --> ";
const file_arrow_s: [:0]const u8 = del_s ++ if (compact_arrows) "|-> " else "|---> ";
const last_file_arrow_s: [:0]const u8 = del_s ++ if (compact_arrows) "`-> " else "`---> ";
const link_arrow_s: [:0]const u8 = file_arrow_s;
const last_link_arrow_s: [:0]const u8 = last_file_arrow_s;
const dir_arrow_s: [:0]const u8 = del_s ++ if (compact_arrows) "|-+ " else "|---+ ";
const last_dir_arrow_s: [:0]const u8 = del_s ++ if (compact_arrows) "`-+ " else "`---+ ";
const empty_dir_arrow_s: [:0]const u8 = del_s ++ "|-- ";
const last_empty_dir_arrow_s: [:0]const u8 = del_s ++ "`-- ";

// config constants derived by `message_style` library configuration
const about = .{
    .dirs_s = zl.fmt.about("dirs"),
    .files_s = zl.fmt.about("files"),
    .links_s = zl.fmt.about("links"),
    .depth_s = zl.fmt.about("depth"),
    .errors_s = zl.fmt.about("errors"),
    .size_s = zl.fmt.about("size"),
};

// user config end
const write_spec: zl.file.WriteSpec = .{
    .errors = .{},
};
const clone_spec: zl.proc.CloneSpec = .{
    .errors = .{},
    .function_type = @TypeOf(&printAlong),
    .return_type = usize,
};
fn show(status: Status) void {
    var array: PrintArray = .{};
    if (count_dirs) {
        array.writeMany(about.dirs_s);
        array.writeFormat(zl.fmt.udh(status.dir_count));
        array.writeOne('\n');
    }
    if (count_files) {
        array.writeMany(about.files_s);
        array.writeFormat(zl.fmt.udh(status.file_count));
        array.writeOne('\n');
    }
    if (count_links) {
        array.writeMany(about.links_s);
        array.writeFormat(zl.fmt.udh(status.link_count));
        array.writeOne('\n');
    }
    if (track_max_depth) {
        array.writeMany(about.depth_s);
        array.writeFormat(zl.fmt.udh(status.max_depth));
        array.writeOne('\n');
    }
    if (count_errors) {
        array.writeMany(about.errors_s);
        array.writeFormat(zl.fmt.udh(status.errors));
        array.writeOne('\n');
    }
    if (sum_file_size) {
        array.writeMany(about.size_s);
        array.writeFormat(zl.fmt.Bytes{ .value = status.size });
        array.writeOne('\n');
    }
    zl.file.write(.{ .errors = .{} }, 1, array.readAll());
}
noinline fn printAlong(status: *volatile Status, allocator: *Allocator1, array: *Array) void {
    while (true) {
        const many: []u8 = array.referManyAt(allocator.*, array.index(allocator.*));
        if (many.len > 56) {
            zl.file.write(write_spec, 1, many);
            array.stream(many.len);
        }
        if (done(status)) break;
    }
    const many: []u8 = array.referManyAt(allocator.*, array.index(allocator.*));
    if (many.len > 56) {
        zl.file.write(write_spec, 1, many);
        array.stream(many.len);
    }
    status.flag = 0;
    zl.proc.futexWake(.{ .errors = .{} }, @volatileCast(&status.flag), 1);
}
fn getNames(args: [][*:0]u8) Names {
    var names: Names = .{};
    var i: usize = 1;
    while (i != args.len) : (i +%= 1) {
        names.writeOne(zl.meta.manyToSlice(args[i]));
    }
    return names;
}
fn writeReadLink(
    allocator_1: *Allocator1,
    array: *Array,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: usize,
    base_name: [:0]const u8,
) !void {
    const buf: []u8 = link_buf.referManyUndefined(4096);
    if (read_link) {
        if (zl.file.readLinkAt(.{}, dir_fd, base_name, buf)) |link_pathname| {
            array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ link_pathname, endl_s });
        } else |readlink_err| {
            array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
            if (quit_on_error) {
                return readlink_err;
            }
            if (count_errors) {
                status.errors +%= 1;
            }
        }
    } else {
        array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
    }
}
fn getSymbol(kind: zl.file.Kind) [:0]const u8 {
    switch (kind) {
        .regular => return "f ",
        .directory => return "d ",
        .symbolic_link => return "L ",
        .block_special => return "b ",
        .character_special => return "c ",
        .named_pipe => return "p ",
        .socket => return "S ",
        .unknown => return "? ",
    }
}
fn writeAndWalkNamed(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *Array,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: ?usize,
    name: [:0]const u8,
    depth: usize,
    require: [:0]const u8,
) !void {
    const save: usize = allocator_0.save();
    defer allocator_0.restore(save);
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: usize = 1;
    var st: zl.file.Status = zl.builtin.zero(zl.file.Status);
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        const last: bool = index == list.count -% 1;
        const indent: []const u8 = if (last) spc_s else bar_s;
        alts_buf.writeMany(indent);
        defer alts_buf.undefine(indent.len);
        switch (entry.kind()) {
            .symbolic_link => {
                if (count_links) {
                    status.link_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_link_arrow_s else link_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(.symbolic_link);
                array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, links_to_s });
                try writeReadLink(allocator_1, array, link_buf, status, dir.fd, basename);
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => |kind| {
                if (!zl.mem.testEqualManyIn(u8, require, basename)) {
                    continue;
                }
                if (count_files) {
                    status.file_count +%= 1;
                }
                if (sum_file_size) {
                    try zl.file.statusAt(.{}, .{}, dir.fd, basename, &st);
                    status.size +%= st.size;
                }
                const arrow_s: [:0]const u8 = if (last) last_file_arrow_s else file_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(kind);
                array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s });
            },
            .directory => {
                if (count_dirs) {
                    status.dir_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_dir_arrow_s else dir_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(.directory);
                const len: usize = array.len(allocator_1.*);
                try zl.meta.wrap(array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s }));
                if (track_max_depth) {
                    status.max_depth = @max(usize, status.max_depth, depth +% 1);
                }
                const count: usize = status.file_count;
                writeAndWalkNamed(allocator_0, allocator_1, array, alts_buf, link_buf, status, dir.fd, basename, depth +% 1, require) catch |any_error| {
                    if (quit_on_error) {
                        return any_error;
                    }
                    if (count_errors) {
                        status.errors +%= 1;
                    }
                };
                if (status.file_count == count) {
                    array.undefine(array.len(allocator_1.*) -% len);
                }
            },
            .unknown => {},
        }
    }
}
fn writeAndWalk(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *Array,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: ?usize,
    name: [:0]const u8,
    depth: usize,
) !void {
    const save: usize = allocator_0.save();
    defer allocator_0.restore(save);
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: usize = 1;
    var st: zl.file.Status = zl.builtin.zero(zl.file.Status);
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        const last: bool = index == list.count -% 1;
        const indent: []const u8 = if (last) spc_s else bar_s;
        alts_buf.writeMany(indent);
        defer alts_buf.undefine(indent.len);
        switch (entry.kind()) {
            .symbolic_link => {
                if (count_links) {
                    status.link_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_link_arrow_s else link_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(.symbolic_link);
                array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, links_to_s });
                try writeReadLink(allocator_1, array, link_buf, status, dir.fd, basename);
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => |kind| {
                if (count_files) {
                    status.file_count +%= 1;
                }
                if (sum_file_size) {
                    try zl.file.statusAt(.{}, .{}, dir.fd, basename, &st);
                    status.size +%= st.size;
                }
                const arrow_s: [:0]const u8 = if (last) last_file_arrow_s else file_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(kind);
                array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s });
            },
            .directory => {
                if (count_dirs) {
                    status.dir_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_dir_arrow_s else dir_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(.directory);
                try zl.meta.wrap(array.appendAny(zl.mem.array.spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s }));
                if (track_max_depth) {
                    status.max_depth = @max(usize, status.max_depth, depth +% 1);
                }
                writeAndWalk(allocator_0, allocator_1, array, alts_buf, link_buf, status, dir.fd, basename, depth +% 1) catch |any_error| {
                    if (quit_on_error) {
                        return any_error;
                    }
                    if (count_errors) {
                        status.errors +%= 1;
                    }
                };
            },
            .unknown => {},
        }
    }
}
pub fn main(args: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var names: Names = getNames(args);
    if (names.len() == 0) {
        names.writeOne(".");
    }
    var allocator_0: Allocator0 = Allocator0.init(&address_space);
    defer allocator_0.deinit(&address_space);
    var allocator_1: Allocator1 = Allocator1.init(&address_space);
    defer allocator_1.deinit(&address_space);
    try zl.meta.wrap(allocator_0.map(32768));
    try zl.meta.wrap(allocator_1.map(32768));
    for (names.readAll()) |arg| {
        var status: Status = .{};
        var array: Array = Array.init(&allocator_1);
        var alts_buf: PrintArray = undefined;
        var link_buf: PrintArray = undefined;
        alts_buf.undefineAll();
        link_buf.undefineAll();
        defer array.deinit(&allocator_1);
        array.writeMany(arg);
        array.writeMany(if (arg[arg.len -% 1] != '/') "/\n" else "\n");
        @memset(alts_buf.referManyAt(0), ' ');
        if (print_in_second_thread) {
            var ret: void = {};
            var tid: usize = undefined;
            var stack_buf: [16384]u8 align(16) = undefined;
            const stack_addr: usize = @intFromPtr(&stack_buf);
            tid = zl.proc.clone(clone_spec, .{}, stack_addr, stack_buf.len, &ret, printAlong, .{ &status, &allocator_1, &array });
            writeAndWalk(&allocator_0, &allocator_1, &array, &alts_buf, &link_buf, &status, null, arg, 0) catch {
                if (count_errors) {
                    status.errors +%= 1;
                }
            };
            status.flag = 255;
            zl.proc.futexWait(.{ .errors = .{} }, &status.flag, 255, &.{ .sec = 86400 });
            zl.debug.write(array.readManyAt(allocator_1, array.index(allocator_1)));
            show(status);
        } else {
            writeAndWalk(&allocator_0, &allocator_1, &array, &alts_buf, &link_buf, &status, null, arg, 0) catch if (count_errors) {
                status.errors +%= 1;
            };
            zl.debug.write(array.readManyAt(allocator_1, array.index(allocator_1)));
            show(status);
        }
    }
}
