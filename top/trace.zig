const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const dwarf = @import("./dwarf.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub const logging_override: builtin.Logging.Override = builtin.Logging.Override{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Success = false,
    .Release = false,
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
const LineLocation = struct {
    start: u64 = 0,
    finish: u64 = 0,
    line: u64 = 0,
    fn len(loc: LineLocation) u64 {
        return loc.finish -% loc.start;
    }
    fn ptr(loc: LineLocation, buf: []u8) [*]u8 {
        return buf[loc.start..].ptr;
    }
    fn update(loc: *LineLocation, buf: []u8, line: u64) bool {
        while (loc.finish != buf.len) : (loc.finish +%= 1) {
            if (buf[loc.finish] == '\n') {
                loc.line +%= 1;
                if (loc.line == line) {
                    return true;
                }
                loc.start = loc.finish +% 1;
            }
        }
        return false;
    }
};
pub const StackIterator = struct {
    first_addr: ?u64,
    frame_addr: u64,
    const frame_addr_off: u64 = if (false //isRISCV
    ) 2 * @sizeOf(usize) else if (false // isSPARC
    ) 14 * @sizeOf(usize) else 0;
    const frame_addr_bias: u64 = if (false // isSPARC
    ) 2047 else 0;
    const instr_addr_off: u64 = if (false // native_arch == .powerpc64le
    ) 2 *% @sizeOf(usize) else @sizeOf(usize);
    pub fn init(first_addr: ?usize, frame_addr: ?usize) StackIterator {
        return .{
            .first_addr = first_addr,
            .frame_addr = frame_addr orelse @frameAddress(),
        };
    }
    pub fn next(itr: *StackIterator) ?usize {
        var next_addr: u64 = itr.next_internal() orelse {
            return null;
        };
        if (itr.first_addr) |first_addr| {
            while (next_addr != first_addr) {
                next_addr = itr.next_internal() orelse {
                    return null;
                };
            }
            itr.first_addr = null;
        }
        return next_addr;
    }
    fn next_internal(itr: *StackIterator) ?usize {
        const frame_addr: u64 = itr.frame_addr -% frame_addr_off;
        if (frame_addr > itr.frame_addr) {
            return null;
        }
        if (frame_addr == 0) {
            return null;
        }
        const new_frame_addr: u64 = @ptrFromInt(*usize, frame_addr).* +% frame_addr_bias;
        if (new_frame_addr < itr.frame_addr) {
            return null;
        }
        const new_instr_addr: u64 = @ptrFromInt(*usize, frame_addr +% instr_addr_off).*;
        itr.frame_addr = new_frame_addr;
        return new_instr_addr;
    }
};
fn writeEndOfMessage(buf: [*]u8) u64 {
    @ptrCast(*[4]u8, buf).* = "\x1b[0m".*;
    if ((buf - 1)[0] != '\n') {
        buf[4] = '\n';
        return 5;
    }
    return 4;
}
fn writeLastLine(traces: *const builtin.Traces, buf: [*]u8, break_lines_count: u8) u64 {
    var len: u64 = 0;
    var idx: u64 = 0;
    while (idx != break_lines_count) : (idx +%= 1) {
        if (traces.options.write_sidebar) {
            len +%= writeSideBar(traces, 8, buf + len, .none);
        }
        buf[len] = '\n';
        len +%= 1;
    }
    return len;
}
fn writeSideBar(traces: *const builtin.Traces, width: u64, buf: [*]u8, number: Number) u64 {
    const sidebar: []const u8 = traces.options.tokens.sidebar;
    const sidebar_char: bool = sidebar.len == 1;
    var tmp: [8]u8 = undefined;
    var len: u64 = 0;
    var pos: u64 = 0;
    switch (number) {
        .none => {
            @ptrCast(*[2]u8, &tmp).* = ": ".*;
            pos +%= 2;
        },
        .pc_addr => |pc_addr| if (traces.options.show_pc_addr) {
            if (traces.options.tokens.pc_addr) |style| {
                mach.memcpy(buf, style.ptr, style.len);
                len +%= style.len;
            }
            pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        },
        .line_no => |line_no| if (traces.options.show_line_no) {
            if (traces.options.tokens.line_no) |style| {
                mach.memcpy(buf, style.ptr, style.len);
                len +%= style.len;
            }
            pos +%= fmt.ud64(line_no).formatWriteBuf(&tmp);
        },
    }
    const spaces: u64 = (width -% 1) -| pos;
    mach.memset(buf + len, ' ', spaces);
    len +%= spaces;
    mach.memcpy(buf + len, &tmp, pos);
    len +%= pos;
    @ptrCast(*[4]u8, buf + len).* = "\x1b[0m".*;
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
fn writeCaret(traces: *const builtin.Traces, buf: [*]u8, addr: u64, column: u64) u64 {
    const caret: []const u8 = traces.options.tokens.caret;
    const caret_fill: []const u8 = traces.options.tokens.caret_fill;
    const caret_fill_char: bool = caret.len == 1;
    var len: u64 = 0;
    if (traces.options.write_sidebar) {
        len +%= writeSideBar(traces, 8, buf, if (traces.options.show_pc_addr) .{ .pc_addr = addr } else .none);
    }
    const fill_len: u64 = column -| 1;
    if (caret_fill_char) {
        mach.memset(buf + len, caret_fill[0], fill_len);
        len +%= fill_len;
    } else {
        for (0..fill_len) |_| {
            @memcpy(buf + len, caret_fill);
            len +%= caret_fill.len;
        }
    }
    @memcpy(buf + len, caret);
    len +%= caret.len;
    buf[len] = '\n';
    return len +% 1;
}
fn writeSourceLine(
    traces: *const builtin.Traces,
    buf: [*]u8,
    fbuf: []u8,
    loc: *const LineLocation,
    itr: *builtin.zig.TokenIterator,
    tok: *builtin.zig.Token,
) u64 {
    var loc_itr: LineLocation = loc.*;
    var len: u64 = 0;
    if (traces.options.write_sidebar) {
        len +%= writeSideBar(traces, 8, buf, .{ .line_no = loc_itr.line });
    }
    if (traces.options.tokens.syntax) |syntax| {
        while (itr.buf_pos < loc_itr.start) {
            tok.* = itr.next();
        }
        const finish: u64 = loc_itr.finish;
        while (itr.buf_pos <= finish) {
            loc_itr.finish = tok.loc.finish;
            for (syntax) |pair| {
                for (pair.tags) |tag| {
                    if (tok.tag == tag) {
                        mach.memcpy(buf + len, pair.style.ptr, pair.style.len);
                        len +%= pair.style.len;
                        break;
                    }
                }
            }
            mach.memcpy(buf + len, loc_itr.ptr(fbuf), loc_itr.len());
            len +%= loc_itr.len();
            loc_itr.start = loc_itr.finish;
            tok.* = itr.next();
            @ptrCast(*[4]u8, buf + len).* = "\x1b[0m".*;
            len +%= 4;
        }
    } else {
        mach.memcpy(buf + len, loc_itr.ptr(fbuf), loc_itr.len());
        len +%= loc_itr.len();
    }
    if (buf[len -% 1] != '\n') {
        buf[len] = '\n';
        len +%= 1;
    }
    return len;
}
fn writeExtendedSourceLocation(dwarf_info: *dwarf.DwarfInfo, buf: [*]u8, addr: u64, unit: *const dwarf.Unit, src: dwarf.SourceLocation) u64 {
    var len: u64 = src.formatWriteBuf(buf);
    @ptrCast(*[2]u8, buf + len).* = ": ".*;
    len +%= 2;
    len +%= fmt.ux64(addr).formatWriteBuf(buf + len);
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        @ptrCast(*[4]u8, buf + len).* = " in ".*;
        len +%= 4;
        mach.memcpy(buf + len, fn_name.ptr, fn_name.len);
        len +%= fn_name.len;
    }
    if (unit.info_entry.get(.name)) |form_val| {
        @ptrCast(*[2]u8, buf + len).* = " (".*;
        len +%= 2;
        const name: []const u8 = form_val.getString(dwarf_info);
        mach.memcpy(buf + len, name.ptr, name.len);
        len +%= name.len;
        @ptrCast(*[2]u8, buf + len).* = ")\n".*;
        len +%= 2;
    } else {
        buf[len] = '\n';
        len +%= 1;
    }
    return len;
}
fn writeSourceContext(traces: *const builtin.Traces, allocator: *mem.SimpleAllocator, buf: [*]u8, addr: u64, src: dwarf.SourceLocation) u64 {
    const save: u64 = allocator.next;
    defer allocator.next = save;
    const fbuf: [:0]u8 = fastAllocFile(allocator, src.file);
    var len: u64 = 0;
    var itr: builtin.zig.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.zig.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    const min: u64 = src.line -| traces.options.context_lines_count;
    const max: u64 = src.line +% traces.options.context_lines_count +% 1;
    var line: u64 = min;
    while (line != max) : (line +%= 1) {
        var loc: LineLocation = .{};
        if (loc.update(fbuf, line)) {
            len +%= writeSourceLine(traces, buf + len, fbuf, &loc, &itr, &tok);
            if (line == src.line and traces.options.write_caret) {
                len +%= writeCaret(traces, buf + len, addr, src.column);
            }
        }
    }
    return len;
}
fn writeSourceCodeAtAddress(
    traces: *const builtin.Traces,
    allocator: *mem.SimpleAllocator,
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    pos: u64,
    addr: u64,
) ?dwarf.DwarfInfo.AddressInfo {
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len]) |*addr_info| {
        if (addr_info.addr == addr) {
            addr_info.count +%= 1;
        }
    } else {
        if (dwarf_info.findCompileUnit(addr)) |unit| {
            if (dwarf_info.getSourceLocation(allocator, unit, addr)) |src| {
                var len: u64 = pos;
                len +%= writeExtendedSourceLocation(dwarf_info, buf + len, addr, unit, src);
                len +%= writeSourceContext(traces, allocator, buf + len, addr, src);
                len +%= writeLastLine(traces, buf + len, traces.options.break_lines_count);
                return .{
                    .addr = addr,
                    .start = pos,
                    .finish = pos +% len +% writeEndOfMessage(buf + len),
                };
            }
        }
    }
    return null;
}
fn fastAllocFile(allocator: *mem.SimpleAllocator, pathname: [:0]const u8) [:0]u8 {
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @intFromPtr(pathname.ptr), sys.O.RDONLY, 0 });
    mach.assert(
        fd < 1024,
        tab.open_error_s,
    );
    var rc: u64 = sys.call_noexcept(.fstat, u64, .{ fd, @intFromPtr(&st) });
    mach.assert(
        rc == 0,
        tab.stat_error_s,
    );
    const buf: []u8 = allocator.allocateAligned(u8, st.size +% 1, 8);
    rc = sys.call_noexcept(.read, u64, .{ fd, @intFromPtr(buf.ptr), st.size });
    buf[st.size] = 0;
    mach.assert(
        rc == st.size,
        tab.read_error_s,
    );
    sys.call_noexcept(.close, void, .{fd});
    return buf[0..st.size :0];
}
pub export fn printStackTrace(traces: *const builtin.Traces, first_addr: usize, frame_addr: usize) void {
    const Level = struct {
        var start: u64 = 0x600000000000;
    };
    Level.start -%= 0x200000000000;
    var allocator: mem.SimpleAllocator = .{ .start = Level.start, .next = Level.start, .finish = Level.start };
    const exe_buf: []u8 = fastAllocFile(&allocator, tab.self_link_s);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));
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
    if (frame_addr != 0) {
        if (writeSourceCodeAtAddress(traces, &allocator, &dwarf_info, buf.ptr, len, first_addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    while (itr.next()) |addr| {
        if (writeSourceCodeAtAddress(traces, &allocator, &dwarf_info, buf[len..].ptr, len, addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len], 1..) |addr_info, idx| {
        builtin.debug.write(buf[addr_info.start..addr_info.finish]);
        if (idx == traces.options.max_depth) {
            break;
        }
    }
    allocator.unmap();
}
