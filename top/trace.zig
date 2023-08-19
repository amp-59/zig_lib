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
pub fn _start() void {}
pub const logging_override: debug.Logging.Override = .{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Release = false,
    .Success = false,
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
    if (!trace.options.show_line_no and
        !trace.options.show_pc_addr)
    {
        return 0;
    }
    const sidebar: []const u8 = trace.options.tokens.sidebar;
    const sidebar_char: bool = sidebar.len == 1;
    const fill: []const u8 = trace.options.tokens.sidebar_fill;
    var tmp: [8]u8 = undefined;
    var len: usize = 0;
    var pos: usize = 0;
    const fill_len: usize = @min(width, fill.len);
    switch (number) {
        .none => {
            for (0..fill_len) |idx| tmp[idx] = fill[idx];
            pos = fill_len;
        },
        .pc_addr => |pc_addr| if (trace.options.show_pc_addr) {
            if (trace.options.tokens.pc_addr) |style| {
                @memcpy(buf, style);
                len +%= style.len;
            }
            pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        } else {
            for (0..fill_len) |idx| tmp[idx] = fill[idx];
            pos = fill_len;
        },
        .line_no => |line_no| if (trace.options.show_line_no) {
            if (trace.options.tokens.line_no) |style| {
                @memcpy(buf, style);
                len +%= style.len;
            }
            pos +%= fmt.ud64(line_no).formatWriteBuf(&tmp);
        } else {
            for (0..fill_len) |idx| tmp[idx] = fill[idx];
            pos = fill_len;
        },
    }
    const spaces: u64 = (width -% 1) -| pos;
    mach.memset(buf + len, ' ', spaces);
    len +%= spaces;
    @memcpy(buf + len, &tmp);
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
    var ptr: [*]u8 = buf + src.formatWriteBuf(buf);
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
        ptr[0..2].* = ")\n".*;
        ptr += 2;
    } else {
        ptr[0] = '\n';
        ptr += 1;
    }
    return @intFromPtr(ptr - @intFromPtr(buf));
}
fn writeSourceContext(
    trace: *const debug.Trace,
    allocator: *mem.SimpleAllocator,
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
    allocator: *mem.SimpleAllocator,
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
fn printMessage(buf: [*]u8, addr_info: *dwarf.DwarfInfo.AddressInfo) void {
    @setRuntimeSafety(builtin.is_safe);
    const msg: []const u8 = buf[addr_info.start..addr_info.finish];
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

fn fastAllocFile(allocator: *mem.SimpleAllocator, file_map: *FileMap, pathname: [:0]const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    for (file_map.pairs[0..file_map.pairs_len]) |l_pair| {
        if (mach.testEqualMany8(l_pair.key, pathname)) {
            return l_pair.val;
        }
    }
    var st: file.Status = undefined;
    const fd: usize = sys.call_noexcept(.open, usize, .{ @intFromPtr(pathname.ptr), sys.O.RDONLY, 0 });
    mach.assert(fd < 1024, tab.open_error_s);
    var rc: usize = sys.call_noexcept(.fstat, usize, .{ fd, @intFromPtr(&st) });
    mach.assert(rc == 0, tab.stat_error_s);
    const ptr: [*]u8 = @ptrFromInt(allocator.allocateRaw(st.size +% 1, 8));
    rc = sys.call_noexcept(.read, usize, .{ fd, @intFromPtr(ptr), st.size });
    ptr[st.size] = 0;
    mach.assert(rc == st.size, tab.read_error_s);
    sys.call_noexcept(.close, void, .{fd});
    const ret: [:0]u8 = ptr[0..st.size :0];
    file_map.appendOne(allocator, .{ .key = pathname, .val = ret });
    return ret;
}
fn maximumSideBarWidth(addrs: anytype) usize {
    @setRuntimeSafety(builtin.is_safe);
    var max_len: usize = 0;
    if (@TypeOf(addrs) == StackIterator) {
        var tmp: StackIterator = addrs;
        while (tmp.next()) |addr| {
            max_len = @max(max_len, fmt.ux64(addr).formatLength());
        }
    } else {
        for (addrs) |addr| {
            max_len = @max(max_len, fmt.ux64(addr).formatLength());
        }
    }
    return max_len +% 1;
}
fn printSourceCodeAtAddress(trace: *const debug.Trace, addr: usize) callconv(.C) void {
    printSourceCodeAtAddresses(trace, 0, &[_]usize{addr}, 1);
}
fn printSourceCodeAtAddresses(trace: *const debug.Trace, ret_addr: usize, addrs: [*]const usize, addrs_len: usize) callconv(.C) void {
    @setRuntimeSafety(builtin.is_safe);
    var allocator: mem.SimpleAllocator = .{ .start = Level.start, .next = Level.start, .finish = Level.start };
    var buf: []u8 = allocator.allocate(u8, 4096);
    dwarf.SourceLocation.cwd = file.getCwd(.{ .errors = .{} }, buf);
    defer allocator.unmap();
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));
    dwarf_info.scanAllCompileUnits(&allocator);
    buf = allocator.allocate(u8, 1024 *% 4096);
    var len: usize = 0;
    var width: usize = fmt.ux64(ret_addr).formatLength();
    for (addrs[0..addrs_len]) |addr| {
        width = @max(width, fmt.ux64(addr).formatLength());
    }
    width *%= @intFromBool(trace.options.write_sidebar);
    for (addrs[0..addrs_len]) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf.ptr, len, width, addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    if (ret_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf.ptr, len, width, ret_addr)) |addr_info| {
            len = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    debug.write(buf[0..len]);
}
pub fn printStackTrace(trace: *const debug.Trace, first_addr: usize, frame_addr: usize) callconv(.C) void {
    @setRuntimeSafety(builtin.is_safe);
    var allocator: mem.SimpleAllocator = .{ .start = Level.start, .next = Level.start, .finish = Level.start };
    var buf: []u8 = allocator.allocate(u8, 4096);
    dwarf.SourceLocation.cwd = file.getCwd(.{ .errors = .{} }, buf);
    defer allocator.unmap();
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(exe_buf.ptr));

    dwarf_info.scanAllCompileUnits(&allocator);
    buf = allocator.allocate(u8, 1024 *% 4096);
    var len: usize = 0;
    var itr: StackIterator = if (frame_addr != 0) .{
        .first_addr = null,
        .frame_addr = frame_addr,
    } else .{
        .first_addr = first_addr,
        .frame_addr = @frameAddress(),
    };
    var width: usize = 0;
    if (trace.options.write_sidebar) {
        var tmp: StackIterator = itr;
        while (tmp.next()) |addr| {
            width = @max(width, fmt.ux64(addr).formatLength());
        }
    }
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
comptime {
    if (builtin.output_mode == .Obj and
        builtin.root.build_config == .trace)
    {
        @export(printStackTrace, .{ .name = "printStackTrace", .linkage = .Strong });
        @export(printSourceCodeAtAddress, .{ .name = "printSourceCodeAtAddress", .linkage = .Strong });
        @export(printSourceCodeAtAddresses, .{ .name = "printSourceCodeAtAddresses", .linkage = .Strong });
    }
}
