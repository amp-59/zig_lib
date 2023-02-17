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

pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 32,
});

pub const runtime_assertions: bool = false;
pub const is_verbose: bool = false;
pub const is_silent: bool = false;

const map_spec: thread.MapSpec = .{
    .errors = .{},
    .options = .{},
};
const thread_spec: proc.CloneSpec = .{
    .errors = .{},
    .options = .{},
    .return_type = u64,
};
const Allocator0 = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .options = blk: {
        var tmp = preset.allocator.options.small;
        tmp.init_commit = 32768;
        tmp.prefer_remap = false;
        break :blk tmp;
    },
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .arena_index = 1,
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const String1 = Allocator1.StructuredHolder(u8);
const String0 = Allocator0.StructuredHolder(u8);
const DirStream = file.GenericDirStream(.{ .Allocator = Allocator0, .options = .{}, .logging = .{} });
const Names = mem.StructuredAutomaticVector([:0]const u8, null, 128, 8, .{});

const PrintArray = mem.StaticString(4096);
const Options = struct {
    all: bool = true,
    follow: bool = false,
    wide: bool = false,
    max_depth: ?u8 = null,
    pub const Map = proc.GenericOptions(Options);
    const plain_print: bool = false;
    const print_in_second_thread: bool = true;
    const always_show_hidden: bool = true;
    const permit_switch_arrows: bool = false;
    const use_wide_arrows: bool = false;
    const always_try_empty_dir_correction: bool = false;
    const about_all_s: []const u8 = "show hidden file system objects";
    const about_follow_s: []const u8 = "follow symbolic links";
    const about_no_follow_s: []const u8 = "do not " ++ about_follow_s;
    const about_wide_s: []const u8 = "display entries using wide character symbols";
    const about_max_depth_s: []const u8 = "limit the maximum depth of recursion";
    const yes = .{ .boolean = true };
    const no = .{ .boolean = false };
    const int = .{ .convert = convertToInt };
};
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{ // zig fmt: off
    .{ .field_name = "all",        .short = "-a", .long = "--all",         .assign = Options.yes, .descr = Options.about_all_s },
    .{ .field_name = "follow",     .short = "-L", .long = "--follow",      .assign = Options.yes, .descr = Options.about_follow_s },
    .{ .field_name = "follow",     .short = "+L", .long = "--no-follow",   .assign = Options.no,  .descr = Options.about_no_follow_s },
    .{ .field_name = "wide",       .short = "-w", .long = "--wide",        .assign = Options.yes, .descr = Options.about_wide_s },
    .{ .field_name = "max_depth",  .short = "-d", .long = "--max-depth",   .assign = Options.int, .descr = Options.about_max_depth_s },
}); // zig fmt: on

const Results = struct {
    files: u64 = 0,
    dirs: u64 = 0,
    links: u64 = 0,
    depth: u64 = 0,
    fn total(results: Results) u64 {
        return results.dirs + results.files + results.links;
    }
    fn show(results: Results) void {
        var array: PrintArray = .{};
        array.writeAny(preset.reinterpret.fmt, .{
            "dirs:       ", fmt.udh(results.dirs),         '\n',
            "files:      ", fmt.udh(results.files),        '\n',
            "links:      ", fmt.udh(results.links),        '\n',
            "depth:      ", fmt.udh(results.depth),        '\n',
            "swaps:      ", fmt.udh(DirStream.disordered), '\n',
        });
        file.noexcept.write(2, array.readAll());
    }
};
const Filter = meta.EnumBitField(file.Kind);
const any_style: [16][]const u8 = blk: {
    var tmp: [16][]const u8 = .{undefined} ** 16;
    tmp[sys.S.IFDIR >> 12] = lit.fx.style.bold;
    tmp[sys.S.IFREG >> 12] = lit.fx.color.fg.yellow;
    tmp[sys.S.IFLNK >> 12] = lit.fx.color.fg.hi_cyan;
    tmp[sys.S.IFBLK >> 12] = lit.fx.color.fg.orange;
    tmp[sys.S.IFCHR >> 12] = lit.fx.color.fg.hi_yellow;
    tmp[sys.S.IFIFO >> 12] = lit.fx.color.fg.magenta;
    tmp[sys.S.IFSOCK >> 12] = lit.fx.color.fg.hi_magenta;
    break :blk tmp;
};
const endl_s: []const u8 = "\x1b[0m\n";
const del_s: []const u8 = "\x08\x08\x08\x08";
const spc_bs: []const u8 = "    ";
const spc_ws: []const u8 = "    ";
const bar_bs: []const u8 = "|   ";
const bar_ws: []const u8 = "│   ";
const links_to_bs: []const u8 = " --> ";
const links_to_ws: []const u8 = " ⟶  ";
const file_arrow_bs: []const u8 = del_s ++ "|-> ";
const file_arrow_ws: []const u8 = del_s ++ "├── ";
const last_file_arrow_bs: []const u8 = del_s ++ "`-> ";
const last_file_arrow_ws: []const u8 = del_s ++ "└── ";
const link_arrow_bs: []const u8 = file_arrow_bs;
const link_arrow_ws: []const u8 = file_arrow_ws;
const last_link_arrow_bs: []const u8 = last_file_arrow_bs;
const last_link_arrow_ws: []const u8 = last_file_arrow_ws;
const dir_arrow_bs: []const u8 = del_s ++ "|---+ ";
const dir_arrow_ws: []const u8 = del_s ++ "├───┬ ";
const last_dir_arrow_bs: []const u8 = del_s ++ "`---+ ";
const last_dir_arrow_ws: []const u8 = del_s ++ "└───┬ ";
const empty_dir_arrow_bs: []const u8 = del_s ++ "|-- ";
const empty_dir_arrow_ws: []const u8 = del_s ++ "├── ";
const last_empty_dir_arrow_bs: []const u8 = del_s ++ "`-- ";
const last_empty_dir_arrow_ws: []const u8 = del_s ++ "└── ";
const Style = if (Options.permit_switch_arrows) struct {
    var spc_s: []const u8 = undefined;
    var bar_s: []const u8 = undefined;
    var links_to_s: []const u8 = undefined;
    var file_arrow_s: []const u8 = undefined;
    var last_file_arrow_s: []const u8 = undefined;
    var link_arrow_s: []const u8 = undefined;
    var last_link_arrow_s: []const u8 = undefined;
    var dir_arrow_s: []const u8 = undefined;
    var last_dir_arrow_s: []const u8 = undefined;
    var empty_dir_arrow_s: []const u8 = undefined;
    var last_empty_dir_arrow_s: []const u8 = undefined;
    fn setArrows(options: Options) void {
        spc_s = if (options.wide) spc_ws else spc_bs;
        bar_s = if (options.wide) bar_ws else bar_bs;
        links_to_s = if (options.wide) links_to_ws else links_to_bs;
        file_arrow_s = if (options.wide) file_arrow_ws else file_arrow_bs;
        last_file_arrow_s = if (options.wide) last_file_arrow_ws else last_file_arrow_bs;
        link_arrow_s = if (options.wide) file_arrow_ws else file_arrow_bs;
        last_link_arrow_s = if (options.wide) last_file_arrow_ws else last_file_arrow_bs;
        dir_arrow_s = if (options.wide) dir_arrow_ws else dir_arrow_bs;
        last_dir_arrow_s = if (options.wide) last_dir_arrow_ws else last_dir_arrow_bs;
        empty_dir_arrow_s = if (options.wide) empty_dir_arrow_ws else empty_dir_arrow_bs;
        last_empty_dir_arrow_s = if (options.wide) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
    }
} else struct {
    const spc_s: []const u8 = if (Options.use_wide_arrows) spc_ws else spc_bs;
    const bar_s: []const u8 = if (Options.use_wide_arrows) bar_ws else bar_bs;
    const links_to_s: []const u8 = if (Options.use_wide_arrows) links_to_ws else links_to_bs;
    const file_arrow_s: []const u8 = if (Options.use_wide_arrows) file_arrow_ws else file_arrow_bs;
    const last_file_arrow_s: []const u8 = if (Options.use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
    const link_arrow_s: []const u8 = if (Options.use_wide_arrows) file_arrow_ws else file_arrow_bs;
    const last_link_arrow_s: []const u8 = if (Options.use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
    const dir_arrow_s: []const u8 = if (Options.use_wide_arrows) dir_arrow_ws else dir_arrow_bs;
    const last_dir_arrow_s: []const u8 = if (Options.use_wide_arrows) last_dir_arrow_ws else last_dir_arrow_bs;
    const empty_dir_arrow_s: []const u8 = if (Options.use_wide_arrows) empty_dir_arrow_ws else empty_dir_arrow_bs;
    const last_empty_dir_arrow_s: []const u8 = if (Options.use_wide_arrows) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
};
fn conditionalSkip(entry_name: []const u8) bool {
    if (entry_name[0] == '.') {
        return true;
    }
    if (mem.testEqualMany(u8, "zig-cache", entry_name) or
        mem.testEqualMany(u8, "zig-out", entry_name))
    {
        return true;
    }
    return false;
}
fn writeAndWalk(
    options: *const Options,
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    results: *Results,
    dirfd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const need_separator: bool = name[name.len - 1] != '/';
    if (Options.plain_print) {
        alts_buf.writeMany(name);
        if (need_separator) alts_buf.writeOne('/');
    }
    defer if (Options.plain_print) {
        alts_buf.undefine(name.len);
        alts_buf.undefine(builtin.int(u64, need_separator));
    };
    const try_empty_dir_correction: bool =
        (Options.permit_switch_arrows and options.wide) or
        (Options.use_wide_arrows) or
        (Options.always_try_empty_dir_correction);
    var dir: DirStream = try DirStream.initAt(allocator_0, dirfd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (list.at(index)) |entry| : (index += 1) {
        const is_last: bool = index == list.count - 1;
        const indent: []const u8 = if (is_last) Style.spc_s else Style.bar_s;
        if (!Options.plain_print) {
            alts_buf.writeMany(indent);
        }
        defer if (!Options.plain_print) alts_buf.undefine(indent.len);
        const base_name: [:0]const u8 = entry.name();
        if (!options.all and conditionalSkip(base_name)) {
            continue;
        }
        switch (entry.kind()) {
            .directory => {
                if (options.max_depth) |max_depth| {
                    if (depth == max_depth) continue;
                } else {
                    results.depth = @max(results.depth, depth + 1);
                }
                results.dirs += 1;
                const len_0: u64 = array.len(allocator_1.*);
                const s_arrow_s: []const u8 = if (is_last) Style.last_dir_arrow_s else Style.dir_arrow_s;
                try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, blk: {
                    if (Options.plain_print) {
                        break :blk .{ alts_buf.readAll(), base_name, endl_s };
                    } else {
                        break :blk .{ alts_buf.readAll(), s_arrow_s, base_name, endl_s };
                    }
                }));
                const s_total: u64 = results.total();
                writeAndWalk(options, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, base_name, depth + 1) catch {};
                const t_total: u64 = results.total();
                if (try_empty_dir_correction) {
                    const t_arrow_s: []const u8 = if (is_last) Style.last_empty_dir_arrow_s else Style.empty_dir_arrow_s;
                    if (s_total == t_total) {
                        array.undefine(array.len(allocator_1.*) -% len_0);
                        array.writeAny(preset.reinterpret.ptr, .{ alts_buf.readAll(), t_arrow_s, base_name, endl_s });
                    }
                }
            },
            .symbolic_link => {
                results.links += 1;
                const arrow: []const u8 = if (is_last) Style.last_link_arrow_s else Style.link_arrow_s;
                const style: []const u8 = lit.fx.color.fg.cyan;
                if (options.follow) {
                    try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, blk: {
                        if (Options.plain_print) {
                            break :blk .{ alts_buf.readAll(), base_name, endl_s };
                        } else {
                            break :blk .{ alts_buf.readAll(), arrow, style, base_name, Style.links_to_s };
                        }
                    }));
                    if (file.readLinkAt(.{}, dir.fd, base_name, link_buf.referCountAt(0, 4096))) |path_name| {
                        try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, .{ path_name, endl_s }));
                    } else |_| {
                        try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, .{ "???", endl_s }));
                    }
                } else {
                    try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, blk: {
                        if (Options.plain_print) {
                            break :blk .{ alts_buf.readAll(), base_name, endl_s };
                        } else {
                            break :blk .{ alts_buf.readAll(), arrow, style, base_name, endl_s };
                        }
                    }));
                }
            },
            else => {
                results.files += 1;
                const arrow: []const u8 = if (is_last) Style.last_file_arrow_s else Style.file_arrow_s;
                try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, blk: {
                    if (Options.plain_print) {
                        break :blk .{ alts_buf.readAll(), base_name, endl_s };
                    } else {
                        break :blk .{ alts_buf.readAll(), arrow, any_style[@enumToInt(entry.kind())], base_name, endl_s };
                    }
                }));
            },
        }
    }
}
fn setType(arg: []const u8) Filter {
    var mask: Filter = .{ .val = ~@as(@typeInfo(Filter.Tag).Enum.tag_type, 0) };
    if (mem.testEqualMany(u8, "-f", arg)) {
        mask.set(.regular);
    } else if (mem.testEqualMany(u8, "-d", arg)) {
        mask.set(.directory);
    } else if (mem.testEqualMany(u8, "-b", arg)) {
        mask.set(.block_special);
    } else if (mem.testEqualMany(u8, "-h", arg)) {
        mask.set(.symbolic_link);
    } else if (mem.testEqualMany(u8, "-S", arg)) {
        mask.set(.socket);
    } else if (mem.testEqualMany(u8, "-p", arg)) {
        mask.set(.named_pipe);
    } else if (mem.testEqualMany(u8, "-c", arg)) {
        mask.set(.character_special);
    } else if (mem.testEqualMany(u8, "+f", arg)) {
        mask.unset(.regular);
    } else if (mem.testEqualMany(u8, "+d", arg)) {
        mask.unset(.directory);
    } else if (mem.testEqualMany(u8, "+b", arg)) {
        mask.unset(.block_special);
    } else if (mem.testEqualMany(u8, "+h", arg)) {
        mask.unset(.symbolic_link);
    } else if (mem.testEqualMany(u8, "+S", arg)) {
        mask.unset(.socket);
    } else if (mem.testEqualMany(u8, "+p", arg)) {
        mask.unset(.named_pipe);
    } else if (mem.testEqualMany(u8, "+c", arg)) {
        mask.unset(.character_special);
    }
    return mask;
}
inline fn printIfNAvail(comptime n: usize, allocator: Allocator1, array: String1, offset: u64) u64 {
    const many: []const u8 = array.readManyAt(allocator, offset);
    if (many.len > (n - 1)) {
        if (n == 1) {
            file.noexcept.write(1, many);
            return many.len;
        } else if (many[many.len - 1] == '\n') {
            file.noexcept.write(1, many);
            return many.len;
        }
    }
    return 0;
}
noinline fn printAlong(results: *Results, done: *bool, allocator: *Allocator1, array: *String1) void {
    var offset: u64 = 0;
    while (true) {
        offset += printIfNAvail(4096, allocator.*, array.*, offset);
        if (done.*) {
            break;
        }
    }
    while (offset != array.len(allocator.*)) {
        offset += printIfNAvail(1, allocator.*, array.*, offset);
    }
    results.show();
    done.* = false;
}
inline fn getNames(args: *[][*:0]u8) Names {
    var names: Names = .{};
    var i: u64 = 1;
    while (i != args.len) : (i += 1) {
        names.writeOne(meta.manyToSlice(args.*[i]));
    }
    return names;
}
fn convertToInt(options: *Options, arg: []const u8) void {
    options.max_depth = builtin.parse.ud(u8, arg);
}
pub fn main(args_in: [][*:0]u8) !void {
    var address_space: builtin.AddressSpace = .{};
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    var done: bool = undefined;
    if (Options.permit_switch_arrows) {
        Style.setArrows(options);
    }
    var names: Names = getNames(&args);
    if (names.len() == 0) {
        names.writeOne(".");
    }
    var allocator_0: Allocator0 = try Allocator0.init(&address_space);
    defer allocator_0.deinit(&address_space);
    var allocator_1: Allocator1 = try Allocator1.init(&address_space);
    defer allocator_1.deinit(&address_space);
    const stack_addr: u64 = if (Options.print_in_second_thread) try meta.wrap(thread.map(map_spec, 8)) else 0;
    defer thread.unmap(.{ .errors = .{} }, 8);
    try meta.wrap(allocator_0.map(64 * 1024 * 1024));
    try meta.wrap(allocator_1.map(64 * 1024 * 1024));
    for (names.readAll()) |arg| {
        done = false;
        var results: Results = .{};
        var alts_buf: PrintArray = .{};
        if (!Options.plain_print) {
            alts_buf.writeCount(4096, (" " ** 4096).*);
            alts_buf.undefine(4096);
        }
        var link_buf: PrintArray = .{};
        var array: String1 = String1.init(&allocator_1);
        var tid: u64 = undefined;
        defer array.deinit(&allocator_1);
        if (Options.print_in_second_thread) {
            tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &results, &done, &allocator_1, &array });
        }
        try meta.wrap(array.appendMany(&allocator_1, arg));
        if (arg[arg.len - 1] != '/') {
            try meta.wrap(array.appendMany(&allocator_1, "/\n"));
        } else {
            try meta.wrap(array.appendMany(&allocator_1, "\n"));
        }
        writeAndWalk(&options, &allocator_0, &allocator_1, &array, &alts_buf, &link_buf, &results, null, arg, 0) catch {};
        if (Options.print_in_second_thread) {
            done = true;
            mem.monitor(bool, &done);
        } else {
            file.noexcept.write(2, array.readAll(allocator_1));
            results.show();
        }
    }
}
