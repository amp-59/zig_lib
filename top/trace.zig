const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const zig = @import("./zig.zig");
const proc = @import("./proc.zig");
const math = @import("./math.zig");
const file = @import("./file.zig");
const debug = @import("./debug.zig");
const build = @import("./build.zig");
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
pub const FileMap = mem.GenericSimpleMap([:0]const u8, [:0]u8);

pub const SourceLocation = struct {
    file: [:0]const u8,
    line: u64,
    column: u64,
    const Format = @This();
    pub var cwd: [:0]const u8 = &.{};
    pub fn formatWriteBuf(format: Format, buf: [*]u8) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..4].* = "\x1b[1m".*;
        var ptr: [*]u8 = file.CompoundPath.writeDisplayPath(buf + 4, format.file);
        ptr[0] = ':';
        ptr += 1;
        var ud64: fmt.Type.Ud64 = .{ .value = format.line };
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = ':';
        ptr += 1;
        ud64.value = format.column;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..4].* = "\x1b[0m".*;
        return ptr + 4;
    }
    fn fromBundleLocation(src: build.SourceLocation, bytes: [:0]u8) SourceLocation {
        const pathname: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
        return .{
            .file = pathname,
            .line = src.line +% 1,
            .column = src.column +% 1,
        };
    }
};
pub const LineLocation = struct {
    start: usize = 0,
    finish: usize = 0,
    line: usize = 0,
    pub fn update(loc: *LineLocation, buf: []u8, line: u64) bool {
        if (loc.line != 0) {
            loc.finish +%= 1;
            loc.start = loc.finish;
        }
        if (loc.line > line) {
            loc.* = .{};
        }
        while (loc.finish < buf.len) : (loc.finish +%= 1) {
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

const AboutKind = enum(u8) {
    @"error",
    note,
};
fn writeAbout(buf: [*]u8, kind: AboutKind) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = buf;
    switch (kind) {
        .@"error" => {
            ptr[0..4].* = "\x1b[1m".*;
            ptr += 4;
        },
        .note => {
            ptr[0..15].* = "\x1b[0;38;5;250;1m".*;
            ptr += 15;
        },
    }
    ptr = fmt.strcpyEqu(ptr, @tagName(kind));
    ptr[0..2].* = ": ".*;
    ptr += 2;
    ptr[0..4].* = "\x1b[1m".*;
    ptr += 4;
    return fmt.strlen(ptr, buf);
}
fn writeTopSrcLoc(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32) usize {
    @setRuntimeSafety(builtin.is_safe);
    const err: *build.ErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *build.SourceLocation = @ptrCast(extra + err.src_loc);
    buf[0..4].* = "\x1b[1m".*;
    var ptr: [*]u8 = buf + 4;
    if (err.src_loc != 0) {
        const src_file: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
        ptr += writeSourceLocation(ptr, src_file, src.line +% 1, src.column +% 1);
        ptr[0..2].* = ": ".*;
        ptr += 2;
    }
    return fmt.strlen(ptr, buf);
}
fn writeSourceContextNoAddr(
    trace: *const debug.Trace,
    allocator: *Allocator,
    file_map: *FileMap,
    buf: [*]u8,
    width: usize,
    src: *build.SourceLocation,
    pathname: [:0]const u8,
) [*]u8 {
    @setRuntimeSafety(false);
    const min: u64 = (src.line +% 1) -| trace.options.context_line_count;
    const max: u64 = (src.line +% 1) +% trace.options.context_line_count +% 1;
    var line: u64 = min;
    const fbuf: [:0]u8 = fastAllocFile(allocator, file_map, pathname);
    var itr: builtin.parse.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.parse.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    var ptr: [*]u8 = buf;
    var end: usize = 0;
    var loc: LineLocation = .{};
    while (line != max) : (line +%= 1) {
        if (loc.update(fbuf, line)) {
            if (trace.options.write_sidebar) {
                ptr = writeSideBarBuf(ptr, trace, width, .{ .line_no = loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                while (itr.buf_pos <= loc.start) {
                    tok = itr.next();
                }
                end = @min(loc.finish, tok.loc.start);
                ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..end]);
                loc.start +%= end -% loc.start;
                while (loc.start < loc.finish) {
                    if (loc.start < tok.loc.start) {
                        ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..tok.loc.start]);
                    }
                    if (loc.finish > tok.loc.start) {
                        ptr = highlight(ptr, &tok, syntax);
                    }
                    ptr = fmt.strcpyEqu(ptr, fbuf[tok.loc.start..tok.loc.finish]);
                    loc.start = tok.loc.finish;
                    ptr[0..4].* = "\x1b[0m".*;
                    ptr += 4;
                    tok = itr.next();
                }
            } else {
                ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..loc.finish]);
            }
            if ((ptr - 1)[0] != '\n') {
                ptr[0] = '\n';
                ptr += 1;
            }
            if (src.src_line != 0 and
                (src.line +% 1) == line and trace.options.write_caret)
            {
                ptr = writeCaretNoAddr(ptr, trace, width, src);
            }
        }
    }
    return ptr;
}
fn writeCaretNoAddr(buf: [*]u8, trace: *const debug.Trace, width: u64, src: *build.SourceLocation) [*]u8 {
    @setRuntimeSafety(false);
    const before_caret: u64 = (src.span_main -% src.span_start);
    const indent: u64 = (src.column -% before_caret);
    const after_caret: u64 = src.span_end -% src.span_main -| 1;
    var ptr: [*]u8 = buf;
    if (trace.options.write_sidebar) {
        ptr = writeSideBarBuf(ptr, trace, width, .none);
    }
    ptr = writeFiller(ptr, trace.options.tokens.caret_fill, indent);
    ptr[0..10].* = "\x1b[38;5;46m".*;
    ptr += 10;
    ptr = fmt.strsetEqu(ptr, '~', before_caret);
    ptr[0] = '^';
    ptr += 1;
    ptr = fmt.strsetEqu(ptr, '~', after_caret);
    ptr[0..5].* = "\x1b[0m\n".*;
    return ptr + 5;
}
fn writeSourceLocation(buf: [*]u8, pathname: [:0]const u8, line: usize, column: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ud64: fmt.Type.Ud64 = .{ .value = line };
    var ptr: [*]u8 = buf;
    ptr[0..11].* = "\x1b[38;5;247m".*;
    ptr += 11;
    ptr = fmt.strcpyEqu(ptr, pathname);
    ptr[0] = ':';
    ptr += 1;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0] = ':';
    ptr += 1;
    ud64.value = column;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..4].* = "\x1b[0m".*;
    return fmt.strlen(ptr, buf) +% 4;
}
fn writeTimes(buf: [*]u8, count: u64) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ud64: fmt.Type.Ud64 = .{ .value = count };
    var ptr: [*]u8 = buf - 1;
    ptr[0..4].* = "\x1b[2m".*;
    ptr += 4;
    ptr[0..2].* = " (".*;
    ptr += 2;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..7].* = " times)".*;
    ptr += 7;
    ptr[0..5].* = "\x1b[0m\n".*;
    return fmt.strlen(ptr, buf) +% 5;
}
fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: usize, indent: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ptr: [*]u8 = buf;
    var next: usize = start;
    var pos: usize = start;
    while (bytes[pos] != 0) : (pos +%= 1) {
        if (bytes[pos] == '\n') {
            ptr = fmt.strcpyEqu(ptr, bytes[next..pos]);
            ptr[0] = '\n';
            ptr += 1;
            ptr = fmt.strsetEqu(ptr, ' ', indent);
            next = pos +% 1;
        }
    }
    ptr = fmt.strcpyEqu(ptr, bytes[next..pos]);
    ptr[0..5].* = "\x1b[0m\n".*;
    return fmt.strlen(ptr, buf) +% 5;
}
fn writeTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: usize, ref_len: usize) usize {
    @setRuntimeSafety(builtin.is_safe);
    var ref_idx: usize = start +% build.SourceLocation.len;
    buf[0..11].* = "\x1b[38;5;247m".*;
    var ptr: [*]u8 = buf + 11;
    ptr[0..15].* = "referenced by:\n".*;
    ptr += 15;
    var len: usize = 0;
    while (len != ref_len) : (len +%= 1) {
        const ref_trc: *build.ReferenceTrace = @ptrCast(extra + ref_idx);
        if (ref_trc.src_loc != 0) {
            const ref_src: *build.SourceLocation = @ptrCast(extra + ref_trc.src_loc);
            const src_file: [:0]u8 = mem.terminate(bytes + ref_src.src_path, 0);
            const decl_name: [:0]u8 = mem.terminate(bytes + ref_trc.decl_name, 0);
            @memset(ptr[0..4], ' ');
            ptr += 4;
            ptr = fmt.strcpyEqu(ptr, decl_name);
            ptr[0..2].* = ": ".*;
            ptr += 2;
            ptr += writeSourceLocation(ptr, src_file, ref_src.line +% 1, ref_src.column +% 1);
            ptr[0] = '\n';
            ptr += 1;
        }
        ref_idx +%= build.ReferenceTrace.len;
    }
    ptr[0..5].* = "\x1b[0m\n".*;
    return (@intFromPtr(ptr) -% @intFromPtr(buf)) +% 5;
}

fn writeCompileError(allocator: *Allocator, buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind, file_map: *FileMap) [*]u8 {
    @setRuntimeSafety(builtin.is_safe);
    const err: *build.ErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *build.SourceLocation = @ptrCast(extra + err.src_loc);
    const notes: [*]u32 = extra + err_msg_idx + build.ErrorMessage.len;

    buf[0..7].* = "\x1b[1;92m".*;
    var ptr: [*]u8 = buf + 7;
    const pathname: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
    if (err.src_loc != 0) {
        ptr += writeSourceLocation(ptr, pathname, src.line +% 1, src.column +% 1);
        ptr[0..2].* = ": ".*;
        ptr += 2;
    }
    ptr += writeAbout(ptr, kind);
    ptr += writeMessage(ptr, bytes, err.start, fmt.strlen(ptr, buf) +% @tagName(kind).len -% 11 -% 2);

    if (err.src_loc == 0) {
        if (err.count != 1) {
            ptr += writeTimes(ptr, err.count);
        }
        for (0..err.notes_len) |idx| {
            ptr = writeCompileError(allocator, ptr, extra, bytes, notes[idx], .note, file_map);
        }
    } else {
        if (err.count != 1) {
            ptr += writeTimes(ptr, err.count);
        }
        if (src.src_line != 0) {
            ptr = writeSourceContextNoAddr(&builtin.trace, allocator, file_map, ptr, 8, src, pathname);
            ptr = writeLastLine(ptr, &builtin.trace, 8);
        }
        for (0..err.notes_len) |idx| {
            ptr = writeCompileError(allocator, ptr, extra, bytes, notes[idx], .note, file_map);
        }
        if (src.ref_len != 0) {
            ptr += writeTrace(ptr, extra, bytes, err.src_loc, src.ref_len);
        }
    }
    return ptr;
}

pub fn printCompileErrors(allocator: *Allocator, msg: [*:0]u8) void {
    @setRuntimeSafety(builtin.is_safe);
    const extra: [*]u32 = @ptrCast(@alignCast(msg + 8));
    var file_map: FileMap = FileMap.init(allocator, 8);
    var bytes: [*:0]u8 = msg;
    bytes += 8 +% (extra - 2)[0] *% 4;
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
        debug.write(fmt.slice(writeCompileError(allocator, buf, extra, bytes, err_msg_idx, .@"error", &file_map), buf));
    }
    debug.write(mem.terminate(bytes + extra[2], 0));
}

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
fn writeLastLine(buf: [*]u8, trace: *const debug.Trace, width: u64) [*]u8 {
    @setRuntimeSafety(false);
    var idx: u64 = 0;
    var ptr: [*]u8 = buf;
    while (idx != trace.options.break_line_count) : (idx +%= 1) {
        if (trace.options.write_sidebar) {
            ptr = writeSideBarBuf(ptr, trace, width, .none);
        }
        ptr[0] = '\n';
        ptr += 1;
    }
    ptr[0..4].* = "\x1b[0m".*;
    ptr -= 1;
    if (ptr[0] != '\n') {
        ptr[4] = '\n';
        return ptr + 5;
    }
    return ptr + 4;
}
fn writeSideBarBuf(buf: [*]u8, trace: *const debug.Trace, width: u64, number: Number) [*]u8 {
    @setRuntimeSafety(false);
    const sidebar: []const u8 = trace.options.tokens.sidebar;
    const sidebar_char: bool = sidebar.len == 1;
    if (!trace.options.show_line_no and
        !trace.options.show_pc_addr)
    {
        return buf;
    }
    var tmp: [8]u8 = undefined;
    var ptr: [*]u8 = buf;
    const fill: []const u8 = trace.options.tokens.sidebar_fill;
    const fill_len: usize = @min(width, fill.len);
    const pos: usize = switch (number) {
        .none => fmt.strcpy(&tmp, fill[0..fill_len]),
        .pc_addr => |pc_addr| if (trace.options.show_pc_addr) blk: {
            if (trace.options.tokens.pc_addr) |style| {
                ptr = fmt.strcpyEqu(ptr, style);
            }
            break :blk fmt.ux64(pc_addr).formatWriteBuf(&tmp);
        } else fmt.strcpy(&tmp, fill[0..fill_len]),
        .line_no => |line_no| if (trace.options.show_line_no) blk: {
            if (trace.options.tokens.line_no) |style| {
                ptr = fmt.strcpyEqu(ptr, style);
            }
            break :blk fmt.ud64(line_no).formatWriteBuf(&tmp);
        } else fmt.strcpy(&tmp, fill[0..fill_len]),
    };
    ptr = fmt.strsetEqu(ptr, ' ', width -| (pos +% 1));
    ptr = fmt.strcpyEqu(ptr, tmp[0..pos]);
    ptr[0..4].* = "\x1b[0m".*;
    ptr += 4;
    if (sidebar_char) {
        ptr[0] = sidebar[0];
        ptr += 1;
    } else {
        ptr = fmt.strcpyEqu(ptr, sidebar);
    }
    return ptr;
}
fn writeFiller(buf: [*]u8, filler: []const u8, fill_len: u64) [*]u8 {
    @setRuntimeSafety(false);
    if (filler.len == 1) {
        return fmt.strsetEqu(buf, filler[0], fill_len);
    } else {
        var ptr: [*]u8 = buf;
        for (0..fill_len) |_| {
            ptr = fmt.strcpyEqu(ptr, filler);
        }
        return ptr;
    }
}
fn writeCaret(buf: [*]u8, trace: *const debug.Trace, width: u64, addr: u64, column: u64) [*]u8 {
    @setRuntimeSafety(false);
    const caret: []const u8 = trace.options.tokens.caret;
    var ptr: [*]u8 = buf;
    if (trace.options.write_sidebar) {
        ptr = writeSideBarBuf(ptr, trace, width, .{ .pc_addr = addr });
    }
    const fill_len: u64 = column -| 1;
    ptr = writeFiller(ptr, trace.options.tokens.caret_fill, fill_len);
    ptr = fmt.strcpyEqu(ptr, caret);
    ptr[0] = '\n';
    return ptr + 1;
}
fn highlight(buf: [*]u8, tok: *builtin.parse.Token, syntax: anytype) [*]u8 {
    @setRuntimeSafety(false);
    for (syntax) |pair| {
        for (pair.tags) |tag| {
            if (tok.tag == tag) {
                return fmt.strcpyEqu(buf, pair.style);
            }
        }
    }
    return buf;
}
fn writeExtendedSourceLocation(
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    addr: u64,
    unit: *const dwarf.Unit,
    src: SourceLocation,
) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = src.formatWriteBuf(buf);
    ptr[0..2].* = ": ".*;
    ptr += 2;
    ptr += fmt.ux64(addr).formatWriteBuf(ptr);
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        ptr[0..4].* = " in ".*;
        ptr += 4;
        ptr = fmt.strcpyEqu(ptr, fn_name);
    }
    if (unit.info_entry.get(.name)) |form_val| {
        ptr[0..2].* = " (".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, form_val.getString(dwarf_info));
        ptr[0] = ')';
        ptr += 1;
    }
    ptr[0] = '\n';
    return ptr + 1;
}
fn writeSourceContext(
    trace: *const debug.Trace,
    allocator: *Allocator,
    file_map: *FileMap,
    buf: [*]u8,
    width: u64,
    addr: u64,
    src: SourceLocation,
) [*]u8 {
    @setRuntimeSafety(false);
    const min: u64 = src.line -| trace.options.context_line_count;
    const max: u64 = src.line +% trace.options.context_line_count +% 1;
    var line: u64 = min;
    const fbuf: [:0]u8 = fastAllocFile(allocator, file_map, src.file);
    var itr: builtin.parse.TokenIterator = .{ .buf = fbuf, .buf_pos = 0, .inval = null };
    var tok: builtin.parse.Token = .{ .tag = .eof, .loc = .{ .start = 0, .finish = 0 } };
    var ptr: [*]u8 = buf;
    var end: usize = 0;
    var loc: LineLocation = .{};
    while (line != max) : (line +%= 1) {
        if (loc.update(fbuf, line)) {
            if (trace.options.write_sidebar) {
                ptr = writeSideBarBuf(ptr, trace, width, .{ .line_no = loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                while (itr.buf_pos <= loc.start) {
                    tok = itr.next();
                }
                end = @min(loc.finish, tok.loc.start);
                ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..end]);
                loc.start +%= end -% loc.start;
                while (loc.start < loc.finish) {
                    if (loc.start < tok.loc.start) {
                        ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..tok.loc.start]);
                    }
                    if (loc.finish > tok.loc.start) {
                        ptr = highlight(ptr, &tok, syntax);
                    }
                    ptr = fmt.strcpyEqu(ptr, fbuf[tok.loc.start..tok.loc.finish]);
                    loc.start = tok.loc.finish;
                    ptr[0..4].* = "\x1b[0m".*;
                    ptr += 4;
                    tok = itr.next();
                }
            } else {
                ptr = fmt.strcpyEqu(ptr, fbuf[loc.start..loc.finish]);
            }
            if ((ptr - 1)[0] != '\n') {
                ptr[0] = '\n';
                ptr += 1;
            }
            if (line == src.line and trace.options.write_caret) {
                ptr = writeCaret(ptr, trace, width, addr, src.column);
            }
        }
    }
    return ptr;
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
                ptr = writeExtendedSourceLocation(dwarf_info, ptr, addr, unit, src);
                ptr = writeSourceContext(trace, allocator, file_map, ptr, width, addr, src);
                ptr = writeLastLine(trace, ptr, width);
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
    if (SourceLocation.cwd.len == 0) {
        const cwd_addr: usize = allocator.allocateRaw(4096, 1);
        const rc: usize = sys.call_noexcept(.getcwd, usize, .{ cwd_addr, 4096 });
        if (rc > 4096) {
            sys.call_noexcept(.exit, void, .{2});
        }
        const cwd: [*]u8 = @ptrFromInt(cwd_addr);
        SourceLocation.cwd = cwd[0 .. rc -% 1 :0];
    }
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    SourceLocation.cwd = file.getCwd(.{ .errors = .{} }, buf[0..4096]);
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
    @setRuntimeSafety(false);
    const start: usize = @atomicRmw(usize, &Level.start, .Add, 0x40000000, .SeqCst);
    defer Level.start = start;
    if (start != Level.lb_addr) {
        return debug.write(working);
    }
    var allocator: Allocator = .{ .start = start, .next = start, .finish = start };
    var file_map: FileMap = FileMap.init(&allocator, 8);
    const exe_buf: []u8 = fastAllocFile(&allocator, &file_map, tab.self_link_s);
    if (SourceLocation.cwd.len == 0) {
        const cwd_addr: usize = allocator.allocateRaw(4096, 1);
        const rc: usize = sys.call_noexcept(.getcwd, usize, .{ cwd_addr, 4096 });
        if (rc > 4096) {
            sys.call_noexcept(.exit, void, .{2});
        }
        const cwd: [*]u8 = @ptrFromInt(cwd_addr);
        SourceLocation.cwd = cwd[0 .. rc -% 1 :0];
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
