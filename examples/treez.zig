const srg = @import("zig_lib");
const lit = srg.lit;
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
const String1 = Allocator1.StructuredHolder(u8);
const String0 = Allocator0.StructuredHolder(u8);
const DirStream = file.GenericDirStream(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = preset.dir.logging.silent,
});
const Filter = meta.EnumBitField(file.Kind);
const Names = mem.StaticArray([:0]const u8, max_pathname_args);
const Results = struct {
    files: u64 = 0,
    dirs: u64 = 0,
    links: u64 = 0,
    depth: u64 = 0,
    errors: u64 = 0,
    inline fn total(results: Results) u64 {
        return results.dirs +% results.files +% results.links;
    }
};
const Options = packed struct {
    hide: bool = false,
    follow: bool = true,
    max_depth: u16 = ~@as(u16, 0),
    pub const Map = proc.GenericOptions(Options);
    const yes = .{ .boolean = true };
    const no = .{ .boolean = false };
    const int = .{ .convert = convertToInt };
};
//
const plain_print: bool = false;
const print_in_second_thread: bool = true;
const use_wide_arrows: bool = false;
const always_try_empty_dir_correction: bool = false;
const max_pathname_args: u16 = 128;
//
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{ // zig fmt: off
    .{ .field_name = "hide",       .long = "--hide",                        .assign = Options.yes, .descr = about_hide_s },
    .{ .field_name = "follow",     .short = "-L", .long = "--follow",       .assign = Options.yes, .descr = about_follow_s },
    .{ .field_name = "follow",     .short = "+L", .long = "--no-follow",    .assign = Options.no,  .descr = about_no_follow_s },
    .{ .field_name = "max_depth",  .short = "-d", .long = "--max-depth",    .assign = Options.int, .descr = about_max_depth_s },
}); // zig fmt: on
const map_spec: thread.MapSpec = .{
    .errors = .{},
    .options = .{},
};
const thread_spec: proc.CloneSpec = .{
    .errors = .{},
    .options = .{},
    .return_type = u64,
};
const about_hide_s: [:0]const u8 = "do not show hidden file system objects";
const about_follow_s: [:0]const u8 = "follow symbolic links";
const about_no_follow_s: [:0]const u8 = "do not " ++ about_follow_s;
const about_wide_s: [:0]const u8 = "display entries using wide character symbols";
const about_max_depth_s: [:0]const u8 = "limit the maximum depth of recursion";
const what_s: [:0]const u8 = "???";
const endl_s: [:0]const u8 = "\x1b[0m\n";
const del_s: [:0]const u8 = "\x08\x08\x08\x08";
const spc_bs: [:0]const u8 = "    ";
const spc_ws: [:0]const u8 = "    ";
const bar_bs: [:0]const u8 = "|   ";
const bar_ws: [:0]const u8 = "│   ";
const links_to_bs: [:0]const u8 = " --> ";
const links_to_ws: [:0]const u8 = " ⟶  ";
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
const any_style: [16][:0]const u8 = blk: {
    var tmp: [16][:0]const u8 = .{undefined} ** 16;
    tmp[sys.S.IFDIR >> 12] = lit.fx.style.bold;
    tmp[sys.S.IFREG >> 12] = lit.fx.color.fg.yellow;
    tmp[sys.S.IFLNK >> 12] = lit.fx.color.fg.hi_cyan;
    tmp[sys.S.IFBLK >> 12] = lit.fx.color.fg.orange;
    tmp[sys.S.IFCHR >> 12] = lit.fx.color.fg.hi_yellow;
    tmp[sys.S.IFIFO >> 12] = lit.fx.color.fg.magenta;
    tmp[sys.S.IFSOCK >> 12] = lit.fx.color.fg.hi_magenta;
    break :blk tmp;
};
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
fn show(results: Results) void {
    var array: PrintArray = .{};
    array.writeMany(about_dirs_s);
    array.writeFormat(fmt.udh(results.dirs));
    array.writeOne('\n');
    array.writeMany(about_files_s);
    array.writeFormat(fmt.udh(results.files));
    array.writeOne('\n');
    array.writeMany(about_links_s);
    array.writeFormat(fmt.udh(results.links));
    array.writeOne('\n');
    array.writeMany(about_depth_s);
    array.writeFormat(fmt.udh(results.depth));
    array.writeOne('\n');
    array.writeMany(about_errors_s);
    array.writeFormat(fmt.udh(results.errors));
    array.writeOne('\n');
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
inline fn printIfNAvail(comptime n: usize, allocator: Allocator1, array: String1, offset: u64) u64 {
    const many: []const u8 = array.readManyAt(allocator, offset);
    if (many.len > (n -% 1)) {
        if (n == 1) {
            file.write(.{ .errors = .{} }, 1, many);
            return many.len;
        } else if (many[many.len -% 1] == '\n') {
            file.write(.{ .errors = .{} }, 1, many);
            return many.len;
        }
    }
    return 0;
}
noinline fn printAlong(results: *Results, done: *bool, allocator: *Allocator1, array: *String1) void {
    var offset: u64 = 0;
    while (true) {
        offset +%= printIfNAvail(4096, allocator.*, array.*, offset);
        if (done.*) {
            break;
        }
    }
    while (offset != array.len(allocator.*)) {
        offset +%= printIfNAvail(1, allocator.*, array.*, offset);
    }
    show(results.*);
    done.* = false;
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
    results: *Results,
    dir_fd: u64,
    base_name: [:0]const u8,
) !void {
    const buf: []u8 = link_buf.referManyUndefined(4096);
    const link_pathname: [:0]const u8 = file.readLinkAt(.{}, dir_fd, base_name, buf) catch {
        results.errors +%= 1;
        return array.appendAny(preset.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
    };
    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ link_pathname, endl_s });
}
fn writeAndWalkPlain(
    options: *const Options,
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    results: *Results,
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
        if (options.hide and conditionalSkip(basename)) {
            continue;
        }
        switch (entry.kind()) {
            .symbolic_link => {
                results.links +%= 1;
                if (options.follow) {
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, '\t' });
                    try writeReadLink(allocator_1, array, link_buf, results, dir.fd, basename);
                } else {
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, endl_s });
                }
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => {
                results.files +%= 1;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, endl_s });
            },
            .directory => {
                results.dirs +%= 1;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, endl_s });
                if (depth != options.max_depth) {
                    results.depth = builtin.max(u64, results.depth, depth +% 1);
                    writeAndWalkPlain(options, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, basename, depth +% 1) catch {
                        results.errors +%= 1;
                    };
                }
            },
        }
    }
}
fn writeAndWalk(
    options: *const Options,
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    results: *Results,
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
        if (options.hide and conditionalSkip(basename)) {
            continue;
        }
        const kind: file.Kind = entry.kind();
        const indent: []const u8 = if (last) Style.spc_s else Style.bar_s;
        alts_buf.writeMany(indent);
        defer alts_buf.undefine(indent.len);
        switch (kind) {
            .symbolic_link => {
                results.links +%= 1;
                if (options.follow) {
                    const arrow_s: [:0]const u8 = if (last) Style.last_link_arrow_s else Style.link_arrow_s;
                    const style_s: [:0]const u8 = lit.fx.color.fg.cyan;
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, Style.links_to_s });
                    try writeReadLink(allocator_1, array, link_buf, results, dir.fd, basename);
                } else {
                    const arrow_s: [:0]const u8 = if (last) Style.last_link_arrow_s else Style.link_arrow_s;
                    const style_s: [:0]const u8 = lit.fx.color.fg.cyan;
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, endl_s });
                }
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => {
                results.files +%= 1;
                const arrow_s: [:0]const u8 = if (last) Style.last_file_arrow_s else Style.file_arrow_s;
                const style_s: [:0]const u8 = any_style[@enumToInt(kind)];
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, endl_s });
            },
            .directory => {
                results.dirs +%= 1;
                var arrow_s: [:0]const u8 = if (last) Style.last_dir_arrow_s else Style.dir_arrow_s;
                const len_0: u64 = array.len(allocator_1.*);
                try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, basename, endl_s }));
                if (depth != options.max_depth) {
                    results.depth = builtin.max(u64, results.depth, depth +% 1);
                    const en_total: u64 = results.total();
                    writeAndWalk(options, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, basename, depth +% 1) catch {
                        results.errors +%= 1;
                    };
                    const ex_total: u64 = results.total();
                    if (try_empty_dir_correction) {
                        arrow_s = if (index == list.count -% 1) Style.last_empty_dir_arrow_s else Style.empty_dir_arrow_s;
                        if (en_total == ex_total) {
                            array.undefine(array.len(allocator_1.*) -% len_0);
                            array.writeAny(preset.reinterpret.ptr, .{ alts_buf.readAll(), arrow_s, basename, endl_s });
                        }
                    }
                }
            },
        }
    }
}
fn convertToInt(options: *Options, arg: []const u8) void {
    options.max_depth = builtin.parse.ud(u8, arg);
}
pub fn main(args: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    const options: Options = proc.getOpts(Options, &args, opts_map);
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
        var results: Results = .{};
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
                var done: bool = false;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &results, &done, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                done = true;
                mem.monitor(bool, &done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(results);
            }
        } else {
            alts_buf.writeMany(" " ** 4096);
            alts_buf.undefine(4096);
            if (print_in_second_thread) {
                var tid: u64 = undefined;
                var done: bool = false;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &results, &done, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                done = true;
                mem.monitor(bool, &done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(results);
            }
        }
    }
}
