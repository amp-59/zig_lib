const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const thread = @import("./thread.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = false;
pub const is_verbose: bool = false;

const map_spec: thread.MapSpec = .{ .options = .{} };
const thread_spec = proc.CloneSpec{
    .errors = null,
    .return_type = u64,
    .options = .{
        .set_thread_local_storage = true,
        .set_parent_thread_id = true,
        .set_child_thread_id = true,
        .clear_child_thread_id = true,
        .address_space = true,
        .thread = true,
        .file_system = true,
        .files = true,
        .signal_handlers = true,
        .sysvsem = true,
        .io = false,
    },
};
const wait_spec: proc.WaitIdSpec = .{
    .id_type = .{ .tag = .pid },
    .options = .{
        .continued = false,
        .no_thread = false,
        .clone = true,
        .exited = false,
        .stopped = false,
        .all = false,
    },
};

const BlockAllocator0 = mem.GenericArenaAllocator(.{
    .arena_index = 24,
    .options = .{
        .count_allocations = false,
        .require_filo_free = false,
        .require_geometric_growth = true,
        .trace_state = false,
    },
});
const BlockAllocator1 = mem.GenericArenaAllocator(.{
    .arena_index = 32,
    .options = .{
        .count_allocations = false,
        .require_filo_free = true,
        .require_geometric_growth = true,
        .trace_state = false,
    },
});
const String1 = BlockAllocator1.StructuredHolder(u8);
const String0 = BlockAllocator0.StructuredHolder(u8);
const DirStream = file.DirStreamBlock(.{
    .Allocator = BlockAllocator0,
    .options = .{},
    .logging = .{},
});
const Names = mem.StructuredAutomaticVector(.{
    .child = [:0]const u8,
    .count = 128,
    .low_alignment = 8,
});
const PrintArray = mem.StaticString(4096);
const Options = struct {
    show_hidden: bool = always_show_hidden or permit_switch_arrows,
    try_print_links: bool = false,
};
const Results = struct {
    files: u64 = 0,
    dirs: u64 = 0,
    links: u64 = 0,
    fn total(results: Results) u64 {
        return results.dirs + results.files + results.links;
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

const print_in_second_thread: bool = true;
const always_show_hidden: bool = true;
const permit_switch_arrows: bool = false;
const plain_print: bool = false;
const pretty_print: bool = !plain_print;

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
const empty_dir_arrow_bs: []const u8 = del_s ++ "|---- ";
const empty_dir_arrow_ws: []const u8 = del_s ++ "├──── ";
const last_empty_dir_arrow_bs: []const u8 = del_s ++ "`---- ";
const last_empty_dir_arrow_ws: []const u8 = del_s ++ "└──── ";
const Style = if (permit_switch_arrows) struct {
    var wide: bool = false;
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
    fn setArrows() void {
        spc_s = if (wide) spc_ws else spc_bs;
        bar_s = if (wide) bar_ws else bar_bs;
        links_to_s = if (wide) links_to_ws else links_to_bs;
        file_arrow_s = if (wide) file_arrow_ws else file_arrow_bs;
        last_file_arrow_s = if (wide) last_file_arrow_ws else last_file_arrow_bs;
        link_arrow_s = if (wide) file_arrow_ws else file_arrow_bs;
        last_link_arrow_s = if (wide) last_file_arrow_ws else last_file_arrow_bs;
        dir_arrow_s = if (wide) dir_arrow_ws else dir_arrow_bs;
        last_dir_arrow_s = if (wide) last_dir_arrow_ws else last_dir_arrow_bs;
        empty_dir_arrow_s = if (wide) empty_dir_arrow_ws else empty_dir_arrow_bs;
        last_empty_dir_arrow_s = if (wide) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
    }
} else struct {
    const wide: bool = false;
    const spc_s: []const u8 = if (wide) spc_ws else spc_bs;
    const bar_s: []const u8 = if (wide) bar_ws else bar_bs;
    const links_to_s: []const u8 = if (wide) links_to_ws else links_to_bs;
    const file_arrow_s: []const u8 = if (wide) file_arrow_ws else file_arrow_bs;
    const last_file_arrow_s: []const u8 = if (wide) last_file_arrow_ws else last_file_arrow_bs;
    const link_arrow_s: []const u8 = if (wide) file_arrow_ws else file_arrow_bs;
    const last_link_arrow_s: []const u8 = if (wide) last_file_arrow_ws else last_file_arrow_bs;
    const dir_arrow_s: []const u8 = if (wide) dir_arrow_ws else dir_arrow_bs;
    const last_dir_arrow_s: []const u8 = if (wide) last_dir_arrow_ws else last_dir_arrow_bs;
    const empty_dir_arrow_s: []const u8 = if (wide) empty_dir_arrow_ws else empty_dir_arrow_bs;
    const last_empty_dir_arrow_s: []const u8 = if (wide) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
};
fn writeAndWalk(
    opts: *Options,
    allocator_0: *BlockAllocator0,
    allocator_1: *BlockAllocator1,
    array: *String1,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    results: *Results,
    dirfd: ?u64,
    name: [:0]const u8,
) anyerror!void {
    var dir: DirStream = try DirStream.initAt(allocator_0, dirfd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    const need_separator: bool = name[name.len - 1] != '/';
    if (plain_print) {
        alts_buf.writeMany(name);
        if (need_separator) alts_buf.writeOne('/');
    }
    defer if (plain_print) {
        alts_buf.undefine(name.len);
        alts_buf.undefine(builtin.int(u64, need_separator));
    };
    while (index != list.count) : (index += 1) {
        const entry: *DirStream.Entry = list.at(index) catch break;
        const is_last: bool = index == list.count - 1;
        const indent: []const u8 = if (is_last) Style.spc_s else Style.bar_s;
        if (pretty_print) alts_buf.writeMany(indent);
        defer if (pretty_print) alts_buf.undefine(indent.len);
        const base_name: [:0]const u8 = entry.name();
        if (!opts.show_hidden) {
            if (base_name[0] == '.') {
                continue;
            }
            if (builtin.int2v(
                bool,
                equalMany(u8, "zig-cache", base_name),
                equalMany(u8, "zig-out", base_name),
            )) {
                continue;
            }
        }
        switch (entry.kind) {
            .directory => {
                results.dirs += 1;
                const s_arrow_s: []const u8 = mach.cmovx(is_last, Style.last_dir_arrow_s, Style.dir_arrow_s);
                if (plain_print) {
                    try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), base_name, endl_s });
                } else {
                    try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), s_arrow_s, base_name, endl_s });
                }
                const s_total: u64 = results.total();
                writeAndWalk(opts, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, base_name) catch {};
                const t_total: u64 = results.total();
                const t_arrow_s: []const u8 = mach.cmovx(is_last, last_empty_dir_arrow_ws, empty_dir_arrow_ws);
                if (Style.wide and !plain_print) {
                    if (s_total == t_total) {
                        array.rewriteAny(mem.ptr_wr_spec, .{ alts_buf.readAll(), t_arrow_s, base_name, endl_s });
                    }
                }
            },
            .symbolic_link => {
                results.links += 1;
                const arrow: []const u8 = mach.cmovx(is_last, Style.last_link_arrow_s, Style.link_arrow_s);
                const style: []const u8 = lit.fx.color.fg.cyan;
                if (opts.try_print_links) {
                    if (plain_print) {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), base_name, endl_s });
                    } else {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), arrow, style, base_name, Style.links_to_s });
                    }
                    if (file.readLinkAt(.{}, dir.fd, base_name, link_buf.referCountAt(0, 4096))) |path_name| {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ path_name, endl_s });
                    } else |_| {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ "???", endl_s });
                    }
                } else {
                    if (plain_print) {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), base_name, endl_s });
                    } else {
                        try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), arrow, style, base_name, endl_s });
                    }
                }
            },
            else => {
                results.files += 1;
                const arrow: []const u8 = mach.cmovx(is_last, Style.last_file_arrow_s, Style.file_arrow_s);
                if (plain_print) {
                    try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), base_name, endl_s });
                } else {
                    try array.appendAny(mem.ptr_wr_spec, allocator_1, .{ alts_buf.readAll(), arrow, any_style[@enumToInt(entry.kind)], base_name, endl_s });
                }
            },
        }
    }
}
fn equalMany(comptime T: type, arg1: []const T, arg2: []const T) bool {
    if (arg1.len != arg2.len) {
        return false;
    }
    for (arg1) |c, i| {
        if (c != arg2[i]) return false;
    }
    return true;
}
fn setType(arg: []const u8) Filter {
    var mask: Filter = .{ .val = ~@as(u64, 0) };
    if (equalMany(u8, "-f", arg)) {
        mask.set(.regular);
    } else if (equalMany(u8, "-d", arg)) {
        mask.set(.directory);
    } else if (equalMany(u8, "-b", arg)) {
        mask.set(.block_special);
    } else if (equalMany(u8, "-h", arg)) {
        mask.set(.symbolic_link);
    } else if (equalMany(u8, "-S", arg)) {
        mask.set(.socket);
    } else if (equalMany(u8, "-p", arg)) {
        mask.set(.named_pipe);
    } else if (equalMany(u8, "-c", arg)) {
        mask.set(.character_special);
    } else if (equalMany(u8, "+f", arg)) {
        mask.unset(.regular);
    } else if (equalMany(u8, "+d", arg)) {
        mask.unset(.directory);
    } else if (equalMany(u8, "+b", arg)) {
        mask.unset(.block_special);
    } else if (equalMany(u8, "+h", arg)) {
        mask.unset(.symbolic_link);
    } else if (equalMany(u8, "+S", arg)) {
        mask.unset(.socket);
    } else if (equalMany(u8, "+p", arg)) {
        mask.unset(.named_pipe);
    } else if (equalMany(u8, "+c", arg)) {
        mask.unset(.character_special);
    }
    return mask;
}
fn showResults(counts: Results) !void {
    var array: PrintArray = .{};
    array.writeAny(mem.fmt_wr_spec, .{
        "dirs:       ", fmt.udh(counts.dirs),          '\n',
        "files:      ", fmt.udh(counts.files),         '\n',
        "links:      ", fmt.udh(counts.links),         '\n',
        "swaps:      ", fmt.udh(DirStream.disordered), '\n',
    });
    try file.write(2, array.readAll());
}
fn shift(args: *[][*:0]u8, i: u64) void {
    if (args.len > i + 1) {
        var this: *[*:0]u8 = &args.*[i];
        for (args.*[i + 1 ..]) |*next| {
            this.* = next.*;
            this = next;
        }
    }
    args.* = args.*[0 .. args.len - 1];
}

inline fn printIfAvail(allocator: BlockAllocator1, array: String1, offset: u64) u64 {
    const many: []const u8 = array.readManyAt(allocator, offset);
    if (many.len != 0) {
        file.noexcept.write(2, many);
    }
    return many.len;
}
noinline fn printAlong(done: *volatile bool, allocator: *BlockAllocator1, array: *String1) void {
    var offset: u64 = 0;
    while (true) {
        offset += printIfAvail(allocator.*, array.*, offset);
        if (done.*) {
            break;
        }
    }
    offset += printIfAvail(allocator.*, array.*, offset);
    builtin.assert(offset == array.count(allocator.*));
    file.noexcept.write(2, "\n");
}
inline fn getOpts(args: *[][*:0]u8) Options {
    var opts: Options = .{};
    var i: u64 = 1;
    while (i != args.len) {
        if (!always_show_hidden) {
            if (equalMany(u8, "-a", meta.manyToSlice(args.*[i])) or
                equalMany(u8, "--all", meta.manyToSlice(args.*[i])))
            {
                opts.show_hidden = true;
                shift(args, i);
                continue;
            }
        }
        if (permit_switch_arrows) {
            if (equalMany(u8, "-w", meta.manyToSlice(args.*[i])) or
                equalMany(u8, "--wide", meta.manyToSlice(args.*[i])))
            {
                Style.wide = true;
                shift(args, i);
                continue;
            }
        }
        if (equalMany(u8, "-L", meta.manyToSlice(args.*[i])) or
            equalMany(u8, "--follow", meta.manyToSlice(args.*[i])))
        {
            opts.try_print_links = true;
            shift(args, i);
            continue;
        }
        if (equalMany(u8, "+L", meta.manyToSlice(args.*[i])) or
            equalMany(u8, "--no-follow", meta.manyToSlice(args.*[i])))
        {
            opts.try_print_links = false;
            shift(args, i);
            continue;
        }
        if (equalMany(u8, "-h", meta.manyToSlice(args.*[i])) or equalMany(u8, "--help", meta.manyToSlice(args.*[i]))) {
            file.noexcept.write(2,
                \\-h, --help        print this text
                \\-a, --all         print hidden entries
                \\-L, --follow      print link destinations
            ++ if (permit_switch_arrows)
                \\-w, --wide        print fancy arrows
                \\
            else
                \\
            );
            sys.exit(0);
        }
        if (equalMany(u8, "--", meta.manyToSlice(args.*[i]))) {
            break;
        }
        i += 1;
    }
    return opts;
}
inline fn getNames(args: *[][*:0]u8) Names {
    var names: Names = .{};
    var i: u64 = 1;
    while (i != args.len) : (i += 1) {
        names.writeOne(meta.manyToSlice(args.*[i]));
    }
    return names;
}

pub fn threadMain(address_space: *mem.AddressSpace, args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;
    var done: bool = undefined;
    var opts: Options = getOpts(&args);
    var names: Names = getNames(&args);
    if (permit_switch_arrows) {
        Style.setArrows();
    }
    if (names.count() == 0) {
        names.writeOne(".");
    }
    var allocator_0: BlockAllocator0 = try BlockAllocator0.init(address_space);
    var allocator_1: BlockAllocator1 = try BlockAllocator1.init(address_space);
    defer allocator_0.deinit(address_space);
    defer allocator_1.deinit(address_space);
    const stack_addr: u64 = mach.cmov64(print_in_second_thread, try thread.map(map_spec, 8), 0);
    defer thread.unmap(.{ .errors = null }, 8);
    try allocator_0.map(4096);
    try allocator_1.map(4096);
    for (names.readAll()) |arg| {
        done = false;
        var results: Results = .{};
        var alts_buf: PrintArray = .{};
        if (!plain_print) {
            alts_buf.writeCount(4096, (" " ** 4096).*);
            alts_buf.undefine(4096);
        }
        var link_buf: PrintArray = .{};
        var array: String1 = String1.init(&allocator_1);
        defer array.deinit(&allocator_1);
        if (print_in_second_thread) {
            _ = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &done, &allocator_1, &array });
        }
        try array.appendMany(&allocator_1, arg);
        if (arg[arg.len - 1] != '/') {
            try array.appendMany(&allocator_1, "/\n");
        } else {
            try array.appendMany(&allocator_1, "\n");
        }
        try writeAndWalk(&opts, &allocator_0, &allocator_1, &array, &alts_buf, &link_buf, &results, null, arg);
        if (print_in_second_thread) {
            done = true;
            try time.sleep(.{}, .{ .nsec = 25 });
        } else {
            file.noexcept.write(2, array.readAll(allocator_1));
        }
        try showResults(results);
    }
}
pub fn main(args: [][*:0]u8, _: [][*:0]u8) !void {
    var address_space: mem.AddressSpace = .{};
    try threadMain(&address_space, args);
}
