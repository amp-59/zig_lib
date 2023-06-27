const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const mach = @import("./mach.zig");
const algo = @import("./algo.zig");
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
const ctn = struct {
    const Array = mem.StaticString(4096 *% 1024);
    fn highlight(array: *Array, tok: *builtin.zig.Token, syntax: anytype) void {
        for (syntax) |pair| {
            for (pair.tags) |tag| {
                if (tok.tag == tag) {
                    return array.writeMany(pair.style);
                }
            }
        }
    }
    fn writeLastLine(trace: *const builtin.Trace, array: *Array, width: u64, break_lines_count: u8) void {
        var idx: u64 = 0;
        while (idx != break_lines_count) : (idx +%= 1) {
            if (trace.options.write_sidebar) {
                ctn.writeSideBar(trace, width, array, .none);
            }
            array.writeOne('\n');
        }
        if (array.readOneBack() != '\n') {
            array.writeOne('\n');
        }
        array.writeMany("\x1b[0m");
    }
    fn writeSideBar(trace: *const builtin.Trace, width: u64, array: *Array, number: Number) void {
        var tmp: [8]u8 = undefined;
        var pos: u64 = 0;
        const sidebar_fill: []const u8 = trace.options.tokens.sidebar_fill;
        const fill_len: u64 = @min(8, sidebar_fill.len);
        switch (number) {
            .none => {
                mach.memcpy(&tmp, sidebar_fill.ptr, fill_len);
                pos = sidebar_fill.len;
            },
            .pc_addr => |pc_addr| if (trace.options.show_pc_addr) {
                if (trace.options.tokens.pc_addr) |style| {
                    array.writeMany(style);
                }
                pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
            } else {
                mach.memcpy(&tmp, sidebar_fill.ptr, fill_len);
                pos = sidebar_fill.len;
            },
            .line_no => |line_no| if (trace.options.show_line_no) {
                if (trace.options.tokens.line_no) |style| {
                    array.writeMany(style);
                }
                pos +%= fmt.ud64(line_no).formatWriteBuf(&tmp);
            } else {
                mach.memcpy(&tmp, sidebar_fill.ptr, fill_len);
                pos = sidebar_fill.len;
            },
        }
        const spaces: u64 = (width -% 1) -| pos;
        for (0..spaces) |_| array.writeOne(' ');
        array.writeMany(tmp[0..pos]);
        array.writeMany("\x1b[0m");
        array.writeMany(trace.options.tokens.sidebar);
    }
    fn writeSourceLine(
        trace: *const builtin.Trace,
        array: *Array,
        fbuf: []u8,
        loc: *dwarf.LineLocation,
        itr: *builtin.zig.TokenIterator,
        tok: *builtin.zig.Token,
    ) void {
        if (trace.options.write_sidebar and
            trace.options.show_line_no or trace.options.show_pc_addr)
        {
            ctn.writeSideBar(trace, 8, array, .{ .line_no = loc.line });
        }
        if (trace.options.tokens.syntax) |syntax| {
            while (itr.buf_pos < loc.start) {
                tok.* = itr.next();
            }
            const finish: u64 = loc.finish;
            while (itr.buf_pos <= finish) {
                loc.finish = tok.loc.finish;
                lo: for (syntax) |pair| {
                    for (pair.tags) |tag| {
                        if (tok.tag == tag) {
                            break :lo array.writeMany(pair.style);
                        }
                    }
                }
                array.writeMany(loc.slice(fbuf));
                loc.start = loc.finish;
                tok.* = itr.next();
                array.writeMany("\x1b[0m");
            }
        } else {
            array.writeMany(loc.slice(fbuf));
        }
        if (array.readOneBack() != '\n') {
            array.writeOne('\n');
        }
    }
    fn writeExtendedSourceLocation(dwarf_info: *dwarf.DwarfInfo, array: *Array, addr: u64, unit: *const dwarf.Unit, src: dwarf.SourceLocation) void {
        array.writeFormat(src);
        array.writeMany(": ");
        array.writeFormat(fmt.ux64(addr));
        if (dwarf_info.getSymbolName(addr)) |fn_name| {
            array.writeMany(" in ");
            array.writeMany(fn_name);
        }
        if (unit.info_entry.get(.name)) |form_val| {
            array.writeMany(" (");
            array.writeMany(form_val.getString(dwarf_info));
            array.writeMany(")\n");
        } else {
            array.writeOne('\n');
        }
    }
    fn writeSourceContext(trace: *const builtin.Trace, allocator: *mem.SimpleAllocator, array: *Array, addr: u64, src: dwarf.SourceLocation) void {
        const save: u64 = allocator.next;
        defer allocator.next = save;
        const fbuf: [:0]u8 = fastAllocFile(allocator, src.file);
        var itr: builtin.zig.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
        var tok: builtin.zig.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
        const min: u64 = src.line -| trace.options.context_lines_count;
        const max: u64 = src.line +% trace.options.context_lines_count +% 1;
        var line: u64 = min;
        while (line != max) : (line +%= 1) {
            var loc: dwarf.LineLocation = .{};
            if (loc.update(fbuf, line)) {
                ctn.writeSourceLine(trace, array, fbuf, &loc, &itr, &tok);
                if (line == src.line and trace.options.write_caret) {
                    const caret_fill: []const u8 = trace.options.tokens.caret_fill;
                    if (trace.options.write_sidebar and
                        trace.options.show_line_no or trace.options.show_pc_addr)
                    {
                        ctn.writeSideBar(trace, 8, array, .{ .pc_addr = addr });
                    }
                    const fill_len: u64 = src.column -| 1;
                    if (trace.options.tokens.caret.len == 1) {
                        for (0..fill_len) |_|
                            array.writeOne(caret_fill[0]);
                    } else {
                        for (0..fill_len) |_| {
                            array.writeMany(caret_fill);
                        }
                    }
                    array.writeMany(trace.options.tokens.caret);
                    if (array.readOneBack() != '\n') {
                        array.writeOne('\n');
                    }
                }
            }
        }
    }
    fn writeSourceCodeAtAddress(
        trace: *const builtin.Trace,
        allocator: *mem.SimpleAllocator,
        dwarf_info: *dwarf.DwarfInfo,
        array: *Array,
        addr: u64,
    ) ?dwarf.DwarfInfo.AddressInfo {
        for (dwarf_info.addr_info[0..dwarf_info.addr_info_len]) |*addr_info| {
            if (addr_info.addr == addr) {
                addr_info.count +%= 1;
            }
        } else {
            if (dwarf_info.findCompileUnit(addr)) |unit| {
                if (dwarf_info.getSourceLocation(allocator, unit, addr)) |src| {
                    const start: u64 = array.len();
                    ctn.writeExtendedSourceLocation(dwarf_info, array, addr, unit, src);
                    ctn.writeSourceContext(trace, allocator, array, addr, src);
                    ctn.writeLastLine(trace, array, trace.options.break_lines_count);
                    return .{
                        .addr = addr,
                        .start = start,
                        .finish = array.len(),
                    };
                }
            }
        }
        return null;
    }
};
fn writeLastLine(trace: *const builtin.Trace, buf: [*]u8, width: u64, break_lines_count: u8) u64 {
    var len: u64 = 0;
    var idx: u64 = 0;
    while (idx != break_lines_count) : (idx +%= 1) {
        if (trace.options.write_sidebar) {
            len +%= writeSideBar(trace, width, buf + len, .none);
        }
        buf[len] = '\n';
        len +%= 1;
    }
    @ptrCast(*[4]u8, buf + len).* = "\x1b[0m".*;
    if (buf[len -% 1] != '\n') {
        buf[len +% 4] = '\n';
        return len +% 5;
    }
    return len +% 4;
}
fn writeSideBar(trace: *const builtin.Trace, width: u64, buf: [*]u8, number: Number) u64 {
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
fn writeFiller(buf: [*]u8, filler: []const u8, fill_len: u64) u64 {
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
fn writeCaret(trace: *const builtin.Trace, buf: [*]u8, width: u64, addr: u64, column: u64) u64 {
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
fn highlight(buf: [*]u8, tok: *builtin.zig.Token, syntax: anytype) u64 {
    for (syntax) |pair| {
        for (pair.tags) |tag| {
            if (tok.tag == tag) {
                mach.memcpy(buf, pair.style.ptr, pair.style.len);
                return pair.style.len;
            }
        }
    }
    return 0;
}
fn writeSourceLine(
    trace: *const builtin.Trace,
    buf: [*]u8,
    width: u64,
    fbuf: []u8,
    loc: *const dwarf.LineLocation,
    itr: *builtin.zig.TokenIterator,
    tok: *builtin.zig.Token,
) u64 {
    var loc_itr: dwarf.LineLocation = loc.*;
    var len: u64 = 0;
    if (trace.options.write_sidebar) {
        len +%= writeSideBar(trace, width, buf, .{ .line_no = loc_itr.line });
    }
    if (trace.options.tokens.syntax) |syntax| {
        while (itr.buf_pos < loc_itr.start) {
            tok.* = itr.next();
        }
        const finish: u64 = loc_itr.finish;
        while (itr.buf_pos <= finish) {
            loc_itr.finish = tok.loc.finish;
            len +%= highlight(buf + len, tok, syntax);
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
fn writeSourceContext(trace: *const builtin.Trace, allocator: *mem.SimpleAllocator, buf: [*]u8, width: u64, addr: u64, src: dwarf.SourceLocation) u64 {
    const min: u64 = src.line -| trace.options.context_lines_count;
    const max: u64 = src.line +% trace.options.context_lines_count +% 1;
    var line: u64 = min;
    const save: u64 = allocator.next;
    defer allocator.next = save;
    const fbuf: [:0]u8 = fastAllocFile(allocator, src.file);
    var itr: builtin.zig.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.zig.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    var len: u64 = 0;
    while (line != max) : (line +%= 1) {
        var loc: dwarf.LineLocation = .{};
        if (loc.update(fbuf, line)) {
            len +%= writeSourceLine(trace, buf + len, width, fbuf, &loc, &itr, &tok);
            if (line == src.line and trace.options.write_caret) {
                len +%= writeCaret(trace, buf + len, width, addr, src.column);
            }
        }
    }
    return len;
}
fn writeSourceCodeAtAddress(
    trace: *const builtin.Trace,
    allocator: *mem.SimpleAllocator,
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    pos: u64,
    width: u64,
    depth: u64,
    addr: u64,
) ?dwarf.DwarfInfo.AddressInfo {
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len]) |*addr_info| {
        if (addr_info.addr == addr) {
            addr_info.count +%= 1;
            addr_info.depth = depth;
            break;
        }
    } else {
        if (dwarf_info.findCompileUnit(addr)) |unit| {
            if (dwarf_info.getSourceLocation(allocator, unit, addr)) |src| {
                var len: u64 = pos;
                len +%= writeExtendedSourceLocation(dwarf_info, buf + len, addr, unit, src);
                len +%= writeSourceContext(trace, allocator, buf + len, width, addr, src);
                len +%= writeLastLine(trace, buf + len, width, trace.options.break_lines_count);
                return .{ .addr = addr, .start = pos, .finish = pos +% len, .depth = depth };
            }
        }
    }
    return null;
}
fn printMessage(buf: [*]u8, addr_info: *dwarf.DwarfInfo.AddressInfo) void {
    const msg = buf[addr_info.start..addr_info.finish];
    var tmp: [32768]u8 = undefined;
    var len: u64 = 0;
    if (addr_info.count != 0) {
        var idx: u64 = 0;
        while (msg[idx] != '\n') idx +%= 1;
        @memcpy(tmp[len..].ptr, msg[0..idx]);
        len +%= idx;
        @ptrCast(*[2]u8, tmp[len..].ptr).* = " (".*;
        len +%= 2;
        if (addr_info.count > 16) {
            @ptrCast(*[4]u8, tmp[len..].ptr).* = "\x1b[1m".*;
            len +%= 4;
        }
        len +%= fmt.ud64(addr_info.count).formatWriteBuf(tmp[len..].ptr);
        @ptrCast(*[12]u8, tmp[len..].ptr).* = "\x1b[0m times) ".*;
        len +%= 12;
        @memcpy(tmp[len..].ptr, msg[idx..]);
        len +%= msg[idx..].len;
        builtin.debug.write(tmp[0..len]);
    } else {
        builtin.debug.write(msg);
    }
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
fn maximumSideBarWidth(itr: StackIterator) u64 {
    var tmp: StackIterator = itr;
    var max_len: u64 = 0;
    while (tmp.next()) |addr| {
        max_len = @max(max_len, fmt.ux64(addr).formatLength());
    }
    return max_len +% 1;
}
pub export fn printStackTrace(trace: *const builtin.Trace, first_addr: usize, frame_addr: usize) void {
    const Level = struct {
        var start: u64 = 0x600000000000;
    };
    Level.start -%= 0x20000000000;
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
    const width: u64 = if (trace.options.write_sidebar) maximumSideBarWidth(itr) else 0;
    var depth: u64 = 0;
    if (frame_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &dwarf_info, buf.ptr, len, width, depth, first_addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    while (itr.next()) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &dwarf_info, buf[len..].ptr, len, width, depth, addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
            depth +%= 1;
        }
    }
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len], 1..) |*addr_info, idx| {
        printMessage(buf.ptr, addr_info);
        if (idx == trace.options.max_depth) {
            break;
        }
    }
    allocator.unmap();
}
