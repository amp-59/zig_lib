const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const proc = @import("./proc.zig");
const math = @import("./math.zig");
const file = @import("./file.zig");
const debug = @import("./debug.zig");
const dwarf = @import("./dwarf.zig");
const builtin = @import("./builtin.zig");

pub const panic = debug.panic;
pub usingnamespace debug.panic_extra;

var working: []const u8 = &.{};

pub const Allocator = mem.SimpleAllocator;
pub const logging_default: debug.Logging.Default = .{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Success = false,
    .Release = false,
};
const FileMap = mem.GenericSimpleMap([:0]const u8, [:0]u8);

const Level = struct {
    var start: usize = lb_addr;

    const lb_addr: usize = 0x600000000000;
};
const tab = .{
    .self_link_s = "/proc/self/exe",
    .open_error_s = "could not open executable",
    .stat_error_s = "could not stat executable",
    .read_error_s = "could not read executable",
};
const Number = union(enum) {
    pc_addr: u64,
    line_no: u64,
    none,
};
pub const StackIterator = struct {
    first_addr: ?usize,
    frame_addr: usize,
    pub fn init(first_address: ?usize, frame_addr: ?usize) StackIterator {
        return .{
            .first_addr = first_address,
            .frame_addr = frame_addr orelse @frameAddress(),
        };
    }
    pub fn next(itr: *StackIterator) ?usize {
        var addr: usize = itr.next_internal() orelse return null;
        if (itr.first_addr) |first_addr| {
            while (addr != first_addr) {
                addr = itr.next_internal() orelse return null;
            }
            itr.first_addr = null;
        }
        return addr;
    }
    fn next_internal(itr: *StackIterator) ?usize {
        if (itr.frame_addr == 0) {
            return null;
        }
        const next_addr: usize = @as(*const usize, @ptrFromInt(itr.frame_addr)).*;
        if (next_addr != 0 and
            next_addr < itr.frame_addr)
        {
            return null;
        }
        const pc = @addWithOverflow(itr.frame_addr, @sizeOf(usize));
        if (pc[1] != 0) {
            return null;
        }
        itr.frame_addr = next_addr;
        return @as(*usize, @ptrFromInt(pc[0])).*;
    }
};
fn writeLastLine(trace: *const debug.Trace, buf: [*]u8, width: u64, break_line_count: u8) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    var idx: u64 = 0;
    while (idx != break_line_count) : (idx +%= 1) {
        if (trace.options.write_sidebar) {
            len +%= writeSideBar(trace, width, buf + len, .none);
        }
        buf[len] = '\n';
        len +%= 1;
    }
    @as(*[4]u8, @ptrCast(buf + len)).* = "\x1b[0m".*;
    if (buf[len -% 1] != '\n') {
        buf[len +% 4] = '\n';
        return len +% 5;
    }
    return len +% 4;
}
fn writeSideBar(trace: *const debug.Trace, width: u64, buf: [*]u8, number: Number) u64 {
    @setRuntimeSafety(false);
    const sidebar: []const u8 = trace.options.tokens.sidebar;
    const sidebar_char: bool = sidebar.len == 1;
    if (!trace.options.show_line_no and
        !trace.options.show_pc_addr)
    {
        return 0;
    }
    var tmp: [8]u8 = undefined;
    var len: u64 = 0;
    var pos: u64 = 0;
    const fill: []const u8 = trace.options.tokens.sidebar_fill;
    const fill_len: u64 = @min(width, fill.len);
    switch (number) {
        .none => {
            pos = fmt.strcpy(&tmp, fill[0..fill_len]);
        },
        .pc_addr => |pc_addr| if (trace.options.show_pc_addr) {
            if (trace.options.tokens.pc_addr) |style| {
                len +%= fmt.strcpy(buf, style);
            }
            pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        } else {
            pos = fmt.strcpy(&tmp, fill[0..fill_len]);
        },
        .line_no => |line_no| if (trace.options.show_line_no) {
            if (trace.options.tokens.line_no) |style| {
                len +%= fmt.strcpy(buf, style);
            }
            pos +%= fmt.ud64(line_no).formatWriteBuf(&tmp);
        } else {
            pos = fmt.strcpy(&tmp, fill[0..fill_len]);
        },
    }
    const spaces: u64 = (width -% 1) -| pos;
    @memset((buf + len)[0..spaces], ' ');
    len +%= spaces;
    len +%= fmt.strcpy(buf + len, tmp[0..pos]);
    @as(*[4]u8, @ptrCast(buf + len)).* = "\x1b[0m".*;
    len +%= 4;
    if (sidebar_char) {
        buf[len] = sidebar[0];
        len +%= 1;
    } else {
        len +%= fmt.strcpy(buf + len, sidebar);
    }
    return len;
}
fn writeFiller(buf: [*]u8, filler: []const u8, fill_len: u64) u64 {
    @setRuntimeSafety(false);
    if (filler.len == 1) {
        @memset(buf[0..fill_len], filler[0]);
        return fill_len;
    } else {
        var len: u64 = 0;
        for (0..fill_len) |_| {
            @memcpy(buf + len, filler);
            len +%= filler.len;
        }
        return len;
    }
}
fn writeCaret(trace: *const debug.Trace, buf: [*]u8, width: u64, addr: u64, column: u64) u64 {
    @setRuntimeSafety(false);
    const caret: []const u8 = trace.options.tokens.caret;
    var len: u64 = 0;
    if (trace.options.write_sidebar) {
        len +%= writeSideBar(trace, width, buf, .{ .pc_addr = addr });
    }
    const fill_len: u64 = column -| 1;
    len +%= writeFiller(buf + len, trace.options.tokens.caret_fill, fill_len);
    @memcpy(buf + len, caret);
    len +%= caret.len;
    buf[len] = '\n';
    return len +% 1;
}
fn highlight(buf: [*]u8, tok: *builtin.parse.Token, syntax: anytype) u64 {
    @setRuntimeSafety(false);
    for (syntax) |pair| {
        for (pair.tags) |tag| {
            if (tok.tag == tag) {
                @memcpy(buf, pair.style);
                return pair.style.len;
            }
        }
    }
    return 0;
}
fn writeExtendedSourceLocation(
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    addr: u64,
    unit: *const dwarf.Unit,
    src: dwarf.SourceLocation,
) u64 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = src.formatWriteBuf(buf);
    ptr[0..2].* = ": ".*;
    ptr += 2;
    ptr += fmt.ux64(addr).formatWriteBuf(ptr);
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        ptr[0..4].* = " in ".*;
        ptr += 4;
        @memcpy(ptr, fn_name);
        ptr += fn_name.len;
    }
    if (unit.info_entry.get(.name)) |form_val| {
        ptr[0..2].* = " (".*;
        ptr += 2;
        const name: []const u8 = form_val.getString(dwarf_info);
        @memcpy(ptr, name);
        ptr += name.len;
        ptr[0] = ')';
        ptr += 1;
    }
    ptr[0] = '\n';
    return @intFromPtr(ptr + 1) -% @intFromPtr(buf);
}
fn writeSourceContext(
    trace: *const debug.Trace,
    allocator: *Allocator,
    file_map: *FileMap,
    buf: [*]u8,
    width: u64,
    addr: u64,
    src: dwarf.SourceLocation,
) u64 {
    @setRuntimeSafety(false);
    const min: u64 = src.line -| trace.options.context_line_count;
    const max: u64 = src.line +% trace.options.context_line_count +% 1;
    var line: u64 = min;
    const fbuf: [:0]u8 = fastAllocFile(allocator, file_map, src.file);
    var itr: builtin.parse.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.parse.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    var ptr: [*]u8 = buf;
    var loc: dwarf.LineLocation = .{};
    while (line != max) : (line +%= 1) {
        if (loc.update(fbuf, line)) {
            if (trace.options.write_sidebar) {
                ptr += writeSideBar(trace, width, ptr, .{ .line_no = loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                while (itr.buf_pos <= loc.start) {
                    tok = itr.next();
                }
                var bytes: []const u8 = fbuf[loc.start..@min(loc.finish, tok.loc.start)];
                @memcpy(ptr, bytes);
                ptr += bytes.len;
                loc.start +%= bytes.len;
                while (loc.start < loc.finish) {
                    if (loc.start < tok.loc.start) {
                        bytes = fbuf[loc.start..tok.loc.start];
                        @memcpy(ptr, bytes);
                        ptr += bytes.len;
                    }
                    if (loc.finish > tok.loc.start) {
                        ptr += highlight(ptr, &tok, syntax);
                    }
                    bytes = fbuf[tok.loc.start..tok.loc.finish];
                    loc.start = tok.loc.finish;
                    @memcpy(ptr, bytes);
                    ptr += bytes.len;
                    ptr = ptr - @intFromBool((ptr - 1)[0] == '\n');
                    ptr[0..4].* = "\x1b[0m".*;
                    ptr += 4;
                    tok = itr.next();
                }
            } else {
                const bytes: []const u8 = loc.slice(fbuf);
                @memcpy(ptr, bytes);
                ptr += bytes.len;
            }
            if ((ptr - 1)[0] != '\n') {
                ptr[0] = '\n';
                ptr += 1;
            }
            if (line == src.line and trace.options.write_caret) {
                ptr += writeCaret(trace, ptr, width, addr, src.column);
            }
        }
    }
    return @intFromPtr(ptr - @intFromPtr(buf));
}
fn writeSourceCodeAtAddress(
    trace: *const debug.Trace,
    allocator: *Allocator,
    file_map: *FileMap,
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    pos: u64,
    width: u64,
    addr: u64,
) ?dwarf.DwarfInfo.AddressInfo {
    @setRuntimeSafety(false);
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len]) |*addr_info| {
        if (addr_info.addr == addr) {
            addr_info.count +%= 1;
            break;
        }
    } else {
        if (dwarf_info.findCompileUnit(addr)) |unit| {
            if (dwarf_info.getSourceLocation(allocator, unit, addr)) |src| {
                var ptr: [*]u8 = buf + pos;
                ptr += writeExtendedSourceLocation(dwarf_info, ptr, addr, unit, src);
                ptr += writeSourceContext(trace, allocator, file_map, ptr, width, addr, src);
                ptr += writeLastLine(trace, ptr, width, trace.options.break_line_count);
                return .{ .addr = addr, .start = pos, .finish = pos +% @intFromPtr(ptr - @intFromPtr(buf)) };
            }
        }
    }
    return null;
}
fn writeNTimes(buf: [*]u8, count: usize) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..2].* = " (".*;
    var ptr: [*]u8 = buf;
    ptr += 2;
    if (count > 16) {
        ptr[0..4].* = "\x1b[1m".*;
        ptr += 4;
    }
    ptr += fmt.ud64(count +% 1).formatWriteBuf(ptr);
    ptr[0..12].* = "\x1b[0m times) ".*;
    ptr += 12;
    return ptr;
}
fn printMessage(allocator: *mem.SimpleAllocator, buf: [*]u8, addr_info: *dwarf.DwarfInfo.AddressInfo) void {
    @setRuntimeSafety(false);
    const msg: []u8 = buf[addr_info.start..addr_info.finish];
    if (addr_info.count != 0) {
        const new: [*]u8 = @ptrFromInt(allocator.allocateRaw(msg.len +% 32, 1));
        const save: usize = allocator.next;
        var end: usize = 0;
        while (msg[end] != '\n') : (end +%= 1) new[end] = msg[end];
        var ptr: [*]u8 = writeNTimes(new + end, addr_info.count);
        ptr = fmt.strcpyEqu(ptr, msg[end..]);
        debug.write(new[0..fmt.strlen(ptr, new)]);
        allocator.next = save;
    } else {
        debug.write(msg);
    }
}
fn fastAllocFile(allocator: *Allocator, file_map: *FileMap, pathname: [:0]const u8) [:0]u8 {
    @setRuntimeSafety(false);
    for (file_map.pairs[0..file_map.pairs_len]) |l_pair| {
        if (mem.testEqualString(l_pair.key, pathname)) {
            return l_pair.val;
        }
    }
    const fd: usize = sys.call_noexcept(.open, usize, .{ @intFromPtr(pathname.ptr), sys.O.RDONLY, 0 });
    if (fd >= 1024) {
        sys.call_noexcept(.exit, void, .{2});
    }
    var st: file.Status = undefined;
    var rc: usize = sys.call_noexcept(.fstat, usize, .{ fd, @intFromPtr(&st) });
    if (rc != 0) {
        proc.exit(2);
    }
    const addr: usize = allocator.allocateRaw(st.size +% 1, 8);
    var buf: [*]u8 = @ptrFromInt(addr);
    @memset(buf[0 .. st.size +% 1], undefined);
    rc = sys.call_noexcept(.read, usize, .{ fd, addr, st.size });
    buf += st.size;
    buf[0] = 0;
    if (rc != st.size) {
        sys.call_noexcept(.exit, void, .{2});
    }
    buf -= st.size;
    sys.call_noexcept(.close, void, .{fd});
    const ret: [:0]u8 = buf[0..st.size :0];
    file_map.appendOne(allocator, .{ .key = pathname, .val = ret });
    return ret;
}
fn maximumSideBarWidth(itr: StackIterator) usize {
    @setRuntimeSafety(false);
    var tmp: StackIterator = itr;
    var max_len: usize = 0;
    while (tmp.next()) |addr| {
        max_len = @max(max_len, fmt.ux64(addr).formatLength());
    }
    return max_len +% 1;
}
pub fn printSourceCodeAtAddress(trace: *const debug.Trace, addr: usize) callconv(.C) void {
    printSourceCodeAtAddresses(trace, 0, &[_]usize{addr}, 1);
}
pub fn printSourceCodeAtAddresses(trace: *const debug.Trace, ret_addr: usize, addrs: [*]const usize, addrs_len: usize) callconv(.C) void {
    @setRuntimeSafety(false);
    const start: usize = @atomicRmw(usize, &Level.start, .Add, 0x40000000, .SeqCst);
    var allocator: mem.SimpleAllocator = .{ .start = start, .next = start, .finish = start };
    if (dwarf.SourceLocation.cwd.len == 0) {
        const cwd_addr: usize = allocator.allocateRaw(4096, 1);
        const rc: usize = sys.call_noexcept(.getcwd, usize, .{ cwd_addr, 4096 });
        if (rc > 4096) {
            sys.call_noexcept(.exit, void, .{2});
        }
        const cwd: [*]u8 = @ptrFromInt(cwd_addr);
        dwarf.SourceLocation.cwd = cwd[0 .. rc -% 1 :0];
    }
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    dwarf.SourceLocation.cwd = file.getCwd(.{ .errors = .{} }, buf[0..4096]);
    defer allocator.unmapAll();
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));
    dwarf_info.scanAllCompileUnits(&allocator);
    buf = @ptrFromInt(allocator.allocateRaw(1024 *% 4096, 1));
    @memset(buf[0 .. 1024 *% 4096], 0);
    var len: usize = 0;
    var width: usize = fmt.ux64(ret_addr).formatLength();
    for (addrs[0..addrs_len]) |addr| {
        width = @max(width, fmt.ux64(addr).formatLength());
    }
    width *%= @intFromBool(trace.options.write_sidebar);
    for (addrs[0..addrs_len]) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf, len, width, addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    if (ret_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf, len, width, ret_addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    debug.write(buf[0..len]);
}
pub fn printStackTrace(trace: *const debug.Trace, first_addr: usize, frame_addr: usize) callconv(.C) void {
    @setRuntimeSafety(builtin.is_safe);
    if (Level.start != 0x600000000000) {
        return;
    }
    debug.aboutWhere(debug.about.note_p0_s, "Requesting stack trace", first_addr, @src());
    const start: usize = @atomicRmw(usize, &Level.start, .Add, 0x40000000, .SeqCst);
    var allocator: Allocator = .{ .start = start, .next = start, .finish = start };
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    if (dwarf.SourceLocation.cwd.len == 0) {
        const cwd_addr: usize = allocator.allocateRaw(4096, 1);
        const rc: usize = sys.call_noexcept(.getcwd, usize, .{ cwd_addr, 4096 });
        if (rc > 4096) {
            sys.call_noexcept(.exit, void, .{2});
        }
        const cwd: [*]u8 = @ptrFromInt(cwd_addr);
        dwarf.SourceLocation.cwd = cwd[0 .. rc -% 1 :0];
    }
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));
    if (dwarf.logging_abbrev_entry or
        dwarf.logging_summary or
        dwarf.logging_info_entry)
    {
        dwarf.DwarfInfo.active = &dwarf_info;
    }
    dwarf_info.scanAllCompileUnits(&allocator);
    var buf: []u8 = allocator.allocate(u8, 1024 *% 4096);
    working = buf;
    var len: usize = 0;
    var itr: StackIterator = if (frame_addr != 0) .{
        .first_addr = null,
        .frame_addr = frame_addr,
    } else .{
        .first_addr = first_addr,
        .frame_addr = @frameAddress(),
    };
    const width: usize = if (trace.options.write_sidebar) maximumSideBarWidth(itr) else 0;
    if (frame_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf.ptr, len, width, first_addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    while (itr.next()) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf[len..].ptr, len, width, addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len], 1..) |*addr_info, idx| {
        printMessage(&allocator, buf.ptr, addr_info);
        if (idx == trace.options.max_depth) {
            break;
        }
    }
    allocator.unmapAll();
}
comptime {
    if (builtin.output_mode == .Obj or builtin.want_stack_traces) {
        @export(printStackTrace, .{ .name = "printStackTrace", .linkage = .Strong });
        @export(printSourceCodeAtAddress, .{ .name = "printSourceCodeAtAddress", .linkage = .Strong });
        @export(printSourceCodeAtAddresses, .{ .name = "printSourceCodeAtAddresses", .linkage = .Strong });
    }
}
