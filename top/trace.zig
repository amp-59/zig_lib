const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const spec = @import("./spec.zig");
const math = @import("./math.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const debug = @import("./debug.zig");
const dwarf = @import("./dwarf.zig");
const builtin = @import("./builtin.zig");
pub const Allocator = mem.SimpleAllocator;
pub const logging_override: debug.Logging.Override = debug.Logging.Override{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Success = false,
    .Release = false,
};
const FileMap = mem.GenericSimpleMap([:0]const u8, [:0]u8);
const Level = struct {
    var start: u64 = 0x600000000000;
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
    @setRuntimeSafety(builtin.is_safe);
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
    @setRuntimeSafety(builtin.is_safe);
    const sidebar: []const u8 = trace.options.tokens.sidebar;
    const sidebar_char: bool = sidebar.len == 1;
    var tmp: [8]u8 = undefined;
    var len: u64 = 0;
    if (!trace.options.show_line_no and
        !trace.options.show_pc_addr)
    {
        return len;
    }
    var pos: u64 = 0;
    const fill: []const u8 = trace.options.tokens.sidebar_fill;
    const fill_len: u64 = @min(width, fill.len);
    switch (number) {
        .none => {
            mach.memcpy(&tmp, fill.ptr, fill_len);
            pos = fill_len;
        },
        .pc_addr => |pc_addr| if (trace.options.show_pc_addr) {
            if (trace.options.tokens.pc_addr) |style| {
                mach.memcpy(buf, style.ptr, style.len);
                len +%= style.len;
            }
            pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        } else {
            mach.memcpy(&tmp, fill.ptr, fill_len);
            pos = fill_len;
        },
        .line_no => |line_no| if (trace.options.show_line_no) {
            if (trace.options.tokens.line_no) |style| {
                mach.memcpy(buf, style.ptr, style.len);
                len +%= style.len;
            }
            pos +%= fmt.ud64(line_no).formatWriteBuf(&tmp);
        } else {
            mach.memcpy(&tmp, fill.ptr, fill_len);
            pos = fill_len;
        },
    }
    const spaces: u64 = (width -% 1) -| pos;
    mach.memset(buf + len, ' ', spaces);
    len +%= spaces;
    mach.memcpy(buf + len, &tmp, pos);
    len +%= pos;
    @as(*[4]u8, @ptrCast(buf + len)).* = "\x1b[0m".*;
    len +%= 4;
    if (sidebar_char) {
        buf[len] = sidebar[0];
        len +%= 1;
    } else {
        @memcpy(buf + len, sidebar);
        len +%= sidebar.len;
    }
    return len;
}
fn writeFiller(buf: [*]u8, filler: []const u8, fill_len: u64) u64 {
    @setRuntimeSafety(builtin.is_safe);
    if (filler.len == 1) {
        mach.memset(buf, filler[0], fill_len);
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
    @setRuntimeSafety(builtin.is_safe);
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
    @setRuntimeSafety(builtin.is_safe);
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
    @setRuntimeSafety(builtin.is_safe);
    var len: u64 = src.formatWriteBuf(buf);
    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
    len +%= 2;
    len +%= fmt.ux64(addr).formatWriteBuf(buf + len);
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        @as(*[4]u8, @ptrCast(buf + len)).* = " in ".*;
        len +%= 4;
        @memcpy(buf + len, fn_name);
        len +%= fn_name.len;
    }
    if (unit.info_entry.get(.name)) |form_val| {
        @as(*[2]u8, @ptrCast(buf + len)).* = " (".*;
        len +%= 2;
        const name: []const u8 = form_val.getString(dwarf_info);
        @memcpy(buf + len, name);
        len +%= name.len;
        @as(*[2]u8, @ptrCast(buf + len)).* = ")\n".*;
        len +%= 2;
    } else {
        buf[len] = '\n';
        len +%= 1;
    }
    return len;
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
    @setRuntimeSafety(builtin.is_safe);
    const min: u64 = src.line -| trace.options.context_line_count;
    const max: u64 = src.line +% trace.options.context_line_count +% 1;
    var line: u64 = min;
    const fbuf: [:0]u8 = fastAllocFile(allocator, file_map, src.file);
    var itr: builtin.parse.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.parse.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    var len: u64 = 0;
    var loc: dwarf.LineLocation = .{};
    while (line != max) : (line +%= 1) {
        if (loc.update(fbuf, line)) {
            if (trace.options.write_sidebar) {
                len +%= writeSideBar(trace, width, buf + len, .{ .line_no = loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                while (itr.buf_pos <= loc.start) {
                    tok = itr.next();
                }
                var bytes: []const u8 = fbuf[loc.start..@min(loc.finish, tok.loc.start)];
                @memcpy(buf + len, bytes);
                len +%= bytes.len;
                loc.start +%= bytes.len;
                while (loc.start < loc.finish) {
                    if (loc.start < tok.loc.start) {
                        bytes = fbuf[loc.start..tok.loc.start];
                        @memcpy(buf + len, bytes);
                        len +%= bytes.len;
                    }
                    if (loc.finish > tok.loc.start) {
                        len +%= highlight(buf + len, &tok, syntax);
                    }
                    bytes = fbuf[tok.loc.start..tok.loc.finish];
                    loc.start = tok.loc.finish;
                    @memcpy(buf + len, bytes);
                    len +%= bytes.len;
                    len -%= @intFromBool(buf[len -% 1] == '\n');
                    @as(*[4]u8, @ptrCast(buf + len)).* = "\x1b[0m".*;
                    len +%= 4;
                    tok = itr.next();
                }
            } else {
                const bytes: []const u8 = loc.slice(fbuf);
                @memcpy(buf + len, bytes);
                len +%= bytes.len;
            }
            if (buf[len -% 1] != '\n') {
                buf[len] = '\n';
                len +%= 1;
            }
            if (line == src.line and trace.options.write_caret) {
                len +%= writeCaret(trace, buf + len, width, addr, src.column);
            }
        }
    }
    return len;
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
    @setRuntimeSafety(builtin.is_safe);
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len]) |*addr_info| {
        if (addr_info.addr == addr) {
            addr_info.count +%= 1;
            break;
        }
    } else {
        if (dwarf_info.findCompileUnit(addr)) |unit| {
            if (dwarf_info.getSourceLocation(allocator, unit, addr)) |src| {
                var len: u64 = pos;
                len +%= writeExtendedSourceLocation(dwarf_info, buf + len, addr, unit, src);
                len +%= writeSourceContext(trace, allocator, file_map, buf + len, width, addr, src);
                len +%= writeLastLine(trace, buf + len, width, trace.options.break_line_count);
                return .{ .addr = addr, .start = pos, .finish = pos +% len };
            }
        }
    }
    return null;
}
fn printMessage(buf: [*]u8, addr_info: *dwarf.DwarfInfo.AddressInfo) void {
    @setRuntimeSafety(builtin.is_safe);
    const msg = buf[addr_info.start..addr_info.finish];
    var tmp: [32768]u8 = undefined;
    var len: u64 = 0;
    if (addr_info.count != 0) {
        var idx: u64 = 0;
        while (msg[idx] != '\n') idx +%= 1;
        @memcpy(tmp[len..].ptr, msg[0..idx]);
        len +%= idx;
        @as(*[2]u8, @ptrCast(tmp[len..].ptr)).* = " (".*;
        len +%= 2;
        if (addr_info.count > 16) {
            @as(*[4]u8, @ptrCast(tmp[len..].ptr)).* = "\x1b[1m".*;
            len +%= 4;
        }
        len +%= fmt.ud64(addr_info.count).formatWriteBuf(tmp[len..].ptr);
        @as(*[12]u8, @ptrCast(tmp[len..].ptr)).* = "\x1b[0m times) ".*;
        len +%= 12;
        @memcpy(tmp[len..].ptr, msg[idx..]);
        len +%= msg[idx..].len;
        debug.write(tmp[0..len]);
    } else {
        debug.write(msg);
    }
}
fn fastAllocFile(allocator: *Allocator, file_map: *FileMap, pathname: [:0]const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    for (file_map.pairs[0..file_map.pairs_len]) |l_pair| {
        if (mach.testEqualMany8(l_pair.key, pathname)) {
            return l_pair.val;
        }
    }
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @intFromPtr(pathname.ptr), sys.O.RDONLY, 0 });
    mach.assert(fd < 1024, tab.open_error_s);
    var rc: u64 = sys.call_noexcept(.fstat, u64, .{ fd, @intFromPtr(&st) });
    mach.assert(rc == 0, tab.stat_error_s);
    const buf: []u8 = allocator.allocateAligned(u8, st.size +% 1, 8);
    rc = sys.call_noexcept(.read, u64, .{ fd, @intFromPtr(buf.ptr), st.size });
    buf[st.size] = 0;
    mach.assert(rc == st.size, tab.read_error_s);
    sys.call_noexcept(.close, void, .{fd});
    const ret: [:0]u8 = buf[0..st.size :0];
    file_map.appendOne(allocator, .{ .key = pathname, .val = ret });
    return ret;
}
fn maximumSideBarWidth(itr: StackIterator) u64 {
    @setRuntimeSafety(builtin.is_safe);
    var tmp: StackIterator = itr;
    var max_len: u64 = 0;
    while (tmp.next()) |addr| {
        max_len = @max(max_len, fmt.ux64(addr).formatLength());
    }
    return max_len +% 1;
}
pub export fn printStackTrace(trace: *const debug.Trace, first_addr: usize, frame_addr: usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var allocator: Allocator = .{ .start = Level.start, .next = Level.start, .finish = Level.start };
    defer allocator.unmap();
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));
    if (dwarf.logging_abbrev_entry or
        dwarf.logging_summary or
        dwarf.logging_info_entry)
    {
        dwarf.DwarfInfo.active = &dwarf_info;
    }
    dwarf_info.scanAllCompileUnits(&allocator);
    var buf: []u8 = allocator.allocate(u8, 1024 *% 4096);
    var len: u64 = 0;
    var itr: StackIterator = if (frame_addr != 0) .{
        .first_addr = null,
        .frame_addr = frame_addr,
    } else .{
        .first_addr = first_addr,
        .frame_addr = @frameAddress(),
    };
    const width: u64 = if (trace.options.write_sidebar) maximumSideBarWidth(itr) else 0;
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
        printMessage(buf.ptr, addr_info);
        if (idx == trace.options.max_depth) {
            break;
        }
    }
}
