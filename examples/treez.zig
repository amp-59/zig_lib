const srg = @import("../zig_lib.zig");
const sys = srg.sys;
const fmt = srg.fmt;
const mem = srg.mem;
const file = srg.file;
const meta = srg.meta;
const mach = srg.mach;
const proc = srg.proc;
const spec = srg.spec;
const thread = srg.thread;
const builtin = srg.builtin;
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const signal_handlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .Trap = false,
    .FloatingPointError = false,
};
pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 32,
    .errors = .{ .acquire = .ignore, .release = .ignore },
});
const Allocator0 = mem.GenericArenaAllocator(.{
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
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
});
const Allocator1 = mem.GenericArenaAllocator(.{
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
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
});
const PrintArray = mem.StaticString(4096);
const Array = Allocator1.StructuredStreamHolder(u8);
const String0 = Allocator0.StructuredHolder(u8);
const DirStream = file.GenericDirStream(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = spec.dir.logging.silent,
});
const Filter = meta.EnumBitField(file.Kind);
const Names = mem.StaticArray([:0]const u8, max_pathname_args);
const Status = packed struct {
    flag: meta.maybe(print_in_second_thread, u8) = 0,
    file_count: meta.maybe(count_files, u64) = 0,
    dir_count: meta.maybe(count_dirs, u64) = 0,
    link_count: meta.maybe(count_links, u64) = 0,
    max_depth: meta.maybe(track_max_depth, u64) = 0,
    errors: meta.maybe(count_errors, u64) = 0,
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
const about_dirs_s: [:0]const u8 = builtin.fmt.about("dirs");
const about_files_s: [:0]const u8 = builtin.fmt.about("files");
const about_links_s: [:0]const u8 = builtin.fmt.about("links");
const about_depth_s: [:0]const u8 = builtin.fmt.about("depth");
const about_errors_s: [:0]const u8 = builtin.fmt.about("errors");

// user config end
const write_spec: file.WriteSpec = .{
    .errors = .{},
};
const map_spec: thread.MapSpec = .{
    .errors = .{},
    .options = .{},
};
const thread_spec: proc.CloneSpec = .{
    .errors = .{},
    .options = .{},
    .return_type = u64,
};
fn show(status: Status) void {
    var array: PrintArray = .{};
    if (count_dirs) {
        array.writeMany(about_dirs_s);
        array.writeFormat(fmt.udh(status.dir_count));
        array.writeOne('\n');
    }
    if (count_files) {
        array.writeMany(about_files_s);
        array.writeFormat(fmt.udh(status.file_count));
        array.writeOne('\n');
    }
    if (count_links) {
        array.writeMany(about_links_s);
        array.writeFormat(fmt.udh(status.link_count));
        array.writeOne('\n');
    }
    if (track_max_depth) {
        array.writeMany(about_depth_s);
        array.writeFormat(fmt.udh(status.max_depth));
        array.writeOne('\n');
    }
    if (count_errors) {
        array.writeMany(about_errors_s);
        array.writeFormat(fmt.udh(status.errors));
        array.writeOne('\n');
    }
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
noinline fn printAlong(status: *volatile Status, allocator: *Allocator1, array: *Array) void {
    while (true) {
        const many: []u8 = array.referManyAt(allocator.*, array.index(allocator.*));
        if (many.len > 56) {
            file.write(write_spec, 1, many);
            array.stream(many.len);
        }
        if (done(status)) break;
    }
    const many: []u8 = array.referManyAt(allocator.*, array.index(allocator.*));
    if (many.len > 56) {
        file.write(write_spec, 1, many);
        array.stream(many.len);
    }
    show(status.*);
    status.flag = 0;
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
    return builtin.int3v(
        entry_name[0] == '.',
        mem.testEqualMany(u8, "zig-cache", entry_name),
        mem.testEqualMany(u8, "zig-out", entry_name),
    );
}
fn writeReadLink(
    allocator_1: *Allocator1,
    array: *Array,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: u64,
    base_name: [:0]const u8,
) !void {
    const buf: []u8 = link_buf.referManyUndefined(4096);
    if (read_link) {
        if (file.readLinkAt(.{}, dir_fd, base_name, buf)) |link_pathname| {
            array.appendAny(spec.reinterpret.ptr, allocator_1, .{ link_pathname, endl_s });
        } else |readlink_err| {
            array.appendAny(spec.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
            if (quit_on_error) {
                return readlink_err;
            }
            if (count_errors) {
                status.errors +%= 1;
            }
        }
    } else {
        array.appendAny(spec.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
    }
}
fn getSymbol(kind: file.Kind) [:0]const u8 {
    switch (kind) {
        .regular => return "f ",
        .directory => return "d ",
        .symbolic_link => return "L ",
        .block_special => return "b ",
        .character_special => return "c ",
        .named_pipe => return "p ",
        .socket => return "S ",
        .unknown => unreachable,
    }
}
fn writeAndWalk(
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *Array,
    alts_buf: *PrintArray,
    link_buf: *PrintArray,
    status: *volatile Status,
    dir_fd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const save: Allocator0.Save = allocator_0.save();
    defer allocator_0.restore(save);
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
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
                array.appendAny(spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, links_to_s });
                try writeReadLink(allocator_1, array, link_buf, status, dir.fd, basename);
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => |kind| {
                if (count_files) {
                    status.file_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_file_arrow_s else file_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(kind);
                array.appendAny(spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s });
            },
            .directory => {
                if (count_dirs) {
                    status.dir_count +%= 1;
                }
                const arrow_s: [:0]const u8 = if (last) last_dir_arrow_s else dir_arrow_s;
                const kind_s: [:0]const u8 = getSymbol(.directory);
                try meta.wrap(array.appendAny(spec.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, kind_s, basename, endl_s }));
                if (track_max_depth) {
                    status.max_depth = builtin.max(u64, status.max_depth, depth +% 1);
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
            .unknown => unreachable,
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
        var array: Array = Array.init(&allocator_1);
        var alts_buf: PrintArray = undefined;
        var link_buf: PrintArray = undefined;
        alts_buf.undefineAll();
        link_buf.undefineAll();
        defer array.deinit(&allocator_1);
        array.writeMany(arg);
        array.writeMany(if (arg[arg.len -% 1] != '/') "/\n" else "\n");
        mach.memset(alts_buf.referManyAt(0).ptr, ' ', 4096);
        if (print_in_second_thread) {
            var tid: u64 = undefined;
            var stack_buf: [16384]u8 align(16) = undefined;
            const stack_addr: u64 = @intFromPtr(&stack_buf);
            tid = proc.clone(thread_spec, stack_addr, stack_buf.len, {}, printAlong, .{ &status, &allocator_1, &array });
            @call(.always_inline, writeAndWalk, .{
                &allocator_0, &allocator_1, &array, &alts_buf, &link_buf,
                &status,      null,         arg,    0,
            }) catch if (count_errors) {
                status.errors +%= 1;
            };
            status.flag = 255;
            mem.monitor(u8, &status.flag);
            thread.unmap(.{ .errors = .{} }, 8);
        } else {
            @call(.always_inline, writeAndWalk, .{
                &allocator_0, &allocator_1, &array, &alts_buf, &link_buf,
                &status,      null,         arg,    0,
            }) catch if (count_errors) {
                status.errors +%= 1;
            };
            builtin.debug.write(array.readAll(allocator_1));
            show(status);
        }
    }
}
