const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const math = @import("./math.zig");
const algo = @import("./algo.zig");
const debug = @import("./debug.zig");
const parse = @import("./parse.zig");
const ascii = @import("./fmt/ascii.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
pub const Assembler = struct {
    buf: []const u8,
    buf_pos: usize = 0,
    const Error = error{InvalidToken};
    pub const Token = struct {
        id: Id,
        start: usize,
        end: usize,
        pub const Id = enum {
            eof,
            space,
            new_line,
            colon,
            comma,
            open_br,
            close_br,
            plus,
            minus,
            star,
            string,
            numeral,
        };
    };
    pub fn next(as: *Assembler) !Token {
        var result = Token{
            .id = .eof,
            .start = as.buf_pos,
            .end = as.buf_pos,
        };
        var state: enum {
            start,
            space,
            new_line,
            string,
            numeral,
            numeral_hex,
        } = .start;
        while (as.buf_pos != as.buf.len) : (as.buf_pos +%= 1) {
            const ch = as.buf[as.buf_pos];
            switch (state) {
                .start => switch (ch) {
                    ',' => {
                        result.id = .comma;
                        as.buf_pos +%= 1;
                        break;
                    },
                    ':' => {
                        result.id = .colon;
                        as.buf_pos +%= 1;
                        break;
                    },
                    '[' => {
                        result.id = .open_br;
                        as.buf_pos +%= 1;
                        break;
                    },
                    ']' => {
                        result.id = .close_br;
                        as.buf_pos +%= 1;
                        break;
                    },
                    '+' => {
                        result.id = .plus;
                        as.buf_pos +%= 1;
                        break;
                    },
                    '-' => {
                        result.id = .minus;
                        as.buf_pos +%= 1;
                        break;
                    },
                    '*' => {
                        result.id = .star;
                        as.buf_pos +%= 1;
                        break;
                    },
                    ' ', '\t' => state = .space,
                    '\n', '\r' => state = .new_line,
                    'a'...'z', 'A'...'Z' => state = .string,
                    '0'...'9' => state = .numeral,
                    else => return error.InvalidToken,
                },
                .space => switch (ch) {
                    ' ', '\t' => {},
                    else => {
                        result.id = .space;
                        break;
                    },
                },
                .new_line => switch (ch) {
                    '\n', '\r', ' ', '\t' => {},
                    else => {
                        result.id = .new_line;
                        break;
                    },
                },
                .string => switch (ch) {
                    'a'...'z', 'A'...'Z', '0'...'9' => {},
                    else => {
                        result.id = .string;
                        break;
                    },
                },
                .numeral => switch (ch) {
                    'x' => state = .numeral_hex,
                    '0'...'9' => {},
                    else => {
                        result.id = .numeral;
                        break;
                    },
                },
                .numeral_hex => switch (ch) {
                    'a'...'f' => {},
                    '0'...'9' => {},
                    else => {
                        result.id = .numeral;
                        break;
                    },
                },
            }
        }
        if (as.buf_pos >= as.buf.len) {
            switch (state) {
                .string => result.id = .string,
                .numeral, .numeral_hex => result.id = .numeral,
                else => {},
            }
        }
        result.end = as.buf_pos;
        return result;
    }
    pub fn init(buf: []const u8) Assembler {
        return .{ .buf = buf };
    }
    const OperandRule = enum {
        register,
        memory,
        immediate,
    };
    const rules = &[_][]const OperandRule{
        &.{},
        &.{.register},
        &.{.memory},
        &.{.immediate},
        &.{ .register, .register },
        &.{ .register, .memory },
        &.{ .memory, .register },
        &.{ .register, .immediate },
        &.{ .memory, .immediate },
        &.{ .register, .register, .immediate },
        &.{ .register, .memory, .immediate },
        &.{ .register, .register, .register },
        &.{ .register, .register, .memory },
    };
    pub fn parseNext(as: *Assembler) ParseError!?ParseResult {
        try as.skip(2, .{ .space, .new_line });
        const mnemonic_tok = as.expect(.string) catch |err| switch (err) {
            error.UnexpectedToken => return if (try as.peek() == .eof) null else err,
            else => return err,
        };
        const mnemonic = mnemonicFromString(as.source(mnemonic_tok)) orelse
            return error.InvalidMnemonic;
        try as.skip(1, .{.space});
        const pos: usize = as.buf_pos;
        for (rules) |rule| {
            var ops = [4]Instruction.Operand{ .none, .none, .none, .none };
            if (as.parseOperandRule(rule, &ops)) {
                return .{
                    .mnemonic = mnemonic,
                    .ops = ops,
                };
            } else |_| {
                as.buf_pos = pos;
            }
        }
        return error.InvalidOperand;
    }
    fn source(as: *Assembler, token: Assembler.Token) []const u8 {
        return as.buf[token.start..token.end];
    }
    fn peek(as: *Assembler) Assembler.Error!Assembler.Token.Id {
        const pos = as.buf_pos;
        const next_tok = try as.next();
        const id = next_tok.id;
        as.buf_pos = pos;
        return id;
    }
    fn expect(as: *Assembler, id: Assembler.Token.Id) ParseError!Assembler.Token {
        const next_tok_id = try as.peek();
        if (next_tok_id == id) return as.next();
        return error.UnexpectedToken;
    }
    fn skip(as: *Assembler, comptime num: comptime_int, tok_ids: [num]Assembler.Token.Id) Assembler.Error!void {
        outer: while (true) {
            const pos = as.buf_pos;
            const next_tok = try as.next();
            for (tok_ids) |tok_id| {
                if (next_tok.id == tok_id) continue :outer;
            }
            as.buf_pos = pos;
            break;
        }
    }
    fn mnemonicFromString(bytes: []const u8) ?Encoding.Mnemonic {
        const ti = @typeInfo(Encoding.Mnemonic).Enum;
        inline for (ti.fields) |field| {
            if (mem.testEqualString(bytes, field.name)) {
                return @field(Encoding.Mnemonic, field.name);
            }
        }
        return null;
    }
    fn parseOperandRule(as: *Assembler, rule: []const OperandRule, ops: *[4]Instruction.Operand) ParseError!void {
        for (rule, 0..) |cond, i| {
            if (i > 0) {
                _ = try as.expect(.comma);
                try as.skip(1, .{.space});
            }
            switch (cond) {
                .register => {
                    const tok = try as.expect(.string);
                    const register = registerFromString(as.source(tok)) orelse
                        return error.InvalidOperand;
                    ops[i] = .{ .register = register };
                },
                .memory => {
                    const memory = try as.parseMemory();
                    ops[i] = .{ .memory = memory };
                },
                .immediate => {
                    const is_neg = if (as.expect(.minus)) |_| true else |_| false;
                    const tok = try as.expect(.numeral);
                    const immediate: Immediate = if (is_neg) blk: {
                        const val: i32 = try parse.any(i32, as.source(tok));
                        break :blk .{ .signed = val * -1 };
                    } else .{ .unsigned = try parse.any(u64, as.source(tok)) };
                    ops[i] = .{ .immediate = immediate };
                },
            }
            try as.skip(1, .{.space});
        }
        try as.skip(1, .{.space});
        const tok = try as.next();
        switch (tok.id) {
            .new_line, .eof => {},
            else => {
                return error.InvalidOperand;
            },
        }
    }
    fn registerFromString(bytes: []const u8) ?Register {
        const ti = @typeInfo(Register).Enum;
        inline for (ti.fields) |field| {
            if (mem.testEqualString(bytes, field.name)) {
                return @field(Register, field.name);
            }
        }
        return null;
    }
    const MemoryRule = enum(u8) {
        base = 0,
        disp = 1,
        rip = 2,
        colon = @intFromEnum(Token.Id.colon),
        index = 4,
        open_br = @intFromEnum(Token.Id.open_br),
        close_br = @intFromEnum(Token.Id.close_br),
        plus = @intFromEnum(Token.Id.plus),
        minus = @intFromEnum(Token.Id.minus),
        star = @intFromEnum(Token.Id.star),
        scale = 10,
    };
    const mem_rules = [_][]const MemoryRule{
        &.{ .open_br, .base, .close_br }, // [ base ]
        &.{ .open_br, .base, .plus, .disp, .close_br }, // [ base + disp ]
        &.{ .open_br, .base, .minus, .disp, .close_br }, // [ base - disp ]
        &.{ .open_br, .disp, .plus, .base, .close_br }, // [ disp + base ]
        &.{ .open_br, .base, .plus, .index, .close_br }, // [ base + index ]
        &.{ .open_br, .base, .plus, .index, .star, .scale, .close_br }, // [ base + index * scale ]
        &.{ .open_br, .index, .star, .scale, .plus, .base, .close_br }, // [ index * scale + base ]
        &.{ .open_br, .base, .plus, .index, .star, .scale, .plus, .disp, .close_br }, // [ base + index * scale + disp ]
        &.{ .open_br, .base, .plus, .index, .star, .scale, .minus, .disp, .close_br }, // [ base + index * scale - disp ]
        &.{ .open_br, .index, .star, .scale, .plus, .base, .plus, .disp, .close_br }, // [ index * scale + base + disp ]
        &.{ .open_br, .index, .star, .scale, .plus, .base, .minus, .disp, .close_br }, // [ index * scale + base - disp ]
        &.{ .open_br, .disp, .plus, .index, .star, .scale, .plus, .base, .close_br }, // [ disp + index * scale + base ]
        &.{ .open_br, .disp, .plus, .base, .plus, .index, .star, .scale, .close_br }, // [ disp + base + index * scale ]
        &.{ .open_br, .base, .plus, .disp, .plus, .index, .star, .scale, .close_br }, // [ base + disp + index * scale ]
        &.{ .open_br, .base, .minus, .disp, .plus, .index, .star, .scale, .close_br }, // [ base - disp + index * scale ]
        &.{ .open_br, .base, .plus, .disp, .plus, .scale, .star, .index, .close_br }, // [ base + disp + scale * index ]
        &.{ .open_br, .base, .minus, .disp, .plus, .scale, .star, .index, .close_br }, // [ base - disp + scale * index ]
        &.{ .open_br, .rip, .plus, .disp, .close_br }, // [ rip + disp ]
        &.{ .open_br, .rip, .minus, .disp, .close_br }, // [ rig - disp ]
        &.{ .open_br, .rip, .plus, .base, .close_br }, // [ rig - disp ]
        &.{ .base, .colon, .disp }, // seg:disp
    };
    fn parseMemory(as: *Assembler) ParseError!Memory {
        const ptr_size: ?Memory.PtrSize = blk: {
            const pos = as.buf_pos;
            const ptr_size = as.parsePtrSize() catch |err| switch (err) {
                error.UnexpectedToken => {
                    as.buf_pos = pos;
                    break :blk null;
                },
                else => return err,
            };
            break :blk ptr_size;
        };
        try as.skip(1, .{.space});
        const pos = as.buf_pos;
        for (mem_rules) |rule| {
            if (as.parseMemoryRule(rule)) |res| {
                if (res.rip) {
                    if (res.base != .none or
                        res.scale_index != null or
                        res.offset != null)
                    {
                        return error.InvalidMemoryOperand;
                    }
                    return Memory.rip(ptr_size orelse .qword, res.disp orelse 0);
                }
                switch (res.base) {
                    .none => {},
                    .register => |base| {
                        if (res.rip)
                            return error.InvalidMemoryOperand;
                        if (res.offset) |offset| {
                            if (res.scale_index != null or res.disp != null)
                                return error.InvalidMemoryOperand;
                            return Memory.moffs(base, offset);
                        }
                        return Memory.sib(ptr_size orelse .qword, .{
                            .base = .{ .register = base },
                            .scale_index = res.scale_index,
                            .disp = res.disp orelse 0,
                        });
                    },
                    .frame => unreachable,
                }
                return error.InvalidMemoryOperand;
            } else |_| {
                as.buf_pos = pos;
            }
        }
        return error.InvalidOperand;
    }
    const MemoryParseResult = struct {
        rip: bool = false,
        base: Memory.Base = .none,
        scale_index: ?Memory.ScaleIndex = null,
        disp: ?i32 = null,
        offset: ?u64 = null,
    };
    fn parseMemoryRule(as: *Assembler, rule: []const MemoryRule) ParseError!MemoryParseResult {
        var res: MemoryParseResult = .{};
        for (rule, 0..) |cond, i| {
            switch (cond) {
                .open_br, .close_br, .plus, .minus, .star, .colon => {
                    _ = try as.expect(@enumFromInt(@intFromEnum(cond)));
                },
                .base => {
                    const tok = try as.expect(.string);
                    res.base = .{ .register = registerFromString(as.source(tok)) orelse return error.InvalidMemoryOperand };
                },
                .rip => {
                    const tok = try as.expect(.string);
                    if (!mem.testEqualString(as.source(tok), "rip")) return error.InvalidMemoryOperand;
                    res.rip = true;
                },
                .index => {
                    const tok = try as.expect(.string);
                    const index = registerFromString(as.source(tok)) orelse
                        return error.InvalidMemoryOperand;
                    if (res.scale_index) |*si| {
                        si.index = index;
                    } else {
                        res.scale_index = .{ .scale = 1, .index = index };
                    }
                },
                .scale => {
                    const tok = try as.expect(.numeral);
                    const scale = try parse.any(u2, as.source(tok));
                    if (res.scale_index) |*si| {
                        si.scale = scale;
                    } else {
                        res.scale_index = .{ .scale = scale, .index = undefined };
                    }
                },
                .disp => {
                    const tok = try as.expect(.numeral);
                    const is_neg = blk: {
                        if (i > 0) {
                            if (rule[i - 1] == .minus) break :blk true;
                        }
                        break :blk false;
                    };
                    if (parse.any(i32, as.source(tok))) |disp| {
                        res.disp = if (is_neg) -1 * disp else disp;
                    } else |err| switch (err) {
                        error.Overflow => {
                            if (is_neg) return err;
                            switch (res.base) {
                                .none => {},
                                .register => |base| if (base.class() != .segment) return err,
                                .frame => unreachable,
                            }
                            const offset: u64 = try parse.any(u64, as.source(tok));
                            res.offset = offset;
                        },
                        else => return err,
                    }
                },
            }
            try as.skip(1, .{.space});
        }
        return res;
    }
    fn parsePtrSize(as: *Assembler) ParseError!Memory.PtrSize {
        const size = try as.expect(.string);
        try as.skip(1, .{.space});
        const ptr = try as.expect(.string);
        const size_raw = as.source(size);
        const ptr_raw = as.source(ptr);
        const len = size_raw.len + ptr_raw.len + 1;
        var buf: ["qword ptr".len]u8 = undefined;
        if (len > buf.len) return error.InvalidPtrSize;
        for (size_raw, 0..) |c, i| {
            buf[i] = ascii.toLower(c);
        }
        buf[size_raw.len] = ' ';
        for (ptr_raw, 0..) |c, i| {
            buf[size_raw.len + i + 1] = ascii.toLower(c);
        }
        const slice = buf[0..len];
        if (mem.testEqualString(slice, "qword ptr")) return .qword;
        if (mem.testEqualString(slice, "dword ptr")) return .dword;
        if (mem.testEqualString(slice, "word ptr")) return .word;
        if (mem.testEqualString(slice, "byte ptr")) return .byte;
        if (mem.testEqualString(slice, "tbyte ptr")) return .tbyte;
        return error.InvalidPtrSize;
    }
};
pub fn assemble(as: *Assembler, writer: anytype) !void {
    while (try as.next()) |parsed_inst| {
        const inst = try Instruction.new(.none, parsed_inst.mnemonic, &parsed_inst.ops);
        try inst.encode(writer, .{});
    }
}
const ParseResult = struct {
    mnemonic: Encoding.Mnemonic,
    ops: [4]Instruction.Operand,
};
const ParseError = error{
    UnexpectedToken,
    InvalidMnemonic,
    InvalidOperand,
    InvalidRegister,
    InvalidPtrSize,
    InvalidMemoryOperand,
    InvalidScaleIndex,
    InvalidEncoding,
    Overflow,
    InvalidCharacter,
    BadParse,
} || Assembler.Error;
pub const Register = enum(u7) {
    rax,
    rcx,
    rdx,
    rbx,
    rsp,
    rbp,
    rsi,
    rdi,
    r8,
    r9,
    r10,
    r11,
    r12,
    r13,
    r14,
    r15,
    eax,
    ecx,
    edx,
    ebx,
    esp,
    ebp,
    esi,
    edi,
    r8d,
    r9d,
    r10d,
    r11d,
    r12d,
    r13d,
    r14d,
    r15d,
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,
    r8w,
    r9w,
    r10w,
    r11w,
    r12w,
    r13w,
    r14w,
    r15w,
    al,
    cl,
    dl,
    bl,
    spl,
    bpl,
    sil,
    dil,
    r8b,
    r9b,
    r10b,
    r11b,
    r12b,
    r13b,
    r14b,
    r15b,
    ah,
    ch,
    dh,
    bh,
    ymm0,
    ymm1,
    ymm2,
    ymm3,
    ymm4,
    ymm5,
    ymm6,
    ymm7,
    ymm8,
    ymm9,
    ymm10,
    ymm11,
    ymm12,
    ymm13,
    ymm14,
    ymm15,
    xmm0,
    xmm1,
    xmm2,
    xmm3,
    xmm4,
    xmm5,
    xmm6,
    xmm7,
    xmm8,
    xmm9,
    xmm10,
    xmm11,
    xmm12,
    xmm13,
    xmm14,
    xmm15,
    mm0,
    mm1,
    mm2,
    mm3,
    mm4,
    mm5,
    mm6,
    mm7,
    st0,
    st1,
    st2,
    st3,
    st4,
    st5,
    st6,
    st7,
    es,
    cs,
    ss,
    ds,
    fs,
    gs,
    none,
    pub const Class = enum {
        general_purpose,
        segment,
        x87,
        mmx,
        sse,
    };
    pub fn class(register: Register) Class {
        return switch (@intFromEnum(register)) {
            @intFromEnum(Register.rax)...@intFromEnum(Register.r15) => .general_purpose,
            @intFromEnum(Register.eax)...@intFromEnum(Register.r15d) => .general_purpose,
            @intFromEnum(Register.ax)...@intFromEnum(Register.r15w) => .general_purpose,
            @intFromEnum(Register.al)...@intFromEnum(Register.r15b) => .general_purpose,
            @intFromEnum(Register.ah)...@intFromEnum(Register.bh) => .general_purpose,
            @intFromEnum(Register.ymm0)...@intFromEnum(Register.ymm15) => .sse,
            @intFromEnum(Register.xmm0)...@intFromEnum(Register.xmm15) => .sse,
            @intFromEnum(Register.mm0)...@intFromEnum(Register.mm7) => .mmx,
            @intFromEnum(Register.st0)...@intFromEnum(Register.st7) => .x87,
            @intFromEnum(Register.es)...@intFromEnum(Register.gs) => .segment,
            else => unreachable,
        };
    }
    pub fn id(register: Register) u6 {
        const base = switch (@intFromEnum(register)) {
            @intFromEnum(Register.rax)...@intFromEnum(Register.r15) => @intFromEnum(Register.rax),
            @intFromEnum(Register.eax)...@intFromEnum(Register.r15d) => @intFromEnum(Register.eax),
            @intFromEnum(Register.ax)...@intFromEnum(Register.r15w) => @intFromEnum(Register.ax),
            @intFromEnum(Register.al)...@intFromEnum(Register.r15b) => @intFromEnum(Register.al),
            @intFromEnum(Register.ah)...@intFromEnum(Register.bh) => @intFromEnum(Register.ah) - 4,
            @intFromEnum(Register.ymm0)...@intFromEnum(Register.ymm15) => @intFromEnum(Register.ymm0) - 16,
            @intFromEnum(Register.xmm0)...@intFromEnum(Register.xmm15) => @intFromEnum(Register.xmm0) - 16,
            @intFromEnum(Register.mm0)...@intFromEnum(Register.mm7) => @intFromEnum(Register.mm0) - 32,
            @intFromEnum(Register.st0)...@intFromEnum(Register.st7) => @intFromEnum(Register.st0) - 40,
            @intFromEnum(Register.es)...@intFromEnum(Register.gs) => @intFromEnum(Register.es) - 48,
            else => unreachable,
        };
        return @as(u6, @intCast(@intFromEnum(register) - base));
    }
    pub fn bitSize(register: Register) u64 {
        return switch (@intFromEnum(register)) {
            @intFromEnum(Register.rax)...@intFromEnum(Register.r15) => 64,
            @intFromEnum(Register.eax)...@intFromEnum(Register.r15d) => 32,
            @intFromEnum(Register.ax)...@intFromEnum(Register.r15w) => 16,
            @intFromEnum(Register.al)...@intFromEnum(Register.r15b) => 8,
            @intFromEnum(Register.ah)...@intFromEnum(Register.bh) => 8,
            @intFromEnum(Register.ymm0)...@intFromEnum(Register.ymm15) => 256,
            @intFromEnum(Register.xmm0)...@intFromEnum(Register.xmm15) => 128,
            @intFromEnum(Register.mm0)...@intFromEnum(Register.mm7) => 64,
            @intFromEnum(Register.st0)...@intFromEnum(Register.st7) => 80,
            @intFromEnum(Register.es)...@intFromEnum(Register.gs) => 16,
            else => unreachable,
        };
    }
    pub fn isExtended(register: Register) bool {
        return switch (@intFromEnum(register)) {
            @intFromEnum(Register.r8)...@intFromEnum(Register.r15) => true,
            @intFromEnum(Register.r8d)...@intFromEnum(Register.r15d) => true,
            @intFromEnum(Register.r8w)...@intFromEnum(Register.r15w) => true,
            @intFromEnum(Register.r8b)...@intFromEnum(Register.r15b) => true,
            @intFromEnum(Register.ymm8)...@intFromEnum(Register.ymm15) => true,
            @intFromEnum(Register.xmm8)...@intFromEnum(Register.xmm15) => true,
            else => false,
        };
    }
    pub fn enc(register: Register) u4 {
        const base = switch (@intFromEnum(register)) {
            @intFromEnum(Register.rax)...@intFromEnum(Register.r15) => @intFromEnum(Register.rax),
            @intFromEnum(Register.eax)...@intFromEnum(Register.r15d) => @intFromEnum(Register.eax),
            @intFromEnum(Register.ax)...@intFromEnum(Register.r15w) => @intFromEnum(Register.ax),
            @intFromEnum(Register.al)...@intFromEnum(Register.r15b) => @intFromEnum(Register.al),
            @intFromEnum(Register.ah)...@intFromEnum(Register.bh) => @intFromEnum(Register.ah) - 4,
            @intFromEnum(Register.ymm0)...@intFromEnum(Register.ymm15) => @intFromEnum(Register.ymm0),
            @intFromEnum(Register.xmm0)...@intFromEnum(Register.xmm15) => @intFromEnum(Register.xmm0),
            @intFromEnum(Register.mm0)...@intFromEnum(Register.mm7) => @intFromEnum(Register.mm0),
            @intFromEnum(Register.st0)...@intFromEnum(Register.st7) => @intFromEnum(Register.st0),
            @intFromEnum(Register.es)...@intFromEnum(Register.gs) => @intFromEnum(Register.es),
            else => unreachable,
        };
        return @as(u4, @truncate(@intFromEnum(register) - base));
    }
    pub fn lowEnc(register: Register) u3 {
        return @as(u3, @truncate(register.enc()));
    }
    pub fn toBitSize(register: Register, bit_size: u64) Register {
        return switch (bit_size) {
            8 => register.to8(),
            16 => register.to16(),
            32 => register.to32(),
            64 => register.to64(),
            128 => register.to128(),
            256 => register.to256(),
            else => unreachable,
        };
    }
    fn gpBase(register: Register) u7 {
        debug.assert(register.class() == .general_purpose);
        return switch (@intFromEnum(register)) {
            @intFromEnum(Register.rax)...@intFromEnum(Register.r15) => @intFromEnum(Register.rax),
            @intFromEnum(Register.eax)...@intFromEnum(Register.r15d) => @intFromEnum(Register.eax),
            @intFromEnum(Register.ax)...@intFromEnum(Register.r15w) => @intFromEnum(Register.ax),
            @intFromEnum(Register.al)...@intFromEnum(Register.r15b) => @intFromEnum(Register.al),
            @intFromEnum(Register.ah)...@intFromEnum(Register.bh) => @intFromEnum(Register.ah) - 4,
            else => unreachable,
        };
    }
    pub fn to64(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.gpBase() + @intFromEnum(Register.rax)));
    }
    pub fn to32(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.gpBase() + @intFromEnum(Register.eax)));
    }
    pub fn to16(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.gpBase() + @intFromEnum(Register.ax)));
    }
    pub fn to8(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.gpBase() + @intFromEnum(Register.al)));
    }
    fn sseBase(register: Register) u7 {
        debug.assert(register.class() == .sse);
        return switch (@intFromEnum(register)) {
            @intFromEnum(Register.ymm0)...@intFromEnum(Register.ymm15) => @intFromEnum(Register.ymm0),
            @intFromEnum(Register.xmm0)...@intFromEnum(Register.xmm15) => @intFromEnum(Register.xmm0),
            else => unreachable,
        };
    }
    pub fn to256(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.sseBase() + @intFromEnum(Register.ymm0)));
    }
    pub fn to128(register: Register) Register {
        return @as(Register, @enumFromInt(@intFromEnum(register) - register.sseBase() + @intFromEnum(Register.xmm0)));
    }
};
pub const FrameIndex = enum(u32) {
    // This index refers to the start of the arguments passed to this function
    args_frame,
    // This index refers to the return address pushed by a `call` and popped by a `ret`.
    ret_addr,
    // This index refers to the base pointer pushed in the prologue and popped in the epilogue.
    base_ptr,
    // This index refers to the entire stack frame.
    stack_frame,
    // This index refers to the start of the call frame for arguments passed to called functions
    call_frame,
    // Other indices are used for local variable stack slots
    _,
    pub const named_count = @typeInfo(FrameIndex).Enum.fields.len;
    pub fn isNamed(fi: FrameIndex) bool {
        return @intFromEnum(fi) < named_count;
    }
    fn formatWriteBuf(fi: FrameIndex, buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        ptr[0..12].* = "FrameIndex".*;
        ptr += 12;
        if (fi.isNamed()) {
            ptr[0] = '.';
            ptr += 1;
            @memcpy(ptr, @tagName(fi));
            ptr += @tagName(fi).len;
        } else {
            ptr[0] = '(';
            ptr += 1;
            //try std.fmt.formatType(@intFromEnum(fi), fmt, options, writer, 0);
            ptr[0] = ')';
            ptr += 1;
        }
    }
};
pub const Memory = union(enum) {
    sib: Sib,
    rip: Rip,
    moffs: Moffs,
    pub const Base = union(enum) {
        none,
        register: Register,
        frame: FrameIndex,
        pub const Tag = @typeInfo(Base).Union.tag_type.?;
        pub fn isExtended(self: Base) bool {
            return switch (self) {
                .none, .frame => false, // neither rsp nor rbp are extended
                .register => |register| register.isExtended(),
            };
        }
    };
    pub const ScaleIndex = struct {
        scale: u4,
        index: Register,
        const none = ScaleIndex{ .scale = 0, .index = undefined };
    };
    pub const PtrSize = enum {
        byte,
        word,
        dword,
        qword,
        tbyte,
        xword,
        yword,
        zword,
        pub fn fromSize(size: u32) PtrSize {
            return switch (size) {
                1...1 => .byte,
                2...2 => .word,
                3...4 => .dword,
                5...8 => .qword,
                9...16 => .xword,
                17...32 => .yword,
                33...64 => .zword,
                else => unreachable,
            };
        }
        pub fn fromBitSize(bit_size: u64) PtrSize {
            return switch (bit_size) {
                8 => .byte,
                16 => .word,
                32 => .dword,
                64 => .qword,
                80 => .tbyte,
                128 => .xword,
                256 => .yword,
                512 => .zword,
                else => unreachable,
            };
        }
        pub fn bitSize(s: PtrSize) u64 {
            return switch (s) {
                .byte => 8,
                .word => 16,
                .dword => 32,
                .qword => 64,
                .tbyte => 80,
                .xword => 128,
                .yword => 256,
                .zword => 512,
            };
        }
    };
    pub const Sib = struct {
        ptr_size: PtrSize,
        base: Base,
        scale_index: ScaleIndex,
        disp: i32,
    };
    pub const Rip = struct {
        ptr_size: PtrSize,
        disp: i32,
    };
    pub const Moffs = struct {
        seg: Register,
        offset: u64,
    };
    pub fn moffs(register: Register, offset: u64) Memory {
        debug.assert(register.class() == .segment);
        return .{ .moffs = .{ .seg = register, .offset = offset } };
    }
    pub fn sib(ptr_size: PtrSize, args: struct {
        disp: i32 = 0,
        base: Base = .none,
        scale_index: ?ScaleIndex = null,
    }) Memory {
        if (args.scale_index) |si| debug.assert(@popCount(si.scale) == 1);
        return .{ .sib = .{
            .base = args.base,
            .disp = args.disp,
            .ptr_size = ptr_size,
            .scale_index = if (args.scale_index) |si| si else ScaleIndex.none,
        } };
    }
    pub fn rip(ptr_size: PtrSize, disp: i32) Memory {
        return .{ .rip = .{ .ptr_size = ptr_size, .disp = disp } };
    }
    pub fn isSegmentRegister(memory: Memory) bool {
        return switch (memory) {
            .moffs => true,
            .rip => false,
            .sib => |s| switch (s.base) {
                .none, .frame => false,
                .register => |register| register.class() == .segment,
            },
        };
    }
    pub fn base(memory: Memory) Base {
        return switch (memory) {
            .moffs => |m| .{ .register = m.seg },
            .sib => |s| s.base,
            .rip => .none,
        };
    }
    pub fn scaleIndex(memory: Memory) ?ScaleIndex {
        return switch (memory) {
            .moffs, .rip => null,
            .sib => |s| if (s.scale_index.scale > 0) s.scale_index else null,
        };
    }
    pub fn bitSize(memory: Memory) u64 {
        return switch (memory) {
            .rip => |r| r.ptr_size.bitSize(),
            .sib => |s| s.ptr_size.bitSize(),
            .moffs => 64,
        };
    }
};
pub const Immediate = union(enum) {
    signed: i32,
    unsigned: u64,
    pub fn u(x: u64) Immediate {
        return .{ .unsigned = x };
    }
    pub fn s(x: i32) Immediate {
        return .{ .signed = x };
    }
    pub fn asUnsigned(immediate: Immediate, bit_size: u64) u64 {
        return switch (immediate) {
            .signed => |x| switch (bit_size) {
                1, 8 => @as(u8, @bitCast(@as(i8, @intCast(x)))),
                16 => @as(u16, @bitCast(@as(i16, @intCast(x)))),
                32, 64 => @as(u32, @bitCast(x)),
                else => unreachable,
            },
            .unsigned => |x| switch (bit_size) {
                1, 8 => @as(u8, @intCast(x)),
                16 => @as(u16, @intCast(x)),
                32 => @as(u32, @intCast(x)),
                64 => x,
                else => unreachable,
            },
        };
    }
};
pub const Instruction = struct {
    prefix: Prefix = .none,
    encoding: Encoding,
    ops: [4]Operand = .{.none} ** 4,
    pub const Prefix = enum(u3) {
        none,
        lock,
        rep,
        repe,
        repz,
        repne,
        repnz,
    };
    pub const Operand = union(enum) {
        none,
        register: Register,
        memory: Memory,
        immediate: Immediate,
        /// Returns the bitsize of the operand.
        pub fn bitSize(op: Operand) u64 {
            return switch (op) {
                .none => unreachable,
                .register => |register| register.bitSize(),
                .memory => |memory| memory.bitSize(),
                .immediate => unreachable,
            };
        }
        /// Returns true if the operand is a segment register.
        /// Asserts the operand is either register or memory.
        pub fn isSegmentRegister(op: Operand) bool {
            return switch (op) {
                .none => unreachable,
                .register => |register| register.class() == .segment,
                .memory => |memory| memory.isSegmentRegister(),
                .immediate => unreachable,
            };
        }
        pub fn isBaseExtended(op: Operand) bool {
            return switch (op) {
                .none, .immediate => false,
                .register => |register| register.isExtended(),
                .memory => |memory| memory.base().isExtended(),
            };
        }
        pub fn isIndexExtended(op: Operand) bool {
            return switch (op) {
                .none, .register, .immediate => false,
                .memory => |memory| if (memory.scaleIndex()) |si| si.index.isExtended() else false,
            };
        }
        const FormatContext = struct {
            op: Operand,
            enc_op: Encoding.Op,
        };
    };
    pub fn new(prefix: Prefix, mnemonic: Encoding.Mnemonic, ops: []const Operand) !Instruction {
        const encoding = (try Encoding.findByMnemonic(prefix, mnemonic, ops)) orelse {
            return error.InvalidInstruction;
        };
        var inst = Instruction{
            .prefix = prefix,
            .encoding = encoding,
            .ops = [1]Operand{.none} ** 4,
        };
        @memcpy(inst.ops[0..ops.len], ops);
        return inst;
    }
    /// Encodes legacy prefixes
    pub fn writeLegacyPrefixes(buf: [*]u8, prefixes: LegacyPrefixes) usize {
        var ptr: [*]u8 = buf;
        if (@as(u16, @bitCast(prefixes)) != 0) {
            ptr[0] = 0xf0;
            ptr += @intFromBool(prefixes.prefix_f0);
            ptr[0] = 0xf2;
            ptr += @intFromBool(prefixes.prefix_f2);
            ptr[0] = 0xf2;
            ptr += @intFromBool(prefixes.prefix_f2);
            ptr[0] = 0xf3;
            ptr += @intFromBool(prefixes.prefix_f3);
            ptr[0] = 0x2e;
            ptr += @intFromBool(prefixes.prefix_2e);
            ptr[0] = 0x36;
            ptr += @intFromBool(prefixes.prefix_36);
            ptr[0] = 0x26;
            ptr += @intFromBool(prefixes.prefix_26);
            ptr[0] = 0x64;
            ptr += @intFromBool(prefixes.prefix_64);
            ptr[0] = 0x65;
            ptr += @intFromBool(prefixes.prefix_65);
            ptr[0] = 0x3e;
            ptr += @intFromBool(prefixes.prefix_3e);
            ptr[0] = 0x66;
            ptr += @intFromBool(prefixes.prefix_66);
            ptr[0] = 0x67;
            ptr += @intFromBool(prefixes.prefix_67);
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    /// Use 16 bit operand size
    ///
    /// Note that this flag is overridden by REX.W, if both are present.
    pub fn writePrefix16BitMode(buf: [*]u8) usize {
        buf[0] = 0x66;
        return 1;
    }
    /// Encodes a REX prefix byte given all the fields
    ///
    /// Use this byte whenever you need 64 bit operation,
    /// or one of register, index, r/m, base, or opcode-register might be extended.
    ///
    /// See struct `Rex` for a description of each field.
    pub fn writeRex(buf: [*]u8, fields: Rex) usize {
        if (!fields.present and !fields.isSet()) return 0;
        var byte: u8 = 0b0100_0000;
        if (fields.w) byte |= 0b1000;
        if (fields.r) byte |= 0b0100;
        if (fields.x) byte |= 0b0010;
        if (fields.b) byte |= 0b0001;
        buf[0] = byte;
        return 1;
    }
    /// Encodes a VEX prefix given all the fields
    ///
    /// See struct `Vex` for a description of each field.
    pub fn writeVex(buf: [*]u8, fields: Vex) usize {
        var ptr: [*]u8 = buf;
        if (fields.is3Byte()) {
            ptr[0] = 0b1100_0100;
            ptr += 1;
            ptr[0] =
                @as(u8, ~@intFromBool(fields.r)) << 7 |
                @as(u8, ~@intFromBool(fields.x)) << 6 |
                @as(u8, ~@intFromBool(fields.b)) << 5 |
                @as(u8, @intFromEnum(fields.m)) << 0;
            ptr += 1;
            ptr[0] =
                @as(u8, @intFromBool(fields.w)) << 7 |
                @as(u8, ~fields.v.enc()) << 3 |
                @as(u8, @intFromBool(fields.l)) << 2 |
                @as(u8, @intFromEnum(fields.p)) << 0;
            ptr += 1;
        } else {
            ptr[0] = 0b1100_0101;
            ptr += 1;
            ptr[0] =
                @as(u8, ~@intFromBool(fields.r)) << 7 |
                @as(u8, ~fields.v.enc()) << 3 |
                @as(u8, @intFromBool(fields.l)) << 2 |
                @as(u8, @intFromEnum(fields.p)) << 0;
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    // ------
    // Opcode
    // ------
    /// Encodes a 1 byte opcode
    pub fn writeOpcode1Byte(buf: [*]u8, opcode: u8) usize {
        buf[0] = opcode;
        return 1;
    }
    /// Encodes a 2 byte opcode
    ///
    /// e.g. IMUL has the opcode 0x0f 0xaf, so you use
    ///
    /// opcode_2byte(buf, 0x0f, 0xaf);
    pub fn writeOpcode2Byte(buf: [*]u8, prefix: u8, opcode: u8) usize {
        buf[0] = prefix;
        buf[1] = opcode;
        return 2;
    }
    /// Encodes a 3 byte opcode
    ///
    /// e.g. MOVSD has the opcode 0xf2 0x0f 0x10
    ///
    /// opcode_3byte(buf, 0xf2, 0x0f, 0x10);
    pub fn writeOpcode3Byte(buf: [*]u8, prefix_1: u8, prefix_2: u8, opcode: u8) usize {
        buf[0] = prefix_1;
        buf[1] = prefix_2;
        buf[2] = opcode;
        return 3;
    }
    /// Encodes a 1 byte opcode with a register field
    ///
    /// Remember to add a REX prefix byte if register is extended!
    pub fn writeOpcodeWithReg(buf: [*]u8, opcode: u8, register: u3) usize {
        debug.assert(opcode & 0b111 == 0);
        buf[0] = opcode | register;
        return 1;
    }
    // ------
    // ModR/M
    // ------
    /// Construct a ModR/M byte given all the fields
    ///
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRm(buf: [*]u8, mod: u2, reg_or_opx: u3, rm: u3) usize {
        buf[0] = @as(u8, mod) << 6 | @as(u8, reg_or_opx) << 3 | rm;
        return 1;
    }
    /// Construct a ModR/M byte using direct r/m addressing
    /// r/m effective address: r/m
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmDirect(buf: [*]u8, reg_or_opx: u3, rm: u3) usize {
        return writeModRm(buf, 0b11, reg_or_opx, rm);
    }
    /// Construct a ModR/M byte using indirect r/m addressing
    /// r/m effective address: [r/m]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmIndirectDisp0(buf: [*]u8, reg_or_opx: u3, rm: u3) usize {
        debug.assert(rm != 4 and rm != 5);
        return writeModRm(buf, 0b00, reg_or_opx, rm);
    }
    /// Construct a ModR/M byte using indirect SIB addressing
    /// r/m effective address: [SIB]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmSIBDisp0(buf: [*]u8, reg_or_opx: u3) usize {
        return writeModRm(buf, 0b00, reg_or_opx, 0b100);
    }
    /// Construct a ModR/M byte using RIP-relative addressing
    /// r/m effective address: [RIP + disp32]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmRIPDisp32(buf: [*]u8, reg_or_opx: u3) usize {
        return writeModRm(buf, 0b00, reg_or_opx, 0b101);
    }
    /// Construct a ModR/M byte using indirect r/m with a 8bit displacement
    /// r/m effective address: [r/m + disp8]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmIndirectDisp8(buf: [*]u8, reg_or_opx: u3, rm: u3) usize {
        debug.assert(rm != 4);
        return writeModRm(buf, 0b01, reg_or_opx, rm);
    }
    /// Construct a ModR/M byte using indirect SIB with a 8bit displacement
    /// r/m effective address: [SIB + disp8]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmSIBDisp8(buf: [*]u8, reg_or_opx: u3) usize {
        return writeModRm(buf, 0b01, reg_or_opx, 0b100);
    }
    /// Construct a ModR/M byte using indirect r/m with a 32bit displacement
    /// r/m effective address: [r/m + disp32]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmIndirectDisp32(buf: [*]u8, reg_or_opx: u3, rm: u3) usize {
        debug.assert(rm != 4);
        return writeModRm(buf, 0b10, reg_or_opx, rm);
    }
    /// Construct a ModR/M byte using indirect SIB with a 32bit displacement
    /// r/m effective address: [SIB + disp32]
    ///
    /// Note register's effective address is always just register for the ModR/M byte.
    /// Remember to add a REX prefix byte if register or rm are extended!
    pub fn writeModRmSIBDisp32(buf: [*]u8, reg_or_opx: u3) usize {
        return writeModRm(buf, 0b10, reg_or_opx, 0b100);
    }
    // ---
    // SIB
    // ---
    /// Construct a SIB byte given all the fields
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSib(buf: [*]u8, scale: u2, index: u3, base: u3) usize {
        buf[0] = (@as(u8, scale) << 6 | @as(u8, index) << 3 | base);
        return 1;
    }
    /// Construct a SIB byte with scale * index + base, no frills.
    /// r/m effective address: [base + scale * index]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibScaleIndexBase(buf: [*]u8, scale: u2, index: u3, base: u3) usize {
        debug.assert(base != 5);
        return writeSib(buf, scale, index, base);
    }
    /// Construct a SIB byte with scale * index + disp32
    /// r/m effective address: [scale * index + disp32]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibScaleIndexDisp32(buf: [*]u8, scale: u2, index: u3) usize {
        // scale is actually ignored
        // index = 4 means no index if and only if we haven't extended the register
        // TODO enforce this
        // base = 5 means no base, if mod == 0.
        return writeSib(buf, scale, index, 5);
    }
    /// Construct a SIB byte with just base
    /// r/m effective address: [base]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibBase(buf: [*]u8, base: u3) usize {
        debug.assert(base != 5);
        // scale is actually ignored
        // index = 4 means no index
        return writeSib(buf, 0, 4, base);
    }
    /// Construct a SIB byte with just disp32
    /// r/m effective address: [disp32]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibDisp32(buf: [*]u8) usize {
        // scale is actually ignored
        // index = 4 means no index
        // base = 5 means no base, if mod == 0.
        return writeSib(buf, 0, 4, 5);
    }
    /// Construct a SIB byte with scale * index + base + disp8
    /// r/m effective address: [base + scale * index + disp8]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibScaleIndexBaseDisp8(buf: [*]u8, scale: u2, index: u3, base: u3) usize {
        return writeSib(buf, scale, index, base);
    }
    /// Construct a SIB byte with base + disp8, no index
    /// r/m effective address: [base + disp8]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibBaseDisp8(buf: [*]u8, base: u3) usize {
        // scale is ignored
        // index = 4 means no index
        return writeSib(buf, 0, 4, base);
    }
    /// Construct a SIB byte with scale * index + base + disp32
    /// r/m effective address: [base + scale * index + disp32]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibScaleIndexBaseDisp32(buf: [*]u8, scale: u2, index: u3, base: u3) usize {
        return writeSib(buf, scale, index, base);
    }
    /// Construct a SIB byte with base + disp32, no index
    /// r/m effective address: [base + disp32]
    ///
    /// Remember to add a REX prefix byte if index or base are extended!
    pub fn writeSibBaseDisp32(buf: [*]u8, base: u3) usize {
        // scale is ignored
        // index = 4 means no index
        return writeSib(buf, 0, 4, base);
    }
    // -------------------------
    // Trivial (no bit fiddling)
    // -------------------------
    /// Encode an 8 bit displacement
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeDisp8(buf: [*]u8, disp: i8) usize {
        buf[0] = @bitCast(disp);
        return 1;
    }
    /// Encode an 32 bit displacement
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeDisp32(buf: [*]u8, disp: i32) usize {
        @as(*align(1) i32, @ptrCast(buf)).* = disp;
        return 4;
    }
    /// Encode an 8 bit immediate
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeImm8(buf: [*]u8, immediate: u8) usize {
        buf[0] = immediate;
        return 1;
    }
    /// Encode an 16 bit immediate
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeImm16(buf: [*]u8, immediate: u16) usize {
        @as(*align(1) u16, @ptrCast(buf)).* = immediate;
        return 2;
    }
    /// Encode an 32 bit immediate
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeImm32(buf: [*]u8, immediate: u32) usize {
        @as(*align(1) u32, @ptrCast(buf)).* = immediate;
        return 4;
    }
    /// Encode an 64 bit immediate
    ///
    /// It is sign-extended to 64 bits by the cpu.
    pub fn writeImm64(buf: [*]u8, immediate: u64) usize {
        @as(*align(1) u64, @ptrCast(buf)).* = immediate;
        return 8;
    }
    pub fn formatWriteBuf(instr: Instruction, buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        @memcpy(ptr, @tagName(instr.encoding.mnemonic));
        ptr += @tagName(instr.encoding.mnemonic).len;
        for (instr.ops, instr.encoding.data.ops) |op, enc| {
            if (op == .none) {
                continue;
            }
            ptr[0] = ' ';
            ptr += 1;
            if (op == .immediate) {
                ptr += fmt.ux64(op.immediate.asUnsigned(enc.immBitSize())).formatWriteBuf(ptr);
            }
            if (op == .register) {
                @memcpy(ptr, @tagName(op.register));
                ptr += @tagName(op.register).len;
            }
            if (op == .memory) {
                switch (op.memory) {
                    .moffs => |moffs| {
                        @memcpy(ptr, @tagName(moffs.seg));
                        ptr += @tagName(moffs.seg).len;
                        ptr[0] = ':';
                        ptr += 1;
                        ptr += fmt.ux64(moffs.offset).formatWriteBuf(ptr);
                    },
                    .rip => |rip| {
                        @memcpy(ptr, @tagName(rip.ptr_size));
                        ptr += @tagName(rip.ptr_size).len;
                        ptr[0..9].* = " ptr [rip".*;
                        ptr += 9;
                        if (rip.disp != 0) {
                            ptr[0..3].* = if (rip.disp < 0) " - ".* else " + ".*;
                            ptr += 3;
                            ptr += fmt.ux32(math.absoluteVal(rip.disp)).formatWriteBuf(ptr);
                        }
                        ptr[0] = ']';
                        ptr += 1;
                    },
                    .sib => |sib| {
                        var any: bool = false;
                        @memcpy(ptr, @tagName(sib.ptr_size));
                        ptr += @tagName(sib.ptr_size).len;
                        ptr[0..5].* = " ptr ".*;
                        ptr += 5;
                        if (op.memory.isSegmentRegister()) {
                            @memcpy(ptr, @tagName(sib.base.register));
                            ptr += @tagName(sib.base.register).len;
                            ptr[0] = ':';
                            ptr += 1;
                            ptr += fmt.ix32(sib.disp).formatWriteBuf(ptr);
                        } else {
                            ptr[0] = '[';
                            ptr += 1;
                            if (sib.base == .register) {
                                @memcpy(ptr, @tagName(sib.base.register));
                                ptr += @tagName(sib.base.register).len;
                                any = true;
                            }
                            if (sib.base == .frame) {
                                any = true;
                            }
                            if (op.memory.scaleIndex()) |si| {
                                if (any) {
                                    ptr[0..3].* = " + ".*;
                                    ptr += 3;
                                }
                                @memcpy(ptr, @tagName(si.index));
                                ptr += @tagName(si.index).len;
                                ptr[0..3].* = " * ".*;
                                ptr += 3;
                                ptr += fmt.ud64(si.scale).formatWriteBuf(ptr);
                                any = true;
                            }
                            if (sib.disp != 0 or !any) {
                                if (any) {
                                    ptr[0..3].* = if (sib.disp < 0) " - ".* else " + ".*;
                                    ptr += 3;
                                } else if (sib.disp < 0) {
                                    ptr[0] = '-';
                                    ptr += 1;
                                }
                                ptr += fmt.ux32(math.absoluteVal(sib.disp)).formatWriteBuf(ptr);
                                any = true;
                            }
                            ptr[0] = ']';
                            ptr += 1;
                        }
                    },
                }
            }
            ptr[0] = ',';
            ptr += 1;
        }
        ptr -= 1;
        if (ptr[0] != ',') {
            ptr += 1;
        }
        ptr[0] = '\n';
        ptr += 1;
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    pub fn encode(inst: Instruction, buf: [*]u8) usize {
        const enc = inst.encoding;
        const data = enc.data;
        var ptr: [*]u8 = buf;
        if (data.mode.isVex()) {
            ptr += inst.encodeVexPrefix(ptr);
            const opc = inst.encoding.opcode();
            ptr += writeOpcode1Byte(ptr, opc[opc.len - 1]);
        } else {
            ptr += inst.encodeLegacyPrefixes(ptr);
            ptr += inst.encodeMandatoryPrefix(ptr);
            ptr += inst.encodeRexPrefix(ptr);
            ptr += inst.encodeOpcode(ptr);
        }
        switch (data.op_en) {
            .np, .o => {},
            .i, .d => ptr += encodeImm(inst.ops[0].immediate, data.ops[0], ptr),
            .zi, .oi => ptr += encodeImm(inst.ops[1].immediate, data.ops[1], ptr),
            .fd => ptr += writeImm64(ptr, inst.ops[1].memory.moffs.offset),
            .td => ptr += writeImm64(ptr, inst.ops[0].memory.moffs.offset),
            else => {
                const mem_op = switch (data.op_en) {
                    .m, .mi, .m1, .mc, .mr, .mri, .mrc, .mvr => inst.ops[0],
                    .rm, .rmi, .rm0, .vmi => inst.ops[1],
                    .rvm, .rvmr, .rvmi => inst.ops[2],
                    else => unreachable,
                };
                switch (mem_op) {
                    .register => |register| {
                        const rm = switch (data.op_en) {
                            .m, .mi, .m1, .mc, .vmi => enc.modRmExt(),
                            .mr, .mri, .mrc => inst.ops[1].register.lowEnc(),
                            .rm, .rmi, .rm0, .rvm, .rvmr, .rvmi => inst.ops[0].register.lowEnc(),
                            .mvr => inst.ops[2].register.lowEnc(),
                            else => unreachable,
                        };
                        ptr += writeModRmDirect(ptr, rm, register.lowEnc());
                    },
                    .memory => |memory| {
                        const op = switch (data.op_en) {
                            .m, .mi, .m1, .mc, .vmi => .none,
                            .mr, .mri, .mrc => inst.ops[1],
                            .rm, .rmi, .rm0, .rvm, .rvmr, .rvmi => inst.ops[0],
                            .mvr => inst.ops[2],
                            else => unreachable,
                        };
                        ptr += encodeMemory(enc, memory, op, ptr);
                    },
                    else => unreachable,
                }
                switch (data.op_en) {
                    .mi => ptr += encodeImm(inst.ops[1].immediate, data.ops[1], ptr),
                    .rmi, .mri, .vmi => ptr += encodeImm(inst.ops[2].immediate, data.ops[2], ptr),
                    .rvmr => ptr += writeImm8(ptr, @as(u8, inst.ops[3].register.enc()) << 4),
                    .rvmi => ptr += encodeImm(inst.ops[3].immediate, data.ops[3], ptr),
                    else => {},
                }
            },
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    fn encodeOpcode(inst: Instruction, buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        const opcode = inst.encoding.opcode();
        const first = @intFromBool(inst.encoding.mandatoryPrefix() != null);
        const final = opcode.len - 1;
        for (opcode[first..final]) |byte| {
            ptr += writeOpcode1Byte(ptr, byte);
        }
        switch (inst.encoding.data.op_en) {
            .o, .oi => ptr += writeOpcodeWithReg(ptr, opcode[final], inst.ops[0].register.lowEnc()),
            else => ptr += writeOpcode1Byte(ptr, opcode[final]),
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    fn encodeLegacyPrefixes(inst: Instruction, buf: [*]u8) usize {
        const enc = inst.encoding;
        const data = enc.data;
        const op_en = data.op_en;
        var legacy = LegacyPrefixes{};
        switch (inst.prefix) {
            .none => {},
            .lock => legacy.prefix_f0 = true,
            .repne, .repnz => legacy.prefix_f2 = true,
            .rep, .repe, .repz => legacy.prefix_f3 = true,
        }
        switch (data.mode) {
            .short, .rex_short => legacy.set16BitOverride(),
            else => {},
        }
        const segment_override: ?Register = switch (op_en) {
            .i, .zi, .o, .oi, .d, .np => null,
            .fd => inst.ops[1].memory.base().register,
            .td => inst.ops[0].memory.base().register,
            .rm, .rmi, .rm0 => if (inst.ops[1].isSegmentRegister())
                switch (inst.ops[1]) {
                    .register => |register| register,
                    .memory => |memory| memory.base().register,
                    else => unreachable,
                }
            else
                null,
            .m, .mi, .m1, .mc, .mr, .mri, .mrc => if (inst.ops[0].isSegmentRegister())
                switch (inst.ops[0]) {
                    .register => |register| register,
                    .memory => |memory| memory.base().register,
                    else => unreachable,
                }
            else
                null,
            .vmi, .rvm, .rvmr, .rvmi, .mvr => unreachable,
        };
        if (segment_override) |seg| {
            legacy.setSegmentOverride(seg);
        }
        return writeLegacyPrefixes(buf, legacy);
    }
    fn encodeRexPrefix(inst: Instruction, buf: [*]u8) usize {
        const op_en = inst.encoding.data.op_en;
        var rex = Rex{};
        rex.present = inst.encoding.data.mode == .rex;
        rex.w = inst.encoding.data.mode == .long;
        switch (op_en) {
            .np, .i, .zi, .fd, .td, .d => {},
            .o, .oi => rex.b = inst.ops[0].register.isExtended(),
            .m, .mi, .m1, .mc, .mr, .rm, .rmi, .mri, .mrc, .rm0 => {
                const r_op = switch (op_en) {
                    .rm, .rmi, .rm0 => inst.ops[0],
                    .mr, .mri, .mrc => inst.ops[1],
                    else => .none,
                };
                rex.r = r_op.isBaseExtended();
                const b_x_op = switch (op_en) {
                    .rm, .rmi, .rm0 => inst.ops[1],
                    .m, .mi, .m1, .mc, .mr, .mri, .mrc => inst.ops[0],
                    else => unreachable,
                };
                rex.b = b_x_op.isBaseExtended();
                rex.x = b_x_op.isIndexExtended();
            },
            .vmi, .rvm, .rvmr, .rvmi, .mvr => unreachable,
        }
        return writeRex(buf, rex);
    }
    fn encodeVexPrefix(inst: Instruction, buf: [*]u8) usize {
        const op_en = inst.encoding.data.op_en;
        const opc = inst.encoding.opcode();
        const mand_pre = inst.encoding.mandatoryPrefix();
        var vex = Vex{};
        vex.w = inst.encoding.data.mode.isLong();
        switch (op_en) {
            .np, .i, .zi, .fd, .td, .d => {},
            .o, .oi => vex.b = inst.ops[0].register.isExtended(),
            .m, .mi, .m1, .mc, .mr, .rm, .rmi, .mri, .mrc, .rm0, .vmi, .rvm, .rvmr, .rvmi, .mvr => {
                const r_op = switch (op_en) {
                    .rm, .rmi, .rm0, .rvm, .rvmr, .rvmi => inst.ops[0],
                    .mr, .mri, .mrc => inst.ops[1],
                    .mvr => inst.ops[2],
                    .m, .mi, .m1, .mc, .vmi => .none,
                    else => unreachable,
                };
                vex.r = r_op.isBaseExtended();
                const b_x_op = switch (op_en) {
                    .rm, .rmi, .rm0, .vmi => inst.ops[1],
                    .m, .mi, .m1, .mc, .mr, .mri, .mrc, .mvr => inst.ops[0],
                    .rvm, .rvmr, .rvmi => inst.ops[2],
                    else => unreachable,
                };
                vex.b = b_x_op.isBaseExtended();
                vex.x = b_x_op.isIndexExtended();
            },
        }
        vex.l = inst.encoding.data.mode.isVecLong();
        vex.p = if (mand_pre) |mand| switch (mand) {
            0x66 => .@"66",
            0xf2 => .f2,
            0xf3 => .f3,
            else => unreachable,
        } else .none;
        const leading: usize = if (mand_pre) |_| 1 else 0;
        debug.assert(opc[leading] == 0x0f);
        vex.m = switch (opc[leading + 1]) {
            else => .@"0f",
            0x38 => .@"0f38",
            0x3a => .@"0f3a",
        };
        switch (op_en) {
            else => {},
            .vmi => vex.v = inst.ops[0].register,
            .rvm, .rvmr, .rvmi => vex.v = inst.ops[1].register,
        }
        return writeVex(buf, vex);
    }
    fn encodeMandatoryPrefix(inst: Instruction, buf: [*]u8) usize {
        const prefix = inst.encoding.mandatoryPrefix() orelse return 0;
        return writeOpcode1Byte(buf, prefix);
    }
    fn encodeMemory(encoding: Encoding, memory: Memory, operand: Operand, buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        const operand_enc = switch (operand) {
            .register => |register| register.lowEnc(),
            .none => encoding.modRmExt(),
            else => unreachable,
        };
        switch (memory) {
            .moffs => unreachable,
            .sib => |sib| switch (sib.base) {
                .none => {
                    ptr += writeModRmSIBDisp0(ptr, operand_enc);
                    if (memory.scaleIndex()) |si| {
                        const scale = math.log2(u4, si.scale);
                        ptr += writeSibScaleIndexDisp32(ptr, scale, si.index.lowEnc());
                    } else {
                        ptr += writeSibDisp32(ptr);
                    }
                    ptr += writeDisp32(ptr, sib.disp);
                },
                .register => |base| if (base.class() == .segment) {
                    // TODO audit this wrt SIB
                    ptr += writeModRmSIBDisp0(ptr, operand_enc);
                    if (memory.scaleIndex()) |si| {
                        const scale = math.log2(u4, si.scale);
                        ptr += writeSibScaleIndexDisp32(ptr, scale, si.index.lowEnc());
                    } else {
                        ptr += writeSibDisp32(ptr);
                    }
                    ptr += writeDisp32(ptr, sib.disp);
                } else {
                    debug.assert(base.class() == .general_purpose);
                    const dst = base.lowEnc();
                    const src = operand_enc;
                    if (dst == 4 or memory.scaleIndex() != null) {
                        if (sib.disp == 0 and dst != 5) {
                            ptr += writeModRmSIBDisp0(ptr, src);
                            if (memory.scaleIndex()) |si| {
                                const scale = math.log2(u4, si.scale);
                                ptr += writeSibScaleIndexBase(ptr, scale, si.index.lowEnc(), dst);
                            } else {
                                ptr += writeSibBase(ptr, dst);
                            }
                        } else if (math.cast(i8, sib.disp)) |_| {
                            ptr += writeModRmSIBDisp8(ptr, src);
                            if (memory.scaleIndex()) |si| {
                                const scale = math.log2(u4, si.scale);
                                ptr += writeSibScaleIndexBaseDisp8(ptr, scale, si.index.lowEnc(), dst);
                            } else {
                                ptr += writeSibBaseDisp8(ptr, dst);
                            }
                            ptr += writeDisp8(ptr, @as(i8, @truncate(sib.disp)));
                        } else {
                            ptr += writeModRmSIBDisp32(ptr, src);
                            if (memory.scaleIndex()) |si| {
                                const scale = math.log2(u4, si.scale);
                                ptr += writeSibScaleIndexBaseDisp32(ptr, scale, si.index.lowEnc(), dst);
                            } else {
                                ptr += writeSibBaseDisp32(ptr, dst);
                            }
                            ptr += writeDisp32(ptr, sib.disp);
                        }
                    } else {
                        if (sib.disp == 0 and dst != 5) {
                            ptr += writeModRmIndirectDisp0(ptr, src, dst);
                        } else if (math.cast(i8, sib.disp)) |_| {
                            ptr += writeModRmIndirectDisp8(ptr, src, dst);
                            ptr += writeDisp8(ptr, @as(i8, @truncate(sib.disp)));
                        } else {
                            ptr += writeModRmIndirectDisp32(ptr, src, dst);
                            ptr += writeDisp32(ptr, sib.disp);
                        }
                    }
                },
                .frame => {
                    ptr += writeModRmIndirectDisp32(ptr, operand_enc, undefined);
                    ptr += writeDisp32(ptr, undefined);
                },
                // if (!allow_frame_loc) return error.CannotEncode,
            },
            .rip => |rip| {
                ptr += writeModRmRIPDisp32(ptr, operand_enc);
                ptr += writeDisp32(ptr, rip.disp);
            },
        }
        return @intFromPtr(ptr - @intFromPtr(buf));
    }
    fn encodeImm(immediate: Immediate, kind: Encoding.Op, buf: [*]u8) usize {
        const raw: u64 = immediate.asUnsigned(kind.immBitSize());
        switch (kind.immBitSize()) {
            8 => return writeImm8(buf, @intCast(raw)),
            16 => return writeImm16(buf, @intCast(raw)),
            32 => return writeImm32(buf, @intCast(raw)),
            64 => return writeImm64(buf, raw),
            else => unreachable,
        }
    }
};
pub const LegacyPrefixes = packed struct {
    /// LOCK
    prefix_f0: bool = false,
    /// REPNZ, REPNE, REP, Scalar Double-precision
    prefix_f2: bool = false,
    /// REPZ, REPE, REP, Scalar Single-precision
    prefix_f3: bool = false,
    /// CS segment override or Branch not taken
    prefix_2e: bool = false,
    /// SS segment override
    prefix_36: bool = false,
    /// ES segment override
    prefix_26: bool = false,
    /// FS segment override
    prefix_64: bool = false,
    /// GS segment override
    prefix_65: bool = false,
    /// Branch taken
    prefix_3e: bool = false,
    /// Address size override (enables 16 bit address size)
    prefix_67: bool = false,
    /// Operand size override (enables 16 bit operation)
    prefix_66: bool = false,
    padding: u5 = 0,
    pub fn setSegmentOverride(self: *LegacyPrefixes, register: Register) void {
        debug.assert(register.class() == .segment);
        switch (register) {
            .cs => self.prefix_2e = true,
            .ss => self.prefix_36 = true,
            .es => self.prefix_26 = true,
            .fs => self.prefix_64 = true,
            .gs => self.prefix_65 = true,
            .ds => {},
            else => unreachable,
        }
    }
    pub fn set16BitOverride(self: *LegacyPrefixes) void {
        self.prefix_66 = true;
    }
};
pub const Options = struct { allow_frame_loc: bool = false };
pub const Rex = struct {
    w: bool = false,
    r: bool = false,
    x: bool = false,
    b: bool = false,
    present: bool = false,
    pub fn isSet(rex: Rex) bool {
        return rex.w or rex.r or rex.x or rex.b;
    }
};
pub const Vex = struct {
    w: bool = false,
    r: bool = false,
    x: bool = false,
    b: bool = false,
    l: bool = false,
    p: enum(u2) {
        none = 0b00,
        @"66" = 0b01,
        f3 = 0b10,
        f2 = 0b11,
    } = .none,
    m: enum(u5) {
        @"0f" = 0b0_0001,
        @"0f38" = 0b0_0010,
        @"0f3a" = 0b0_0011,
        _,
    } = .@"0f",
    v: Register = .ymm0,
    pub fn is3Byte(vex: Vex) bool {
        return vex.w or vex.x or vex.b or vex.m != .@"0f";
    }
};
pub const tab = [_]Encoding.Entry{
    .{ .adc, .zi, &.{ .al, .imm8 }, &.{0x14}, 0x0, .none, .none },
    .{ .adc, .zi, &.{ .ax, .imm16 }, &.{0x15}, 0x0, .short, .none },
    .{ .adc, .zi, &.{ .eax, .imm32 }, &.{0x15}, 0x0, .none, .none },
    .{ .adc, .zi, &.{ .rax, .imm32s }, &.{0x15}, 0x0, .long, .none },
    .{ .adc, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x2, .none, .none },
    .{ .adc, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x2, .rex, .none },
    .{ .adc, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x2, .short, .none },
    .{ .adc, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x2, .none, .none },
    .{ .adc, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x2, .long, .none },
    .{ .adc, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x2, .short, .none },
    .{ .adc, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x2, .none, .none },
    .{ .adc, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x2, .long, .none },
    .{ .adc, .mr, &.{ .rm8, .r8 }, &.{0x10}, 0x0, .none, .none },
    .{ .adc, .mr, &.{ .rm8, .r8 }, &.{0x10}, 0x0, .rex, .none },
    .{ .adc, .mr, &.{ .rm16, .r16 }, &.{0x11}, 0x0, .short, .none },
    .{ .adc, .mr, &.{ .rm32, .r32 }, &.{0x11}, 0x0, .none, .none },
    .{ .adc, .mr, &.{ .rm64, .r64 }, &.{0x11}, 0x0, .long, .none },
    .{ .adc, .rm, &.{ .r8, .rm8 }, &.{0x12}, 0x0, .none, .none },
    .{ .adc, .rm, &.{ .r8, .rm8 }, &.{0x12}, 0x0, .rex, .none },
    .{ .adc, .rm, &.{ .r16, .rm16 }, &.{0x13}, 0x0, .short, .none },
    .{ .adc, .rm, &.{ .r32, .rm32 }, &.{0x13}, 0x0, .none, .none },
    .{ .adc, .rm, &.{ .r64, .rm64 }, &.{0x13}, 0x0, .long, .none },
    .{ .add, .zi, &.{ .al, .imm8 }, &.{0x4}, 0x0, .none, .none },
    .{ .add, .zi, &.{ .ax, .imm16 }, &.{0x5}, 0x0, .short, .none },
    .{ .add, .zi, &.{ .eax, .imm32 }, &.{0x5}, 0x0, .none, .none },
    .{ .add, .zi, &.{ .rax, .imm32s }, &.{0x5}, 0x0, .long, .none },
    .{ .add, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x0, .none, .none },
    .{ .add, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x0, .rex, .none },
    .{ .add, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x0, .short, .none },
    .{ .add, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x0, .none, .none },
    .{ .add, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x0, .long, .none },
    .{ .add, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x0, .short, .none },
    .{ .add, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x0, .none, .none },
    .{ .add, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x0, .long, .none },
    .{ .add, .mr, &.{ .rm8, .r8 }, &.{0x0}, 0x0, .none, .none },
    .{ .add, .mr, &.{ .rm8, .r8 }, &.{0x0}, 0x0, .rex, .none },
    .{ .add, .mr, &.{ .rm16, .r16 }, &.{0x1}, 0x0, .short, .none },
    .{ .add, .mr, &.{ .rm32, .r32 }, &.{0x1}, 0x0, .none, .none },
    .{ .add, .mr, &.{ .rm64, .r64 }, &.{0x1}, 0x0, .long, .none },
    .{ .add, .rm, &.{ .r8, .rm8 }, &.{0x2}, 0x0, .none, .none },
    .{ .add, .rm, &.{ .r8, .rm8 }, &.{0x2}, 0x0, .rex, .none },
    .{ .add, .rm, &.{ .r16, .rm16 }, &.{0x3}, 0x0, .short, .none },
    .{ .add, .rm, &.{ .r32, .rm32 }, &.{0x3}, 0x0, .none, .none },
    .{ .add, .rm, &.{ .r64, .rm64 }, &.{0x3}, 0x0, .long, .none },
    .{ .@"and", .zi, &.{ .al, .imm8 }, &.{0x24}, 0x0, .none, .none },
    .{ .@"and", .zi, &.{ .ax, .imm16 }, &.{0x25}, 0x0, .short, .none },
    .{ .@"and", .zi, &.{ .eax, .imm32 }, &.{0x25}, 0x0, .none, .none },
    .{ .@"and", .zi, &.{ .rax, .imm32s }, &.{0x25}, 0x0, .long, .none },
    .{ .@"and", .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x4, .none, .none },
    .{ .@"and", .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x4, .rex, .none },
    .{ .@"and", .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x4, .short, .none },
    .{ .@"and", .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x4, .none, .none },
    .{ .@"and", .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x4, .long, .none },
    .{ .@"and", .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x4, .short, .none },
    .{ .@"and", .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x4, .none, .none },
    .{ .@"and", .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x4, .long, .none },
    .{ .@"and", .mr, &.{ .rm8, .r8 }, &.{0x20}, 0x0, .none, .none },
    .{ .@"and", .mr, &.{ .rm8, .r8 }, &.{0x20}, 0x0, .rex, .none },
    .{ .@"and", .mr, &.{ .rm16, .r16 }, &.{0x21}, 0x0, .short, .none },
    .{ .@"and", .mr, &.{ .rm32, .r32 }, &.{0x21}, 0x0, .none, .none },
    .{ .@"and", .mr, &.{ .rm64, .r64 }, &.{0x21}, 0x0, .long, .none },
    .{ .@"and", .rm, &.{ .r8, .rm8 }, &.{0x22}, 0x0, .none, .none },
    .{ .@"and", .rm, &.{ .r8, .rm8 }, &.{0x22}, 0x0, .rex, .none },
    .{ .@"and", .rm, &.{ .r16, .rm16 }, &.{0x23}, 0x0, .short, .none },
    .{ .@"and", .rm, &.{ .r32, .rm32 }, &.{0x23}, 0x0, .none, .none },
    .{ .@"and", .rm, &.{ .r64, .rm64 }, &.{0x23}, 0x0, .long, .none },
    .{ .bsf, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0xbc }, 0x0, .short, .none },
    .{ .bsf, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0xbc }, 0x0, .none, .none },
    .{ .bsf, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0xbc }, 0x0, .long, .none },
    .{ .bsr, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0xbd }, 0x0, .short, .none },
    .{ .bsr, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0xbd }, 0x0, .none, .none },
    .{ .bsr, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0xbd }, 0x0, .long, .none },
    .{ .bswap, .o, &.{.r32}, &.{ 0xf, 0xc8 }, 0x0, .none, .none },
    .{ .bswap, .o, &.{.r64}, &.{ 0xf, 0xc8 }, 0x0, .long, .none },
    .{ .bt, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xa3 }, 0x0, .short, .none },
    .{ .bt, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xa3 }, 0x0, .none, .none },
    .{ .bt, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xa3 }, 0x0, .long, .none },
    .{ .bt, .mi, &.{ .rm16, .imm8 }, &.{ 0xf, 0xba }, 0x4, .short, .none },
    .{ .bt, .mi, &.{ .rm32, .imm8 }, &.{ 0xf, 0xba }, 0x4, .none, .none },
    .{ .bt, .mi, &.{ .rm64, .imm8 }, &.{ 0xf, 0xba }, 0x4, .long, .none },
    .{ .btc, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xbb }, 0x0, .short, .none },
    .{ .btc, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xbb }, 0x0, .none, .none },
    .{ .btc, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xbb }, 0x0, .long, .none },
    .{ .btc, .mi, &.{ .rm16, .imm8 }, &.{ 0xf, 0xba }, 0x7, .short, .none },
    .{ .btc, .mi, &.{ .rm32, .imm8 }, &.{ 0xf, 0xba }, 0x7, .none, .none },
    .{ .btc, .mi, &.{ .rm64, .imm8 }, &.{ 0xf, 0xba }, 0x7, .long, .none },
    .{ .btr, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xb3 }, 0x0, .short, .none },
    .{ .btr, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xb3 }, 0x0, .none, .none },
    .{ .btr, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xb3 }, 0x0, .long, .none },
    .{ .btr, .mi, &.{ .rm16, .imm8 }, &.{ 0xf, 0xba }, 0x6, .short, .none },
    .{ .btr, .mi, &.{ .rm32, .imm8 }, &.{ 0xf, 0xba }, 0x6, .none, .none },
    .{ .btr, .mi, &.{ .rm64, .imm8 }, &.{ 0xf, 0xba }, 0x6, .long, .none },
    .{ .bts, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xab }, 0x0, .short, .none },
    .{ .bts, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xab }, 0x0, .none, .none },
    .{ .bts, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xab }, 0x0, .long, .none },
    .{ .bts, .mi, &.{ .rm16, .imm8 }, &.{ 0xf, 0xba }, 0x5, .short, .none },
    .{ .bts, .mi, &.{ .rm32, .imm8 }, &.{ 0xf, 0xba }, 0x5, .none, .none },
    .{ .bts, .mi, &.{ .rm64, .imm8 }, &.{ 0xf, 0xba }, 0x5, .long, .none },
    .{ .call, .d, &.{.rel32}, &.{0xe8}, 0x0, .none, .none },
    .{ .call, .m, &.{.rm64}, &.{0xff}, 0x2, .none, .none },
    .{ .cbw, .np, &.{.o16}, &.{0x98}, 0x0, .short, .none },
    .{ .cdq, .np, &.{.o32}, &.{0x99}, 0x0, .none, .none },
    .{ .cdqe, .np, &.{.o64}, &.{0x98}, 0x0, .long, .none },
    .{ .cmova, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x47 }, 0x0, .short, .none },
    .{ .cmova, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x47 }, 0x0, .none, .none },
    .{ .cmova, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x47 }, 0x0, .long, .none },
    .{ .cmovae, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x43 }, 0x0, .short, .none },
    .{ .cmovae, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x43 }, 0x0, .none, .none },
    .{ .cmovae, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x43 }, 0x0, .long, .none },
    .{ .cmovb, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x42 }, 0x0, .short, .none },
    .{ .cmovb, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x42 }, 0x0, .none, .none },
    .{ .cmovb, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x42 }, 0x0, .long, .none },
    .{ .cmovbe, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x46 }, 0x0, .short, .none },
    .{ .cmovbe, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x46 }, 0x0, .none, .none },
    .{ .cmovbe, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x46 }, 0x0, .long, .none },
    .{ .cmovc, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x42 }, 0x0, .short, .none },
    .{ .cmovc, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x42 }, 0x0, .none, .none },
    .{ .cmovc, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x42 }, 0x0, .long, .none },
    .{ .cmove, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x44 }, 0x0, .short, .none },
    .{ .cmove, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x44 }, 0x0, .none, .none },
    .{ .cmove, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x44 }, 0x0, .long, .none },
    .{ .cmovg, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4f }, 0x0, .short, .none },
    .{ .cmovg, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4f }, 0x0, .none, .none },
    .{ .cmovg, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4f }, 0x0, .long, .none },
    .{ .cmovge, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4d }, 0x0, .short, .none },
    .{ .cmovge, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4d }, 0x0, .none, .none },
    .{ .cmovge, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4d }, 0x0, .long, .none },
    .{ .cmovl, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4c }, 0x0, .short, .none },
    .{ .cmovl, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4c }, 0x0, .none, .none },
    .{ .cmovl, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4c }, 0x0, .long, .none },
    .{ .cmovle, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4e }, 0x0, .short, .none },
    .{ .cmovle, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4e }, 0x0, .none, .none },
    .{ .cmovle, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4e }, 0x0, .long, .none },
    .{ .cmovna, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x46 }, 0x0, .short, .none },
    .{ .cmovna, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x46 }, 0x0, .none, .none },
    .{ .cmovna, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x46 }, 0x0, .long, .none },
    .{ .cmovnae, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x42 }, 0x0, .short, .none },
    .{ .cmovnae, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x42 }, 0x0, .none, .none },
    .{ .cmovnae, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x42 }, 0x0, .long, .none },
    .{ .cmovnb, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x43 }, 0x0, .short, .none },
    .{ .cmovnb, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x43 }, 0x0, .none, .none },
    .{ .cmovnb, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x43 }, 0x0, .long, .none },
    .{ .cmovnbe, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x47 }, 0x0, .short, .none },
    .{ .cmovnbe, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x47 }, 0x0, .none, .none },
    .{ .cmovnbe, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x47 }, 0x0, .long, .none },
    .{ .cmovnc, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x43 }, 0x0, .short, .none },
    .{ .cmovnc, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x43 }, 0x0, .none, .none },
    .{ .cmovnc, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x43 }, 0x0, .long, .none },
    .{ .cmovne, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x45 }, 0x0, .short, .none },
    .{ .cmovne, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x45 }, 0x0, .none, .none },
    .{ .cmovne, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x45 }, 0x0, .long, .none },
    .{ .cmovng, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4e }, 0x0, .short, .none },
    .{ .cmovng, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4e }, 0x0, .none, .none },
    .{ .cmovng, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4e }, 0x0, .long, .none },
    .{ .cmovnge, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4c }, 0x0, .short, .none },
    .{ .cmovnge, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4c }, 0x0, .none, .none },
    .{ .cmovnge, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4c }, 0x0, .long, .none },
    .{ .cmovnl, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4d }, 0x0, .short, .none },
    .{ .cmovnl, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4d }, 0x0, .none, .none },
    .{ .cmovnl, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4d }, 0x0, .long, .none },
    .{ .cmovnle, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4f }, 0x0, .short, .none },
    .{ .cmovnle, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4f }, 0x0, .none, .none },
    .{ .cmovnle, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4f }, 0x0, .long, .none },
    .{ .cmovno, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x41 }, 0x0, .short, .none },
    .{ .cmovno, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x41 }, 0x0, .none, .none },
    .{ .cmovno, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x41 }, 0x0, .long, .none },
    .{ .cmovnp, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4b }, 0x0, .short, .none },
    .{ .cmovnp, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4b }, 0x0, .none, .none },
    .{ .cmovnp, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4b }, 0x0, .long, .none },
    .{ .cmovns, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x49 }, 0x0, .short, .none },
    .{ .cmovns, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x49 }, 0x0, .none, .none },
    .{ .cmovns, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x49 }, 0x0, .long, .none },
    .{ .cmovnz, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x45 }, 0x0, .short, .none },
    .{ .cmovnz, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x45 }, 0x0, .none, .none },
    .{ .cmovnz, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x45 }, 0x0, .long, .none },
    .{ .cmovo, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x40 }, 0x0, .short, .none },
    .{ .cmovo, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x40 }, 0x0, .none, .none },
    .{ .cmovo, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x40 }, 0x0, .long, .none },
    .{ .cmovp, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4a }, 0x0, .short, .none },
    .{ .cmovp, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4a }, 0x0, .none, .none },
    .{ .cmovp, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4a }, 0x0, .long, .none },
    .{ .cmovpe, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4a }, 0x0, .short, .none },
    .{ .cmovpe, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4a }, 0x0, .none, .none },
    .{ .cmovpe, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4a }, 0x0, .long, .none },
    .{ .cmovpo, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x4b }, 0x0, .short, .none },
    .{ .cmovpo, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x4b }, 0x0, .none, .none },
    .{ .cmovpo, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x4b }, 0x0, .long, .none },
    .{ .cmovs, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x48 }, 0x0, .short, .none },
    .{ .cmovs, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x48 }, 0x0, .none, .none },
    .{ .cmovs, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x48 }, 0x0, .long, .none },
    .{ .cmovz, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0x44 }, 0x0, .short, .none },
    .{ .cmovz, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0x44 }, 0x0, .none, .none },
    .{ .cmovz, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0x44 }, 0x0, .long, .none },
    .{ .cmp, .zi, &.{ .al, .imm8 }, &.{0x3c}, 0x0, .none, .none },
    .{ .cmp, .zi, &.{ .ax, .imm16 }, &.{0x3d}, 0x0, .short, .none },
    .{ .cmp, .zi, &.{ .eax, .imm32 }, &.{0x3d}, 0x0, .none, .none },
    .{ .cmp, .zi, &.{ .rax, .imm32s }, &.{0x3d}, 0x0, .long, .none },
    .{ .cmp, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x7, .none, .none },
    .{ .cmp, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x7, .rex, .none },
    .{ .cmp, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x7, .short, .none },
    .{ .cmp, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x7, .none, .none },
    .{ .cmp, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x7, .long, .none },
    .{ .cmp, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x7, .short, .none },
    .{ .cmp, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x7, .none, .none },
    .{ .cmp, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x7, .long, .none },
    .{ .cmp, .mr, &.{ .rm8, .r8 }, &.{0x38}, 0x0, .none, .none },
    .{ .cmp, .mr, &.{ .rm8, .r8 }, &.{0x38}, 0x0, .rex, .none },
    .{ .cmp, .mr, &.{ .rm16, .r16 }, &.{0x39}, 0x0, .short, .none },
    .{ .cmp, .mr, &.{ .rm32, .r32 }, &.{0x39}, 0x0, .none, .none },
    .{ .cmp, .mr, &.{ .rm64, .r64 }, &.{0x39}, 0x0, .long, .none },
    .{ .cmp, .rm, &.{ .r8, .rm8 }, &.{0x3a}, 0x0, .none, .none },
    .{ .cmp, .rm, &.{ .r8, .rm8 }, &.{0x3a}, 0x0, .rex, .none },
    .{ .cmp, .rm, &.{ .r16, .rm16 }, &.{0x3b}, 0x0, .short, .none },
    .{ .cmp, .rm, &.{ .r32, .rm32 }, &.{0x3b}, 0x0, .none, .none },
    .{ .cmp, .rm, &.{ .r64, .rm64 }, &.{0x3b}, 0x0, .long, .none },
    .{ .cmps, .np, &.{ .m8, .m8 }, &.{0xa6}, 0x0, .none, .none },
    .{ .cmps, .np, &.{ .m16, .m16 }, &.{0xa7}, 0x0, .short, .none },
    .{ .cmps, .np, &.{ .m32, .m32 }, &.{0xa7}, 0x0, .none, .none },
    .{ .cmps, .np, &.{ .m64, .m64 }, &.{0xa7}, 0x0, .long, .none },
    .{ .cmpsb, .np, &.{}, &.{0xa6}, 0x0, .none, .none },
    .{ .cmpsd, .np, &.{}, &.{0xa7}, 0x0, .none, .none },
    .{ .cmpsd, .rmi, &.{ .xmm, .xmm_m64, .imm8 }, &.{ 0xf2, 0xf, 0xc2 }, 0x0, .none, .sse2 },
    .{ .cmpsq, .np, &.{}, &.{0xa7}, 0x0, .long, .none },
    .{ .cmpsw, .np, &.{}, &.{0xa7}, 0x0, .short, .none },
    .{ .cmpxchg, .mr, &.{ .rm8, .r8 }, &.{ 0xf, 0xb0 }, 0x0, .none, .none },
    .{ .cmpxchg, .mr, &.{ .rm8, .r8 }, &.{ 0xf, 0xb0 }, 0x0, .rex, .none },
    .{ .cmpxchg, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xb1 }, 0x0, .short, .none },
    .{ .cmpxchg, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xb1 }, 0x0, .none, .none },
    .{ .cmpxchg, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xb1 }, 0x0, .long, .none },
    .{ .cmpxchg8b, .m, &.{.m64}, &.{ 0xf, 0xc7 }, 0x1, .none, .none },
    .{ .cmpxchg16b, .m, &.{.m128}, &.{ 0xf, 0xc7 }, 0x1, .long, .none },
    .{ .cqo, .np, &.{.o64}, &.{0x99}, 0x0, .long, .none },
    .{ .cwd, .np, &.{.o16}, &.{0x99}, 0x0, .short, .none },
    .{ .cwde, .np, &.{.o32}, &.{0x98}, 0x0, .none, .none },
    .{ .div, .m, &.{.rm8}, &.{0xf6}, 0x6, .none, .none },
    .{ .div, .m, &.{.rm8}, &.{0xf6}, 0x6, .rex, .none },
    .{ .div, .m, &.{.rm16}, &.{0xf7}, 0x6, .short, .none },
    .{ .div, .m, &.{.rm32}, &.{0xf7}, 0x6, .none, .none },
    .{ .div, .m, &.{.rm64}, &.{0xf7}, 0x6, .long, .none },
    .{ .endbr64, .np, &.{}, &.{ 0xf3, 0xf, 0x1e, 0xfa }, 0x0, .none, .none },
    .{ .hlt, .np, &.{}, &.{0xf4}, 0x0, .none, .none },
    .{ .idiv, .m, &.{.rm8}, &.{0xf6}, 0x7, .none, .none },
    .{ .idiv, .m, &.{.rm8}, &.{0xf6}, 0x7, .rex, .none },
    .{ .idiv, .m, &.{.rm16}, &.{0xf7}, 0x7, .short, .none },
    .{ .idiv, .m, &.{.rm32}, &.{0xf7}, 0x7, .none, .none },
    .{ .idiv, .m, &.{.rm64}, &.{0xf7}, 0x7, .long, .none },
    .{ .imul, .m, &.{.rm8}, &.{0xf6}, 0x5, .none, .none },
    .{ .imul, .m, &.{.rm8}, &.{0xf6}, 0x5, .rex, .none },
    .{ .imul, .m, &.{.rm16}, &.{0xf7}, 0x5, .short, .none },
    .{ .imul, .m, &.{.rm32}, &.{0xf7}, 0x5, .none, .none },
    .{ .imul, .m, &.{.rm64}, &.{0xf7}, 0x5, .long, .none },
    .{ .imul, .rm, &.{ .r16, .rm16 }, &.{ 0xf, 0xaf }, 0x0, .short, .none },
    .{ .imul, .rm, &.{ .r32, .rm32 }, &.{ 0xf, 0xaf }, 0x0, .none, .none },
    .{ .imul, .rm, &.{ .r64, .rm64 }, &.{ 0xf, 0xaf }, 0x0, .long, .none },
    .{ .imul, .rmi, &.{ .r16, .rm16, .imm8s }, &.{0x6b}, 0x0, .short, .none },
    .{ .imul, .rmi, &.{ .r32, .rm32, .imm8s }, &.{0x6b}, 0x0, .none, .none },
    .{ .imul, .rmi, &.{ .r64, .rm64, .imm8s }, &.{0x6b}, 0x0, .long, .none },
    .{ .imul, .rmi, &.{ .r16, .rm16, .imm16 }, &.{0x69}, 0x0, .short, .none },
    .{ .imul, .rmi, &.{ .r32, .rm32, .imm32 }, &.{0x69}, 0x0, .none, .none },
    .{ .imul, .rmi, &.{ .r64, .rm64, .imm32 }, &.{0x69}, 0x0, .long, .none },
    .{ .int3, .np, &.{}, &.{0xcc}, 0x0, .none, .none },
    .{ .ja, .d, &.{.rel32}, &.{ 0xf, 0x87 }, 0x0, .none, .none },
    .{ .jae, .d, &.{.rel32}, &.{ 0xf, 0x83 }, 0x0, .none, .none },
    .{ .jb, .d, &.{.rel32}, &.{ 0xf, 0x82 }, 0x0, .none, .none },
    .{ .jbe, .d, &.{.rel32}, &.{ 0xf, 0x86 }, 0x0, .none, .none },
    .{ .jc, .d, &.{.rel32}, &.{ 0xf, 0x82 }, 0x0, .none, .none },
    .{ .jrcxz, .d, &.{.rel32}, &.{0xe3}, 0x0, .none, .none },
    .{ .je, .d, &.{.rel32}, &.{ 0xf, 0x84 }, 0x0, .none, .none },
    .{ .jg, .d, &.{.rel32}, &.{ 0xf, 0x8f }, 0x0, .none, .none },
    .{ .jge, .d, &.{.rel32}, &.{ 0xf, 0x8d }, 0x0, .none, .none },
    .{ .jl, .d, &.{.rel32}, &.{ 0xf, 0x8c }, 0x0, .none, .none },
    .{ .jle, .d, &.{.rel32}, &.{ 0xf, 0x8e }, 0x0, .none, .none },
    .{ .jna, .d, &.{.rel32}, &.{ 0xf, 0x86 }, 0x0, .none, .none },
    .{ .jnae, .d, &.{.rel32}, &.{ 0xf, 0x82 }, 0x0, .none, .none },
    .{ .jnb, .d, &.{.rel32}, &.{ 0xf, 0x83 }, 0x0, .none, .none },
    .{ .jnbe, .d, &.{.rel32}, &.{ 0xf, 0x87 }, 0x0, .none, .none },
    .{ .jnc, .d, &.{.rel32}, &.{ 0xf, 0x83 }, 0x0, .none, .none },
    .{ .jne, .d, &.{.rel32}, &.{ 0xf, 0x85 }, 0x0, .none, .none },
    .{ .jng, .d, &.{.rel32}, &.{ 0xf, 0x8e }, 0x0, .none, .none },
    .{ .jnge, .d, &.{.rel32}, &.{ 0xf, 0x8c }, 0x0, .none, .none },
    .{ .jnl, .d, &.{.rel32}, &.{ 0xf, 0x8d }, 0x0, .none, .none },
    .{ .jnle, .d, &.{.rel32}, &.{ 0xf, 0x8f }, 0x0, .none, .none },
    .{ .jno, .d, &.{.rel32}, &.{ 0xf, 0x81 }, 0x0, .none, .none },
    .{ .jnp, .d, &.{.rel32}, &.{ 0xf, 0x8b }, 0x0, .none, .none },
    .{ .jns, .d, &.{.rel32}, &.{ 0xf, 0x89 }, 0x0, .none, .none },
    .{ .jnz, .d, &.{.rel32}, &.{ 0xf, 0x85 }, 0x0, .none, .none },
    .{ .jo, .d, &.{.rel32}, &.{ 0xf, 0x80 }, 0x0, .none, .none },
    .{ .jp, .d, &.{.rel32}, &.{ 0xf, 0x8a }, 0x0, .none, .none },
    .{ .jpe, .d, &.{.rel32}, &.{ 0xf, 0x8a }, 0x0, .none, .none },
    .{ .jpo, .d, &.{.rel32}, &.{ 0xf, 0x8b }, 0x0, .none, .none },
    .{ .js, .d, &.{.rel32}, &.{ 0xf, 0x88 }, 0x0, .none, .none },
    .{ .jz, .d, &.{.rel32}, &.{ 0xf, 0x84 }, 0x0, .none, .none },
    .{ .jmp, .d, &.{.rel32}, &.{0xe9}, 0x0, .none, .none },
    .{ .jmp, .m, &.{.rm64}, &.{0xff}, 0x4, .none, .none },
    .{ .lea, .rm, &.{ .r16, .m }, &.{0x8d}, 0x0, .short, .none },
    .{ .lea, .rm, &.{ .r32, .m }, &.{0x8d}, 0x0, .none, .none },
    .{ .lea, .rm, &.{ .r64, .m }, &.{0x8d}, 0x0, .long, .none },
    .{ .leave, .np, &.{}, &.{0xc9}, 0x0, .none, .none },
    .{ .lfence, .np, &.{}, &.{ 0xf, 0xae, 0xe8 }, 0x0, .none, .none },
    .{ .lods, .np, &.{.m8}, &.{0xac}, 0x0, .none, .none },
    .{ .lods, .np, &.{.m16}, &.{0xad}, 0x0, .short, .none },
    .{ .lods, .np, &.{.m32}, &.{0xad}, 0x0, .none, .none },
    .{ .lods, .np, &.{.m64}, &.{0xad}, 0x0, .long, .none },
    .{ .lodsb, .np, &.{}, &.{0xac}, 0x0, .none, .none },
    .{ .lodsd, .np, &.{}, &.{0xad}, 0x0, .none, .none },
    .{ .lodsq, .np, &.{}, &.{0xad}, 0x0, .long, .none },
    .{ .lodsw, .np, &.{}, &.{0xad}, 0x0, .short, .none },
    .{ .lzcnt, .rm, &.{ .r16, .rm16 }, &.{ 0xf3, 0xf, 0xbd }, 0x0, .short, .lzcnt },
    .{ .lzcnt, .rm, &.{ .r32, .rm32 }, &.{ 0xf3, 0xf, 0xbd }, 0x0, .none, .lzcnt },
    .{ .lzcnt, .rm, &.{ .r64, .rm64 }, &.{ 0xf3, 0xf, 0xbd }, 0x0, .long, .lzcnt },
    .{ .mfence, .np, &.{}, &.{ 0xf, 0xae, 0xf0 }, 0x0, .none, .none },
    .{ .mov, .mr, &.{ .rm8, .r8 }, &.{0x88}, 0x0, .none, .none },
    .{ .mov, .mr, &.{ .rm8, .r8 }, &.{0x88}, 0x0, .rex, .none },
    .{ .mov, .mr, &.{ .rm16, .r16 }, &.{0x89}, 0x0, .short, .none },
    .{ .mov, .mr, &.{ .rm32, .r32 }, &.{0x89}, 0x0, .none, .none },
    .{ .mov, .mr, &.{ .rm64, .r64 }, &.{0x89}, 0x0, .long, .none },
    .{ .mov, .rm, &.{ .r8, .rm8 }, &.{0x8a}, 0x0, .none, .none },
    .{ .mov, .rm, &.{ .r8, .rm8 }, &.{0x8a}, 0x0, .rex, .none },
    .{ .mov, .rm, &.{ .r16, .rm16 }, &.{0x8b}, 0x0, .short, .none },
    .{ .mov, .rm, &.{ .r32, .rm32 }, &.{0x8b}, 0x0, .none, .none },
    .{ .mov, .rm, &.{ .r64, .rm64 }, &.{0x8b}, 0x0, .long, .none },
    .{ .mov, .mr, &.{ .rm16, .sreg }, &.{0x8c}, 0x0, .short, .none },
    .{ .mov, .mr, &.{ .r32_m16, .sreg }, &.{0x8c}, 0x0, .none, .none },
    .{ .mov, .mr, &.{ .r64_m16, .sreg }, &.{0x8c}, 0x0, .long, .none },
    .{ .mov, .rm, &.{ .sreg, .rm16 }, &.{0x8e}, 0x0, .short, .none },
    .{ .mov, .rm, &.{ .sreg, .r32_m16 }, &.{0x8e}, 0x0, .none, .none },
    .{ .mov, .rm, &.{ .sreg, .r64_m16 }, &.{0x8e}, 0x0, .long, .none },
    .{ .mov, .fd, &.{ .al, .moffs }, &.{0xa0}, 0x0, .none, .none },
    .{ .mov, .fd, &.{ .ax, .moffs }, &.{0xa1}, 0x0, .short, .none },
    .{ .mov, .fd, &.{ .eax, .moffs }, &.{0xa1}, 0x0, .none, .none },
    .{ .mov, .fd, &.{ .rax, .moffs }, &.{0xa1}, 0x0, .long, .none },
    .{ .mov, .td, &.{ .moffs, .al }, &.{0xa2}, 0x0, .none, .none },
    .{ .mov, .td, &.{ .moffs, .ax }, &.{0xa3}, 0x0, .short, .none },
    .{ .mov, .td, &.{ .moffs, .eax }, &.{0xa3}, 0x0, .none, .none },
    .{ .mov, .td, &.{ .moffs, .rax }, &.{0xa3}, 0x0, .long, .none },
    .{ .mov, .oi, &.{ .r8, .imm8 }, &.{0xb0}, 0x0, .none, .none },
    .{ .mov, .oi, &.{ .r8, .imm8 }, &.{0xb0}, 0x0, .rex, .none },
    .{ .mov, .oi, &.{ .r16, .imm16 }, &.{0xb8}, 0x0, .short, .none },
    .{ .mov, .oi, &.{ .r32, .imm32 }, &.{0xb8}, 0x0, .none, .none },
    .{ .mov, .oi, &.{ .r64, .imm64 }, &.{0xb8}, 0x0, .long, .none },
    .{ .mov, .mi, &.{ .rm8, .imm8 }, &.{0xc6}, 0x0, .none, .none },
    .{ .mov, .mi, &.{ .rm8, .imm8 }, &.{0xc6}, 0x0, .rex, .none },
    .{ .mov, .mi, &.{ .rm16, .imm16 }, &.{0xc7}, 0x0, .short, .none },
    .{ .mov, .mi, &.{ .rm32, .imm32 }, &.{0xc7}, 0x0, .none, .none },
    .{ .mov, .mi, &.{ .rm64, .imm32s }, &.{0xc7}, 0x0, .long, .none },
    .{ .movbe, .rm, &.{ .r16, .m16 }, &.{ 0xf, 0x38, 0xf0 }, 0x0, .short, .movbe },
    .{ .movbe, .rm, &.{ .r32, .m32 }, &.{ 0xf, 0x38, 0xf0 }, 0x0, .none, .movbe },
    .{ .movbe, .rm, &.{ .r64, .m64 }, &.{ 0xf, 0x38, 0xf0 }, 0x0, .long, .movbe },
    .{ .movbe, .mr, &.{ .m16, .r16 }, &.{ 0xf, 0x38, 0xf1 }, 0x0, .short, .movbe },
    .{ .movbe, .mr, &.{ .m32, .r32 }, &.{ 0xf, 0x38, 0xf1 }, 0x0, .none, .movbe },
    .{ .movbe, .mr, &.{ .m64, .r64 }, &.{ 0xf, 0x38, 0xf1 }, 0x0, .long, .movbe },
    .{ .movs, .np, &.{ .m8, .m8 }, &.{0xa4}, 0x0, .none, .none },
    .{ .movs, .np, &.{ .m16, .m16 }, &.{0xa5}, 0x0, .short, .none },
    .{ .movs, .np, &.{ .m32, .m32 }, &.{0xa5}, 0x0, .none, .none },
    .{ .movs, .np, &.{ .m64, .m64 }, &.{0xa5}, 0x0, .long, .none },
    .{ .movsb, .np, &.{}, &.{0xa4}, 0x0, .none, .none },
    .{ .movsd, .np, &.{}, &.{0xa5}, 0x0, .none, .none },
    .{ .movsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x10 }, 0x0, .none, .sse2 },
    .{ .movsd, .mr, &.{ .xmm_m64, .xmm }, &.{ 0xf2, 0xf, 0x11 }, 0x0, .none, .sse2 },
    .{ .movsq, .np, &.{}, &.{0xa5}, 0x0, .long, .none },
    .{ .movsw, .np, &.{}, &.{0xa5}, 0x0, .short, .none },
    .{ .movsx, .rm, &.{ .r16, .rm8 }, &.{ 0xf, 0xbe }, 0x0, .short, .none },
    .{ .movsx, .rm, &.{ .r16, .rm8 }, &.{ 0xf, 0xbe }, 0x0, .rex_short, .none },
    .{ .movsx, .rm, &.{ .r32, .rm8 }, &.{ 0xf, 0xbe }, 0x0, .none, .none },
    .{ .movsx, .rm, &.{ .r32, .rm8 }, &.{ 0xf, 0xbe }, 0x0, .rex, .none },
    .{ .movsx, .rm, &.{ .r64, .rm8 }, &.{ 0xf, 0xbe }, 0x0, .long, .none },
    .{ .movsx, .rm, &.{ .r32, .rm16 }, &.{ 0xf, 0xbf }, 0x0, .none, .none },
    .{ .movsx, .rm, &.{ .r32, .rm16 }, &.{ 0xf, 0xbf }, 0x0, .rex, .none },
    .{ .movsx, .rm, &.{ .r64, .rm16 }, &.{ 0xf, 0xbf }, 0x0, .long, .none },
    .{ .movsxd, .rm, &.{ .r32, .rm32 }, &.{0x63}, 0x0, .none, .none },
    .{ .movsxd, .rm, &.{ .r64, .rm32 }, &.{0x63}, 0x0, .long, .none },
    .{ .movzx, .rm, &.{ .r16, .rm8 }, &.{ 0xf, 0xb6 }, 0x0, .short, .none },
    .{ .movzx, .rm, &.{ .r16, .rm8 }, &.{ 0xf, 0xb6 }, 0x0, .rex_short, .none },
    .{ .movzx, .rm, &.{ .r32, .rm8 }, &.{ 0xf, 0xb6 }, 0x0, .none, .none },
    .{ .movzx, .rm, &.{ .r32, .rm8 }, &.{ 0xf, 0xb6 }, 0x0, .rex, .none },
    .{ .movzx, .rm, &.{ .r64, .rm8 }, &.{ 0xf, 0xb6 }, 0x0, .long, .none },
    .{ .movzx, .rm, &.{ .r32, .rm16 }, &.{ 0xf, 0xb7 }, 0x0, .none, .none },
    .{ .movzx, .rm, &.{ .r32, .rm16 }, &.{ 0xf, 0xb7 }, 0x0, .rex, .none },
    .{ .movzx, .rm, &.{ .r64, .rm16 }, &.{ 0xf, 0xb7 }, 0x0, .long, .none },
    .{ .mul, .m, &.{.rm8}, &.{0xf6}, 0x4, .none, .none },
    .{ .mul, .m, &.{.rm8}, &.{0xf6}, 0x4, .rex, .none },
    .{ .mul, .m, &.{.rm16}, &.{0xf7}, 0x4, .short, .none },
    .{ .mul, .m, &.{.rm32}, &.{0xf7}, 0x4, .none, .none },
    .{ .mul, .m, &.{.rm64}, &.{0xf7}, 0x4, .long, .none },
    .{ .neg, .m, &.{.rm8}, &.{0xf6}, 0x3, .none, .none },
    .{ .neg, .m, &.{.rm8}, &.{0xf6}, 0x3, .rex, .none },
    .{ .neg, .m, &.{.rm16}, &.{0xf7}, 0x3, .short, .none },
    .{ .neg, .m, &.{.rm32}, &.{0xf7}, 0x3, .none, .none },
    .{ .neg, .m, &.{.rm64}, &.{0xf7}, 0x3, .long, .none },
    .{ .nop, .np, &.{}, &.{0x90}, 0x0, .none, .none },
    .{ .not, .m, &.{.rm8}, &.{0xf6}, 0x2, .none, .none },
    .{ .not, .m, &.{.rm8}, &.{0xf6}, 0x2, .rex, .none },
    .{ .not, .m, &.{.rm16}, &.{0xf7}, 0x2, .short, .none },
    .{ .not, .m, &.{.rm32}, &.{0xf7}, 0x2, .none, .none },
    .{ .not, .m, &.{.rm64}, &.{0xf7}, 0x2, .long, .none },
    .{ .@"or", .zi, &.{ .al, .imm8 }, &.{0xc}, 0x0, .none, .none },
    .{ .@"or", .zi, &.{ .ax, .imm16 }, &.{0xd}, 0x0, .short, .none },
    .{ .@"or", .zi, &.{ .eax, .imm32 }, &.{0xd}, 0x0, .none, .none },
    .{ .@"or", .zi, &.{ .rax, .imm32s }, &.{0xd}, 0x0, .long, .none },
    .{ .@"or", .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x1, .none, .none },
    .{ .@"or", .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x1, .rex, .none },
    .{ .@"or", .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x1, .short, .none },
    .{ .@"or", .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x1, .none, .none },
    .{ .@"or", .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x1, .long, .none },
    .{ .@"or", .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x1, .short, .none },
    .{ .@"or", .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x1, .none, .none },
    .{ .@"or", .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x1, .long, .none },
    .{ .@"or", .mr, &.{ .rm8, .r8 }, &.{0x8}, 0x0, .none, .none },
    .{ .@"or", .mr, &.{ .rm8, .r8 }, &.{0x8}, 0x0, .rex, .none },
    .{ .@"or", .mr, &.{ .rm16, .r16 }, &.{0x9}, 0x0, .short, .none },
    .{ .@"or", .mr, &.{ .rm32, .r32 }, &.{0x9}, 0x0, .none, .none },
    .{ .@"or", .mr, &.{ .rm64, .r64 }, &.{0x9}, 0x0, .long, .none },
    .{ .@"or", .rm, &.{ .r8, .rm8 }, &.{0xa}, 0x0, .none, .none },
    .{ .@"or", .rm, &.{ .r8, .rm8 }, &.{0xa}, 0x0, .rex, .none },
    .{ .@"or", .rm, &.{ .r16, .rm16 }, &.{0xb}, 0x0, .short, .none },
    .{ .@"or", .rm, &.{ .r32, .rm32 }, &.{0xb}, 0x0, .none, .none },
    .{ .@"or", .rm, &.{ .r64, .rm64 }, &.{0xb}, 0x0, .long, .none },
    .{ .pop, .o, &.{.r16}, &.{0x58}, 0x0, .short, .none },
    .{ .pop, .o, &.{.r64}, &.{0x58}, 0x0, .none, .none },
    .{ .pop, .m, &.{.rm16}, &.{0x8f}, 0x0, .short, .none },
    .{ .pop, .m, &.{.rm64}, &.{0x8f}, 0x0, .none, .none },
    .{ .popcnt, .rm, &.{ .r16, .rm16 }, &.{ 0xf3, 0xf, 0xb8 }, 0x0, .short, .popcnt },
    .{ .popcnt, .rm, &.{ .r32, .rm32 }, &.{ 0xf3, 0xf, 0xb8 }, 0x0, .none, .popcnt },
    .{ .popcnt, .rm, &.{ .r64, .rm64 }, &.{ 0xf3, 0xf, 0xb8 }, 0x0, .long, .popcnt },
    .{ .push, .o, &.{.r16}, &.{0x50}, 0x0, .short, .none },
    .{ .push, .o, &.{.r64}, &.{0x50}, 0x0, .none, .none },
    .{ .push, .m, &.{.rm16}, &.{0xff}, 0x6, .short, .none },
    .{ .push, .m, &.{.rm64}, &.{0xff}, 0x6, .none, .none },
    .{ .push, .i, &.{.imm8}, &.{0x6a}, 0x0, .none, .none },
    .{ .push, .i, &.{.imm16}, &.{0x68}, 0x0, .short, .none },
    .{ .push, .i, &.{.imm32}, &.{0x68}, 0x0, .none, .none },
    .{ .rcl, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x2, .none, .none },
    .{ .rcl, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x2, .rex, .none },
    .{ .rcl, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x2, .none, .none },
    .{ .rcl, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x2, .rex, .none },
    .{ .rcl, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x2, .none, .none },
    .{ .rcl, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x2, .rex, .none },
    .{ .rcl, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x2, .short, .none },
    .{ .rcl, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x2, .short, .none },
    .{ .rcl, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x2, .short, .none },
    .{ .rcl, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x2, .none, .none },
    .{ .rcl, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x2, .long, .none },
    .{ .rcl, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x2, .none, .none },
    .{ .rcl, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x2, .long, .none },
    .{ .rcl, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x2, .none, .none },
    .{ .rcl, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x2, .long, .none },
    .{ .rcr, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x3, .none, .none },
    .{ .rcr, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x3, .rex, .none },
    .{ .rcr, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x3, .none, .none },
    .{ .rcr, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x3, .rex, .none },
    .{ .rcr, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x3, .none, .none },
    .{ .rcr, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x3, .rex, .none },
    .{ .rcr, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x3, .short, .none },
    .{ .rcr, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x3, .short, .none },
    .{ .rcr, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x3, .short, .none },
    .{ .rcr, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x3, .none, .none },
    .{ .rcr, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x3, .long, .none },
    .{ .rcr, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x3, .none, .none },
    .{ .rcr, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x3, .long, .none },
    .{ .rcr, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x3, .none, .none },
    .{ .rcr, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x3, .long, .none },
    .{ .ret, .np, &.{}, &.{0xc3}, 0x0, .none, .none },
    .{ .rol, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x0, .none, .none },
    .{ .rol, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x0, .rex, .none },
    .{ .rol, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x0, .none, .none },
    .{ .rol, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x0, .rex, .none },
    .{ .rol, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x0, .none, .none },
    .{ .rol, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x0, .rex, .none },
    .{ .rol, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x0, .short, .none },
    .{ .rol, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x0, .short, .none },
    .{ .rol, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x0, .short, .none },
    .{ .rol, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x0, .none, .none },
    .{ .rol, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x0, .long, .none },
    .{ .rol, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x0, .none, .none },
    .{ .rol, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x0, .long, .none },
    .{ .rol, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x0, .none, .none },
    .{ .rol, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x0, .long, .none },
    .{ .ror, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x1, .none, .none },
    .{ .ror, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x1, .rex, .none },
    .{ .ror, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x1, .none, .none },
    .{ .ror, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x1, .rex, .none },
    .{ .ror, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x1, .none, .none },
    .{ .ror, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x1, .rex, .none },
    .{ .ror, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x1, .short, .none },
    .{ .ror, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x1, .short, .none },
    .{ .ror, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x1, .short, .none },
    .{ .ror, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x1, .none, .none },
    .{ .ror, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x1, .long, .none },
    .{ .ror, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x1, .none, .none },
    .{ .ror, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x1, .long, .none },
    .{ .ror, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x1, .none, .none },
    .{ .ror, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x1, .long, .none },
    .{ .sal, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x4, .none, .none },
    .{ .sal, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x4, .rex, .none },
    .{ .sal, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x4, .short, .none },
    .{ .sal, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x4, .none, .none },
    .{ .sal, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x4, .long, .none },
    .{ .sal, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x4, .none, .none },
    .{ .sal, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x4, .rex, .none },
    .{ .sal, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x4, .short, .none },
    .{ .sal, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x4, .none, .none },
    .{ .sal, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x4, .long, .none },
    .{ .sal, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x4, .none, .none },
    .{ .sal, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x4, .rex, .none },
    .{ .sal, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x4, .short, .none },
    .{ .sal, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x4, .none, .none },
    .{ .sal, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x4, .long, .none },
    .{ .sar, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x7, .none, .none },
    .{ .sar, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x7, .rex, .none },
    .{ .sar, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x7, .short, .none },
    .{ .sar, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x7, .none, .none },
    .{ .sar, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x7, .long, .none },
    .{ .sar, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x7, .none, .none },
    .{ .sar, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x7, .rex, .none },
    .{ .sar, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x7, .short, .none },
    .{ .sar, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x7, .none, .none },
    .{ .sar, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x7, .long, .none },
    .{ .sar, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x7, .none, .none },
    .{ .sar, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x7, .rex, .none },
    .{ .sar, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x7, .short, .none },
    .{ .sar, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x7, .none, .none },
    .{ .sar, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x7, .long, .none },
    .{ .sbb, .zi, &.{ .al, .imm8 }, &.{0x1c}, 0x0, .none, .none },
    .{ .sbb, .zi, &.{ .ax, .imm16 }, &.{0x1d}, 0x0, .short, .none },
    .{ .sbb, .zi, &.{ .eax, .imm32 }, &.{0x1d}, 0x0, .none, .none },
    .{ .sbb, .zi, &.{ .rax, .imm32s }, &.{0x1d}, 0x0, .long, .none },
    .{ .sbb, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x3, .none, .none },
    .{ .sbb, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x3, .rex, .none },
    .{ .sbb, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x3, .short, .none },
    .{ .sbb, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x3, .none, .none },
    .{ .sbb, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x3, .long, .none },
    .{ .sbb, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x3, .short, .none },
    .{ .sbb, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x3, .none, .none },
    .{ .sbb, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x3, .long, .none },
    .{ .sbb, .mr, &.{ .rm8, .r8 }, &.{0x18}, 0x0, .none, .none },
    .{ .sbb, .mr, &.{ .rm8, .r8 }, &.{0x18}, 0x0, .rex, .none },
    .{ .sbb, .mr, &.{ .rm16, .r16 }, &.{0x19}, 0x0, .short, .none },
    .{ .sbb, .mr, &.{ .rm32, .r32 }, &.{0x19}, 0x0, .none, .none },
    .{ .sbb, .mr, &.{ .rm64, .r64 }, &.{0x19}, 0x0, .long, .none },
    .{ .sbb, .rm, &.{ .r8, .rm8 }, &.{0x1a}, 0x0, .none, .none },
    .{ .sbb, .rm, &.{ .r8, .rm8 }, &.{0x1a}, 0x0, .rex, .none },
    .{ .sbb, .rm, &.{ .r16, .rm16 }, &.{0x1b}, 0x0, .short, .none },
    .{ .sbb, .rm, &.{ .r32, .rm32 }, &.{0x1b}, 0x0, .none, .none },
    .{ .sbb, .rm, &.{ .r64, .rm64 }, &.{0x1b}, 0x0, .long, .none },
    .{ .scas, .np, &.{.m8}, &.{0xae}, 0x0, .none, .none },
    .{ .scas, .np, &.{.m16}, &.{0xaf}, 0x0, .short, .none },
    .{ .scas, .np, &.{.m32}, &.{0xaf}, 0x0, .none, .none },
    .{ .scas, .np, &.{.m64}, &.{0xaf}, 0x0, .long, .none },
    .{ .scasb, .np, &.{}, &.{0xae}, 0x0, .none, .none },
    .{ .scasd, .np, &.{}, &.{0xaf}, 0x0, .none, .none },
    .{ .scasq, .np, &.{}, &.{0xaf}, 0x0, .long, .none },
    .{ .scasw, .np, &.{}, &.{0xaf}, 0x0, .short, .none },
    .{ .shl, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x4, .none, .none },
    .{ .shl, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x4, .rex, .none },
    .{ .shl, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x4, .short, .none },
    .{ .shl, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x4, .none, .none },
    .{ .shl, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x4, .long, .none },
    .{ .shl, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x4, .none, .none },
    .{ .shl, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x4, .rex, .none },
    .{ .shl, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x4, .short, .none },
    .{ .shl, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x4, .none, .none },
    .{ .shl, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x4, .long, .none },
    .{ .shl, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x4, .none, .none },
    .{ .shl, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x4, .rex, .none },
    .{ .shl, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x4, .short, .none },
    .{ .shl, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x4, .none, .none },
    .{ .shl, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x4, .long, .none },
    .{ .shld, .mri, &.{ .rm16, .r16, .imm8 }, &.{ 0xf, 0xa4 }, 0x0, .short, .none },
    .{ .shld, .mrc, &.{ .rm16, .r16, .cl }, &.{ 0xf, 0xa5 }, 0x0, .short, .none },
    .{ .shld, .mri, &.{ .rm32, .r32, .imm8 }, &.{ 0xf, 0xa4 }, 0x0, .none, .none },
    .{ .shld, .mri, &.{ .rm64, .r64, .imm8 }, &.{ 0xf, 0xa4 }, 0x0, .long, .none },
    .{ .shld, .mrc, &.{ .rm32, .r32, .cl }, &.{ 0xf, 0xa5 }, 0x0, .none, .none },
    .{ .shld, .mrc, &.{ .rm64, .r64, .cl }, &.{ 0xf, 0xa5 }, 0x0, .long, .none },
    .{ .shr, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x5, .none, .none },
    .{ .shr, .m1, &.{ .rm8, .unity }, &.{0xd0}, 0x5, .rex, .none },
    .{ .shr, .m1, &.{ .rm16, .unity }, &.{0xd1}, 0x5, .short, .none },
    .{ .shr, .m1, &.{ .rm32, .unity }, &.{0xd1}, 0x5, .none, .none },
    .{ .shr, .m1, &.{ .rm64, .unity }, &.{0xd1}, 0x5, .long, .none },
    .{ .shr, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x5, .none, .none },
    .{ .shr, .mc, &.{ .rm8, .cl }, &.{0xd2}, 0x5, .rex, .none },
    .{ .shr, .mc, &.{ .rm16, .cl }, &.{0xd3}, 0x5, .short, .none },
    .{ .shr, .mc, &.{ .rm32, .cl }, &.{0xd3}, 0x5, .none, .none },
    .{ .shr, .mc, &.{ .rm64, .cl }, &.{0xd3}, 0x5, .long, .none },
    .{ .shr, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x5, .none, .none },
    .{ .shr, .mi, &.{ .rm8, .imm8 }, &.{0xc0}, 0x5, .rex, .none },
    .{ .shr, .mi, &.{ .rm16, .imm8 }, &.{0xc1}, 0x5, .short, .none },
    .{ .shr, .mi, &.{ .rm32, .imm8 }, &.{0xc1}, 0x5, .none, .none },
    .{ .shr, .mi, &.{ .rm64, .imm8 }, &.{0xc1}, 0x5, .long, .none },
    .{ .shrd, .mri, &.{ .rm16, .r16, .imm8 }, &.{ 0xf, 0xac }, 0x0, .short, .none },
    .{ .shrd, .mrc, &.{ .rm16, .r16, .cl }, &.{ 0xf, 0xad }, 0x0, .short, .none },
    .{ .shrd, .mri, &.{ .rm32, .r32, .imm8 }, &.{ 0xf, 0xac }, 0x0, .none, .none },
    .{ .shrd, .mri, &.{ .rm64, .r64, .imm8 }, &.{ 0xf, 0xac }, 0x0, .long, .none },
    .{ .shrd, .mrc, &.{ .rm32, .r32, .cl }, &.{ 0xf, 0xad }, 0x0, .none, .none },
    .{ .shrd, .mrc, &.{ .rm64, .r64, .cl }, &.{ 0xf, 0xad }, 0x0, .long, .none },
    .{ .sub, .zi, &.{ .al, .imm8 }, &.{0x2c}, 0x0, .none, .none },
    .{ .sub, .zi, &.{ .ax, .imm16 }, &.{0x2d}, 0x0, .short, .none },
    .{ .sub, .zi, &.{ .eax, .imm32 }, &.{0x2d}, 0x0, .none, .none },
    .{ .sub, .zi, &.{ .rax, .imm32s }, &.{0x2d}, 0x0, .long, .none },
    .{ .sub, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x5, .none, .none },
    .{ .sub, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x5, .rex, .none },
    .{ .sub, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x5, .short, .none },
    .{ .sub, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x5, .none, .none },
    .{ .sub, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x5, .long, .none },
    .{ .sub, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x5, .short, .none },
    .{ .sub, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x5, .none, .none },
    .{ .sub, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x5, .long, .none },
    .{ .sub, .mr, &.{ .rm8, .r8 }, &.{0x28}, 0x0, .none, .none },
    .{ .sub, .mr, &.{ .rm8, .r8 }, &.{0x28}, 0x0, .rex, .none },
    .{ .sub, .mr, &.{ .rm16, .r16 }, &.{0x29}, 0x0, .short, .none },
    .{ .sub, .mr, &.{ .rm32, .r32 }, &.{0x29}, 0x0, .none, .none },
    .{ .sub, .mr, &.{ .rm64, .r64 }, &.{0x29}, 0x0, .long, .none },
    .{ .sub, .rm, &.{ .r8, .rm8 }, &.{0x2a}, 0x0, .none, .none },
    .{ .sub, .rm, &.{ .r8, .rm8 }, &.{0x2a}, 0x0, .rex, .none },
    .{ .sub, .rm, &.{ .r16, .rm16 }, &.{0x2b}, 0x0, .short, .none },
    .{ .sub, .rm, &.{ .r32, .rm32 }, &.{0x2b}, 0x0, .none, .none },
    .{ .sub, .rm, &.{ .r64, .rm64 }, &.{0x2b}, 0x0, .long, .none },
    .{ .syscall, .np, &.{}, &.{ 0xf, 0x5 }, 0x0, .none, .none },
    .{ .seta, .m, &.{.rm8}, &.{ 0xf, 0x97 }, 0x0, .none, .none },
    .{ .seta, .m, &.{.rm8}, &.{ 0xf, 0x97 }, 0x0, .rex, .none },
    .{ .setae, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .none, .none },
    .{ .setae, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .rex, .none },
    .{ .setb, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .none, .none },
    .{ .setb, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .rex, .none },
    .{ .setbe, .m, &.{.rm8}, &.{ 0xf, 0x96 }, 0x0, .none, .none },
    .{ .setbe, .m, &.{.rm8}, &.{ 0xf, 0x96 }, 0x0, .rex, .none },
    .{ .setc, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .none, .none },
    .{ .setc, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .rex, .none },
    .{ .sete, .m, &.{.rm8}, &.{ 0xf, 0x94 }, 0x0, .none, .none },
    .{ .sete, .m, &.{.rm8}, &.{ 0xf, 0x94 }, 0x0, .rex, .none },
    .{ .setg, .m, &.{.rm8}, &.{ 0xf, 0x9f }, 0x0, .none, .none },
    .{ .setg, .m, &.{.rm8}, &.{ 0xf, 0x9f }, 0x0, .rex, .none },
    .{ .setge, .m, &.{.rm8}, &.{ 0xf, 0x9d }, 0x0, .none, .none },
    .{ .setge, .m, &.{.rm8}, &.{ 0xf, 0x9d }, 0x0, .rex, .none },
    .{ .setl, .m, &.{.rm8}, &.{ 0xf, 0x9c }, 0x0, .none, .none },
    .{ .setl, .m, &.{.rm8}, &.{ 0xf, 0x9c }, 0x0, .rex, .none },
    .{ .setle, .m, &.{.rm8}, &.{ 0xf, 0x9e }, 0x0, .none, .none },
    .{ .setle, .m, &.{.rm8}, &.{ 0xf, 0x9e }, 0x0, .rex, .none },
    .{ .setna, .m, &.{.rm8}, &.{ 0xf, 0x96 }, 0x0, .none, .none },
    .{ .setna, .m, &.{.rm8}, &.{ 0xf, 0x96 }, 0x0, .rex, .none },
    .{ .setnae, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .none, .none },
    .{ .setnae, .m, &.{.rm8}, &.{ 0xf, 0x92 }, 0x0, .rex, .none },
    .{ .setnb, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .none, .none },
    .{ .setnb, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .rex, .none },
    .{ .setnbe, .m, &.{.rm8}, &.{ 0xf, 0x97 }, 0x0, .none, .none },
    .{ .setnbe, .m, &.{.rm8}, &.{ 0xf, 0x97 }, 0x0, .rex, .none },
    .{ .setnc, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .none, .none },
    .{ .setnc, .m, &.{.rm8}, &.{ 0xf, 0x93 }, 0x0, .rex, .none },
    .{ .setne, .m, &.{.rm8}, &.{ 0xf, 0x95 }, 0x0, .none, .none },
    .{ .setne, .m, &.{.rm8}, &.{ 0xf, 0x95 }, 0x0, .rex, .none },
    .{ .setng, .m, &.{.rm8}, &.{ 0xf, 0x9e }, 0x0, .none, .none },
    .{ .setng, .m, &.{.rm8}, &.{ 0xf, 0x9e }, 0x0, .rex, .none },
    .{ .setnge, .m, &.{.rm8}, &.{ 0xf, 0x9c }, 0x0, .none, .none },
    .{ .setnge, .m, &.{.rm8}, &.{ 0xf, 0x9c }, 0x0, .rex, .none },
    .{ .setnl, .m, &.{.rm8}, &.{ 0xf, 0x9d }, 0x0, .none, .none },
    .{ .setnl, .m, &.{.rm8}, &.{ 0xf, 0x9d }, 0x0, .rex, .none },
    .{ .setnle, .m, &.{.rm8}, &.{ 0xf, 0x9f }, 0x0, .none, .none },
    .{ .setnle, .m, &.{.rm8}, &.{ 0xf, 0x9f }, 0x0, .rex, .none },
    .{ .setno, .m, &.{.rm8}, &.{ 0xf, 0x91 }, 0x0, .none, .none },
    .{ .setno, .m, &.{.rm8}, &.{ 0xf, 0x91 }, 0x0, .rex, .none },
    .{ .setnp, .m, &.{.rm8}, &.{ 0xf, 0x9b }, 0x0, .none, .none },
    .{ .setnp, .m, &.{.rm8}, &.{ 0xf, 0x9b }, 0x0, .rex, .none },
    .{ .setns, .m, &.{.rm8}, &.{ 0xf, 0x99 }, 0x0, .none, .none },
    .{ .setns, .m, &.{.rm8}, &.{ 0xf, 0x99 }, 0x0, .rex, .none },
    .{ .setnz, .m, &.{.rm8}, &.{ 0xf, 0x95 }, 0x0, .none, .none },
    .{ .setnz, .m, &.{.rm8}, &.{ 0xf, 0x95 }, 0x0, .rex, .none },
    .{ .seto, .m, &.{.rm8}, &.{ 0xf, 0x90 }, 0x0, .none, .none },
    .{ .seto, .m, &.{.rm8}, &.{ 0xf, 0x90 }, 0x0, .rex, .none },
    .{ .setp, .m, &.{.rm8}, &.{ 0xf, 0x9a }, 0x0, .none, .none },
    .{ .setp, .m, &.{.rm8}, &.{ 0xf, 0x9a }, 0x0, .rex, .none },
    .{ .setpe, .m, &.{.rm8}, &.{ 0xf, 0x9a }, 0x0, .none, .none },
    .{ .setpe, .m, &.{.rm8}, &.{ 0xf, 0x9a }, 0x0, .rex, .none },
    .{ .setpo, .m, &.{.rm8}, &.{ 0xf, 0x9b }, 0x0, .none, .none },
    .{ .setpo, .m, &.{.rm8}, &.{ 0xf, 0x9b }, 0x0, .rex, .none },
    .{ .sets, .m, &.{.rm8}, &.{ 0xf, 0x98 }, 0x0, .none, .none },
    .{ .sets, .m, &.{.rm8}, &.{ 0xf, 0x98 }, 0x0, .rex, .none },
    .{ .setz, .m, &.{.rm8}, &.{ 0xf, 0x94 }, 0x0, .none, .none },
    .{ .setz, .m, &.{.rm8}, &.{ 0xf, 0x94 }, 0x0, .rex, .none },
    .{ .sfence, .np, &.{}, &.{ 0xf, 0xae, 0xf8 }, 0x0, .none, .none },
    .{ .stos, .np, &.{.m8}, &.{0xaa}, 0x0, .none, .none },
    .{ .stos, .np, &.{.m16}, &.{0xab}, 0x0, .short, .none },
    .{ .stos, .np, &.{.m32}, &.{0xab}, 0x0, .none, .none },
    .{ .stos, .np, &.{.m64}, &.{0xab}, 0x0, .long, .none },
    .{ .stosb, .np, &.{}, &.{0xaa}, 0x0, .none, .none },
    .{ .stosd, .np, &.{}, &.{0xab}, 0x0, .none, .none },
    .{ .stosq, .np, &.{}, &.{0xab}, 0x0, .long, .none },
    .{ .stosw, .np, &.{}, &.{0xab}, 0x0, .short, .none },
    .{ .@"test", .zi, &.{ .al, .imm8 }, &.{0xa8}, 0x0, .none, .none },
    .{ .@"test", .zi, &.{ .ax, .imm16 }, &.{0xa9}, 0x0, .short, .none },
    .{ .@"test", .zi, &.{ .eax, .imm32 }, &.{0xa9}, 0x0, .none, .none },
    .{ .@"test", .zi, &.{ .rax, .imm32s }, &.{0xa9}, 0x0, .long, .none },
    .{ .@"test", .mi, &.{ .rm8, .imm8 }, &.{0xf6}, 0x0, .none, .none },
    .{ .@"test", .mi, &.{ .rm8, .imm8 }, &.{0xf6}, 0x0, .rex, .none },
    .{ .@"test", .mi, &.{ .rm16, .imm16 }, &.{0xf7}, 0x0, .short, .none },
    .{ .@"test", .mi, &.{ .rm32, .imm32 }, &.{0xf7}, 0x0, .none, .none },
    .{ .@"test", .mi, &.{ .rm64, .imm32s }, &.{0xf7}, 0x0, .long, .none },
    .{ .@"test", .mr, &.{ .rm8, .r8 }, &.{0x84}, 0x0, .none, .none },
    .{ .@"test", .mr, &.{ .rm8, .r8 }, &.{0x84}, 0x0, .rex, .none },
    .{ .@"test", .mr, &.{ .rm16, .r16 }, &.{0x85}, 0x0, .short, .none },
    .{ .@"test", .mr, &.{ .rm32, .r32 }, &.{0x85}, 0x0, .none, .none },
    .{ .@"test", .mr, &.{ .rm64, .r64 }, &.{0x85}, 0x0, .long, .none },
    .{ .tzcnt, .rm, &.{ .r16, .rm16 }, &.{ 0xf3, 0xf, 0xbc }, 0x0, .short, .bmi },
    .{ .tzcnt, .rm, &.{ .r32, .rm32 }, &.{ 0xf3, 0xf, 0xbc }, 0x0, .none, .bmi },
    .{ .tzcnt, .rm, &.{ .r64, .rm64 }, &.{ 0xf3, 0xf, 0xbc }, 0x0, .long, .bmi },
    .{ .ud2, .np, &.{}, &.{ 0xf, 0xb }, 0x0, .none, .none },
    .{ .xadd, .mr, &.{ .rm8, .r8 }, &.{ 0xf, 0xc0 }, 0x0, .none, .none },
    .{ .xadd, .mr, &.{ .rm8, .r8 }, &.{ 0xf, 0xc0 }, 0x0, .rex, .none },
    .{ .xadd, .mr, &.{ .rm16, .r16 }, &.{ 0xf, 0xc1 }, 0x0, .short, .none },
    .{ .xadd, .mr, &.{ .rm32, .r32 }, &.{ 0xf, 0xc1 }, 0x0, .none, .none },
    .{ .xadd, .mr, &.{ .rm64, .r64 }, &.{ 0xf, 0xc1 }, 0x0, .long, .none },
    .{ .xchg, .o, &.{ .ax, .r16 }, &.{0x90}, 0x0, .short, .none },
    .{ .xchg, .o, &.{ .r16, .ax }, &.{0x90}, 0x0, .short, .none },
    .{ .xchg, .o, &.{ .eax, .r32 }, &.{0x90}, 0x0, .none, .none },
    .{ .xchg, .o, &.{ .rax, .r64 }, &.{0x90}, 0x0, .long, .none },
    .{ .xchg, .o, &.{ .r32, .eax }, &.{0x90}, 0x0, .none, .none },
    .{ .xchg, .o, &.{ .r64, .rax }, &.{0x90}, 0x0, .long, .none },
    .{ .xchg, .mr, &.{ .rm8, .r8 }, &.{0x86}, 0x0, .none, .none },
    .{ .xchg, .mr, &.{ .rm8, .r8 }, &.{0x86}, 0x0, .rex, .none },
    .{ .xchg, .rm, &.{ .r8, .rm8 }, &.{0x86}, 0x0, .none, .none },
    .{ .xchg, .rm, &.{ .r8, .rm8 }, &.{0x86}, 0x0, .rex, .none },
    .{ .xchg, .mr, &.{ .rm16, .r16 }, &.{0x87}, 0x0, .short, .none },
    .{ .xchg, .rm, &.{ .r16, .rm16 }, &.{0x87}, 0x0, .short, .none },
    .{ .xchg, .mr, &.{ .rm32, .r32 }, &.{0x87}, 0x0, .none, .none },
    .{ .xchg, .mr, &.{ .rm64, .r64 }, &.{0x87}, 0x0, .long, .none },
    .{ .xchg, .rm, &.{ .r32, .rm32 }, &.{0x87}, 0x0, .none, .none },
    .{ .xchg, .rm, &.{ .r64, .rm64 }, &.{0x87}, 0x0, .long, .none },
    .{ .xor, .zi, &.{ .al, .imm8 }, &.{0x34}, 0x0, .none, .none },
    .{ .xor, .zi, &.{ .ax, .imm16 }, &.{0x35}, 0x0, .short, .none },
    .{ .xor, .zi, &.{ .eax, .imm32 }, &.{0x35}, 0x0, .none, .none },
    .{ .xor, .zi, &.{ .rax, .imm32s }, &.{0x35}, 0x0, .long, .none },
    .{ .xor, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x6, .none, .none },
    .{ .xor, .mi, &.{ .rm8, .imm8 }, &.{0x80}, 0x6, .rex, .none },
    .{ .xor, .mi, &.{ .rm16, .imm16 }, &.{0x81}, 0x6, .short, .none },
    .{ .xor, .mi, &.{ .rm32, .imm32 }, &.{0x81}, 0x6, .none, .none },
    .{ .xor, .mi, &.{ .rm64, .imm32s }, &.{0x81}, 0x6, .long, .none },
    .{ .xor, .mi, &.{ .rm16, .imm8s }, &.{0x83}, 0x6, .short, .none },
    .{ .xor, .mi, &.{ .rm32, .imm8s }, &.{0x83}, 0x6, .none, .none },
    .{ .xor, .mi, &.{ .rm64, .imm8s }, &.{0x83}, 0x6, .long, .none },
    .{ .xor, .mr, &.{ .rm8, .r8 }, &.{0x30}, 0x0, .none, .none },
    .{ .xor, .mr, &.{ .rm8, .r8 }, &.{0x30}, 0x0, .rex, .none },
    .{ .xor, .mr, &.{ .rm16, .r16 }, &.{0x31}, 0x0, .short, .none },
    .{ .xor, .mr, &.{ .rm32, .r32 }, &.{0x31}, 0x0, .none, .none },
    .{ .xor, .mr, &.{ .rm64, .r64 }, &.{0x31}, 0x0, .long, .none },
    .{ .xor, .rm, &.{ .r8, .rm8 }, &.{0x32}, 0x0, .none, .none },
    .{ .xor, .rm, &.{ .r8, .rm8 }, &.{0x32}, 0x0, .rex, .none },
    .{ .xor, .rm, &.{ .r16, .rm16 }, &.{0x33}, 0x0, .short, .none },
    .{ .xor, .rm, &.{ .r32, .rm32 }, &.{0x33}, 0x0, .none, .none },
    .{ .xor, .rm, &.{ .r64, .rm64 }, &.{0x33}, 0x0, .long, .none },
    .{ .fisttp, .m, &.{.m16}, &.{0xdf}, 0x1, .none, .x87 },
    .{ .fisttp, .m, &.{.m32}, &.{0xdb}, 0x1, .none, .x87 },
    .{ .fisttp, .m, &.{.m64}, &.{0xdd}, 0x1, .none, .x87 },
    .{ .fld, .m, &.{.m32}, &.{0xd9}, 0x0, .none, .x87 },
    .{ .fld, .m, &.{.m64}, &.{0xdd}, 0x0, .none, .x87 },
    .{ .fld, .m, &.{.m80}, &.{0xdb}, 0x5, .none, .x87 },
    .{ .movd, .rm, &.{ .xmm, .rm32 }, &.{ 0x66, 0xf, 0x6e }, 0x0, .none, .sse2 },
    .{ .movd, .mr, &.{ .rm32, .xmm }, &.{ 0x66, 0xf, 0x7e }, 0x0, .none, .sse2 },
    .{ .movq, .rm, &.{ .xmm, .rm64 }, &.{ 0x66, 0xf, 0x6e }, 0x0, .long, .sse2 },
    .{ .movq, .mr, &.{ .rm64, .xmm }, &.{ 0x66, 0xf, 0x7e }, 0x0, .long, .sse2 },
    .{ .movq, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf3, 0xf, 0x7e }, 0x0, .none, .sse2 },
    .{ .movq, .mr, &.{ .xmm_m64, .xmm }, &.{ 0x66, 0xf, 0xd6 }, 0x0, .none, .sse2 },
    .{ .packssdw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6b }, 0x0, .none, .sse2 },
    .{ .packsswb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x63 }, 0x0, .none, .sse2 },
    .{ .packuswb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x67 }, 0x0, .none, .sse2 },
    .{ .paddb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfc }, 0x0, .none, .sse2 },
    .{ .paddd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfe }, 0x0, .none, .sse2 },
    .{ .paddq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd4 }, 0x0, .none, .sse2 },
    .{ .paddsb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xec }, 0x0, .none, .sse2 },
    .{ .paddsw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xed }, 0x0, .none, .sse2 },
    .{ .paddusb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdc }, 0x0, .none, .sse2 },
    .{ .paddusw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdd }, 0x0, .none, .sse2 },
    .{ .paddw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfd }, 0x0, .none, .sse2 },
    .{ .pand, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdb }, 0x0, .none, .sse2 },
    .{ .pandn, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdf }, 0x0, .none, .sse2 },
    .{ .por, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xeb }, 0x0, .none, .sse2 },
    .{ .pxor, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xef }, 0x0, .none, .sse2 },
    .{ .pmulhw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe5 }, 0x0, .none, .sse2 },
    .{ .pmullw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd5 }, 0x0, .none, .sse2 },
    .{ .psubb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xf8 }, 0x0, .none, .sse2 },
    .{ .psubd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfa }, 0x0, .none, .sse2 },
    .{ .psubq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfb }, 0x0, .none, .sse2 },
    .{ .psubsb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe8 }, 0x0, .none, .sse2 },
    .{ .psubsw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe9 }, 0x0, .none, .sse2 },
    .{ .psubusb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd8 }, 0x0, .none, .sse2 },
    .{ .psubusw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd9 }, 0x0, .none, .sse2 },
    .{ .psubw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xf9 }, 0x0, .none, .sse2 },
    .{ .addps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x58 }, 0x0, .none, .sse },
    .{ .addss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x58 }, 0x0, .none, .sse },
    .{ .andps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x54 }, 0x0, .none, .sse },
    .{ .andnps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x55 }, 0x0, .none, .sse },
    .{ .cmpps, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0xf, 0xc2 }, 0x0, .none, .sse },
    .{ .cmpss, .rmi, &.{ .xmm, .xmm_m32, .imm8 }, &.{ 0xf3, 0xf, 0xc2 }, 0x0, .none, .sse },
    .{ .cvtpi2ps, .rm, &.{ .xmm, .mm_m64 }, &.{ 0xf, 0x2a }, 0x0, .none, .sse },
    .{ .cvtps2pi, .rm, &.{ .mm, .xmm_m64 }, &.{ 0xf, 0x2d }, 0x0, .none, .sse },
    .{ .cvtsi2ss, .rm, &.{ .xmm, .rm32 }, &.{ 0xf3, 0xf, 0x2a }, 0x0, .none, .sse },
    .{ .cvtsi2ss, .rm, &.{ .xmm, .rm64 }, &.{ 0xf3, 0xf, 0x2a }, 0x0, .long, .sse },
    .{ .cvtss2si, .rm, &.{ .r32, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2d }, 0x0, .none, .sse },
    .{ .cvtss2si, .rm, &.{ .r64, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2d }, 0x0, .long, .sse },
    .{ .cvttps2pi, .rm, &.{ .mm, .xmm_m64 }, &.{ 0xf, 0x2c }, 0x0, .none, .sse },
    .{ .cvttss2si, .rm, &.{ .r32, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2c }, 0x0, .none, .sse },
    .{ .cvttss2si, .rm, &.{ .r64, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2c }, 0x0, .long, .sse },
    .{ .divps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5e }, 0x0, .none, .sse },
    .{ .divss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5e }, 0x0, .none, .sse },
    .{ .maxps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5f }, 0x0, .none, .sse },
    .{ .maxss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5f }, 0x0, .none, .sse },
    .{ .minps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5d }, 0x0, .none, .sse },
    .{ .minss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5d }, 0x0, .none, .sse },
    .{ .movaps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x28 }, 0x0, .none, .sse },
    .{ .movaps, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf, 0x29 }, 0x0, .none, .sse },
    .{ .movhlps, .rm, &.{ .xmm, .xmm }, &.{ 0xf, 0x12 }, 0x0, .none, .sse },
    .{ .movlhps, .rm, &.{ .xmm, .xmm }, &.{ 0xf, 0x16 }, 0x0, .none, .sse },
    .{ .movss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x10 }, 0x0, .none, .sse },
    .{ .movss, .mr, &.{ .xmm_m32, .xmm }, &.{ 0xf3, 0xf, 0x11 }, 0x0, .none, .sse },
    .{ .movups, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x10 }, 0x0, .none, .sse },
    .{ .movups, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf, 0x11 }, 0x0, .none, .sse },
    .{ .mulps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x59 }, 0x0, .none, .sse },
    .{ .mulss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x59 }, 0x0, .none, .sse },
    .{ .orps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x56 }, 0x0, .none, .sse },
    .{ .pextrw, .rmi, &.{ .r32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0xc5 }, 0x0, .none, .sse2 },
    .{ .pextrw, .mri, &.{ .r32_m16, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x15 }, 0x0, .none, .sse4_1 },
    .{ .pinsrw, .rmi, &.{ .xmm, .r32_m16, .imm8 }, &.{ 0x66, 0xf, 0xc4 }, 0x0, .none, .sse2 },
    .{ .pmaxsw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xee }, 0x0, .none, .sse2 },
    .{ .pmaxub, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xde }, 0x0, .none, .sse2 },
    .{ .pminsw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xea }, 0x0, .none, .sse2 },
    .{ .pminub, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xda }, 0x0, .none, .sse2 },
    .{ .shufps, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0xf, 0xc6 }, 0x0, .none, .sse },
    .{ .sqrtps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x51 }, 0x0, .none, .sse },
    .{ .sqrtss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x51 }, 0x0, .none, .sse },
    .{ .subps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5c }, 0x0, .none, .sse },
    .{ .subss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5c }, 0x0, .none, .sse },
    .{ .ucomiss, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf, 0x2e }, 0x0, .none, .sse },
    .{ .xorps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x57 }, 0x0, .none, .sse },
    .{ .addpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x58 }, 0x0, .none, .sse2 },
    .{ .addsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x58 }, 0x0, .none, .sse2 },
    .{ .andpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x54 }, 0x0, .none, .sse2 },
    .{ .andnpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x55 }, 0x0, .none, .sse2 },
    .{ .cmppd, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0xc2 }, 0x0, .none, .sse2 },
    .{ .cvtdq2pd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf3, 0xf, 0xe6 }, 0x0, .none, .sse2 },
    .{ .cvtdq2ps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5b }, 0x0, .none, .sse2 },
    .{ .cvtpd2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf2, 0xf, 0xe6 }, 0x0, .none, .sse2 },
    .{ .cvtpd2pi, .rm, &.{ .mm, .xmm_m128 }, &.{ 0x66, 0xf, 0x2d }, 0x0, .none, .sse2 },
    .{ .cvtpd2ps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5a }, 0x0, .none, .sse2 },
    .{ .cvtpi2pd, .rm, &.{ .xmm, .mm_m64 }, &.{ 0x66, 0xf, 0x2a }, 0x0, .none, .sse2 },
    .{ .cvtps2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5b }, 0x0, .none, .sse2 },
    .{ .cvtps2pd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf, 0x5a }, 0x0, .none, .sse2 },
    .{ .cvtsd2si, .rm, &.{ .r32, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2d }, 0x0, .none, .sse2 },
    .{ .cvtsd2si, .rm, &.{ .r64, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2d }, 0x0, .long, .sse2 },
    .{ .cvtsd2ss, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5a }, 0x0, .none, .sse2 },
    .{ .cvtsi2sd, .rm, &.{ .xmm, .rm32 }, &.{ 0xf2, 0xf, 0x2a }, 0x0, .none, .sse2 },
    .{ .cvtsi2sd, .rm, &.{ .xmm, .rm64 }, &.{ 0xf2, 0xf, 0x2a }, 0x0, .long, .sse2 },
    .{ .cvtss2sd, .rm, &.{ .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5a }, 0x0, .none, .sse2 },
    .{ .cvttpd2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe6 }, 0x0, .none, .sse2 },
    .{ .cvttpd2pi, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x2c }, 0x0, .none, .sse2 },
    .{ .cvttps2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x5b }, 0x0, .none, .sse2 },
    .{ .cvttsd2si, .rm, &.{ .r32, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2c }, 0x0, .none, .sse2 },
    .{ .cvttsd2si, .rm, &.{ .r64, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2c }, 0x0, .long, .sse2 },
    .{ .divpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5e }, 0x0, .none, .sse2 },
    .{ .divsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5e }, 0x0, .none, .sse2 },
    .{ .maxpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5f }, 0x0, .none, .sse2 },
    .{ .maxsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5f }, 0x0, .none, .sse2 },
    .{ .minpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5d }, 0x0, .none, .sse2 },
    .{ .minsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5d }, 0x0, .none, .sse2 },
    .{ .movapd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x28 }, 0x0, .none, .sse2 },
    .{ .movapd, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x29 }, 0x0, .none, .sse2 },
    .{ .movdqa, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6f }, 0x0, .none, .sse2 },
    .{ .movdqa, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x7f }, 0x0, .none, .sse2 },
    .{ .movdqu, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x6f }, 0x0, .none, .sse2 },
    .{ .movdqu, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf3, 0xf, 0x7f }, 0x0, .none, .sse2 },
    .{ .movupd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x10 }, 0x0, .none, .sse2 },
    .{ .movupd, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x11 }, 0x0, .none, .sse2 },
    .{ .mulpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x59 }, 0x0, .none, .sse2 },
    .{ .mulsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x59 }, 0x0, .none, .sse2 },
    .{ .orpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x56 }, 0x0, .none, .sse2 },
    .{ .pshufhw, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0xf3, 0xf, 0x70 }, 0x0, .none, .sse2 },
    .{ .pshuflw, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0xf2, 0xf, 0x70 }, 0x0, .none, .sse2 },
    .{ .psrld, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd2 }, 0x0, .none, .sse2 },
    .{ .psrld, .mi, &.{ .xmm, .imm8 }, &.{ 0x66, 0xf, 0x72 }, 0x2, .none, .sse2 },
    .{ .psrlq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd3 }, 0x0, .none, .sse2 },
    .{ .psrlq, .mi, &.{ .xmm, .imm8 }, &.{ 0x66, 0xf, 0x73 }, 0x2, .none, .sse2 },
    .{ .psrlw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd1 }, 0x0, .none, .sse2 },
    .{ .psrlw, .mi, &.{ .xmm, .imm8 }, &.{ 0x66, 0xf, 0x71 }, 0x2, .none, .sse2 },
    .{ .punpckhbw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x68 }, 0x0, .none, .sse2 },
    .{ .punpckhdq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6a }, 0x0, .none, .sse2 },
    .{ .punpckhqdq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6d }, 0x0, .none, .sse2 },
    .{ .punpckhwd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x69 }, 0x0, .none, .sse2 },
    .{ .punpcklbw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x60 }, 0x0, .none, .sse2 },
    .{ .punpckldq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x62 }, 0x0, .none, .sse2 },
    .{ .punpcklqdq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6c }, 0x0, .none, .sse2 },
    .{ .punpcklwd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x61 }, 0x0, .none, .sse2 },
    .{ .shufpd, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0xc6 }, 0x0, .none, .sse2 },
    .{ .sqrtpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x51 }, 0x0, .none, .sse2 },
    .{ .sqrtsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x51 }, 0x0, .none, .sse2 },
    .{ .subpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5c }, 0x0, .none, .sse2 },
    .{ .subsd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5c }, 0x0, .none, .sse2 },
    .{ .ucomisd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0x66, 0xf, 0x2e }, 0x0, .none, .sse2 },
    .{ .xorpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x57 }, 0x0, .none, .sse2 },
    .{ .movddup, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x12 }, 0x0, .none, .sse3 },
    .{ .movshdup, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x16 }, 0x0, .none, .sse3 },
    .{ .movsldup, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x12 }, 0x0, .none, .sse3 },
    .{ .blendpd, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xd }, 0x0, .none, .sse4_1 },
    .{ .blendps, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xc }, 0x0, .none, .sse4_1 },
    .{ .blendvpd, .rm0, &.{ .xmm, .xmm_m128, .xmm0 }, &.{ 0x66, 0xf, 0x38, 0x15 }, 0x0, .none, .sse4_1 },
    .{ .blendvps, .rm0, &.{ .xmm, .xmm_m128, .xmm0 }, &.{ 0x66, 0xf, 0x38, 0x14 }, 0x0, .none, .sse4_1 },
    .{ .extractps, .mri, &.{ .rm32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x17 }, 0x0, .none, .sse4_1 },
    .{ .insertps, .rmi, &.{ .xmm, .xmm_m32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x21 }, 0x0, .none, .sse4_1 },
    .{ .packusdw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x2b }, 0x0, .none, .sse4_1 },
    .{ .pextrb, .mri, &.{ .r32_m8, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x14 }, 0x0, .none, .sse4_1 },
    .{ .pextrd, .mri, &.{ .rm32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x16 }, 0x0, .none, .sse4_1 },
    .{ .pextrq, .mri, &.{ .rm64, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x16 }, 0x0, .long, .sse4_1 },
    .{ .pinsrb, .rmi, &.{ .xmm, .r32_m8, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x20 }, 0x0, .none, .sse4_1 },
    .{ .pinsrd, .rmi, &.{ .xmm, .rm32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x22 }, 0x0, .none, .sse4_1 },
    .{ .pinsrq, .rmi, &.{ .xmm, .rm64, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x22 }, 0x0, .long, .sse4_1 },
    .{ .pmaxsb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3c }, 0x0, .none, .sse4_1 },
    .{ .pmaxsd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3d }, 0x0, .none, .sse4_1 },
    .{ .pmaxud, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3f }, 0x0, .none, .sse4_1 },
    .{ .pmaxuw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3e }, 0x0, .none, .sse4_1 },
    .{ .pminsb, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x38 }, 0x0, .none, .sse4_1 },
    .{ .pminsd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x39 }, 0x0, .none, .sse4_1 },
    .{ .pminud, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3b }, 0x0, .none, .sse4_1 },
    .{ .pminuw, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3a }, 0x0, .none, .sse4_1 },
    .{ .pmulld, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x40 }, 0x0, .none, .sse4_1 },
    .{ .roundpd, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x9 }, 0x0, .none, .sse4_1 },
    .{ .roundps, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x8 }, 0x0, .none, .sse4_1 },
    .{ .roundsd, .rmi, &.{ .xmm, .xmm_m64, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xb }, 0x0, .none, .sse4_1 },
    .{ .roundss, .rmi, &.{ .xmm, .xmm_m32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xa }, 0x0, .none, .sse4_1 },
    .{ .vaddpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x58 }, 0x0, .vex_128_wig, .avx },
    .{ .vaddpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x58 }, 0x0, .vex_256_wig, .avx },
    .{ .vaddps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x58 }, 0x0, .vex_128_wig, .avx },
    .{ .vaddps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x58 }, 0x0, .vex_256_wig, .avx },
    .{ .vaddsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x58 }, 0x0, .vex_lig_wig, .avx },
    .{ .vaddss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x58 }, 0x0, .vex_lig_wig, .avx },
    .{ .vandnpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x55 }, 0x0, .vex_128_wig, .avx },
    .{ .vandnpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x55 }, 0x0, .vex_256_wig, .avx },
    .{ .vandnps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x55 }, 0x0, .vex_128_wig, .avx },
    .{ .vandnps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x55 }, 0x0, .vex_256_wig, .avx },
    .{ .vandpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x54 }, 0x0, .vex_128_wig, .avx },
    .{ .vandpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x54 }, 0x0, .vex_256_wig, .avx },
    .{ .vandps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x54 }, 0x0, .vex_128_wig, .avx },
    .{ .vandps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x54 }, 0x0, .vex_256_wig, .avx },
    .{ .vblendpd, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xd }, 0x0, .vex_128_wig, .avx },
    .{ .vblendpd, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xd }, 0x0, .vex_256_wig, .avx },
    .{ .vblendps, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xc }, 0x0, .vex_128_wig, .avx },
    .{ .vblendps, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xc }, 0x0, .vex_256_wig, .avx },
    .{ .vblendvpd, .rvmr, &.{ .xmm, .xmm, .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x3a, 0x4b }, 0x0, .vex_128_w0, .avx },
    .{ .vblendvpd, .rvmr, &.{ .ymm, .ymm, .ymm_m256, .ymm }, &.{ 0x66, 0xf, 0x3a, 0x4b }, 0x0, .vex_256_w0, .avx },
    .{ .vblendvps, .rvmr, &.{ .xmm, .xmm, .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x3a, 0x4a }, 0x0, .vex_128_w0, .avx },
    .{ .vblendvps, .rvmr, &.{ .ymm, .ymm, .ymm_m256, .ymm }, &.{ 0x66, 0xf, 0x3a, 0x4a }, 0x0, .vex_256_w0, .avx },
    .{ .vbroadcastf128, .rm, &.{ .ymm, .m128 }, &.{ 0x66, 0xf, 0x38, 0x1a }, 0x0, .vex_256_w0, .avx },
    .{ .vbroadcastsd, .rm, &.{ .ymm, .m64 }, &.{ 0x66, 0xf, 0x38, 0x19 }, 0x0, .vex_256_w0, .avx },
    .{ .vbroadcastsd, .rm, &.{ .ymm, .xmm }, &.{ 0x66, 0xf, 0x38, 0x19 }, 0x0, .vex_256_w0, .avx2 },
    .{ .vbroadcastss, .rm, &.{ .xmm, .m32 }, &.{ 0x66, 0xf, 0x38, 0x18 }, 0x0, .vex_128_w0, .avx },
    .{ .vbroadcastss, .rm, &.{ .ymm, .m32 }, &.{ 0x66, 0xf, 0x38, 0x18 }, 0x0, .vex_256_w0, .avx },
    .{ .vbroadcastss, .rm, &.{ .xmm, .xmm }, &.{ 0x66, 0xf, 0x38, 0x18 }, 0x0, .vex_128_w0, .avx2 },
    .{ .vbroadcastss, .rm, &.{ .ymm, .xmm }, &.{ 0x66, 0xf, 0x38, 0x18 }, 0x0, .vex_256_w0, .avx2 },
    .{ .vcmppd, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0xc2 }, 0x0, .vex_128_wig, .avx },
    .{ .vcmppd, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0xc2 }, 0x0, .vex_256_wig, .avx },
    .{ .vcmpps, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0xf, 0xc2 }, 0x0, .vex_128_wig, .avx },
    .{ .vcmpps, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0xf, 0xc2 }, 0x0, .vex_256_wig, .avx },
    .{ .vcmpsd, .rvmi, &.{ .xmm, .xmm, .xmm_m64, .imm8 }, &.{ 0xf2, 0xf, 0xc2 }, 0x0, .vex_lig_wig, .avx },
    .{ .vcmpss, .rvmi, &.{ .xmm, .xmm, .xmm_m32, .imm8 }, &.{ 0xf3, 0xf, 0xc2 }, 0x0, .vex_lig_wig, .avx },
    .{ .vcvtdq2pd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf3, 0xf, 0xe6 }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtdq2pd, .rm, &.{ .ymm, .xmm_m128 }, &.{ 0xf3, 0xf, 0xe6 }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtdq2ps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x5b }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtdq2ps, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf, 0x5b }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtpd2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf2, 0xf, 0xe6 }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtpd2dq, .rm, &.{ .xmm, .ymm_m256 }, &.{ 0xf2, 0xf, 0xe6 }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtpd2ps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5a }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtpd2ps, .rm, &.{ .xmm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5a }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtps2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5b }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtps2dq, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5b }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtps2pd, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf, 0x5a }, 0x0, .vex_128_wig, .avx },
    .{ .vcvtps2pd, .rm, &.{ .ymm, .xmm_m128 }, &.{ 0xf, 0x5a }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtsd2si, .rm, &.{ .r32, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2d }, 0x0, .vex_lig_w0, .sse2 },
    .{ .vcvtsd2si, .rm, &.{ .r64, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2d }, 0x0, .vex_lig_w1, .sse2 },
    .{ .vcvtsd2ss, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5a }, 0x0, .vex_lig_wig, .avx },
    .{ .vcvtsi2sd, .rvm, &.{ .xmm, .xmm, .rm32 }, &.{ 0xf2, 0xf, 0x2a }, 0x0, .vex_lig_w0, .avx },
    .{ .vcvtsi2sd, .rvm, &.{ .xmm, .xmm, .rm64 }, &.{ 0xf2, 0xf, 0x2a }, 0x0, .vex_lig_w1, .avx },
    .{ .vcvtsi2ss, .rvm, &.{ .xmm, .xmm, .rm32 }, &.{ 0xf3, 0xf, 0x2a }, 0x0, .vex_lig_w0, .avx },
    .{ .vcvtsi2ss, .rvm, &.{ .xmm, .xmm, .rm64 }, &.{ 0xf3, 0xf, 0x2a }, 0x0, .vex_lig_w1, .avx },
    .{ .vcvtss2sd, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5a }, 0x0, .vex_lig_wig, .avx },
    .{ .vcvtss2si, .rm, &.{ .r32, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2d }, 0x0, .vex_lig_w0, .avx },
    .{ .vcvtss2si, .rm, &.{ .r64, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2d }, 0x0, .vex_lig_w1, .avx },
    .{ .vcvttpd2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe6 }, 0x0, .vex_128_wig, .avx },
    .{ .vcvttpd2dq, .rm, &.{ .xmm, .ymm_m256 }, &.{ 0x66, 0xf, 0xe6 }, 0x0, .vex_256_wig, .avx },
    .{ .vcvttps2dq, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x5b }, 0x0, .vex_128_wig, .avx },
    .{ .vcvttps2dq, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf3, 0xf, 0x5b }, 0x0, .vex_256_wig, .avx },
    .{ .vcvttsd2si, .rm, &.{ .r32, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2c }, 0x0, .vex_lig_w0, .sse2 },
    .{ .vcvttsd2si, .rm, &.{ .r64, .xmm_m64 }, &.{ 0xf2, 0xf, 0x2c }, 0x0, .vex_lig_w1, .sse2 },
    .{ .vcvttss2si, .rm, &.{ .r32, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2c }, 0x0, .vex_lig_w0, .avx },
    .{ .vcvttss2si, .rm, &.{ .r64, .xmm_m32 }, &.{ 0xf3, 0xf, 0x2c }, 0x0, .vex_lig_w1, .avx },
    .{ .vdivpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5e }, 0x0, .vex_128_wig, .avx },
    .{ .vdivpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5e }, 0x0, .vex_256_wig, .avx },
    .{ .vdivps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x5e }, 0x0, .vex_128_wig, .avx },
    .{ .vdivps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x5e }, 0x0, .vex_256_wig, .avx },
    .{ .vdivsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5e }, 0x0, .vex_lig_wig, .avx },
    .{ .vdivss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5e }, 0x0, .vex_lig_wig, .avx },
    .{ .vextractf128, .mri, &.{ .xmm_m128, .ymm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x19 }, 0x0, .vex_256_w0, .avx },
    .{ .vextractps, .mri, &.{ .rm32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x17 }, 0x0, .vex_128_wig, .avx },
    .{ .vinsertf128, .rvmi, &.{ .ymm, .ymm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x18 }, 0x0, .vex_256_w0, .avx },
    .{ .vinsertps, .rvmi, &.{ .xmm, .xmm, .xmm_m32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x21 }, 0x0, .vex_128_wig, .avx },
    .{ .vmaxpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5f }, 0x0, .vex_128_wig, .avx },
    .{ .vmaxpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5f }, 0x0, .vex_256_wig, .avx },
    .{ .vmaxps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x5f }, 0x0, .vex_128_wig, .avx },
    .{ .vmaxps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x5f }, 0x0, .vex_256_wig, .avx },
    .{ .vmaxsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5f }, 0x0, .vex_lig_wig, .avx },
    .{ .vmaxss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5f }, 0x0, .vex_lig_wig, .avx },
    .{ .vminpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5d }, 0x0, .vex_128_wig, .avx },
    .{ .vminpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5d }, 0x0, .vex_256_wig, .avx },
    .{ .vminps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x5d }, 0x0, .vex_128_wig, .avx },
    .{ .vminps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x5d }, 0x0, .vex_256_wig, .avx },
    .{ .vminsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5d }, 0x0, .vex_lig_wig, .avx },
    .{ .vminss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5d }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovapd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x28 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovapd, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x29 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovapd, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x28 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovapd, .mr, &.{ .ymm_m256, .ymm }, &.{ 0x66, 0xf, 0x29 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovaps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x28 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovaps, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf, 0x29 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovaps, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf, 0x28 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovaps, .mr, &.{ .ymm_m256, .ymm }, &.{ 0xf, 0x29 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovd, .rm, &.{ .xmm, .rm32 }, &.{ 0x66, 0xf, 0x6e }, 0x0, .vex_128_w0, .avx },
    .{ .vmovd, .mr, &.{ .rm32, .xmm }, &.{ 0x66, 0xf, 0x7e }, 0x0, .vex_128_w0, .avx },
    .{ .vmovddup, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x12 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovddup, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf2, 0xf, 0x12 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovdqa, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6f }, 0x0, .vex_128_wig, .avx },
    .{ .vmovdqa, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x7f }, 0x0, .vex_128_wig, .avx },
    .{ .vmovdqa, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x6f }, 0x0, .vex_256_wig, .avx },
    .{ .vmovdqa, .mr, &.{ .ymm_m256, .ymm }, &.{ 0x66, 0xf, 0x7f }, 0x0, .vex_256_wig, .avx },
    .{ .vmovdqu, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x6f }, 0x0, .vex_128_wig, .avx },
    .{ .vmovdqu, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf3, 0xf, 0x7f }, 0x0, .vex_128_wig, .avx },
    .{ .vmovdqu, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf3, 0xf, 0x6f }, 0x0, .vex_256_wig, .avx },
    .{ .vmovdqu, .mr, &.{ .ymm_m256, .ymm }, &.{ 0xf3, 0xf, 0x7f }, 0x0, .vex_256_wig, .avx },
    .{ .vmovhlps, .rvm, &.{ .xmm, .xmm, .xmm }, &.{ 0xf, 0x12 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovlhps, .rvm, &.{ .xmm, .xmm, .xmm }, &.{ 0xf, 0x16 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovq, .rm, &.{ .xmm, .rm64 }, &.{ 0x66, 0xf, 0x6e }, 0x0, .vex_128_w1, .avx },
    .{ .vmovq, .mr, &.{ .rm64, .xmm }, &.{ 0x66, 0xf, 0x7e }, 0x0, .vex_128_w1, .avx },
    .{ .vmovq, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0xf3, 0xf, 0x7e }, 0x0, .vex_128_wig, .avx },
    .{ .vmovq, .mr, &.{ .xmm_m64, .xmm }, &.{ 0x66, 0xf, 0xd6 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovsd, .rvm, &.{ .xmm, .xmm, .xmm }, &.{ 0xf2, 0xf, 0x10 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovsd, .rm, &.{ .xmm, .m64 }, &.{ 0xf2, 0xf, 0x10 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovsd, .mvr, &.{ .xmm, .xmm, .xmm }, &.{ 0xf2, 0xf, 0x11 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovsd, .mr, &.{ .m64, .xmm }, &.{ 0xf2, 0xf, 0x11 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovshdup, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x16 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovshdup, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf3, 0xf, 0x16 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovsldup, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf3, 0xf, 0x12 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovsldup, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf3, 0xf, 0x12 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovss, .rvm, &.{ .xmm, .xmm, .xmm }, &.{ 0xf3, 0xf, 0x10 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovss, .rm, &.{ .xmm, .m32 }, &.{ 0xf3, 0xf, 0x10 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovss, .mvr, &.{ .xmm, .xmm, .xmm }, &.{ 0xf3, 0xf, 0x11 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovss, .mr, &.{ .m32, .xmm }, &.{ 0xf3, 0xf, 0x11 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmovupd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x10 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovupd, .mr, &.{ .xmm_m128, .xmm }, &.{ 0x66, 0xf, 0x11 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovupd, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x10 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovupd, .mr, &.{ .ymm_m256, .ymm }, &.{ 0x66, 0xf, 0x11 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovups, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x10 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovups, .mr, &.{ .xmm_m128, .xmm }, &.{ 0xf, 0x11 }, 0x0, .vex_128_wig, .avx },
    .{ .vmovups, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf, 0x10 }, 0x0, .vex_256_wig, .avx },
    .{ .vmovups, .mr, &.{ .ymm_m256, .ymm }, &.{ 0xf, 0x11 }, 0x0, .vex_256_wig, .avx },
    .{ .vmulpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x59 }, 0x0, .vex_128_wig, .avx },
    .{ .vmulpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x59 }, 0x0, .vex_256_wig, .avx },
    .{ .vmulps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x59 }, 0x0, .vex_128_wig, .avx },
    .{ .vmulps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x59 }, 0x0, .vex_256_wig, .avx },
    .{ .vmulsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x59 }, 0x0, .vex_lig_wig, .avx },
    .{ .vmulss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x59 }, 0x0, .vex_lig_wig, .avx },
    .{ .vorpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x56 }, 0x0, .vex_128_wig, .avx },
    .{ .vorpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x56 }, 0x0, .vex_256_wig, .avx },
    .{ .vorps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x56 }, 0x0, .vex_128_wig, .avx },
    .{ .vorps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x56 }, 0x0, .vex_256_wig, .avx },
    .{ .vpackssdw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6b }, 0x0, .vex_128_wig, .avx },
    .{ .vpackssdw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x6b }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpacksswb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x63 }, 0x0, .vex_128_wig, .avx },
    .{ .vpacksswb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x63 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpackusdw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x2b }, 0x0, .vex_128_wig, .avx },
    .{ .vpackusdw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x2b }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpackuswb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x67 }, 0x0, .vex_128_wig, .avx },
    .{ .vpackuswb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x67 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfc }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xfc }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfe }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xfe }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd4 }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xd4 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddsb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xec }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddsb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xec }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddsw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xed }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddsw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xed }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddusb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdc }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddusb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xdc }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddusw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdd }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddusw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xdd }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpaddw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfd }, 0x0, .vex_128_wig, .avx },
    .{ .vpaddw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xfd }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpand, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdb }, 0x0, .vex_128_wig, .avx },
    .{ .vpand, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xdb }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpandn, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xdf }, 0x0, .vex_128_wig, .avx },
    .{ .vpandn, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xdf }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpextrb, .mri, &.{ .r32_m8, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x14 }, 0x0, .vex_128_w0, .avx },
    .{ .vpextrd, .mri, &.{ .rm32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x16 }, 0x0, .vex_128_w0, .avx },
    .{ .vpextrq, .mri, &.{ .rm64, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x16 }, 0x0, .vex_128_w1, .avx },
    .{ .vpextrw, .rmi, &.{ .r32, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x15 }, 0x0, .vex_128_wig, .avx },
    .{ .vpextrw, .mri, &.{ .r32_m16, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x15 }, 0x0, .vex_128_wig, .avx },
    .{ .vpinsrb, .rmi, &.{ .xmm, .r32_m8, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x20 }, 0x0, .vex_128_w0, .avx },
    .{ .vpinsrd, .rmi, &.{ .xmm, .rm32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x22 }, 0x0, .vex_128_w0, .avx },
    .{ .vpinsrq, .rmi, &.{ .xmm, .rm64, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x22 }, 0x0, .vex_128_w1, .avx },
    .{ .vpinsrw, .rvmi, &.{ .xmm, .xmm, .r32_m16, .imm8 }, &.{ 0x66, 0xf, 0xc4 }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxsb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3c }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxsb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3c }, 0x0, .vex_256_wig, .avx },
    .{ .vpmaxsd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3d }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxsd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3d }, 0x0, .vex_256_wig, .avx },
    .{ .vpmaxsw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xee }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxsw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xee }, 0x0, .vex_256_wig, .avx },
    .{ .vpmaxub, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xde }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxub, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xde }, 0x0, .vex_256_wig, .avx },
    .{ .vpmaxud, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3f }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxud, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3f }, 0x0, .vex_256_wig, .avx },
    .{ .vpmaxuw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3e }, 0x0, .vex_128_wig, .avx },
    .{ .vpmaxuw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3e }, 0x0, .vex_256_wig, .avx },
    .{ .vpminsb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x38 }, 0x0, .vex_128_wig, .avx },
    .{ .vpminsb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x38 }, 0x0, .vex_256_wig, .avx },
    .{ .vpminsd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x39 }, 0x0, .vex_128_wig, .avx },
    .{ .vpminsd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x39 }, 0x0, .vex_256_wig, .avx },
    .{ .vpminsw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xea }, 0x0, .vex_128_wig, .avx },
    .{ .vpminsw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xea }, 0x0, .vex_256_wig, .avx },
    .{ .vpminub, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xda }, 0x0, .vex_128_wig, .avx },
    .{ .vpminub, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xda }, 0x0, .vex_256_wig, .avx },
    .{ .vpminud, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3b }, 0x0, .vex_128_wig, .avx },
    .{ .vpminud, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3b }, 0x0, .vex_256_wig, .avx },
    .{ .vpminuw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x3a }, 0x0, .vex_128_wig, .avx },
    .{ .vpminuw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x3a }, 0x0, .vex_256_wig, .avx },
    .{ .vpmulhw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe5 }, 0x0, .vex_128_wig, .avx },
    .{ .vpmulhw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xe5 }, 0x0, .vex_256_wig, .avx },
    .{ .vpmulld, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x40 }, 0x0, .vex_128_wig, .avx },
    .{ .vpmulld, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x40 }, 0x0, .vex_256_wig, .avx },
    .{ .vpmullw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd5 }, 0x0, .vex_128_wig, .avx },
    .{ .vpmullw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xd5 }, 0x0, .vex_256_wig, .avx },
    .{ .vpor, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xeb }, 0x0, .vex_128_wig, .avx },
    .{ .vpor, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xeb }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsrld, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd2 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsrld, .vmi, &.{ .xmm, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x72 }, 0x2, .vex_128_wig, .avx },
    .{ .vpsrld, .rvm, &.{ .ymm, .ymm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd2 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsrld, .vmi, &.{ .ymm, .ymm, .imm8 }, &.{ 0x66, 0xf, 0x72 }, 0x2, .vex_256_wig, .avx2 },
    .{ .vpsrlq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd3 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsrlq, .vmi, &.{ .xmm, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x73 }, 0x2, .vex_128_wig, .avx },
    .{ .vpsrlq, .rvm, &.{ .ymm, .ymm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd3 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsrlq, .vmi, &.{ .ymm, .ymm, .imm8 }, &.{ 0x66, 0xf, 0x73 }, 0x2, .vex_256_wig, .avx2 },
    .{ .vpsrlw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd1 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsrlw, .vmi, &.{ .xmm, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x71 }, 0x2, .vex_128_wig, .avx },
    .{ .vpsrlw, .rvm, &.{ .ymm, .ymm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd1 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsrlw, .vmi, &.{ .ymm, .ymm, .imm8 }, &.{ 0x66, 0xf, 0x71 }, 0x2, .vex_256_wig, .avx2 },
    .{ .vpsubb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xf8 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xf8 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfa }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xfa }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xfb }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xfb }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubsb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe8 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubsb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xe8 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubsw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xe9 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubsw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xe9 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubusb, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd8 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubusb, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xd8 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubusw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xd9 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubusw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xd9 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpsubw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xf9 }, 0x0, .vex_128_wig, .avx },
    .{ .vpsubw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xf9 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpckhbw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x68 }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpckhbw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x68 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpckhdq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6a }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpckhdq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x6a }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpckhqdq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6d }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpckhqdq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x6d }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpckhwd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x69 }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpckhwd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x69 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpcklbw, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x60 }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpcklbw, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x60 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpckldq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x62 }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpckldq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x62 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpcklqdq, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x6c }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpcklqdq, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x6c }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpunpcklwd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x61 }, 0x0, .vex_128_wig, .avx },
    .{ .vpunpcklwd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x61 }, 0x0, .vex_256_wig, .avx2 },
    .{ .vpxor, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0xef }, 0x0, .vex_128_wig, .avx },
    .{ .vpxor, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0xef }, 0x0, .vex_256_wig, .avx2 },
    .{ .vroundpd, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x9 }, 0x0, .vex_128_wig, .avx },
    .{ .vroundpd, .rmi, &.{ .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x9 }, 0x0, .vex_256_wig, .avx },
    .{ .vroundps, .rmi, &.{ .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x8 }, 0x0, .vex_128_wig, .avx },
    .{ .vroundps, .rmi, &.{ .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x8 }, 0x0, .vex_256_wig, .avx },
    .{ .vroundsd, .rvmi, &.{ .xmm, .xmm, .xmm_m64, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xb }, 0x0, .vex_lig_wig, .avx },
    .{ .vroundss, .rvmi, &.{ .xmm, .xmm, .xmm_m32, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0xa }, 0x0, .vex_lig_wig, .avx },
    .{ .vshufpd, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0x66, 0xf, 0xc6 }, 0x0, .vex_128_wig, .avx },
    .{ .vshufpd, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0x66, 0xf, 0xc6 }, 0x0, .vex_256_wig, .avx },
    .{ .vshufps, .rvmi, &.{ .xmm, .xmm, .xmm_m128, .imm8 }, &.{ 0xf, 0xc6 }, 0x0, .vex_128_wig, .avx },
    .{ .vshufps, .rvmi, &.{ .ymm, .ymm, .ymm_m256, .imm8 }, &.{ 0xf, 0xc6 }, 0x0, .vex_256_wig, .avx },
    .{ .vsqrtpd, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x51 }, 0x0, .vex_128_wig, .avx },
    .{ .vsqrtpd, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x51 }, 0x0, .vex_256_wig, .avx },
    .{ .vsqrtps, .rm, &.{ .xmm, .xmm_m128 }, &.{ 0xf, 0x51 }, 0x0, .vex_128_wig, .avx },
    .{ .vsqrtps, .rm, &.{ .ymm, .ymm_m256 }, &.{ 0xf, 0x51 }, 0x0, .vex_256_wig, .avx },
    .{ .vsqrtsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x51 }, 0x0, .vex_lig_wig, .avx },
    .{ .vsqrtss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x51 }, 0x0, .vex_lig_wig, .avx },
    .{ .vsubpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x5c }, 0x0, .vex_128_wig, .avx },
    .{ .vsubpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x5c }, 0x0, .vex_256_wig, .avx },
    .{ .vsubps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x5c }, 0x0, .vex_128_wig, .avx },
    .{ .vsubps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x5c }, 0x0, .vex_256_wig, .avx },
    .{ .vsubsd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0xf2, 0xf, 0x5c }, 0x0, .vex_lig_wig, .avx },
    .{ .vsubss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0xf3, 0xf, 0x5c }, 0x0, .vex_lig_wig, .avx },
    .{ .vxorpd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x57 }, 0x0, .vex_128_wig, .avx },
    .{ .vxorpd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x57 }, 0x0, .vex_256_wig, .avx },
    .{ .vxorps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0xf, 0x57 }, 0x0, .vex_128_wig, .avx },
    .{ .vxorps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0xf, 0x57 }, 0x0, .vex_256_wig, .avx },
    .{ .vcvtph2ps, .rm, &.{ .xmm, .xmm_m64 }, &.{ 0x66, 0xf, 0x38, 0x13 }, 0x0, .vex_128_w0, .f16c },
    .{ .vcvtph2ps, .rm, &.{ .ymm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x13 }, 0x0, .vex_256_w0, .f16c },
    .{ .vcvtps2ph, .mri, &.{ .xmm_m64, .xmm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x1d }, 0x0, .vex_128_w0, .f16c },
    .{ .vcvtps2ph, .mri, &.{ .xmm_m128, .ymm, .imm8 }, &.{ 0x66, 0xf, 0x3a, 0x1d }, 0x0, .vex_256_w0, .f16c },
    .{ .vfmadd132pd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x98 }, 0x0, .vex_128_w1, .fma },
    .{ .vfmadd132pd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x98 }, 0x0, .vex_256_w1, .fma },
    .{ .vfmadd213pd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0xa8 }, 0x0, .vex_128_w1, .fma },
    .{ .vfmadd213pd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0xa8 }, 0x0, .vex_256_w1, .fma },
    .{ .vfmadd231pd, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0xb8 }, 0x0, .vex_128_w1, .fma },
    .{ .vfmadd231pd, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0xb8 }, 0x0, .vex_256_w1, .fma },
    .{ .vfmadd132ps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0x98 }, 0x0, .vex_128_w0, .fma },
    .{ .vfmadd132ps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0x98 }, 0x0, .vex_256_w0, .fma },
    .{ .vfmadd213ps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0xa8 }, 0x0, .vex_128_w0, .fma },
    .{ .vfmadd213ps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0xa8 }, 0x0, .vex_256_w0, .fma },
    .{ .vfmadd231ps, .rvm, &.{ .xmm, .xmm, .xmm_m128 }, &.{ 0x66, 0xf, 0x38, 0xb8 }, 0x0, .vex_128_w0, .fma },
    .{ .vfmadd231ps, .rvm, &.{ .ymm, .ymm, .ymm_m256 }, &.{ 0x66, 0xf, 0x38, 0xb8 }, 0x0, .vex_256_w0, .fma },
    .{ .vfmadd132sd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0x66, 0xf, 0x38, 0x99 }, 0x0, .vex_lig_w1, .fma },
    .{ .vfmadd213sd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0x66, 0xf, 0x38, 0xa9 }, 0x0, .vex_lig_w1, .fma },
    .{ .vfmadd231sd, .rvm, &.{ .xmm, .xmm, .xmm_m64 }, &.{ 0x66, 0xf, 0x38, 0xb9 }, 0x0, .vex_lig_w1, .fma },
    .{ .vfmadd132ss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0x66, 0xf, 0x38, 0x99 }, 0x0, .vex_lig_w0, .fma },
    .{ .vfmadd213ss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0x66, 0xf, 0x38, 0xa9 }, 0x0, .vex_lig_w0, .fma },
    .{ .vfmadd231ss, .rvm, &.{ .xmm, .xmm, .xmm_m32 }, &.{ 0x66, 0xf, 0x38, 0xb9 }, 0x0, .vex_lig_w0, .fma },
};
pub const Encoding = struct {
    mnemonic: Mnemonic,
    data: Data,
    const Data = struct {
        op_en: OpEn,
        ops: [4]Op,
        opc_len: u3,
        opc: [7]u8,
        modrm_ext: u3,
        mode: Mode,
        feature: Feature,
    };
    pub const Entry = struct {
        Encoding.Mnemonic,
        OpEn,
        []const Op,
        []const u8,
        u3,
        Mode,
        Feature,
    };
    fn sortEntry(_: void, lhs: Entry, rhs: Entry) bool {
        return @intFromEnum(lhs[0]) < @intFromEnum(rhs[0]);
    }
    pub fn findByMnemonic(
        prefix: Instruction.Prefix,
        mnemonic: Mnemonic,
        ops: []const Instruction.Operand,
    ) !?Encoding {
        var input_ops = [1]Op{.none} ** 4;
        for (input_ops[0..ops.len], ops) |*input_op, op| input_op.* = Op.fromOperand(op);
        const rex_required = for (ops) |op| switch (op) {
            .register => |r| switch (r) {
                .spl, .bpl, .sil, .dil => break true,
                else => {},
            },
            else => {},
        } else false;
        const rex_invalid = for (ops) |op| switch (op) {
            .register => |r| switch (r) {
                .ah, .bh, .ch, .dh => break true,
                else => {},
            },
            else => {},
        } else false;
        const rex_extended = for (ops) |op| {
            if (op.isBaseExtended() or op.isIndexExtended()) break true;
        } else false;
        if ((rex_required or rex_extended) and rex_invalid) return error.CannotEncode;
        var shortest_enc: ?Encoding = null;
        var shortest_len: ?usize = null;
        next: for (mnemonic_to_encodings_map[@intFromEnum(mnemonic)]) |data| {
            switch (data.mode) {
                .none, .short => if (rex_required) continue,
                .rex, .rex_short => if (!rex_required) continue,
                else => {},
            }
            for (input_ops, data.ops) |input_op, data_op|
                if (!input_op.isSubset(data_op)) continue :next;
            const enc = Encoding{ .mnemonic = mnemonic, .data = data };
            if (shortest_enc) |previous_shortest_enc| {
                const len = estimateInstructionLength(prefix, enc, ops);
                const previous_shortest_len = shortest_len orelse
                    estimateInstructionLength(prefix, previous_shortest_enc, ops);
                if (len < previous_shortest_len) {
                    shortest_enc = enc;
                    shortest_len = len;
                } else shortest_len = previous_shortest_len;
            } else shortest_enc = enc;
        }
        return shortest_enc;
    }
    /// Returns first matching encoding by opcode.
    pub fn findByOpcode(opc: []const u8, prefixes: struct {
        legacy: LegacyPrefixes,
        rex: Rex,
    }, modrm_ext: ?u3) ?Encoding {
        for (mnemonic_to_encodings_map, 0..) |encs, mnemonic_int| for (encs) |data| {
            const enc = Encoding{ .mnemonic = @as(Mnemonic, @enumFromInt(mnemonic_int)), .data = data };
            if (modrm_ext) |ext| if (ext != data.modrm_ext) continue;
            if (!mem.testEqualString(opc, enc.opcode())) continue;
            if (prefixes.rex.w) {
                if (!data.mode.isLong()) continue;
            } else if (prefixes.rex.present and !prefixes.rex.isSet()) {
                if (!data.mode.isRex()) continue;
            } else if (prefixes.legacy.prefix_66) {
                if (!data.mode.isShort()) continue;
            } else {
                if (data.mode.isShort()) continue;
            }
            return enc;
        };
        return null;
    }
    pub fn opcode(encoding: *const Encoding) []const u8 {
        return encoding.data.opc[0..encoding.data.opc_len];
    }
    pub fn mandatoryPrefix(encoding: *const Encoding) ?u8 {
        const prefix = encoding.data.opc[0];
        return switch (prefix) {
            0x66, 0xf2, 0xf3 => prefix,
            else => null,
        };
    }
    pub fn modRmExt(encoding: Encoding) u3 {
        return switch (encoding.data.op_en) {
            .m, .mi, .m1, .mc, .vmi => encoding.data.modrm_ext,
            else => unreachable,
        };
    }
    pub const Mnemonic = enum {
        adc,
        add,
        @"and",
        bsf,
        bsr,
        bswap,
        bt,
        btc,
        btr,
        bts,
        call,
        cbw,
        cdq,
        cdqe,
        cmova,
        cmovae,
        cmovb,
        cmovbe,
        cmovc,
        cmove,
        cmovg,
        cmovge,
        cmovl,
        cmovle,
        cmovna,
        cmovnae,
        cmovnb,
        cmovnbe,
        cmovnc,
        cmovne,
        cmovng,
        cmovnge,
        cmovnl,
        cmovnle,
        cmovno,
        cmovnp,
        cmovns,
        cmovnz,
        cmovo,
        cmovp,
        cmovpe,
        cmovpo,
        cmovs,
        cmovz,
        cmp,
        cmps,
        cmpsb,
        cmpsd,
        cmpsq,
        cmpsw,
        cmpxchg,
        cmpxchg8b,
        cmpxchg16b,
        cqo,
        cwd,
        cwde,
        div,
        endbr64,
        hlt,
        idiv,
        imul,
        int3,
        ja,
        jae,
        jb,
        jbe,
        jc,
        jrcxz,
        je,
        jg,
        jge,
        jl,
        jle,
        jna,
        jnae,
        jnb,
        jnbe,
        jnc,
        jne,
        jng,
        jnge,
        jnl,
        jnle,
        jno,
        jnp,
        jns,
        jnz,
        jo,
        jp,
        jpe,
        jpo,
        js,
        jz,
        jmp,
        lea,
        leave,
        lfence,
        lods,
        lodsb,
        lodsd,
        lodsq,
        lodsw,
        lzcnt,
        mfence,
        mov,
        movbe,
        movs,
        movsb,
        movsd,
        movsq,
        movsw,
        movsx,
        movsxd,
        movzx,
        mul,
        neg,
        nop,
        not,
        @"or",
        pop,
        popcnt,
        push,
        rcl,
        rcr,
        ret,
        rol,
        ror,
        sal,
        sar,
        sbb,
        scas,
        scasb,
        scasd,
        scasq,
        scasw,
        shl,
        shld,
        shr,
        shrd,
        sub,
        syscall,
        seta,
        setae,
        setb,
        setbe,
        setc,
        sete,
        setg,
        setge,
        setl,
        setle,
        setna,
        setnae,
        setnb,
        setnbe,
        setnc,
        setne,
        setng,
        setnge,
        setnl,
        setnle,
        setno,
        setnp,
        setns,
        setnz,
        seto,
        setp,
        setpe,
        setpo,
        sets,
        setz,
        sfence,
        stos,
        stosb,
        stosd,
        stosq,
        stosw,
        @"test",
        tzcnt,
        ud2,
        xadd,
        xchg,
        xor,
        // X87
        fisttp,
        fld,
        // MMX
        movd,
        movq,
        packssdw,
        packsswb,
        packuswb,
        paddb,
        paddd,
        paddq,
        paddsb,
        paddsw,
        paddusb,
        paddusw,
        paddw,
        pand,
        pandn,
        por,
        pxor,
        pmulhw,
        pmullw,
        psubb,
        psubd,
        psubq,
        psubsb,
        psubsw,
        psubusb,
        psubusw,
        psubw,
        // SSE
        addps,
        addss,
        andps,
        andnps,
        cmpps,
        cmpss,
        cvtpi2ps,
        cvtps2pi,
        cvtsi2ss,
        cvtss2si,
        cvttps2pi,
        cvttss2si,
        divps,
        divss,
        maxps,
        maxss,
        minps,
        minss,
        movaps,
        movhlps,
        movlhps,
        movss,
        movups,
        mulps,
        mulss,
        orps,
        pextrw,
        pinsrw,
        pmaxsw,
        pmaxub,
        pminsw,
        pminub,
        shufps,
        sqrtps,
        sqrtss,
        subps,
        subss,
        ucomiss,
        xorps,
        // SSE2
        addpd,
        addsd,
        andpd,
        andnpd,
        cmppd, //cmpsd,
        cvtdq2pd,
        cvtdq2ps,
        cvtpd2dq,
        cvtpd2pi,
        cvtpd2ps,
        cvtpi2pd,
        cvtps2dq,
        cvtps2pd,
        cvtsd2si,
        cvtsd2ss,
        cvtsi2sd,
        cvtss2sd,
        cvttpd2dq,
        cvttpd2pi,
        cvttps2dq,
        cvttsd2si,
        divpd,
        divsd,
        maxpd,
        maxsd,
        minpd,
        minsd,
        movapd,
        movdqa,
        movdqu,
        //movsd,
        movupd,
        mulpd,
        mulsd,
        orpd,
        pshufhw,
        pshuflw,
        psrld,
        psrlq,
        psrlw,
        punpckhbw,
        punpckhdq,
        punpckhqdq,
        punpckhwd,
        punpcklbw,
        punpckldq,
        punpcklqdq,
        punpcklwd,
        shufpd,
        sqrtpd,
        sqrtsd,
        subpd,
        subsd,
        ucomisd,
        xorpd,
        // SSE3
        movddup,
        movshdup,
        movsldup,
        // SSE4.1
        blendpd,
        blendps,
        blendvpd,
        blendvps,
        extractps,
        insertps,
        packusdw,
        pextrb,
        pextrd,
        pextrq,
        pinsrb,
        pinsrd,
        pinsrq,
        pmaxsb,
        pmaxsd,
        pmaxud,
        pmaxuw,
        pminsb,
        pminsd,
        pminud,
        pminuw,
        pmulld,
        roundpd,
        roundps,
        roundsd,
        roundss,
        // AVX
        vaddpd,
        vaddps,
        vaddsd,
        vaddss,
        vandnpd,
        vandnps,
        vandpd,
        vandps,
        vblendpd,
        vblendps,
        vblendvpd,
        vblendvps,
        vbroadcastf128,
        vbroadcastsd,
        vbroadcastss,
        vcmppd,
        vcmpps,
        vcmpsd,
        vcmpss,
        vcvtdq2pd,
        vcvtdq2ps,
        vcvtpd2dq,
        vcvtpd2ps,
        vcvtps2dq,
        vcvtps2pd,
        vcvtsd2si,
        vcvtsd2ss,
        vcvtsi2sd,
        vcvtsi2ss,
        vcvtss2sd,
        vcvtss2si,
        vcvttpd2dq,
        vcvttps2dq,
        vcvttsd2si,
        vcvttss2si,
        vdivpd,
        vdivps,
        vdivsd,
        vdivss,
        vextractf128,
        vextractps,
        vinsertf128,
        vinsertps,
        vmaxpd,
        vmaxps,
        vmaxsd,
        vmaxss,
        vminpd,
        vminps,
        vminsd,
        vminss,
        vmovapd,
        vmovaps,
        vmovd,
        vmovddup,
        vmovdqa,
        vmovdqu,
        vmovhlps,
        vmovlhps,
        vmovq,
        vmovsd,
        vmovshdup,
        vmovsldup,
        vmovss,
        vmovupd,
        vmovups,
        vmulpd,
        vmulps,
        vmulsd,
        vmulss,
        vorpd,
        vorps,
        vpackssdw,
        vpacksswb,
        vpackusdw,
        vpackuswb,
        vpaddb,
        vpaddd,
        vpaddq,
        vpaddsb,
        vpaddsw,
        vpaddusb,
        vpaddusw,
        vpaddw,
        vpand,
        vpandn,
        vpextrb,
        vpextrd,
        vpextrq,
        vpextrw,
        vpinsrb,
        vpinsrd,
        vpinsrq,
        vpinsrw,
        vpmaxsb,
        vpmaxsd,
        vpmaxsw,
        vpmaxub,
        vpmaxud,
        vpmaxuw,
        vpminsb,
        vpminsd,
        vpminsw,
        vpminub,
        vpminud,
        vpminuw,
        vpmulhw,
        vpmulld,
        vpmullw,
        vpor,
        vpshufhw,
        vpshuflw,
        vpsrld,
        vpsrlq,
        vpsrlw,
        vpsubb,
        vpsubd,
        vpsubq,
        vpsubsb,
        vpsubsw,
        vpsubusb,
        vpsubusw,
        vpsubw,
        vpunpckhbw,
        vpunpckhdq,
        vpunpckhqdq,
        vpunpckhwd,
        vpunpcklbw,
        vpunpckldq,
        vpunpcklqdq,
        vpunpcklwd,
        vpxor,
        vroundpd,
        vroundps,
        vroundsd,
        vroundss,
        vshufpd,
        vshufps,
        vsqrtpd,
        vsqrtps,
        vsqrtsd,
        vsqrtss,
        vsubpd,
        vsubps,
        vsubsd,
        vsubss,
        vxorpd,
        vxorps,
        // F16C
        vcvtph2ps,
        vcvtps2ph,
        // FMA
        vfmadd132pd,
        vfmadd213pd,
        vfmadd231pd,
        vfmadd132ps,
        vfmadd213ps,
        vfmadd231ps,
        vfmadd132sd,
        vfmadd213sd,
        vfmadd231sd,
        vfmadd132ss,
        vfmadd213ss,
        vfmadd231ss,
    };
    pub const OpEn = enum(u8) {
        np,
        o,
        oi,
        i,
        zi,
        d,
        m,
        fd,
        td,
        m1,
        mc,
        mi,
        mr,
        rm,
        rmi,
        mri,
        mrc,
        rm0,
        vmi,
        rvm,
        rvmr,
        rvmi,
        mvr,
    };
    pub const Op = enum(u8) {
        none,
        o16,
        o32,
        o64,
        unity,
        imm8,
        imm16,
        imm32,
        imm64,
        imm8s,
        imm16s,
        imm32s,
        al,
        ax,
        eax,
        rax,
        cl,
        r8,
        r16,
        r32,
        r64,
        rm8,
        rm16,
        rm32,
        rm64,
        r32_m8,
        r32_m16,
        r64_m16,
        m8,
        m16,
        m32,
        m64,
        m80,
        m128,
        m256,
        rel8,
        rel16,
        rel32,
        m,
        moffs,
        sreg,
        st,
        mm,
        mm_m64,
        xmm0,
        xmm,
        xmm_m32,
        xmm_m64,
        xmm_m128,
        ymm,
        ymm_m256,
        pub fn fromOperand(operand: Instruction.Operand) Op {
            return switch (operand) {
                .none => .none,
                .register => |register| switch (register.class()) {
                    .general_purpose => if (register.to64() == .rax)
                        switch (register) {
                            .al => .al,
                            .ax => .ax,
                            .eax => .eax,
                            .rax => .rax,
                            else => unreachable,
                        }
                    else if (register == .cl)
                        .cl
                    else switch (register.bitSize()) {
                        8 => .r8,
                        16 => .r16,
                        32 => .r32,
                        64 => .r64,
                        else => unreachable,
                    },
                    .segment => .sreg,
                    .x87 => .st,
                    .mmx => .mm,
                    .sse => if (register == .xmm0)
                        .xmm0
                    else switch (register.bitSize()) {
                        128 => .xmm,
                        256 => .ymm,
                        else => unreachable,
                    },
                },
                .memory => |memory| switch (memory) {
                    .moffs => .moffs,
                    .sib, .rip => switch (memory.bitSize()) {
                        8 => .m8,
                        16 => .m16,
                        32 => .m32,
                        64 => .m64,
                        80 => .m80,
                        128 => .m128,
                        256 => .m256,
                        else => unreachable,
                    },
                },
                .immediate => |immediate| switch (immediate) {
                    .signed => |x| if (x == 1)
                        .unity
                    else if (math.cast(i8, x)) |_|
                        .imm8s
                    else if (math.cast(i16, x)) |_|
                        .imm16s
                    else
                        .imm32s,
                    .unsigned => |x| if (x == 1)
                        .unity
                    else if (math.cast(i8, x)) |_|
                        .imm8s
                    else if (math.cast(u8, x)) |_|
                        .imm8
                    else if (math.cast(i16, x)) |_|
                        .imm16s
                    else if (math.cast(u16, x)) |_|
                        .imm16
                    else if (math.cast(i32, x)) |_|
                        .imm32s
                    else if (math.cast(u32, x)) |_|
                        .imm32
                    else
                        .imm64,
                },
            };
        }
        pub fn immBitSize(op: Op) u64 {
            return switch (op) {
                .none, .o16, .o32, .o64, .moffs, .m, .sreg => unreachable,
                .al, .cl, .r8, .rm8, .r32_m8 => unreachable,
                .ax, .r16, .rm16 => unreachable,
                .eax, .r32, .rm32, .r32_m16 => unreachable,
                .rax, .r64, .rm64, .r64_m16 => unreachable,
                .st, .mm, .mm_m64 => unreachable,
                .xmm0, .xmm, .xmm_m32, .xmm_m64, .xmm_m128 => unreachable,
                .ymm, .ymm_m256 => unreachable,
                .m8, .m16, .m32, .m64, .m80, .m128, .m256 => unreachable,
                .unity => 1,
                .imm8, .imm8s, .rel8 => 8,
                .imm16, .imm16s, .rel16 => 16,
                .imm32, .imm32s, .rel32 => 32,
                .imm64 => 64,
            };
        }
        pub fn registerBitSize(op: Op) u64 {
            return switch (op) {
                .none, .o16, .o32, .o64, .moffs, .m, .sreg => unreachable,
                .unity, .imm8, .imm8s, .imm16, .imm16s, .imm32, .imm32s, .imm64 => unreachable,
                .rel8, .rel16, .rel32 => unreachable,
                .m8, .m16, .m32, .m64, .m80, .m128, .m256 => unreachable,
                .al, .cl, .r8, .rm8 => 8,
                .ax, .r16, .rm16 => 16,
                .eax, .r32, .rm32, .r32_m8, .r32_m16 => 32,
                .rax, .r64, .rm64, .r64_m16, .mm, .mm_m64 => 64,
                .st => 80,
                .xmm0, .xmm, .xmm_m32, .xmm_m64, .xmm_m128 => 128,
                .ymm, .ymm_m256 => 256,
            };
        }
        pub fn memBitSize(op: Op) u64 {
            return switch (op) {
                .none, .o16, .o32, .o64, .moffs, .m, .sreg => unreachable,
                .unity, .imm8, .imm8s, .imm16, .imm16s, .imm32, .imm32s, .imm64 => unreachable,
                .rel8, .rel16, .rel32 => unreachable,
                .al, .cl, .r8, .ax, .r16, .eax, .r32, .rax, .r64 => unreachable,
                .st, .mm, .xmm0, .xmm, .ymm => unreachable,
                .m8, .rm8, .r32_m8 => 8,
                .m16, .rm16, .r32_m16, .r64_m16 => 16,
                .m32, .rm32, .xmm_m32 => 32,
                .m64, .rm64, .mm_m64, .xmm_m64 => 64,
                .m80 => 80,
                .m128, .xmm_m128 => 128,
                .m256, .ymm_m256 => 256,
            };
        }
        pub fn isSigned(op: Op) bool {
            return switch (op) {
                .unity, .imm8, .imm16, .imm32, .imm64 => false,
                .imm8s, .imm16s, .imm32s => true,
                else => unreachable,
            };
        }
        pub fn isUnsigned(op: Op) bool {
            return !op.isSigned();
        }
        pub fn isRegister(op: Op) bool {
            return switch (op) {
                .cl,
                .al,
                .ax,
                .eax,
                .rax,
                .r8,
                .r16,
                .r32,
                .r64,
                .rm8,
                .rm16,
                .rm32,
                .rm64,
                .r32_m8,
                .r32_m16,
                .r64_m16,
                .st,
                .mm,
                .mm_m64,
                .xmm0,
                .xmm,
                .xmm_m32,
                .xmm_m64,
                .xmm_m128,
                .ymm,
                .ymm_m256,
                => true,
                else => false,
            };
        }
        pub fn isImmediate(op: Op) bool {
            return switch (op) {
                .imm8,
                .imm16,
                .imm32,
                .imm64,
                .imm8s,
                .imm16s,
                .imm32s,
                .rel8,
                .rel16,
                .rel32,
                .unity,
                => true,
                else => false,
            };
        }
        pub fn isMemory(op: Op) bool {
            return switch (op) {
                .rm8,
                .rm16,
                .rm32,
                .rm64,
                .r32_m8,
                .r32_m16,
                .r64_m16,
                .m8,
                .m16,
                .m32,
                .m64,
                .m80,
                .m128,
                .m256,
                .m,
                .mm_m64,
                .xmm_m32,
                .xmm_m64,
                .xmm_m128,
                .ymm_m256,
                => true,
                else => false,
            };
        }
        pub fn isSegmentRegister(op: Op) bool {
            return switch (op) {
                .moffs, .sreg => true,
                else => false,
            };
        }
        pub fn class(op: Op) Register.Class {
            return switch (op) {
                else => unreachable,
                .al, .ax, .eax, .rax, .cl => .general_purpose,
                .r8, .r16, .r32, .r64 => .general_purpose,
                .rm8, .rm16, .rm32, .rm64 => .general_purpose,
                .r32_m8, .r32_m16, .r64_m16 => .general_purpose,
                .sreg => .segment,
                .st => .x87,
                .mm, .mm_m64 => .mmx,
                .xmm0, .xmm, .xmm_m32, .xmm_m64, .xmm_m128 => .sse,
                .ymm, .ymm_m256 => .sse,
            };
        }
        /// Given an operand `op` checks if `target` is a subset for the purposes of the encoding.
        pub fn isSubset(op: Op, target: Op) bool {
            switch (op) {
                .m, .o16, .o32, .o64 => unreachable,
                .moffs, .sreg => return op == target,
                .none => switch (target) {
                    .o16, .o32, .o64, .none => return true,
                    else => return false,
                },
                else => {
                    if (op.isRegister() and target.isRegister()) {
                        return switch (target) {
                            .cl, .al, .ax, .eax, .rax, .xmm0 => op == target,
                            else => op.class() == target.class() and op.registerBitSize() == target.registerBitSize(),
                        };
                    }
                    if (op.isMemory() and target.isMemory()) {
                        switch (target) {
                            .m => return true,
                            else => return op.memBitSize() == target.memBitSize(),
                        }
                    }
                    if (op.isImmediate() and target.isImmediate()) {
                        switch (target) {
                            .imm64 => if (op.immBitSize() <= 64) return true,
                            .imm32s, .rel32 => if (op.immBitSize() < 32 or (op.immBitSize() == 32 and op.isSigned()))
                                return true,
                            .imm32 => if (op.immBitSize() <= 32) return true,
                            .imm16s, .rel16 => if (op.immBitSize() < 16 or (op.immBitSize() == 16 and op.isSigned()))
                                return true,
                            .imm16 => if (op.immBitSize() <= 16) return true,
                            .imm8s, .rel8 => if (op.immBitSize() < 8 or (op.immBitSize() == 8 and op.isSigned()))
                                return true,
                            .imm8 => if (op.immBitSize() <= 8) return true,
                            else => {},
                        }
                        return op == target;
                    }
                    return false;
                },
            }
        }
    };
    pub const Mode = enum {
        none,
        short,
        long,
        rex,
        rex_short,
        vex_128_w0,
        vex_128_w1,
        vex_128_wig,
        vex_256_w0,
        vex_256_w1,
        vex_256_wig,
        vex_lig_w0,
        vex_lig_w1,
        vex_lig_wig,
        vex_lz_w0,
        vex_lz_w1,
        vex_lz_wig,
        pub fn isShort(mode: Mode) bool {
            return switch (mode) {
                .short, .rex_short => true,
                else => false,
            };
        }
        pub fn isLong(mode: Mode) bool {
            return switch (mode) {
                .long,
                .vex_128_w1,
                .vex_256_w1,
                .vex_lig_w1,
                .vex_lz_w1,
                => true,
                else => false,
            };
        }
        pub fn isRex(mode: Mode) bool {
            return switch (mode) {
                else => false,
                .rex, .rex_short => true,
            };
        }
        pub fn isVex(mode: Mode) bool {
            return switch (mode) {
                else => false,
                .vex_128_w0,
                .vex_128_w1,
                .vex_128_wig,
                .vex_256_w0,
                .vex_256_w1,
                .vex_256_wig,
                .vex_lig_w0,
                .vex_lig_w1,
                .vex_lig_wig,
                .vex_lz_w0,
                .vex_lz_w1,
                .vex_lz_wig,
                => true,
            };
        }
        pub fn isVecLong(mode: Mode) bool {
            return switch (mode) {
                else => unreachable,
                .vex_128_w0,
                .vex_128_w1,
                .vex_128_wig,
                .vex_lig_w0,
                .vex_lig_w1,
                .vex_lig_wig,
                .vex_lz_w0,
                .vex_lz_w1,
                .vex_lz_wig,
                => false,
                .vex_256_w0,
                .vex_256_w1,
                .vex_256_wig,
                => true,
            };
        }
    };
    pub const Feature = enum {
        none,
        avx,
        avx2,
        bmi,
        f16c,
        fma,
        lzcnt,
        movbe,
        popcnt,
        sse,
        sse2,
        sse3,
        sse4_1,
        x87,
    };
    fn estimateInstructionLength(prefix: Instruction.Prefix, encoding: Encoding, ops: []const Instruction.Operand) usize {
        var inst = Instruction{
            .prefix = prefix,
            .encoding = encoding,
            .ops = [1]Instruction.Operand{.none} ** 4,
        };
        @memcpy(inst.ops[0..ops.len], ops);
        var buf: [512]u8 = undefined;
        return inst.encode(&buf);
    }
    pub const mnemonic_to_encodings_map = init: {
        @setEvalBranchQuota(100_000);
        var data_storage: [tab.len]Data = undefined;
        var mnemonic_map: [@typeInfo(Mnemonic).Enum.fields.len][]const Data = undefined;
        var mnemonic_int = 0;
        var mnemonic_start = 0;
        for (&data_storage, tab, 0..) |*data, entry, data_index| {
            data.* = .{
                .op_en = entry[1],
                .ops = undefined,
                .opc_len = entry[3].len,
                .opc = undefined,
                .modrm_ext = entry[4],
                .mode = entry[5],
                .feature = entry[6],
            };
            // TODO: use `@memcpy` for these. When I did that, I got a false positive
            // compile error for this copy happening at compile time.
            for (entry[2], 0..) |val, idx| data.ops[idx] = val;
            for (entry[3], 0..) |val, idx| data.opc[idx] = val;
            while (mnemonic_int < @intFromEnum(entry[0])) : (mnemonic_int +%= 1) {
                mnemonic_map[mnemonic_int] = data_storage[mnemonic_start..data_index];
                mnemonic_start = data_index;
            }
        }
        while (mnemonic_int < mnemonic_map.len) : (mnemonic_int +%= 1) {
            mnemonic_map[mnemonic_int] = data_storage[mnemonic_start..];
            mnemonic_start = data_storage.len;
        }
        break :init mnemonic_map;
    };
};
pub const Disassembler = struct {
    buf: []const u8,
    buf_pos: usize = 0,
    pub const Error = error{
        EndOfStream,
        LegacyPrefixAfterRex,
        UnknownOpcode,
        Todo,
    };
    pub fn init(buf: []const u8) Disassembler {
        return .{ .buf = buf };
    }
    pub fn next(dis: *Disassembler) Error!?Instruction {
        @setRuntimeSafety(builtin.is_safe);
        const prefixes = dis.parsePrefixes() catch |err| switch (err) {
            error.EndOfStream => return null,
            else => |e| return e,
        };
        const enc: Encoding = try dis.parseEncoding(prefixes);
        switch (enc.data.op_en) {
            .np => return inst(enc, .{}),
            .d, .i => {
                return inst(enc, .{ .op1 = .{ .immediate = dis.parseImmediate(enc.data.ops[0]) } });
            },
            .zi => {
                return inst(enc, .{
                    .op1 = .{ .register = Register.rax.toBitSize(enc.data.ops[0].registerBitSize()) },
                    .op2 = .{ .immediate = dis.parseImmediate(enc.data.ops[1]) },
                });
            },
            .o, .oi => {
                const reg_low_enc: u3 = @truncate(dis.buf[dis.buf_pos - 1]);
                return inst(enc, .{
                    .op1 = .{ .register = parseGpRegister(reg_low_enc, prefixes.rex.b, prefixes.rex, enc.data.ops[0].registerBitSize()) },
                    .op2 = if (enc.data.op_en == .oi) .{ .immediate = dis.parseImmediate(enc.data.ops[1]) } else .none,
                });
            },
            .m, .mi, .m1, .mc => {
                const modrm = try dis.parseModRmByte();
                const act_enc = Encoding.findByOpcode(enc.opcode(), .{
                    .legacy = prefixes.legacy,
                    .rex = prefixes.rex,
                }, modrm.op1) orelse return error.UnknownOpcode;
                const sib = if (modrm.sib()) try dis.parseSibByte() else null;
                if (modrm.direct()) {
                    return inst(act_enc, .{
                        .op1 = .{ .register = parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, act_enc.data.ops[0].registerBitSize()) },
                        .op2 = switch (act_enc.data.op_en) {
                            .mi => .{ .immediate = dis.parseImmediate(act_enc.data.ops[1]) },
                            .m1 => .{ .immediate = Immediate.u(1) },
                            .mc => .{ .register = .cl },
                            else => .none,
                        },
                    });
                }
                const disp = dis.parseDisplacement(modrm, sib);
                if (modrm.rip()) {
                    return inst(act_enc, .{
                        .op1 = .{ .memory = Memory.rip(Memory.PtrSize.fromBitSize(act_enc.data.ops[0].memBitSize()), disp) },
                        .op2 = switch (act_enc.data.op_en) {
                            .mi => .{ .immediate = dis.parseImmediate(act_enc.data.ops[1]) },
                            .m1 => .{ .immediate = Immediate.u(1) },
                            .mc => .{ .register = .cl },
                            else => .none,
                        },
                    });
                }
                const scale_index = if (sib) |info| info.scaleIndex(prefixes.rex) else null;
                const base = if (sib) |info|
                    info.baseReg(modrm, prefixes)
                else
                    parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, 64);
                return inst(act_enc, .{
                    .op1 = .{ .memory = Memory.sib(Memory.PtrSize.fromBitSize(act_enc.data.ops[0].memBitSize()), .{
                        .base = if (base) |base_reg| .{ .register = base_reg } else .none,
                        .scale_index = scale_index,
                        .disp = disp,
                    }) },
                    .op2 = switch (act_enc.data.op_en) {
                        .mi => .{ .immediate = dis.parseImmediate(act_enc.data.ops[1]) },
                        .m1 => .{ .immediate = Immediate.u(1) },
                        .mc => .{ .register = .cl },
                        else => .none,
                    },
                });
            },
            .fd => {
                const seg = segmentRegister(prefixes.legacy);
                const offset: u64 = @as(*align(1) const u64, @ptrCast(dis.buf[dis.buf_pos..].ptr)).*;
                dis.buf_pos +%= 8;
                return inst(enc, .{
                    .op1 = .{ .register = Register.rax.toBitSize(enc.data.ops[0].registerBitSize()) },
                    .op2 = .{ .memory = Memory.moffs(seg, offset) },
                });
            },
            .td => {
                const seg = segmentRegister(prefixes.legacy);
                const offset: u64 = @as(*align(1) const u64, @ptrCast(dis.buf[dis.buf_pos..].ptr)).*;
                dis.buf_pos +%= 8;
                return inst(enc, .{
                    .op1 = .{ .memory = Memory.moffs(seg, offset) },
                    .op2 = .{ .register = Register.rax.toBitSize(enc.data.ops[1].registerBitSize()) },
                });
            },
            .mr, .mri, .mrc => {
                const modrm = try dis.parseModRmByte();
                const sib = if (modrm.sib()) try dis.parseSibByte() else null;
                const src_bit_size = enc.data.ops[1].registerBitSize();
                if (modrm.direct()) {
                    return inst(enc, .{
                        .op1 = .{ .register = parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, enc.data.ops[0].registerBitSize()) },
                        .op2 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.x, prefixes.rex, src_bit_size) },
                    });
                }

                if (modrm.rip()) {
                    return inst(enc, .{
                        .op1 = .{ .memory = Memory.rip(Memory.PtrSize.fromBitSize(enc.data.ops[0].memBitSize()), dis.parseDisplacement(modrm, sib)) },
                        .op2 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.r, prefixes.rex, src_bit_size) },
                        .op3 = switch (enc.data.op_en) {
                            .mri => .{ .immediate = dis.parseImmediate(enc.data.ops[2]) },
                            .mrc => .{ .register = .cl },
                            else => .none,
                        },
                    });
                }
                const scale_index = if (sib) |info| info.scaleIndex(prefixes.rex) else null;
                const base = if (sib) |info|
                    info.baseReg(modrm, prefixes)
                else
                    parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, 64);
                return inst(enc, .{
                    .op1 = .{ .memory = Memory.sib(Memory.PtrSize.fromBitSize(enc.data.ops[0].memBitSize()), .{
                        .base = if (base) |base_reg| .{ .register = base_reg } else .none,
                        .scale_index = scale_index,
                        .disp = dis.parseDisplacement(modrm, sib),
                    }) },
                    .op2 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.r, prefixes.rex, src_bit_size) },
                    .op3 = switch (enc.data.op_en) {
                        .mri => .{ .immediate = dis.parseImmediate(enc.data.ops[2]) },
                        .mrc => .{ .register = .cl },
                        else => .none,
                    },
                });
            },
            .rm, .rmi => {
                const modrm = try dis.parseModRmByte();
                const sib = if (modrm.sib()) try dis.parseSibByte() else null;
                const dst_bit_size = enc.data.ops[0].registerBitSize();
                if (modrm.direct()) {
                    return inst(enc, .{
                        .op1 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.x, prefixes.rex, dst_bit_size) },
                        .op2 = .{ .register = parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, enc.data.ops[1].registerBitSize()) },
                        .op3 = if (enc.data.op_en == .rmi) .{ .immediate = dis.parseImmediate(enc.data.ops[2]) } else .none,
                    });
                }
                const src_bit_size = if (enc.data.ops[1] == .m) dst_bit_size else enc.data.ops[1].memBitSize();
                const disp = dis.parseDisplacement(modrm, sib);
                if (modrm.rip()) {
                    return inst(enc, .{
                        .op1 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.r, prefixes.rex, dst_bit_size) },
                        .op2 = .{ .memory = Memory.rip(Memory.PtrSize.fromBitSize(src_bit_size), disp) },
                        .op3 = if (enc.data.op_en == .rmi) .{ .immediate = dis.parseImmediate(enc.data.ops[2]) } else .none,
                    });
                }
                const scale_index = if (sib) |info| info.scaleIndex(prefixes.rex) else null;
                const base = if (sib) |info|
                    info.baseReg(modrm, prefixes)
                else
                    parseGpRegister(modrm.op2, prefixes.rex.b, prefixes.rex, 64);
                return inst(enc, .{
                    .op1 = .{ .register = parseGpRegister(modrm.op1, prefixes.rex.r, prefixes.rex, dst_bit_size) },
                    .op2 = .{ .memory = Memory.sib(Memory.PtrSize.fromBitSize(src_bit_size), .{
                        .base = if (base) |base_reg| .{ .register = base_reg } else .none,
                        .scale_index = scale_index,
                        .disp = disp,
                    }) },
                    .op3 = if (enc.data.op_en == .rmi) .{ .immediate = dis.parseImmediate(enc.data.ops[2]) } else .none,
                });
            },
            .rm0, .vmi, .rvm, .rvmr, .rvmi, .mvr => |tag| {
                debug.write(@tagName(tag));
                debug.write("\n");
                return undefined;
            },
        }
    }
    fn inst(encoding: Encoding, args: struct {
        prefix: Instruction.Prefix = .none,
        op1: Instruction.Operand = .none,
        op2: Instruction.Operand = .none,
        op3: Instruction.Operand = .none,
        op4: Instruction.Operand = .none,
    }) Instruction {
        return .{
            .encoding = encoding,
            .prefix = args.prefix,
            .ops = .{ args.op1, args.op2, args.op3, args.op4 },
        };
    }
    const Prefixes = struct {
        legacy: LegacyPrefixes = .{},
        rex: Rex = .{},
        // TODO add support for VEX prefix
    };
    fn parsePrefixes(dis: *Disassembler) Error!Prefixes {
        @setRuntimeSafety(builtin.is_safe);
        const rex_prefix_mask: u4 = 0b0100;
        var res: Prefixes = .{};
        while (true) {
            if (dis.buf[dis.buf_pos..].len == 0) {
                return error.EndOfStream;
            }
            const byte: u8 = dis.buf[dis.buf_pos];
            dis.buf_pos +%= 1;
            switch (byte) {
                0xf0, 0xf2, 0xf3, 0x2e, 0x36, 0x26, 0x64, 0x65, 0x3e, 0x66, 0x67 => {
                    // Legacy prefix
                    if (res.rex.present) return error.LegacyPrefixAfterRex;
                    switch (byte) {
                        0xf0 => res.legacy.prefix_f0 = true,
                        0xf2 => res.legacy.prefix_f2 = true,
                        0xf3 => res.legacy.prefix_f3 = true,
                        0x2e => res.legacy.prefix_2e = true,
                        0x36 => res.legacy.prefix_36 = true,
                        0x26 => res.legacy.prefix_26 = true,
                        0x64 => res.legacy.prefix_64 = true,
                        0x65 => res.legacy.prefix_65 = true,
                        0x3e => res.legacy.prefix_3e = true,
                        0x66 => res.legacy.prefix_66 = true,
                        0x67 => res.legacy.prefix_67 = true,
                        else => unreachable,
                    }
                },
                else => {
                    if (rex_prefix_mask == @as(u4, @truncate(byte >> 4))) {
                        // REX prefix
                        res.rex.w = byte & 0b1000 != 0;
                        res.rex.r = byte & 0b100 != 0;
                        res.rex.x = byte & 0b10 != 0;
                        res.rex.b = byte & 0b1 != 0;
                        res.rex.present = true;
                        continue;
                    }
                    // TODO VEX prefix
                    dis.buf_pos -%= 1;
                    break;
                },
            }
        }
        return res;
    }
    fn parseEncoding(dis: *Disassembler, prefixes: Prefixes) !Encoding {
        var opcode: [3]u8 = .{ 0, 0, 0 };
        for (0..3) |opc_count| {
            const byte: u8 = dis.buf[dis.buf_pos];
            opcode[opc_count] = byte;
            dis.buf_pos +%= 1;
            if (byte == 0x0f) {
                // Multi-byte opcode
            } else if (opc_count > 0) {
                // Multi-byte opcode
                if (Encoding.findByOpcode(opcode[0 .. opc_count + 1], .{
                    .legacy = prefixes.legacy,
                    .rex = prefixes.rex,
                }, null)) |mnemonic| {
                    return mnemonic;
                }
            } else {
                // Single-byte opcode
                if (Encoding.findByOpcode(opcode[0..1], .{
                    .legacy = prefixes.legacy,
                    .rex = prefixes.rex,
                }, null)) |mnemonic| {
                    return mnemonic;
                } else {
                    // Try O* encoding
                    if (Encoding.findByOpcode(&.{opcode[0] & 0b1111_1000}, .{
                        .legacy = prefixes.legacy,
                        .rex = prefixes.rex,
                    }, null)) |enc| {
                        return enc;
                    }
                }
            }
        }
        return error.UnknownOpcode;
    }
    fn parseGpRegister(low_enc: u4, is_extended: bool, rex: Rex, bit_size: u64) Register {
        const mask: u4 = if (is_extended) 0b1000 else 0b0000;
        const register: Register = @enumFromInt(low_enc | mask);
        return switch (register.toBitSize(bit_size)) {
            .spl => if (rex.present or rex.isSet()) .spl else .ah,
            .dil => if (rex.present or rex.isSet()) .dil else .bh,
            .bpl => if (rex.present or rex.isSet()) .bpl else .ch,
            .sil => if (rex.present or rex.isSet()) .sil else .dh,
            else => |new_register| new_register,
        };
    }
    fn parseImmediate(dis: *Disassembler, kind: Encoding.Op) Immediate {
        const ptr: [*]const u8 = dis.buf[dis.buf_pos..].ptr;
        switch (kind) {
            .imm8s, .rel8 => {
                dis.buf_pos +%= 1;
                return Immediate.s(@as(*const i8, @ptrCast(ptr)).*);
            },
            .imm16s, .rel16 => {
                dis.buf_pos +%= 2;
                return Immediate.s(@as(*align(1) const i16, @ptrCast(ptr)).*);
            },
            .imm32s, .rel32 => {
                dis.buf_pos +%= 4;
                return Immediate.s(@as(*align(1) const i32, @ptrCast(ptr)).*);
            },
            .imm8 => {
                dis.buf_pos +%= 1;
                return Immediate.u(@as(*const u8, @ptrCast(ptr)).*);
            },
            .imm16 => {
                dis.buf_pos +%= 2;
                return Immediate.u(@as(*align(1) const u16, @ptrCast(ptr)).*);
            },
            .imm32 => {
                dis.buf_pos +%= 4;
                return Immediate.u(@as(*align(1) const u32, @ptrCast(ptr)).*);
            },
            .imm64 => {
                dis.buf_pos +%= 8;
                return Immediate.u(@as(*align(1) const u64, @ptrCast(ptr)).*);
            },
            else => unreachable,
        }
    }
    const ModRm = packed struct {
        mod: u2,
        op1: u3,
        op2: u3,
        inline fn direct(self: ModRm) bool {
            return self.mod == 0b11;
        }
        inline fn rip(self: ModRm) bool {
            return self.mod == 0 and self.op2 == 0b101;
        }
        inline fn sib(self: ModRm) bool {
            return !self.direct() and self.op2 == 0b100;
        }
    };
    fn parseModRmByte(dis: *Disassembler) !ModRm {
        if (dis.buf[dis.buf_pos..].len == 0) {
            return error.EndOfStream;
        }
        const modrm_byte: u8 = dis.buf[dis.buf_pos];
        dis.buf_pos +%= 1;
        return ModRm{
            .mod = @truncate(modrm_byte >> 6),
            .op1 = @truncate(modrm_byte >> 3),
            .op2 = @truncate(modrm_byte),
        };
    }
    fn segmentRegister(prefixes: LegacyPrefixes) Register {
        if (prefixes.prefix_2e) return .cs;
        if (prefixes.prefix_36) return .ss;
        if (prefixes.prefix_26) return .es;
        if (prefixes.prefix_64) return .fs;
        if (prefixes.prefix_65) return .gs;
        return .ds;
    }
    const Sib = packed struct {
        scale: u2,
        index: u3,
        base: u3,
        fn scaleIndex(self: Sib, rex: Rex) ?Memory.ScaleIndex {
            if (self.index == 0b100 and !rex.x) return null;
            return .{
                .scale = @as(u4, 1) << self.scale,
                .index = parseGpRegister(self.index, rex.x, rex, 64),
            };
        }
        fn baseReg(self: Sib, modrm: ModRm, prefixes: Prefixes) ?Register {
            if (self.base == 0b101 and modrm.mod == 0) {
                if (self.scaleIndex(prefixes.rex)) |_| return null;
                return segmentRegister(prefixes.legacy);
            }
            return parseGpRegister(self.base, prefixes.rex.b, prefixes.rex, 64);
        }
    };
    fn parseSibByte(dis: *Disassembler) !Sib {
        if (dis.buf[dis.buf_pos..].len == 0) return error.EndOfStream;
        const sib_byte = dis.buf[dis.buf_pos];
        dis.buf_pos += 1;
        return Sib{
            .scale = @truncate(sib_byte >> 6),
            .index = @truncate(sib_byte >> 3),
            .base = @truncate(sib_byte),
        };
    }
    fn parseDisplacement(dis: *Disassembler, modrm: ModRm, sib: ?Sib) i32 {
        const ptr: [*]const u8 = dis.buf[dis.buf_pos..].ptr;
        if (sib) |info| {
            if (info.base == 0b101 and modrm.mod == 0) {
                dis.buf_pos +%= 4;
                return @as(*align(1) const i32, @ptrCast(ptr)).*;
            }
        }
        if (modrm.rip()) {
            dis.buf_pos +%= 4;
            return @as(*align(1) const i32, @ptrCast(ptr)).*;
        }
        switch (modrm.mod) {
            0b00 => return 0,
            0b01 => {
                dis.buf_pos +%= 1;
                return @as(*const i8, @ptrCast(ptr)).*;
            },
            0b10 => {
                dis.buf_pos +%= 4;
                return @as(*align(1) const i32, @ptrCast(ptr)).*;
            },
            0b11 => unreachable,
        }
    }
    const std = @import("std");
};
