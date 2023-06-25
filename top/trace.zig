const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const dwarf = @import("./dwarf.zig");
const builtin = @import("./builtin.zig");

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
    fn init(buf: []u8, line: u64) LineLocation {
        var ret: LineLocation = .{};
        while (ret.finish != buf.len) : (ret.finish +%= 1) {
            if (buf[ret.finish] == '\n') {
                ret.line +%= 1;
                if (ret.line == line) {
                    return ret;
                }
                ret.start = ret.finish +% 1;
            }
        }
        unreachable;
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
fn writeLastLine(buf: [*]u8, blank_lines: u8) u64 {
    var len: u64 = 0;
    if (builtin.traces.sidebar) {
        len +%= writeSideBar(8, buf, .none);
    }
    mach.memset(buf + len, '\n', blank_lines);
    return len + blank_lines;
}
fn writeSideBar(width: u64, buf: [*]u8, number: Number) u64 {
    var tmp: [8]u8 = undefined;
    var len: u64 = 0;
    var pos: u64 = 0;
    switch (number) {
        .none => {
            @ptrCast(*[2]u8, &tmp).* = ": ".*;
            pos +%= 2;
        },
        .pc_addr => |pc_addr| if (builtin.traces.pc_addr) {
            if (builtin.traces.tokens.pc_addr) |style| {
                mach.memcpy(buf, style.ptr, style.len);
                len +%= style.len;
            }
            pos +%= fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        },
        .line_no => |line_no| if (builtin.traces.line_no) {
            if (builtin.traces.tokens.line_no) |style| {
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
    if (builtin.traces.tokens.sidebar) |sidebar| {
        @memcpy(buf + len, sidebar);
        len +%= sidebar.len;
    }
    return len;
}
fn fastAllocFile(allocator: *mem.SimpleAllocator, pathname: [:0]const u8) []u8 {
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @ptrToInt(pathname.ptr), sys.O.RDONLY, 0 });
    mach.assert(fd < 1024, "could not open executable");
    var rc: u64 = sys.call_noexcept(.fstat, u64, .{ fd, @ptrToInt(&st) });
    mach.assert(rc == 0, "could not stat executable");
    const buf: []u8 = allocator.allocateAligned(u8, st.size, 8);
    rc = sys.call_noexcept(.read, u64, .{ fd, @ptrToInt(buf.ptr), st.size });
    mach.assert(rc == st.size, "could not read executable");
    sys.call_noexcept(.close, void, .{fd});
    return buf;
}
fn self(allocator: *mem.SimpleAllocator) dwarf.DwarfInfo {
    const buf: []u8 = fastAllocFile(allocator, "/proc/self/exe");
    var ret: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@ptrToInt(buf.ptr));
    ret.scanAllCompileUnits(allocator);
    return ret;
}
fn writeSourceCodeAtAddress(allocator: *mem.SimpleAllocator, dwarf_info: *dwarf.DwarfInfo, buf: [*]u8, addr: u64) u64 {
    const instr_addr_s: []const u8 = builtin.fmt.ux64(addr).readAll();
    const unit = dwarf_info.findCompileUnit(addr) orelse {
        return 0;
    };
    const line_info = dwarf_info.getLineNumberInfo(allocator, unit, addr) orelse {
        return 0;
    };
    const fbuf: []u8 = fastAllocFile(allocator, line_info.file);
    var len = writeSourceLocation(buf, line_info.file, line_info.line, line_info.column);
    @ptrCast(*[2]u8, buf + len).* = ": ".*;
    len +%= 2;
    mach.memcpy(buf + len, instr_addr_s.ptr, instr_addr_s.len);
    len +%= instr_addr_s.len;
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        @ptrCast(*[4]u8, buf + len).* = " in ".*;
        len +%= 4;
        mach.memcpy(buf + len, fn_name.ptr, fn_name.len);
        len +%= fn_name.len;
    }
    if (unit.info_entry.get(.name)) |form_val| {
        @ptrCast(*[2]u8, buf + len).* = " (".*;
        len +%= 2;
        const unit_name: []const u8 = form_val.getString(dwarf_info);
        mach.memcpy(buf + len, unit_name.ptr, unit_name.len);
        len +%= unit_name.len;
        @ptrCast(*[2]u8, buf + len).* = ")\n".*;
        len +%= 2;
    }
    const bytes: []const u8 = readLineBytes(fbuf, line_info.line);
    if (false) {
        const b_bytes: []const u8 = readLineBytes(fbuf, line_info.line -% 1);
        const a_bytes: []const u8 = readLineBytes(fbuf, line_info.line +% 1);
        mach.memcpy(buf + len, b_bytes.ptr, b_bytes.len);
        len +%= b_bytes.len;
        buf[len] = '\n';
        len +%= 1;
        const before_caret: u64 = line_info.column -% 1;
        mach.memcpy(buf + len, bytes.ptr, before_caret);
        len +%= before_caret;
        @ptrCast(*[4]u8, buf + len).* = "\x1b[7m".*;
        len +%= 4;
        buf[len] = bytes[before_caret];
        len +%= 1;
        @ptrCast(*[4]u8, buf + len).* = "\x1b[0m".*;
        len +%= 4;
        mach.memcpy(buf + len, bytes.ptr + line_info.column, bytes.len -% line_info.column);
        len +%= bytes.len -% line_info.column;
        buf[len] = '\n';
        len +%= 1;
        mach.memcpy(buf + len, a_bytes.ptr, a_bytes.len);
        len +%= a_bytes.len;
    } else {
        mach.memcpy(buf + len, bytes.ptr, bytes.len);
        len +%= bytes.len;
        buf[len] = '\n';
        len +%= 1;
        mach.memset(buf + len, ' ', line_info.column -| 1);
        len +%= line_info.column;
        @ptrCast(*@TypeOf(about.hi_green_s.*), buf + len).* = about.hi_green_s.*;
        len +%= about.hi_green_s.len;
        buf[len] = '^';
        len +%= 1;
    }
    @ptrCast(*[5]u8, buf + len).* = about.new_s.*;
    return len +% 5;
}
pub export fn printStackTrace(first_addr: usize, frame_addr: usize) void {
    var allocator: mem.SimpleAllocator = .{
        .start = 0x600000000000,
        .next = 0x600000000000,
        .finish = 0x600000000000,
    };
    var dwarf_info: dwarf.DwarfInfo = self(&allocator);
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
        len +%= writeSourceCodeAtAddress(&allocator, &dwarf_info, buf.ptr, first_addr);
    }
    while (itr.next()) |addr| {
        len +%= writeSourceCodeAtAddress(&allocator, &dwarf_info, buf[len..].ptr, addr);
    }
    builtin.debug.write(buf[0..len]);
    allocator.unmap();
}
