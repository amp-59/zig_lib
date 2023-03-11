const srg = @import("zig_lib");
const sys = srg.sys;
const fmt = srg.fmt;
const mem = srg.mem;
const file = srg.file;
const meta = srg.meta;
const proc = srg.proc;
const preset = srg.preset;
const thread = srg.thread;
const builtin = srg.builtin;
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 32,
    .errors = .{ .acquire = .ignore, .release = .ignore },
});
const Allocator0 = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const PrintArray = mem.StaticString(4096);
const String1 = Allocator1.StructuredStreamHolder(u8);
const String0 = Allocator0.StructuredHolder(u8);
const DirStream = file.GenericDirStream(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = preset.dir.logging.silent,
});
const Filter = meta.EnumBitField(file.Kind);
const Names = mem.StaticArray([:0]const u8, max_pathname_args);
const Status = struct {
    files: u64 = 0,
    dirs: u64 = 0,
    links: u64 = 0,
    depth: u64 = 0,
    errors: u64 = 0,
    done: bool = false,
    inline fn total(status: Status) u64 {
        return status.dirs +% status.files +% status.links;
    }
};
const plain_print: bool = false;
const no_read_link: bool = false;
const print_in_second_thread: bool = true;
const use_wide_arrows: bool = false;
const always_try_empty_dir_correction: bool = false;
const max_pathname_args: u16 = 128;
const map_spec: thread.MapSpec = .{
    .errors = .{},
    .options = .{},
};
const thread_spec: proc.CloneSpec = .{
    .errors = .{},
    .options = .{},
    .return_type = u64,
};
const what_s: [:0]const u8 = "???";
const endl_s: [:0]const u8 = if (plain_print) "\x00" else "\x1b[0m\n";
const del_s: [:0]const u8 = "\x08\x08\x08\x08";
const spc_bs: [:0]const u8 = "    ";
const spc_ws: [:0]const u8 = "    ";
const bar_bs: [:0]const u8 = "|   ";
const bar_ws: [:0]const u8 = "│   ";
const links_to_bs: [:0]const u8 = if (plain_print) "\x00L\x00" else " L --> ";
const links_to_ws: [:0]const u8 = if (plain_print) "\x00L\x00" else " L ⟶  ";
const file_arrow_bs: [:0]const u8 = del_s ++ "|-> ";
const file_arrow_ws: [:0]const u8 = del_s ++ "├── ";
const last_file_arrow_bs: [:0]const u8 = del_s ++ "`-> ";
const last_file_arrow_ws: [:0]const u8 = del_s ++ "└── ";
const link_arrow_bs: [:0]const u8 = file_arrow_bs;
const link_arrow_ws: [:0]const u8 = file_arrow_ws;
const last_link_arrow_bs: [:0]const u8 = last_file_arrow_bs;
const last_link_arrow_ws: [:0]const u8 = last_file_arrow_ws;
const dir_arrow_bs: [:0]const u8 = del_s ++ "|---+ ";
const dir_arrow_ws: [:0]const u8 = del_s ++ "├───┬ ";
const last_dir_arrow_bs: [:0]const u8 = del_s ++ "`---+ ";
const last_dir_arrow_ws: [:0]const u8 = del_s ++ "└───┬ ";
const empty_dir_arrow_bs: [:0]const u8 = del_s ++ "|-- ";
const empty_dir_arrow_ws: [:0]const u8 = del_s ++ "├── ";
const last_empty_dir_arrow_bs: [:0]const u8 = del_s ++ "`-- ";
const last_empty_dir_arrow_ws: [:0]const u8 = del_s ++ "└── ";
const about_dirs_s: [:0]const u8 = "dirs:           ";
const about_files_s: [:0]const u8 = "files:          ";
const about_links_s: [:0]const u8 = "links:          ";
const about_depth_s: [:0]const u8 = "depth:          ";
const about_errors_s: [:0]const u8 = "errors:         ";
const Style = struct {
    const spc_s: [:0]const u8 = if (use_wide_arrows) spc_ws else spc_bs;
    const bar_s: [:0]const u8 = if (use_wide_arrows) bar_ws else bar_bs;
    const links_to_s: [:0]const u8 = if (use_wide_arrows) links_to_ws else links_to_bs;
    const file_arrow_s: [:0]const u8 = if (use_wide_arrows) file_arrow_ws else file_arrow_bs;
    const last_file_arrow_s: [:0]const u8 = if (use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
    const link_arrow_s: [:0]const u8 = if (use_wide_arrows) file_arrow_ws else file_arrow_bs;
    const last_link_arrow_s: [:0]const u8 = if (use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
    const dir_arrow_s: [:0]const u8 = if (use_wide_arrows) dir_arrow_ws else dir_arrow_bs;
    const last_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) last_dir_arrow_ws else last_dir_arrow_bs;
    const empty_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) empty_dir_arrow_ws else empty_dir_arrow_bs;
    const last_empty_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
};
fn show(status: Status) void {
    var array: PrintArray = .{};
    array.writeMany(about_dirs_s);
    array.writeFormat(fmt.udh(status.dirs));
    array.writeOne('\n');
    array.writeMany(about_files_s);
    array.writeFormat(fmt.udh(status.files));
    array.writeOne('\n');
    array.writeMany(about_links_s);
    array.writeFormat(fmt.udh(status.links));
    array.writeOne('\n');
    array.writeMany(about_depth_s);
    array.writeFormat(fmt.udh(status.depth));
    array.writeOne('\n');
    array.writeMany(about_errors_s);
    array.writeFormat(fmt.udh(status.errors));
    array.writeOne('\n');
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
inline fn printIfNAvail(comptime n: usize, allocator: Allocator1, array: String1) u64 {
    const many: []u8 = array.referManyAt(allocator, array.index(allocator));
    if (plain_print) {
        if (many.len > (n -% 1)) {
            file.write(.{ .errors = .{} }, 1, many);
            if (n == 1) {
                file.write(.{ .errors = .{} }, 1, "\n");
            }
            return many.len;
        }
    } else {
        if (many.len > (n -% 1)) {
            if (n == 1) {
                file.write(.{ .errors = .{} }, 1, many);
                return many.len;
            } else if (many[many.len -% 1] == '\n') {
                file.write(.{ .errors = .{} }, 1, many);
                return many.len;
            }
        }
    }
    return 0;
}
noinline fn printAlong(status: *volatile Status, allocator: *Allocator1, array: *String1) void {
    while (true) {
        array.stream(printIfNAvail(512, allocator.*, array.*));
        if (status.done) break;
    }
    while (array.index(allocator.*) != array.len(allocator.*)) {
        array.stream(printIfNAvail(1, allocator.*, array.*));
    }
    show(status.*);
    status.done = false;
}
inline fn getNames(args: [][*:0]u8) Names {
    var names: Names = .{};
    var i: u64 = 1;
    while (i != args.len) : (i +%= 1) {
        names.writeOne(meta.manyToSlice(args[i]));
    }
    return names;
}
fn conditionalSkip(entry_name: []const u8) bool {
    return entry_name[0] == '.' or
        mem.testEqualMany(u8, "zig-cache", entry_name) or
        mem.testEqualMany(u8, "zig-out", entry_name);
}
fn writeReadLink(
    allocator_1: *Allocator1,
    array: *String1,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: u64,
    base_name: [:0]const u8,
) !void {
    const buf: []u8 = link_buf.referManyUndefined(4096);
    const link_pathname: [:0]const u8 = file.readLinkAt(.{}, dir_fd, base_name, buf) catch {
        status.errors +%= 1;
        return array.appendAny(preset.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
    };
    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ link_pathname, endl_s });
}
fn getSymbol(kind: file.Kind) []const u8 {
    if (plain_print) {
        switch (kind) {
            .regular => return "\x00f\x00",
            .directory => return "\x00d\x00",
            .symbolic_link => return Style.links_to_s,
            .block_special => return "\x00b",
            .character_special => return "\x00c\x00",
            .named_pipe => return "\x00p",
            .socket => return "\x00S\x00",
        }
    } else {
        switch (kind) {
            .regular => return " f\n",
            .directory => return " d\n",
            .symbolic_link => return " L",
            .block_special => return " b\n",
            .character_special => return " c\n",
            .named_pipe => return " p\n",
            .socket => return " S\n",
        }
    }
}
fn writeAndWalkPlain(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const need_separator: bool = name[name.len -% 1] != '/';
    alts_buf.writeMany(name);
    if (need_separator) alts_buf.writeOne('/');
    defer alts_buf.undefine(name.len + builtin.int(u64, need_separator));
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        switch (entry.kind()) {
            .symbolic_link => {
                status.links +%= 1;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, Style.links_to_s });
                try writeReadLink(allocator_1, array, link_buf, status, dir.fd, basename);
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => |kind| {
                status.files +%= 1;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, getSymbol(kind), 0 });
            },
            .directory => |kind| {
                status.dirs +%= 1;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, getSymbol(kind) });
                status.depth = builtin.max(u64, status.depth, depth +% 1);
                writeAndWalkPlain(allocator_0, allocator_1, array, alts_buf, link_buf, status, dir.fd, basename, depth +% 1) catch {
                    status.errors +%= 1;
                };
            },
        }
    }
}
fn writeAndWalk(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const try_empty_dir_correction: bool = always_try_empty_dir_correction or use_wide_arrows;
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        const last: bool = index == list.count -% 1;
        const kind: file.Kind = entry.kind();
        const indent: []const u8 = if (last) Style.spc_s else Style.bar_s;
        alts_buf.writeMany(indent);
        defer alts_buf.undefine(indent.len);
        switch (kind) {
            .symbolic_link => {
                status.links +%= 1;
                const arrow_s: [:0]const u8 = if (last) Style.last_link_arrow_s else Style.link_arrow_s;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, basename, Style.links_to_s });
                try writeReadLink(allocator_1, array, link_buf, status, dir.fd, basename);
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => {
                status.files +%= 1;
                const arrow_s: [:0]const u8 = if (last) Style.last_file_arrow_s else Style.file_arrow_s;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, basename, endl_s });
            },
            .directory => {
                status.dirs +%= 1;
                var arrow_s: [:0]const u8 = if (last) Style.last_dir_arrow_s else Style.dir_arrow_s;
                const len_0: u64 = array.len(allocator_1.*);
                try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, basename, endl_s }));
                status.depth = builtin.max(u64, status.depth, depth +% 1);
                const en_total: u64 = status.total();
                writeAndWalk(allocator_0, allocator_1, array, alts_buf, link_buf, status, dir.fd, basename, depth +% 1) catch {
                    status.errors +%= 1;
                };
                const ex_total: u64 = status.total();
                if (try_empty_dir_correction) {
                    arrow_s = if (index == list.count -% 1) Style.last_empty_dir_arrow_s else Style.empty_dir_arrow_s;
                    if (en_total == ex_total) {
                        array.undefine(array.len(allocator_1.*) -% len_0);
                        array.writeAny(preset.reinterpret.ptr, .{ alts_buf.readAll(), arrow_s, basename, endl_s });
                    }
                }
            },
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
    try meta.wrap(allocator_0.map(32768));
    try meta.wrap(allocator_1.map(32768));
    for (names.readAll()) |arg| {
        var status: Status = .{};
        var alts_buf: PrintArray = undefined;
        alts_buf.undefineAll();
        var link_buf: PrintArray = undefined;
        link_buf.undefineAll();
        var array: String1 = String1.init(&allocator_1);
        defer array.deinit(&allocator_1);
        try meta.wrap(array.appendMany(&allocator_1, arg));
        try meta.wrap(array.appendMany(&allocator_1, if (arg[arg.len -% 1] != '/') "/\n" else "\n"));
        if (plain_print) {
            if (print_in_second_thread) {
                var tid: u64 = undefined;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &status, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &allocator_0, &allocator_1, &array,
                    &alts_buf,    &link_buf,    &status,
                    null,         arg,          0,
                }) catch {
                    status.errors +%= 1;
                };
                status.done = true;
                mem.monitor(bool, &status.done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &allocator_0, &allocator_1, &array,
                    &alts_buf,    &link_buf,    &status,
                    null,         arg,          0,
                }) catch {
                    status.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(status);
            }
        } else {
            alts_buf.writeMany(" " ** 4096);
            alts_buf.undefine(4096);
            if (print_in_second_thread) {
                var tid: u64 = undefined;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &status, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &allocator_0, &allocator_1, &array, &alts_buf, &link_buf,
                    &status,      null,         arg,    0,
                }) catch {
                    status.errors +%= 1;
                };
                status.done = true;
                mem.monitor(bool, &status.done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &allocator_0, &allocator_1, &array, &alts_buf, &link_buf,
                    &status,      null,         arg,    0,
                }) catch {
                    status.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(status);
            }
        }
    }
}
