const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
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
        const new_frame_addr: u64 = @intToPtr(*const usize, frame_addr).* +% frame_addr_bias;
        if (new_frame_addr < itr.frame_addr) {
            return null;
        }
        const new_instr_addr: u64 = @intToPtr(*const usize, frame_addr +% instr_addr_off).*;
        itr.frame_addr = new_frame_addr;
        return new_instr_addr;
    }
};

const about = .{
    .next_s = ", ",
    .bytes_s = " bytes, ",
    .green_s = "\x1b[92;1m",
    .red_s = "\x1b[91;1m",
    .new_s = "\x1b[0m\n",
    .reset_s = "\x1b[0m",
    .gold_s = "\x1b[93m",
    .bold_s = "\x1b[1m",
    .faint_s = "\x1b[2m",
    .grey_s = "\x1b[0;38;5;250;1m",
    .trace_s = "\x1b[38;5;247m",
    .hi_green_s = "\x1b[38;5;46m",
    .hi_red_s = "\x1b[38;5;196m",
};
fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: u64, column: u64) u64 {
    const line_s: []const u8 = builtin.fmt.ud64(line).readAll();
    const column_s: []const u8 = builtin.fmt.ud64(column).readAll();
    var len: u64 = 0;
    @ptrCast(*@TypeOf(about.bold_s.*), buf + len).* = about.bold_s.*;
    len +%= about.bold_s.len;
    if (true) {
        var cwd_buf: [4096]u8 = undefined;
        const cwd: [:0]const u8 = file.getCwd(.{ .errors = .{} }, &cwd_buf);
        if (mach.testEqualMany8(cwd, pathname[0..cwd.len])) {
            const pos: u64 = cwd.len +% 1;
            mach.memcpy(buf + len, pathname[pos..].ptr, pathname[pos..].len);
            len +%= pathname[pos..].len;
        } else {
            mach.memcpy(buf + len, pathname.ptr, pathname.len);
            len +%= pathname.len;
        }
    } else {
        mach.memcpy(buf + len, pathname.ptr, pathname.len);
        len +%= pathname.len;
    }
    buf[len] = ':';
    len +%= 1;
    mach.memcpy(buf + len, line_s.ptr, line_s.len);
    len +%= line_s.len;
    buf[len] = ':';
    len +%= 1;
    mach.memcpy(buf + len, column_s.ptr, column_s.len);
    len +%= column_s.len;
    @ptrCast(*[4]u8, buf + len).* = about.reset_s.*;
    return len +% 4;
}
fn readLineBytes(buf: []u8, line: u64) []const u8 {
    var lns: u64 = 0;
    var pos: u64 = 0;
    var idx: u64 = 0;
    while (idx != buf.len) : (idx +%= 1) {
        if (buf[idx] == '\n') {
            lns +%= 1;
            if (lns == line) {
                break;
            }
            pos = idx +% 1;
        }
    }
    return buf[pos..idx];
}
fn fastAllocFile(allocator: *mem.SimpleAllocator, pathname: [:0]const u8) []u8 {
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @ptrToInt(pathname.ptr), sys.O.RDONLY, 0 });
    mach.assert(fd < 1024, "could not open executable");
    var rc: u64 = sys.call_noexcept(.fstat, u64, .{ fd, @ptrToInt(&st) });
    mach.assert(rc == 0, "could not stat executable");
    const dest: u64 = allocator.allocateRaw(st.size, 1);
    rc = sys.call_noexcept(.read, u64, .{ fd, dest, st.size });
    mach.assert(rc == st.size, "could not read executable");
    sys.call_noexcept(.close, void, .{fd});
    return @intToPtr([*]u8, dest)[0..st.size];
}
fn self(allocator: *mem.SimpleAllocator) dwarf.DwarfInfo {
    const buf: []u8 = fastAllocFile(allocator, "/proc/self/exe");
    return dwarf.DwarfInfo.init(@ptrToInt(buf.ptr));
}
pub export fn printStackTrace(ret_addr: u64) void {
    var itr: StackIterator = StackIterator.init(if (ret_addr == 0) @returnAddress() else ret_addr, null);
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    var dwarf_info: dwarf.DwarfInfo = self(&allocator);
    dwarf_info.scanAllCompileUnits(&allocator);
    var buf: []u8 = allocator.allocate(u8, 4024 *% 1024);
    var len: u64 = 0;
    while (itr.next()) |instr_addr| {
        const instr_addr_s: []const u8 = builtin.fmt.ux64(instr_addr).readAll();
        const unit = dwarf_info.findCompileUnit(instr_addr) orelse {
            break;
        };
        const line_info = dwarf_info.getLineNumberInfo(&allocator, unit, instr_addr) orelse {
            break;
        };
        len +%= writeSourceLocation(buf[len..].ptr, line_info.file, line_info.line, line_info.column);
        @ptrCast(*[2]u8, buf[len..].ptr).* = ": ".*;
        len +%= 2;
        mach.memcpy(buf[len..].ptr, instr_addr_s.ptr, instr_addr_s.len);
        len +%= instr_addr_s.len;
        if (dwarf_info.getSymbolName(instr_addr)) |fn_name| {
            @ptrCast(*[4]u8, buf[len..].ptr).* = " in ".*;
            len +%= 4;
            mach.memcpy(buf[len..].ptr, fn_name.ptr, fn_name.len);
            len +%= fn_name.len;
        }
        if (unit.info_entry.getAttr(.name)) |form_val| {
            @ptrCast(*[2]u8, buf[len..].ptr).* = " (".*;
            len +%= 2;
            const unit_name: []const u8 = try form_val.getString(dwarf_info);
            mach.memcpy(buf[len..].ptr, unit_name.ptr, unit_name.len);
            len +%= unit_name.len;
            @ptrCast(*[2]u8, buf[len..].ptr).* = ")\n".*;
            len +%= 2;
        }
        const fbuf: []u8 = fastAllocFile(&allocator, line_info.file);
        const bytes: []const u8 = readLineBytes(fbuf, line_info.line);
        if (false) {
            const b_bytes: []const u8 = readLineBytes(fbuf, line_info.line -% 1);
            const a_bytes: []const u8 = readLineBytes(fbuf, line_info.line +% 1);
            mach.memcpy(buf[len..].ptr, b_bytes.ptr, b_bytes.len);
            len +%= b_bytes.len;
            buf[len] = '\n';
            len +%= 1;
            const before_caret: u64 = line_info.column -% 1;
            mach.memcpy(buf[len..].ptr, bytes.ptr, before_caret);
            len +%= before_caret;
            @ptrCast(*[4]u8, buf[len..].ptr).* = "\x1b[7m".*;
            len +%= 4;
            buf[len] = bytes[before_caret];
            len +%= 1;
            @ptrCast(*[4]u8, buf[len..].ptr).* = "\x1b[0m".*;
            len +%= 4;
            mach.memcpy(buf[len..].ptr, bytes.ptr + line_info.column, bytes.len -% line_info.column);
            len +%= bytes.len -% line_info.column;
            buf[len] = '\n';
            len +%= 1;
            mach.memcpy(buf[len..].ptr, a_bytes.ptr, a_bytes.len);
            len +%= a_bytes.len;
        } else {
            mach.memcpy(buf[len..].ptr, bytes.ptr, bytes.len);
            len +%= bytes.len;
            buf[len] = '\n';
            len +%= 1;
            mach.memset(buf[len..].ptr, ' ', line_info.column -% 1);
            len +%= line_info.column;
            @ptrCast(*@TypeOf(about.hi_green_s.*), buf[len..].ptr).* = about.hi_green_s.*;
            len +%= about.hi_green_s.len;
            buf[len] = '^';
            len +%= 1;
        }
        @ptrCast(*[5]u8, buf[len..].ptr).* = about.new_s.*;
        len +%= 5;
    }
    builtin.debug.write(buf[0..len]);
}
