const mem = @import("mem.zig");
const sys = @import("sys.zig");
const fmt = @import("fmt.zig");
const zig = @import("zig.zig");
const proc = @import("proc.zig");
const math = @import("math.zig");
const file = @import("file.zig");
const debug = @import("debug.zig");
const dwarf = @import("dwarf.zig");
const builtin = @import("builtin.zig");
const testing = @import("testing.zig");
pub usingnamespace @import("start.zig");
const is_safe: bool = false;
pub const logging_default: debug.Logging.Default = .{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Success = false,
    .Release = false,
};
pub const logging_override: debug.Logging.Override = .{
    .Acquire = false,
    .Attempt = false,
    .Error = false,
    .Fault = false,
    .Success = false,
    .Release = false,
};
const test_pc_range: bool = false;
const Level = struct {
    var start: usize = lb_addr;
    const lb_addr: usize = 0x600000000000;
};
const Number = union(enum) {
    pc_addr: u64,
    line_no: u64,
    none,
};
pub const WorkingFile = struct {
    itr: builtin.parse.TokenIterator,
    loc: LineLocation,
};
pub const FileMap = mem.array.GenericSimpleMap([:0]const u8, WorkingFile);
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
pub const CompileErrorMessageList = extern struct {
    len: u32,
    start: u32,
    compile_log_text: u32,
    pub const len: comptime_int = @divExact(@sizeOf(@This()), @sizeOf(u32));
    pub const Extra = extern struct {
        data: *CompileErrorMessageList,
        end: u64,
    };
};
pub const CompileSourceLocation = extern struct {
    src_path: u32,
    line: u32,
    column: u32,
    span_start: u32,
    span_main: u32,
    span_end: u32,
    src_line: u32 = 0,
    ref_len: u32 = 0,
    pub const len: comptime_int = @divExact(@sizeOf(@This()), @sizeOf(u32));
    pub const Extra = extern struct {
        data: *SourceLocation,
        end: u64,
    };
};
pub const CompileErrorMessage = extern struct {
    start: u32,
    count: u32 = 1,
    src_loc: u32 = 0,
    notes_len: u32 = 0,
    pub const len: comptime_int = @divExact(@sizeOf(@This()), @sizeOf(u32));
    pub const Extra = extern struct {
        data: *CompileErrorMessage,
        end: u64,
    };
};
pub const CompileReferenceTrace = extern struct {
    decl_name: u32,
    src_loc: u32,
    pub const len: comptime_int = @divExact(@sizeOf(@This()), @sizeOf(u32));
    pub const Extra = extern struct {
        data: *CompileReferenceTrace,
        end: u64,
    };
};
pub const SourceLocation = struct {
    file: [:0]const u8,
    line: usize = 0,
    column: usize = 0,
    pub fn write(buf: [*]u8, pathname: [:0]const u8, line: usize, column: usize) [*]u8 {
        @setRuntimeSafety(false);
        buf[0..4].* = "\x1b[1m".*;
        var ptr: [*]u8 = file.CompoundPath.writeDisplayPath(buf + 4, pathname);
        ptr[0] = ':';
        ptr = fmt.Ud64.write(ptr + 1, line);
        ptr[0] = ':';
        ptr = fmt.Ud64.write(ptr + 1, column);
        ptr[0..4].* = "\x1b[0m".*;
        return ptr + 4;
    }
    pub fn formatWriteBuf(format: SourceLocation, buf: [*]u8) usize {
        return fmt.strlen(write(buf, format.file, format.line, format.column), buf);
    }
};
pub const LineLocation = extern struct {
    start: usize = 0,
    finish: usize = 0,
    line: usize = 0,
    pub fn update(loc: *LineLocation, buf: []u8, line: u64) bool {
        @setRuntimeSafety(false);
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
const AboutKind = enum(u8) { @"error", note };
fn writeAbout(buf: [*]u8, kind: AboutKind) [*]u8 {
    @setRuntimeSafety(false);
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
    return ptr;
}
fn writeTopSrcLoc(buf: [*]u8, err: *CompileErrorMessage, src: *CompileSourceLocation, bytes: [*:0]u8) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..4].* = "\x1b[1m".*;
    var ptr: [*]u8 = buf + 4;
    if (err.src_loc != 0) {
        ptr = SourceLocation.write(ptr, mem.terminate(bytes + src.src_path, 0), src.line +% 1, src.column +% 1);
        ptr[0..2].* = ": ".*;
        ptr += 2;
    }
    return ptr;
}
fn writeTimes(buf: [*]u8, count: u64) [*]u8 {
    @setRuntimeSafety(false);
    var ud64: fmt.Ud64 = .{ .value = count };
    var ptr: [*]u8 = buf - 1;
    ptr[0..4].* = "\x1b[2m".*;
    ptr += 4;
    ptr[0..2].* = " (".*;
    ptr += 2;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..7].* = " times)".*;
    ptr += 7;
    ptr[0..5].* = "\x1b[0m\n".*;
    return ptr + 5;
}
fn writeMessage(buf: [*]u8, bytes: [*:0]u8, start: usize, indent: usize) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    var next: usize = start;
    var pos: usize = start;
    while (bytes[pos] != 0) : (pos +%= 1) {
        if (bytes[pos] == '\n') {
            ptr = fmt.strcpyEqu(ptr, bytes[next..pos]);
            ptr[0] = '\n';
            ptr = fmt.strsetEqu(ptr + 1, ' ', indent);
            next = pos +% 1;
        }
    }
    ptr = fmt.strcpyEqu(ptr, bytes[next..pos]);
    ptr[0..5].* = "\x1b[0m\n".*;
    return ptr + 5;
}
fn backTrackToLine(itr: *builtin.parse.TokenIterator) void {
    @setRuntimeSafety(false);
    while (itr.buf_pos != 0) {
        itr.buf_pos -%= 1;
        if (itr.buf[itr.buf_pos] == '\n') {
            break;
        }
    }
}
fn backTrackToFileScope(itr: *builtin.parse.TokenIterator) void {
    @setRuntimeSafety(false);
    itr.buf_pos -%= @min(1, @intFromBool(itr.buf.len == itr.buf_pos));
    var byte: u8 = itr.buf[itr.buf_pos];
    while (itr.buf_pos != 0) : (byte = itr.buf[itr.buf_pos]) {
        itr.buf_pos -%= 1;
        if (itr.buf[itr.buf_pos] == '\n' and byte != ' ') {
            break;
        }
    }
}
fn writeCompileSourceContext(
    buf: [*]u8,
    allocator: *mem.SimpleAllocator,
    trace: *const debug.Trace,
    file_map: *FileMap,
    width: usize,
    src: *CompileSourceLocation,
    pathname: [:0]const u8,
) [*]u8 {
    @setRuntimeSafety(false);
    const work: *WorkingFile = getWorkingFile(allocator, file_map, pathname);
    const min: usize = (src.line +% 1) -| trace.options.context_line_count;
    const max: usize = (src.line +% 1) +% trace.options.context_line_count +% 1;
    var line: usize = min;
    var ptr: [*]u8 = buf;
    var tok: builtin.parse.Token = work.itr.nextToken();
    while (line != max) : (line +%= 1) {
        if (work.loc.update(work.itr.buf, line)) {
            if (trace.options.write_sidebar) {
                ptr = writeSideBar(ptr, trace, width, .{ .line_no = work.loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                if (work.itr.buf_pos > work.loc.start) {
                    work.itr.buf_pos = work.loc.start;
                    backTrackToFileScope(&work.itr);
                }
                while (work.itr.buf_pos <= work.loc.start) {
                    work.itr.nextExtra(&tok);
                }
                const end: usize = @min(work.loc.finish, tok.loc.start);
                ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..end]);
                work.loc.start +%= end -% work.loc.start;
                while (work.loc.start < work.loc.finish) : (work.itr.nextExtra(&tok)) {
                    if (work.loc.start < tok.loc.start) {
                        ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..tok.loc.start]);
                    }
                    if (work.loc.finish > tok.loc.start) {
                        if (fmt.highlight(&tok, syntax)) |style| {
                            ptr = fmt.strcpyEqu(ptr, style);
                        }
                    }
                    ptr = fmt.strcpyEqu(ptr, work.itr.buf[tok.loc.start..tok.loc.finish]);
                    work.loc.start = tok.loc.finish;
                    ptr[0..4].* = "\x1b[0m".*;
                    ptr += 4;
                }
            } else {
                ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..work.loc.finish]);
            }
            if ((ptr - 1)[0] != '\n') {
                ptr[0] = '\n';
                ptr += 1;
            }
            if (trace.options.write_caret and
                src.line +% 1 == line)
            {
                ptr = writeCompileErrorCaretTrace(ptr, trace, width, src);
            }
        }
    }
    return ptr;
}
fn writeCompileErrorCaretStandard(buf: [*]u8, bytes: [*:0]u8, src: *CompileSourceLocation) [*]u8 {
    @setRuntimeSafety(false);
    const line: [:0]u8 = mem.terminate(bytes + src.src_line, 0);
    const before_caret: u64 = src.span_main -% src.span_start;
    const indent: u64 = src.column -% before_caret;
    const after_caret: u64 = src.span_end -% src.span_main -| 1;
    var ptr: [*]u8 = fmt.strcpyEqu(buf, line);
    ptr[0] = '\n';
    ptr += 1;
    ptr = fmt.strsetEqu(ptr, ' ', indent);
    ptr[0..10].* = "\x1b[38;5;46m".*;
    ptr += 10;
    ptr = fmt.strsetEqu(ptr, '~', before_caret);
    ptr[0] = '^';
    ptr += 1;
    ptr = fmt.strsetEqu(ptr, '~', after_caret);
    ptr[0..5].* = "\x1b[0m\n".*;
    return ptr + 5;
}
fn writeCompileErrorCaretTrace(buf: [*]u8, trace: *const debug.Trace, width: u64, src: *CompileSourceLocation) [*]u8 {
    @setRuntimeSafety(false);
    const before_caret: usize = src.span_main -% src.span_start;
    const indent: usize = src.column -% before_caret;
    const after_caret: usize = src.span_end -% src.span_main -| 1;
    var ptr: [*]u8 = buf;
    if (trace.options.write_sidebar) {
        ptr = writeSideBar(ptr, trace, width, .none);
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
fn writeReferenceTrace(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, start: usize, ref_len: usize) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..30].* = "\x1b[38;5;247mreferenced by:\n\x1b[0m".*;
    var ptr: [*]u8 = buf + 30;
    var refs: [*]CompileReferenceTrace = @ptrCast(extra + start + CompileSourceLocation.len);
    var idx: usize = 0;
    while (idx != ref_len) : (idx +%= 1) {
        if (refs[idx].src_loc != 0) {
            const ref_src: *CompileSourceLocation = @ptrCast(extra + refs[idx].src_loc);
            ptr[0..4].* = "    ".*;
            ptr = fmt.strcpyEqu(ptr + 4, mem.terminate(bytes + refs[idx].decl_name, 0));
            ptr[0..2].* = ": ".*;
            ptr = SourceLocation.write(ptr + 2, mem.terminate(bytes + ref_src.src_path, 0), ref_src.line +% 1, ref_src.column +% 1);
            ptr[0] = '\n';
            ptr += 1;
        }
    }
    ptr[0..5].* = "\x1b[0m\n".*;
    return ptr + 5;
}
fn writeReferenceTraceExtended(
    buf: [*]u8,
    allocator: *mem.SimpleAllocator,
    trace: *const debug.Trace,
    file_map: *FileMap,
    extra: [*]u32,
    bytes: [*:0]u8,
    start: usize,
    ref_len: usize,
    width: usize,
) [*]u8 {
    @setRuntimeSafety(false);
    var refs: [*]CompileReferenceTrace = @ptrCast(extra + start + CompileSourceLocation.len);
    var ptr: [*]u8 = buf;
    var idx: usize = 0;
    while (idx != ref_len) : (idx +%= 1) {
        if (refs[idx].src_loc != 0) {
            const src: *CompileSourceLocation = @ptrCast(extra + refs[idx].src_loc);
            ptr = SourceLocation.write(ptr, mem.terminate(bytes + src.src_path, 0), src.line +% 1, src.column +% 1);
            ptr[0..2].* = ": ".*;
            ptr = writeAbout(ptr + 2, .note);
            ptr[0..11].* = "\x1b[38;5;247m".*;
            ptr += 11;
            ptr[0..15].* = "referenced by '".*;
            ptr = fmt.strcpyEqu(ptr + 15, mem.terminate(bytes + refs[idx].decl_name, 0));
            ptr[0..2].* = "'\n".*;
            ptr = writeCompileSourceContext(ptr + 2, allocator, trace, file_map, width, src, mem.terminate(bytes + src.src_path, 0));
            ptr = writeLastLine(ptr, trace, width);
        }
    }
    ptr[0..4].* = "\x1b[0m".*;
    return ptr + 4;
}
fn writeCompileErrorStandard(buf: [*]u8, extra: [*]u32, bytes: [*:0]u8, err_msg_idx: u32, kind: AboutKind) [*]u8 {
    @setRuntimeSafety(false);
    const err: *CompileErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *CompileSourceLocation = @ptrCast(extra + err.src_loc);
    const notes: [*]u32 = extra + err_msg_idx + CompileErrorMessage.len;
    var ptr: [*]u8 = writeTopSrcLoc(buf, err, src, bytes);
    const pos: u64 = (@intFromPtr(ptr) -% @intFromPtr(buf)) +% @tagName(kind).len -% 13;
    ptr = writeAbout(ptr, kind);
    ptr = writeMessage(ptr, bytes, err.start, pos);
    if (err.src_loc == 0) {
        if (err.count != 1)
            ptr = writeTimes(ptr, err.count);
        for (0..err.notes_len) |idx|
            ptr = writeCompileErrorStandard(ptr, extra, bytes, notes[idx], .note);
    } else {
        if (err.count != 1)
            ptr = writeTimes(ptr, err.count);
        if (src.src_line != 0)
            ptr = writeCompileErrorCaretStandard(ptr, bytes, src);
        for (0..err.notes_len) |idx|
            ptr = writeCompileErrorStandard(ptr, extra, bytes, notes[idx], .note);
        if (src.ref_len != 0)
            ptr = writeReferenceTrace(ptr, extra, bytes, err.src_loc, src.ref_len);
    }
    return ptr;
}
fn writeCompileErrorTrace(
    buf: [*]u8,
    allocator: *mem.SimpleAllocator,
    trace: *const debug.Trace,
    extra: [*]u32,
    bytes: [*:0]u8,
    err_msg_idx: u32,
    kind: AboutKind,
    file_map: *FileMap,
    width: usize,
) [*]u8 {
    @setRuntimeSafety(false);
    const err: *CompileErrorMessage = @ptrCast(extra + err_msg_idx);
    const src: *CompileSourceLocation = @ptrCast(extra + err.src_loc);
    const notes: [*]u32 = extra + err_msg_idx + CompileErrorMessage.len;
    const pathname: [:0]const u8 = mem.terminate(bytes + src.src_path, 0);
    var ptr: [*]u8 = writeTopSrcLoc(buf, err, src, bytes);
    ptr = writeAbout(ptr, kind);
    ptr = writeMessage(ptr, bytes, err.start, fmt.strlen(ptr, buf) +% @tagName(kind).len -% 13);
    if (err.src_loc == 0) {
        if (err.count != 1)
            ptr = writeTimes(ptr, err.count);
        for (0..err.notes_len) |idx|
            ptr = writeCompileErrorTrace(ptr, allocator, trace, extra, bytes, notes[idx], .note, file_map, width);
    } else {
        if (err.count != 1)
            ptr = writeTimes(ptr, err.count);
        if (src.src_line != 0)
            ptr = writeCompileSourceContext(ptr, allocator, trace, file_map, width, src, pathname);
        ptr = writeLastLine(ptr, trace, width);
        for (0..err.notes_len) |idx|
            ptr = writeCompileErrorTrace(ptr, allocator, trace, extra, bytes, notes[idx], .note, file_map, width);
        if (src.ref_len != 0) {
            if (trace.options.write_full_ref_trace) {
                ptr = writeReferenceTraceExtended(ptr, allocator, trace, file_map, extra, bytes, err.src_loc, src.ref_len, width);
            } else {
                ptr = writeReferenceTrace(ptr, extra, bytes, err.src_loc, src.ref_len);
            }
        }
    }
    return ptr;
}
pub fn printCompileErrorsStandard(allocator: *mem.SimpleAllocator, msg: [*:0]u8) void {
    @setRuntimeSafety(false);
    const save: usize = allocator.save();
    const extra: [*]u32 = @ptrCast(@alignCast(msg + 8));
    var bytes: [*:0]u8 = msg;
    bytes += 8 + ((extra - 2)[0] *% 4);
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
        const ptr: [*]u8 = writeCompileErrorStandard(buf, extra, bytes, err_msg_idx, .@"error");
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(buf)]);
    }
    debug.write(mem.terminate(bytes + extra[2], 0));
    allocator.restore(save);
}
pub fn printCompileErrorsTrace(allocator: *mem.SimpleAllocator, trace: *const debug.Trace, msg: [*:0]u8) void {
    @setRuntimeSafety(false);
    const save: usize = allocator.save();
    const extra: [*]u32 = @ptrCast(@alignCast(msg + 8));
    var file_map: FileMap = FileMap.init(allocator, 8);
    var bytes: [*:0]u8 = msg;
    bytes += 8 +% (extra - 2)[0] *% 4;
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    for ((extra + extra[1])[0..extra[0]]) |err_msg_idx| {
        const ptr: [*]u8 = writeCompileErrorTrace(buf, allocator, trace, extra, bytes, err_msg_idx, .@"error", &file_map, 8);
        debug.write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(buf)]);
    }
    debug.write(mem.terminate(bytes + extra[2], 0));
    allocator.restore(save);
}
fn writeLastLine(buf: [*]u8, trace: *const debug.Trace, width: u64) [*]u8 {
    @setRuntimeSafety(false);
    var idx: u64 = 0;
    var ptr: [*]u8 = buf;
    while (idx != trace.options.break_line_count) : (idx +%= 1) {
        if (trace.options.write_sidebar) {
            ptr = writeSideBar(ptr, trace, width, .none);
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
fn writeSideBar(buf: [*]u8, trace: *const debug.Trace, width: u64, number: Number) [*]u8 {
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
        ptr = writeSideBar(ptr, trace, width, .{ .pc_addr = addr });
    }
    const fill_len: u64 = column -| 1;
    ptr = writeFiller(ptr, trace.options.tokens.caret_fill, fill_len);
    ptr = fmt.strcpyEqu(ptr, caret);
    ptr[0] = '\n';
    return ptr + 1;
}
fn writeExtendedSourceLocation(
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    addr: u64,
    unit: *const dwarf.Unit,
    src: SourceLocation,
) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = SourceLocation.write(buf, src.file, src.line, src.column);
    ptr[0..2].* = ": ".*;
    ptr = fmt.Ux64.write(ptr + 2, addr);
    if (dwarf_info.getSymbolName(addr)) |fn_name| {
        ptr[0..4].* = " in ".*;
        ptr = fmt.strcpyEqu(ptr + 4, fn_name);
    }
    if (unit.info_entry.get(.name)) |form_val| {
        ptr[0..2].* = " (".*;
        ptr = fmt.strcpyEqu(ptr + 2, form_val.getString(dwarf_info));
        ptr[0] = ')';
        ptr += 1;
    }
    ptr[0] = '\n';
    return ptr + 1;
}
fn writeSourceContext(
    trace: *const debug.Trace,
    allocator: *mem.SimpleAllocator,
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
    const work: *WorkingFile = getWorkingFile(allocator, file_map, src.file);
    var ptr: [*]u8 = buf;
    var tok: builtin.parse.Token = work.itr.nextToken();
    while (line != max) : (line +%= 1) {
        if (work.loc.update(work.itr.buf, line)) {
            if (trace.options.write_sidebar) {
                ptr = writeSideBar(ptr, trace, width, .{ .line_no = work.loc.line });
            }
            if (trace.options.tokens.syntax) |syntax| {
                if (work.itr.buf_pos > work.loc.start) {
                    work.itr.buf_pos = work.loc.start;
                    backTrackToFileScope(&work.itr);
                }
                while (work.itr.buf_pos <= work.loc.start) {
                    work.itr.nextExtra(&tok);
                }
                const end: usize = @min(work.loc.finish, tok.loc.start);
                ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..end]);
                work.loc.start +%= end -% work.loc.start;
                while (work.loc.start < work.loc.finish) : (work.itr.nextExtra(&tok)) {
                    if (work.loc.start < tok.loc.start) {
                        ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..tok.loc.start]);
                    }
                    if (work.loc.finish > tok.loc.start) {
                        if (fmt.highlight(&tok, syntax)) |style| {
                            ptr = fmt.strcpyEqu(ptr, style);
                        }
                    }
                    ptr = fmt.strcpyEqu(ptr, work.itr.buf[tok.loc.start..tok.loc.finish]);
                    work.loc.start = tok.loc.finish;
                    ptr[0..4].* = "\x1b[0m".*;
                    ptr += 4;
                }
            } else {
                ptr = fmt.strcpyEqu(ptr, work.itr.buf[work.loc.start..work.loc.finish]);
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
    allocator: *mem.SimpleAllocator,
    file_map: *FileMap,
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
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
                if (test_pc_range) {
                    for (dwarf_info.src_locs[0..dwarf_info.src_locs_len]) |*src_loc| {
                        if (src_loc.column == src.column and
                            src_loc.line == src.line and
                            mem.testEqualString(src.file, src_loc.file))
                        {
                            return null;
                        }
                    }
                    dwarf_info.addSourceLocation(allocator).* = src;
                }
                var ptr: [*]u8 = writeExtendedSourceLocation(dwarf_info, buf, addr, unit, src);
                ptr = writeSourceContext(trace, allocator, file_map, ptr, width, addr, src);
                ptr = writeLastLine(ptr, trace, width);
                return .{ .addr = addr, .start = buf, .finish = ptr };
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
fn printMessage(allocator: *mem.SimpleAllocator, addr_info: *dwarf.DwarfInfo.AddressInfo) void {
    @setRuntimeSafety(false);
    const msg: []u8 = fmt.slice(addr_info.finish, addr_info.start);
    if (addr_info.count != 0) {
        const save: usize = allocator.next;
        const new: [*]u8 = @ptrFromInt(allocator.allocateRaw(msg.len +% 32, 64));
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
fn allocateFile(allocator: *mem.SimpleAllocator, pathname: [:0]const u8) [:0]u8 {
    @setRuntimeSafety(false);
    const fd: usize = file.open(.{ .errors = .{} }, .{}, pathname);
    if (fd >= 1024) {
        proc.exit(2);
    }
    var st: file.Status = undefined;
    var rc: usize = file.status(.{ .return_type = usize, .errors = .{} }, fd, &st);
    if (rc != 0) {
        proc.exit(2);
    }
    const addr: usize = allocator.allocateRaw(st.size +% 1, 8);
    var buf: [*]u8 = @ptrFromInt(addr);
    @memset(buf[0 .. st.size +% 1], 0);
    rc = file.read(.{ .errors = .{}, .return_type = usize }, fd, buf[0..st.size]);
    if (rc != st.size) {
        proc.exit(2);
    }
    buf[st.size] = 0;
    file.close(.{ .errors = .{} }, fd);
    return buf[0..st.size :0];
}
fn getWorkingFile(allocator: *mem.SimpleAllocator, file_map: *FileMap, pathname: [:0]const u8) *WorkingFile {
    @setRuntimeSafety(false);
    for (file_map.pairs[0..file_map.pairs_len]) |pair| {
        if (mem.testEqualString(pair.key, pathname)) {
            return &pair.val;
        }
    }
    const buf: [:0]u8 = allocateFile(allocator, pathname);
    file_map.appendOne(allocator, .{ .key = pathname, .val = .{
        .loc = .{},
        .itr = .{ .buf = buf, .buf_pos = 0, .inval = null },
    } });
    return &file_map.pairs[file_map.pairs_len -% 1].val;
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
fn debugFindMoreAddresses(
    trace: *const debug.Trace,
    allocator: *mem.SimpleAllocator,
    file_map: *FileMap,
    dwarf_info: *dwarf.DwarfInfo,
    buf: [*]u8,
    width: usize,
    addr: usize,
) [*]u8 {
    var ptr: [*]u8 = buf;
    var disp: usize = 1;
    var b: bool = true;
    var a: bool = true;
    while (true) : (disp +%= 0x1) {
        if (b) {
            if (writeSourceCodeAtAddress(trace, allocator, file_map, dwarf_info, ptr, width, addr -% disp)) |addr_info| {
                ptr = addr_info.finish;
                dwarf_info.addAddressInfo(allocator).* = addr_info;
            } else {
                b = false;
            }
        }
        if (a) {
            if (writeSourceCodeAtAddress(trace, allocator, file_map, dwarf_info, ptr, width, addr +% disp)) |addr_info| {
                ptr = addr_info.finish;
                dwarf_info.addAddressInfo(allocator).* = addr_info;
            } else {
                a = false;
            }
        }
        if (!a and !b) {
            break;
        }
    }
    return ptr;
}
pub fn printSourceCodeAtAddress(trace: *const debug.Trace, addr: usize) callconv(.C) void {
    printSourceCodeAtAddresses(trace, 0, &[_]usize{addr}, 1);
}
pub fn printSourceCodeAtAddresses(trace: *const debug.Trace, ret_addr: usize, addrs: [*]const usize, addrs_len: usize) callconv(.C) void {
    @setRuntimeSafety(false);
    const start: usize = @atomicRmw(usize, &Level.start, .Add, 0x40000000, .SeqCst);
    if (Level.start > Level.lb_addr +% 1024 *% 1024 *% 1024) {
        return;
    }
    var allocator: mem.SimpleAllocator = .{ .start = start, .next = start, .finish = start };
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(4096, 1));
    defer allocator.unmapAll();
    var file_map: FileMap = FileMap.init(&allocator, 8);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(allocateFile(&allocator, "/proc/self/exe").ptr));
    dwarf_info.scanAllCompileUnits(&allocator);
    buf = @ptrFromInt(allocator.allocateRaw(1024 *% 4096, 1));
    @memset(buf[0 .. 1024 *% 4096], 0);
    var ptr: [*]u8 = buf;
    var width: usize = fmt.ux64(ret_addr).formatLength();
    for (addrs[0..addrs_len]) |addr| {
        width = @max(width, fmt.ux64(addr).formatLength());
    }
    width *%= @intFromBool(trace.options.write_sidebar);
    for (addrs[0..addrs_len]) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf, width, addr)) |addr_info| {
            ptr = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    if (ret_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, buf, width, ret_addr)) |addr_info| {
            ptr = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    fmt.print(ptr, buf);
}
pub fn printStackTrace(trace: *const debug.Trace, first_addr: usize, frame_addr: usize) callconv(.C) void {
    @setRuntimeSafety(false);
    const start: usize = @atomicRmw(usize, &Level.start, .Add, 0x40000000, .SeqCst);
    if (Level.start > Level.lb_addr +% 1024 *% 1024 *% 1024) {
        return;
    }
    var allocator: mem.SimpleAllocator = .{ .start = start, .next = start, .finish = start };
    var file_map: FileMap = FileMap.init(&allocator, 8);
    var dwarf_info: dwarf.DwarfInfo = dwarf.DwarfInfo.init(@intFromPtr(allocateFile(&allocator, "/proc/self/exe").ptr));
    dwarf_info.scanAllCompileUnits(&allocator);
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 4096, 1));
    var ptr: [*]u8 = buf;
    var itr: StackIterator = if (frame_addr != 0) .{
        .first_addr = null,
        .frame_addr = frame_addr,
    } else .{
        .first_addr = first_addr,
        .frame_addr = @frameAddress(),
    };
    const width: usize = if (trace.options.write_sidebar) maximumSideBarWidth(itr) else 0;
    if (frame_addr != 0) {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, ptr, width, first_addr)) |addr_info| {
            ptr = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    while (itr.next()) |addr| {
        if (writeSourceCodeAtAddress(trace, &allocator, &file_map, &dwarf_info, ptr, width, addr)) |addr_info| {
            ptr = addr_info.finish;
            dwarf_info.addAddressInfo(&allocator).* = addr_info;
        }
    }
    for (dwarf_info.addr_info[0..dwarf_info.addr_info_len], 1..) |*addr_info, idx| {
        printMessage(&allocator, addr_info);
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
