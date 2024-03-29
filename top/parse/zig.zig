const abstract = .{};
const debug = .{};
const lit = .{};
const fmt = .{};
const zig = .{};
const mem = .{};
const meta = .{};
const builtin = .{};
pub const TokenIterator = struct {
    buffer: [:0]const u8,
    index: usize,
    pending_invalid_token: ?zig.Token,
    pub fn init(allocator: *zig.Allocator.Node, source: [:0]const u8) !zig.TokenArray {
        var tokens: zig.ProtoTokenArray = zig.ProtoTokenArray.init(allocator);
        const src_start: usize = if (mem.testEqualManyFront(u8, "\xEF\xBB\xBF", source)) 3 else 0;
        var tokenizer: TokenIterator = .{
            .buffer = source,
            .index = src_start,
            .pending_invalid_token = null,
        };
        while (true) {
            const token = tokenizer.next();
            try tokens.appendOne(allocator, .{
                .tag = token.tag,
                .start = @as(u32, @intCast(token.loc.start)),
            });
            if (token.tag == .eof) break;
        }
        return tokens.dynamic(allocator, zig.TokenArray);
    }
    const State = enum {
        start,
        identifier,
        builtin,
        string_literal,
        string_literal_backslash,
        multiline_string_literal_line,
        char_literal,
        char_literal_backslash,
        char_literal_hex_escape,
        char_literal_unicode_escape_saw_u,
        char_literal_unicode_escape,
        char_literal_unicode_invalid,
        char_literal_unicode,
        char_literal_end,
        backslash,
        equal,
        bang,
        pipe,
        minus,
        minus_percent,
        minus_pipe,
        asterisk,
        asterisk_percent,
        asterisk_pipe,
        slash,
        line_comment_start,
        line_comment,
        doc_comment_start,
        doc_comment,
        int,
        int_exponent,
        int_period,
        float,
        float_exponent,
        ampersand,
        caret,
        percent,
        plus,
        plus_percent,
        plus_pipe,
        angle_bracket_left,
        angle_bracket_angle_bracket_left,
        angle_bracket_angle_bracket_left_pipe,
        angle_bracket_right,
        angle_bracket_angle_bracket_right,
        period,
        period_2,
        period_asterisk,
        saw_at_sign,
    };
    pub fn next(self: *TokenIterator) zig.Token {
        if (self.pending_invalid_token) |token| {
            self.pending_invalid_token = null;
            return token;
        }
        var state: State = .start;
        var result = zig.Token{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };
        var seen_escape_digits: usize = undefined;
        var remaining_code_units: usize = undefined;
        while (true) : (self.index += 1) {
            const c = self.buffer[self.index];
            switch (state) {
                .start => switch (c) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            result.tag = .invalid;
                            result.loc.start = self.index;
                            self.index += 1;
                            result.loc.end = self.index;
                            return result;
                        }
                        break;
                    },
                    ' ', '\n', '\t', '\r' => {
                        result.loc.start = self.index + 1;
                    },
                    '"' => {
                        state = .string_literal;
                        result.tag = .string_literal;
                    },
                    '\'' => {
                        state = .char_literal;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .identifier;
                        result.tag = .identifier;
                    },
                    '@' => {
                        state = .saw_at_sign;
                    },
                    '=' => {
                        state = .equal;
                    },
                    '!' => {
                        state = .bang;
                    },
                    '|' => {
                        state = .pipe;
                    },
                    '(' => {
                        result.tag = .l_paren;
                        self.index += 1;
                        break;
                    },
                    ')' => {
                        result.tag = .r_paren;
                        self.index += 1;
                        break;
                    },
                    '[' => {
                        result.tag = .l_bracket;
                        self.index += 1;
                        break;
                    },
                    ']' => {
                        result.tag = .r_bracket;
                        self.index += 1;
                        break;
                    },
                    ';' => {
                        result.tag = .semicolon;
                        self.index += 1;
                        break;
                    },
                    ',' => {
                        result.tag = .comma;
                        self.index += 1;
                        break;
                    },
                    '?' => {
                        result.tag = .question_mark;
                        self.index += 1;
                        break;
                    },
                    ':' => {
                        result.tag = .colon;
                        self.index += 1;
                        break;
                    },
                    '%' => {
                        state = .percent;
                    },
                    '*' => {
                        state = .asterisk;
                    },
                    '+' => {
                        state = .plus;
                    },
                    '<' => {
                        state = .angle_bracket_left;
                    },
                    '>' => {
                        state = .angle_bracket_right;
                    },
                    '^' => {
                        state = .caret;
                    },
                    '\\' => {
                        state = .backslash;
                        result.tag = .multiline_string_literal_line;
                    },
                    '{' => {
                        result.tag = .l_brace;
                        self.index += 1;
                        break;
                    },
                    '}' => {
                        result.tag = .r_brace;
                        self.index += 1;
                        break;
                    },
                    '~' => {
                        result.tag = .tilde;
                        self.index += 1;
                        break;
                    },
                    '.' => {
                        state = .period;
                    },
                    '-' => {
                        state = .minus;
                    },
                    '/' => {
                        state = .slash;
                    },
                    '&' => {
                        state = .ampersand;
                    },
                    '0'...'9' => {
                        state = .int;
                        result.tag = .number_literal;
                    },
                    else => {
                        result.tag = .invalid;
                        result.loc.end = self.index;
                        self.index += 1;
                        return result;
                    },
                },
                .saw_at_sign => switch (c) {
                    '"' => {
                        result.tag = .identifier;
                        state = .string_literal;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .builtin;
                        result.tag = .builtin;
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .ampersand => switch (c) {
                    '=' => {
                        result.tag = .ampersand_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .ampersand;
                        break;
                    },
                },
                .asterisk => switch (c) {
                    '=' => {
                        result.tag = .asterisk_equal;
                        self.index += 1;
                        break;
                    },
                    '*' => {
                        result.tag = .asterisk_asterisk;
                        self.index += 1;
                        break;
                    },
                    '%' => {
                        state = .asterisk_percent;
                    },
                    '|' => {
                        state = .asterisk_pipe;
                    },
                    else => {
                        result.tag = .asterisk;
                        break;
                    },
                },
                .asterisk_percent => switch (c) {
                    '=' => {
                        result.tag = .asterisk_percent_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .asterisk_percent;
                        break;
                    },
                },
                .asterisk_pipe => switch (c) {
                    '=' => {
                        result.tag = .asterisk_pipe_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .asterisk_pipe;
                        break;
                    },
                },
                .percent => switch (c) {
                    '=' => {
                        result.tag = .percent_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .percent;
                        break;
                    },
                },
                .plus => switch (c) {
                    '=' => {
                        result.tag = .plus_equal;
                        self.index += 1;
                        break;
                    },
                    '+' => {
                        result.tag = .plus_plus;
                        self.index += 1;
                        break;
                    },
                    '%' => {
                        state = .plus_percent;
                    },
                    '|' => {
                        state = .plus_pipe;
                    },
                    else => {
                        result.tag = .plus;
                        break;
                    },
                },
                .plus_percent => switch (c) {
                    '=' => {
                        result.tag = .plus_percent_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .plus_percent;
                        break;
                    },
                },
                .plus_pipe => switch (c) {
                    '=' => {
                        result.tag = .plus_pipe_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .plus_pipe;
                        break;
                    },
                },
                .caret => switch (c) {
                    '=' => {
                        result.tag = .caret_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .caret;
                        break;
                    },
                },
                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => {
                        if (zig.Token.getKeyword(self.buffer[result.loc.start..self.index])) |tag| {
                            result.tag = tag;
                        }
                        break;
                    },
                },
                .builtin => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => break,
                },
                .backslash => switch (c) {
                    '\\' => {
                        state = .multiline_string_literal_line;
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .string_literal => switch (c) {
                    '\\' => {
                        state = .string_literal_backslash;
                    },
                    '"' => {
                        self.index += 1;
                        break;
                    },
                    0 => {
                        if (self.index == self.buffer.len) {
                            break;
                        } else {
                            self.checkLiteralCharacter();
                        }
                    },
                    '\n' => {
                        result.tag = .invalid;
                        break;
                    },
                    else => self.checkLiteralCharacter(),
                },
                .string_literal_backslash => switch (c) {
                    0, '\n' => {
                        result.tag = .invalid;
                        break;
                    },
                    else => {
                        state = .string_literal;
                    },
                },
                .char_literal => switch (c) {
                    0 => {
                        result.tag = .invalid;
                        break;
                    },
                    '\\' => {
                        state = .char_literal_backslash;
                    },
                    '\'', 0x80...0xbf, 0xf8...0xff => {
                        result.tag = .invalid;
                        break;
                    },
                    0xc0...0xdf => { // 110xxxxx
                        remaining_code_units = 1;
                        state = .char_literal_unicode;
                    },
                    0xe0...0xef => { // 1110xxxx
                        remaining_code_units = 2;
                        state = .char_literal_unicode;
                    },
                    0xf0...0xf7 => { // 11110xxx
                        remaining_code_units = 3;
                        state = .char_literal_unicode;
                    },
                    '\n' => {
                        result.tag = .invalid;
                        break;
                    },
                    else => {
                        state = .char_literal_end;
                    },
                },
                .char_literal_backslash => switch (c) {
                    0, '\n' => {
                        result.tag = .invalid;
                        break;
                    },
                    'x' => {
                        state = .char_literal_hex_escape;
                        seen_escape_digits = 0;
                    },
                    'u' => {
                        state = .char_literal_unicode_escape_saw_u;
                    },
                    else => {
                        state = .char_literal_end;
                    },
                },
                .char_literal_hex_escape => switch (c) {
                    '0'...'9', 'a'...'f', 'A'...'F' => {
                        seen_escape_digits += 1;
                        if (seen_escape_digits == 2) {
                            state = .char_literal_end;
                        }
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .char_literal_unicode_escape_saw_u => switch (c) {
                    0 => {
                        result.tag = .invalid;
                        break;
                    },
                    '{' => {
                        state = .char_literal_unicode_escape;
                    },
                    else => {
                        result.tag = .invalid;
                        state = .char_literal_unicode_invalid;
                    },
                },
                .char_literal_unicode_escape => switch (c) {
                    0 => {
                        result.tag = .invalid;
                        break;
                    },
                    '0'...'9', 'a'...'f', 'A'...'F' => {},
                    '}' => {
                        state = .char_literal_end; // too many/few digits handled later
                    },
                    else => {
                        result.tag = .invalid;
                        state = .char_literal_unicode_invalid;
                    },
                },
                .char_literal_unicode_invalid => switch (c) {
                    // Keep consuming characters until an obvious stopping point.
                    // This consolidates e.g. `u{0ab1Q}` into a single invalid token
                    // instead of creating the tokens `u{0ab1`, `Q`, `}`
                    '0'...'9', 'a'...'z', 'A'...'Z', '}' => {},
                    else => break,
                },
                .char_literal_end => switch (c) {
                    '\'' => {
                        result.tag = .char_literal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .char_literal_unicode => switch (c) {
                    0x80...0xbf => {
                        remaining_code_units -= 1;
                        if (remaining_code_units == 0) {
                            state = .char_literal_end;
                        }
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .multiline_string_literal_line => switch (c) {
                    0 => break,
                    '\n' => {
                        self.index += 1;
                        break;
                    },
                    '\t' => {},
                    else => self.checkLiteralCharacter(),
                },
                .bang => switch (c) {
                    '=' => {
                        result.tag = .bang_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .bang;
                        break;
                    },
                },
                .pipe => switch (c) {
                    '=' => {
                        result.tag = .pipe_equal;
                        self.index += 1;
                        break;
                    },
                    '|' => {
                        result.tag = .pipe_pipe;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .pipe;
                        break;
                    },
                },
                .equal => switch (c) {
                    '=' => {
                        result.tag = .equal_equal;
                        self.index += 1;
                        break;
                    },
                    '>' => {
                        result.tag = .equal_angle_bracket_right;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .equal;
                        break;
                    },
                },
                .minus => switch (c) {
                    '>' => {
                        result.tag = .arrow;
                        self.index += 1;
                        break;
                    },
                    '=' => {
                        result.tag = .minus_equal;
                        self.index += 1;
                        break;
                    },
                    '%' => {
                        state = .minus_percent;
                    },
                    '|' => {
                        state = .minus_pipe;
                    },
                    else => {
                        result.tag = .minus;
                        break;
                    },
                },
                .minus_percent => switch (c) {
                    '=' => {
                        result.tag = .minus_percent_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .minus_percent;
                        break;
                    },
                },
                .minus_pipe => switch (c) {
                    '=' => {
                        result.tag = .minus_pipe_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .minus_pipe;
                        break;
                    },
                },
                .angle_bracket_left => switch (c) {
                    '<' => {
                        state = .angle_bracket_angle_bracket_left;
                    },
                    '=' => {
                        result.tag = .angle_bracket_left_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .angle_bracket_left;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_left => switch (c) {
                    '=' => {
                        result.tag = .angle_bracket_angle_bracket_left_equal;
                        self.index += 1;
                        break;
                    },
                    '|' => {
                        state = .angle_bracket_angle_bracket_left_pipe;
                    },
                    else => {
                        result.tag = .angle_bracket_angle_bracket_left;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_left_pipe => switch (c) {
                    '=' => {
                        result.tag = .angle_bracket_angle_bracket_left_pipe_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .angle_bracket_angle_bracket_left_pipe;
                        break;
                    },
                },
                .angle_bracket_right => switch (c) {
                    '>' => {
                        state = .angle_bracket_angle_bracket_right;
                    },
                    '=' => {
                        result.tag = .angle_bracket_right_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .angle_bracket_right;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_right => switch (c) {
                    '=' => {
                        result.tag = .angle_bracket_angle_bracket_right_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .angle_bracket_angle_bracket_right;
                        break;
                    },
                },
                .period => switch (c) {
                    '.' => {
                        state = .period_2;
                    },
                    '*' => {
                        state = .period_asterisk;
                    },
                    else => {
                        result.tag = .period;
                        break;
                    },
                },
                .period_2 => switch (c) {
                    '.' => {
                        result.tag = .ellipsis3;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .ellipsis2;
                        break;
                    },
                },
                .period_asterisk => switch (c) {
                    '*' => {
                        result.tag = .invalid_periodasterisks;
                        break;
                    },
                    else => {
                        result.tag = .period_asterisk;
                        break;
                    },
                },
                .slash => switch (c) {
                    '/' => {
                        state = .line_comment_start;
                    },
                    '=' => {
                        result.tag = .slash_equal;
                        self.index += 1;
                        break;
                    },
                    else => {
                        result.tag = .slash;
                        break;
                    },
                },
                .line_comment_start => switch (c) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            result.tag = .invalid;
                            self.index += 1;
                        }
                        break;
                    },
                    '/' => {
                        state = .doc_comment_start;
                    },
                    '!' => {
                        result.tag = .container_doc_comment;
                        state = .doc_comment;
                    },
                    '\n' => {
                        state = .start;
                        result.loc.start = self.index + 1;
                    },
                    '\t', '\r' => state = .line_comment,
                    else => {
                        state = .line_comment;
                        self.checkLiteralCharacter();
                    },
                },
                .doc_comment_start => switch (c) {
                    '/' => {
                        state = .line_comment;
                    },
                    0, '\n' => {
                        result.tag = .doc_comment;
                        break;
                    },
                    '\t', '\r' => {
                        state = .doc_comment;
                        result.tag = .doc_comment;
                    },
                    else => {
                        state = .doc_comment;
                        result.tag = .doc_comment;
                        self.checkLiteralCharacter();
                    },
                },
                .line_comment => switch (c) {
                    0 => break,
                    '\n' => {
                        state = .start;
                        result.loc.start = self.index + 1;
                    },
                    '\t', '\r' => {},
                    else => self.checkLiteralCharacter(),
                },
                .doc_comment => switch (c) {
                    0, '\n' => break,
                    '\t', '\r' => {},
                    else => self.checkLiteralCharacter(),
                },
                .int => switch (c) {
                    '.' => state = .int_period,
                    '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {},
                    'e', 'E', 'p', 'P' => state = .int_exponent,
                    else => break,
                },
                .int_exponent => switch (c) {
                    '-', '+' => {
                        state = .float;
                    },
                    else => {
                        self.index -= 1;
                        state = .int;
                    },
                },
                .int_period => switch (c) {
                    '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {
                        state = .float;
                    },
                    'e', 'E', 'p', 'P' => state = .float_exponent,
                    else => {
                        self.index -= 1;
                        break;
                    },
                },
                .float => switch (c) {
                    '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {},
                    'e', 'E', 'p', 'P' => state = .float_exponent,
                    else => break,
                },
                .float_exponent => switch (c) {
                    '-', '+' => state = .float,
                    else => {
                        self.index -= 1;
                        state = .float;
                    },
                },
            }
        }
        if (result.tag == .eof) {
            if (self.pending_invalid_token) |token| {
                self.pending_invalid_token = null;
                return token;
            }
            result.loc.start = self.index;
        }
        result.loc.end = self.index;
        return result;
    }
    fn checkLiteralCharacter(self: *TokenIterator) void {
        if (self.pending_invalid_token != null) return;
        const invalid_length = self.getInvalidCharacterLength();
        if (invalid_length == 0) return;
        self.pending_invalid_token = .{
            .tag = .invalid,
            .loc = .{
                .start = self.index,
                .end = self.index + invalid_length,
            },
        };
    }
    fn getInvalidCharacterLength(self: *TokenIterator) u3 {
        const c0 = self.buffer[self.index];
        if (fmt.ascii.isASCII(c0)) {
            if (fmt.ascii.isControl(c0)) {
                // ascii control codes are never allowed
                // (note that \n was checked before we got here)
                return 1;
            }
            // looks fine to me.
            return 0;
        } else {
            // check utf8-encoded character.
            const length = fmt.utf8.byteSequenceLength(c0) catch return 1;
            if (self.index + length > self.buffer.len) {
                return @as(u3, @intCast(self.buffer.len - self.index));
            }
            const bytes = self.buffer[self.index .. self.index + length];
            switch (length) {
                2 => {
                    const value = fmt.utf8.decode2(bytes) catch return length;
                    if (value == 0x85) return length; // U+0085 (NEL)
                },
                3 => {
                    const value = fmt.utf8.decode3(bytes) catch return length;
                    if (value == 0x2028) return length; // U+2028 (LS)
                    if (value == 0x2029) return length; // U+2029 (PS)
                },
                4 => {
                    _ = fmt.utf8.decode4(bytes) catch return length;
                },
                else => unreachable,
            }
            self.index += length - 1;
            return 0;
        }
    }
};
const AllocatorN = zig.Allocator.Node;
const AllocatorE = zig.Allocator.Error;
const AllocatorX = zig.Allocator.Extra;
const AllocatorS = zig.Allocator.State;
const AllocatorNEXS = struct {
    allocator: *AllocatorNEXS,
};
const Error = meta.ReturnErrorSet(.{
    AllocatorN.allocate_void, AllocatorE.allocate_void,
    AllocatorX.allocate_void, AllocatorS.allocate_void,
    error{ParseError},
});
const null_node: zig.Index = 0;
pub const Members = struct {
    len: usize,
    lhs: zig.Index,
    rhs: zig.Index,
    trailing: bool,
    pub fn toSpan(members: Members, ast: *abstract.ProtoSyntaxTree, allocator_x: *AllocatorX) !zig.AstNode.SubRange {
        if (members.len <= 2) {
            const nodes = [2]zig.Index{ members.lhs, members.rhs };
            return listToSpan(ast, allocator_x, nodes[0..members.len]);
        } else {
            return .{ .start = members.lhs, .end = members.rhs };
        }
    }
};
fn listToSpan(ast: *abstract.ProtoSyntaxTree, allocator_x: *AllocatorX, list: []const zig.Index) !zig.AstNode.SubRange {
    try ast.extras.appendMany(zig.Index, allocator_x, list);
    return zig.AstNode.SubRange{
        .start = @as(zig.Index, @intCast(ast.extras.len(zig.Index, allocator_x.*) - list.len)),
        .end = @as(zig.Index, @intCast(ast.extras.len(zig.Index, allocator_x.*))),
    };
}
fn addNode(ast: *abstract.ProtoSyntaxTree, allocator_n: *AllocatorN, elem: zig.AstNode) Error!zig.Index {
    const result = @as(zig.Index, @intCast(ast.nodes.len(allocator_n.*)));
    try ast.nodes.appendOne(allocator_n, elem);
    return result;
}
fn setNode(ast: *abstract.ProtoSyntaxTree, allocator_n: *AllocatorN, i: usize, elem: zig.AstNode) zig.Index {
    ast.nodes.overwriteOneAt(allocator_n.*, i, elem);
    return @as(zig.Index, @intCast(i));
}
fn reserveNode(ast: *abstract.ProtoSyntaxTree, allocator_n: *AllocatorN, tag: zig.AstNode.Tag) Error!usize {
    try ast.nodes.increment(allocator_n, 1);
    ast.nodes.define(1);
    ast.nodes.referOneBack().tag = tag;
    return ast.nodes.len(allocator_n.*) - 1;
}
fn unreserveNode(ast: *abstract.ProtoSyntaxTree, allocator_n: *AllocatorN, node_index: usize) void {
    if (ast.nodes.len(allocator_n.*) == node_index) {
        ast.nodes.undefine(1);
    } else {
        ast.nodes.referOneAt(allocator_n.*, node_index).tag = .unreachable_literal;
        ast.nodes.referOneAt(allocator_n.*, node_index).main_token = tokenIndex(ast);
    }
}
fn addExtra(ast: *abstract.ProtoSyntaxTree, allocator_x: *AllocatorX, extra: anytype) Error!zig.Index {
    const result: zig.Index = @as(zig.Index, @intCast(ast.extras.len(zig.Index, allocator_x.*)));
    try ast.extras.appendOne(@TypeOf(extra), allocator_x, extra);
    return result;
}
pub fn warnExpected(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, expected_token: zig.Token.Tag) !void {
    @setCold(true);
    try warnMsg(ast, allocator_e, .{
        .tag = .expected_token,
        .token = tokenIndex(ast),
        .extra = .{ .expected_tag = expected_token },
    });
}
fn warn(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, error_tag: zig.AstError.Tag) !void {
    @setCold(true);
    try warnMsg(ast, allocator_e, .{ .tag = error_tag, .token = tokenIndex(ast) });
}
fn warnMsg(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, msg: zig.AstError) !void {
    @setCold(true);
    switch (msg.tag) {
        .expected_semi_after_decl,
        .expected_semi_after_stmt,
        .expected_comma_after_field,
        .expected_comma_after_arg,
        .expected_comma_after_param,
        .expected_comma_after_initializer,
        .expected_comma_after_switch_prong,
        .expected_semi_or_else,
        .expected_semi_or_lbrace,
        .expected_token,
        .expected_block,
        .expected_block_or_assignment,
        .expected_block_or_expr,
        .expected_block_or_field,
        .expected_expr,
        .expected_expr_or_assignment,
        .expected_fn,
        .expected_inlinable,
        .expected_labelable,
        .expected_param_list,
        .expected_prefix_expr,
        .expected_primary_type_expr,
        .expected_pub_item,
        .expected_return_type,
        .expected_suffix_op,
        .expected_type_expr,
        .expected_var_decl,
        .expected_var_decl_or_fn,
        .expected_loop_payload,
        .expected_container,
        => if (msg.token != 0 and !tokensOnSameLine(ast, msg.token - 1, msg.token)) {
            var copy = msg;
            copy.token_is_prev = true;
            copy.token -= 1;
            return ast.errors.appendOne(allocator_e, copy);
        },
        else => {},
    }
    try ast.errors.appendOne(allocator_e, msg);
}
fn fail(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, tag: zig.AstError.Tag) Error {
    @setCold(true);
    return failMsg(ast, allocator_e, .{ .tag = tag, .token = tokenIndex(ast) });
}
fn failExpected(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, expected_token: zig.Token.Tag) Error {
    @setCold(true);
    return failMsg(ast, allocator_e, .{
        .tag = .expected_token,
        .token = tokenIndex(ast),
        .extra = .{ .expected_tag = expected_token },
    });
}
fn failMsg(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, msg: zig.AstError) Error {
    @setCold(true);
    try warnMsg(ast, allocator_e, msg);
    return error.ParseError;
}
/// ContainerMembers <- ContainerDeclarations (ContainerField COMMA)* (ContainerField / ContainerDeclarations)
/// ContainerDeclarations
///     <- TestDecl ContainerDeclarations
///      / TopLevelComptime ContainerDeclarations
///      / KEYWORD_pub? TopLevelDecl ContainerDeclarations
///      /
/// TopLevelComptime <- KEYWORD_comptime Block
pub fn parseContainerMembers(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!Members {
    const state_top: u64 = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    var field_state: union(enum) { none, seen, end: zig.Index, err } = .none;
    var last_field: zig.Index = undefined;
    // Skip container doc comments.
    while (eatToken(ast, .container_doc_comment)) |_| {}
    var trailing = false;
    while (true) {
        const doc_comment = try eatDocComments(ast, allocator.e);
        switch (readTagAhead(ast)) {
            .keyword_test => {
                if (doc_comment) |some| {
                    try warnMsg(ast, allocator.e, .{ .tag = .test_doc_comment, .token = some });
                }
                const test_decl_node = try expectTestDeclRecoverable(ast, allocator, array_s);
                if (test_decl_node != 0) {
                    if (field_state == .seen) {
                        field_state = .{ .end = test_decl_node };
                    }
                    try array_s.appendOne(allocator.s, test_decl_node);
                }
                trailing = false;
            },
            .keyword_comptime => switch (relativeTagAhead(ast, 1)) {
                .l_brace => {
                    if (doc_comment) |some| {
                        try warnMsg(ast, allocator.e, .{ .tag = .comptime_doc_comment, .token = some });
                    }
                    const comptime_token = nextToken(ast);
                    const block = parseBlock(ast, allocator, array_s) catch |err| switch (err) {
                        error.ParseError => blk: {
                            findNextContainerMember(ast);
                            break :blk null_node;
                        },
                        else => |mem_err| return mem_err,
                    };
                    if (block != 0) {
                        const comptime_node = try addNode(ast, allocator.n, .{
                            .tag = .@"comptime",
                            .main_token = comptime_token,
                            .data = .{ .lhs = block, .rhs = undefined },
                        });
                        if (field_state == .seen) {
                            field_state = .{ .end = comptime_node };
                        }
                        try array_s.appendOne(allocator.s, comptime_node);
                    }
                    trailing = false;
                },
                else => {
                    ast.tokens.stream(1);
                    const identifier = tokenIndex(ast);
                    defer last_field = identifier;
                    const container_field = expectContainerField(ast, allocator, array_s) catch |err| switch (err) {
                        error.ParseError => {
                            findNextContainerMember(ast);
                            continue;
                        },
                        else => |mem_err| return mem_err,
                    };
                    switch (field_state) {
                        .none => field_state = .seen,
                        .err, .seen => {},
                        .end => |node| {
                            try warnMsg(ast, allocator.e, .{
                                .tag = .decl_between_fields,
                                .token = ast.nodes.readOneAt(allocator.n.*, node).main_token,
                            });
                            try warnMsg(ast, allocator.e, .{
                                .tag = .previous_field,
                                .is_note = true,
                                .token = last_field,
                            });
                            try warnMsg(ast, allocator.e, .{
                                .tag = .next_field,
                                .is_note = true,
                                .token = identifier,
                            });
                            // Continue parsing; error will be reported later.
                            field_state = .err;
                        },
                    }
                    try array_s.appendOne(allocator.s, container_field);
                    switch (readTagAhead(ast)) {
                        .comma => {
                            ast.tokens.stream(1);
                            trailing = true;
                            continue;
                        },
                        .r_brace, .eof => {
                            trailing = false;
                            break;
                        },
                        else => {},
                    }
                    // There is not allowed to be a decl after a field with no comma.
                    // Report error but recover parser.
                    try warn(ast, allocator.e, .expected_comma_after_field);
                    findNextContainerMember(ast);
                },
            },
            .keyword_pub => {
                ast.tokens.stream(1);
                const top_level_decl = try expectTopLevelDeclRecoverable(ast, allocator, array_s);
                if (top_level_decl != 0) {
                    if (field_state == .seen) {
                        field_state = .{ .end = top_level_decl };
                    }
                    try array_s.appendOne(allocator.s, top_level_decl);
                }
                trailing = relativeTagBehind(ast, 1) == .semicolon;
            },
            .keyword_usingnamespace => {
                const node = try expectUsingNamespaceRecoverable(ast, allocator, array_s);
                if (node != 0) {
                    if (field_state == .seen) {
                        field_state = .{ .end = node };
                    }
                    try array_s.appendOne(allocator.s, node);
                }
                trailing = relativeTagBehind(ast, 1) == .semicolon;
            },
            .keyword_const,
            .keyword_var,
            .keyword_threadlocal,
            .keyword_export,
            .keyword_extern,
            .keyword_inline,
            .keyword_noinline,
            .keyword_fn,
            => {
                const top_level_decl = try expectTopLevelDeclRecoverable(ast, allocator, array_s);
                if (top_level_decl != 0) {
                    if (field_state == .seen) {
                        field_state = .{ .end = top_level_decl };
                    }
                    try array_s.appendOne(allocator.s, top_level_decl);
                }
                trailing = relativeTagBehind(ast, 1) == .semicolon;
            },
            .eof, .r_brace => {
                if (doc_comment) |tok| {
                    try warnMsg(ast, allocator.e, .{
                        .tag = .unattached_doc_comment,
                        .token = tok,
                    });
                }
                break;
            },
            else => {
                const c_container = parseCStyleContainer(ast, allocator, array_s) catch |err| switch (err) {
                    error.ParseError => false,
                    else => |mem_error| return mem_error,
                };
                if (c_container) continue;
                const identifier = tokenIndex(ast);
                defer last_field = identifier;
                const container_field = expectContainerField(ast, allocator, array_s) catch |err| switch (err) {
                    error.ParseError => {
                        findNextContainerMember(
                            ast,
                        );
                        continue;
                    },
                    else => |mem_error| return mem_error,
                };
                switch (field_state) {
                    .none => field_state = .seen,
                    .err, .seen => {},
                    .end => |node| {
                        try warnMsg(ast, allocator.e, .{
                            .tag = .decl_between_fields,
                            .token = ast.nodes.readOneAt(allocator.n.*, node).main_token,
                        });
                        try warnMsg(ast, allocator.e, .{
                            .tag = .previous_field,
                            .is_note = true,
                            .token = last_field,
                        });
                        try warnMsg(ast, allocator.e, .{
                            .tag = .next_field,
                            .is_note = true,
                            .token = identifier,
                        });
                        // Continue parsing; error will be reported later.
                        field_state = .err;
                    },
                }
                try array_s.appendOne(allocator.s, container_field);
                switch (readTagAhead(ast)) {
                    .comma => {
                        ast.tokens.stream(1);
                        trailing = true;
                        continue;
                    },
                    .r_brace, .eof => {
                        trailing = false;
                        break;
                    },
                    else => {},
                }
                // There is not allowed to be a decl after a field with no comma.
                // Report error but recover parser.
                try warn(ast, allocator.e, .expected_comma_after_field);
                findNextContainerMember(ast);
                continue;
            },
        }
    }
    const items = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
    switch (items.len) {
        0 => return Members{
            .len = 0,
            .lhs = 0,
            .rhs = 0,
            .trailing = trailing,
        },
        1 => return Members{
            .len = 1,
            .lhs = items[0],
            .rhs = 0,
            .trailing = trailing,
        },
        2 => return Members{
            .len = 2,
            .lhs = items[0],
            .rhs = items[1],
            .trailing = trailing,
        },
        else => {
            const span = try listToSpan(ast, allocator.x, items);
            return Members{
                .len = items.len,
                .lhs = span.start,
                .rhs = span.end,
                .trailing = trailing,
            };
        },
    }
}
/// Attempts to find next container member by searching for certain tokens
fn findNextContainerMember(ast: *abstract.ProtoSyntaxTree) void {
    var level: zig.Index = 0;
    while (true) {
        const tok = nextToken(ast);
        switch (readTagAt(ast, tok)) {
            // Any of these can start a new top level declaration.
            .keyword_test,
            .keyword_comptime,
            .keyword_pub,
            .keyword_export,
            .keyword_extern,
            .keyword_inline,
            .keyword_noinline,
            .keyword_usingnamespace,
            .keyword_threadlocal,
            .keyword_const,
            .keyword_var,
            .keyword_fn,
            => {
                if (level == 0) {
                    ast.tokens.unstream(1);
                    return;
                }
            },
            .identifier => {
                if (readTagAt(ast, tok + 1) == .comma and level == 0) {
                    ast.tokens.unstream(1);
                    return;
                }
            },
            .comma, .semicolon => {
                // this decl was likely meant to end here
                if (level == 0) {
                    return;
                }
            },
            .l_paren, .l_bracket, .l_brace => level += 1,
            .r_paren, .r_bracket => {
                if (level != 0) level -= 1;
            },
            .r_brace => {
                if (level == 0) {
                    // end of container, exit
                    ast.tokens.unstream(1);
                    return;
                }
                level -= 1;
            },
            .eof => {
                ast.tokens.unstream(1);
                return;
            },
            else => {},
        }
    }
}
/// Attempts to find the next statement by searching for a semicolon
fn findNextStmt(ast: *abstract.ProtoSyntaxTree) void {
    var level: zig.Index = 0;
    while (true) {
        const tok = nextToken(ast);
        switch (readTagAt(ast, tok)) {
            .l_brace => level += 1,
            .r_brace => {
                if (level == 0) {
                    ast.tokens.unstream(1);
                    return;
                }
                level -= 1;
            },
            .semicolon => {
                if (level == 0) {
                    return;
                }
            },
            .eof => {
                ast.tokens.unstream(1);
                return;
            },
            else => {},
        }
    }
}
/// TestDecl <- KEYWORD_test (STRINGLITERALSINGLE / IDENTIFIER)? Block
fn expectTestDecl(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const test_token = assertToken(ast, .keyword_test);
    const name_token = switch (readTagAt(ast, nextToken(ast))) {
        .string_literal, .identifier => tokenIndex(ast) - 1,
        else => blk: {
            ast.tokens.unstream(1);
            break :blk null;
        },
    };
    const block_node = try parseBlock(ast, allocator, array_s);
    if (block_node == 0) return fail(ast, allocator.e, .expected_block);
    return addNode(ast, allocator.n, .{
        .tag = .test_decl,
        .main_token = test_token,
        .data = .{ .lhs = name_token orelse 0, .rhs = block_node },
    });
}
fn expectTestDeclRecoverable(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    return expectTestDecl(ast, allocator, array_s) catch |err| switch (err) {
        error.ParseError => {
            findNextContainerMember(ast);
            return null_node;
        },
        else => |mem_error| return mem_error,
    };
}
/// TopLevelDecl
///     <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / (KEYWORD_inline / KEYWORD_noinline))? FnProto (SEMICOLON / Block)
///      / (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? VarDecl
///      / KEYWORD_usingnamespace Expr SEMICOLON
fn expectTopLevelDecl(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const extern_export_inline_token = nextToken(ast);
    var is_extern: bool = false;
    var expect_fn: bool = false;
    var expect_var_or_fn: bool = false;
    switch (readTagAt(ast, extern_export_inline_token)) {
        .keyword_extern => {
            _ = eatToken(ast, .string_literal);
            is_extern = true;
            expect_var_or_fn = true;
        },
        .keyword_export => expect_var_or_fn = true,
        .keyword_inline, .keyword_noinline => expect_fn = true,
        else => ast.tokens.unstream(1),
    }
    const fn_proto = try parseFnProto(ast, allocator, array_s);
    if (fn_proto != 0) {
        switch (readTagAhead(ast)) {
            .semicolon => {
                ast.tokens.stream(1);
                return fn_proto;
            },
            .l_brace => {
                if (is_extern) {
                    try warnMsg(ast, allocator.e, .{ .tag = .extern_fn_body, .token = extern_export_inline_token });
                    return null_node;
                }
                const fn_decl_index = try reserveNode(ast, allocator.n, .fn_decl);
                errdefer unreserveNode(ast, allocator.n, fn_decl_index);
                const body_block = try parseBlock(ast, allocator, array_s);
                debug.assert(body_block != 0);
                return setNode(ast, allocator.n, fn_decl_index, .{
                    .tag = .fn_decl,
                    .main_token = ast.nodes.readOneAt(allocator.n.*, fn_proto).main_token,
                    .data = .{ .lhs = fn_proto, .rhs = body_block },
                });
            },
            else => {
                // Since parseBlock only return error.ParseError on
                // a missing '}' we can assume this function was
                // supposed to end here.
                try warn(ast, allocator.e, .expected_semi_or_lbrace);
                return null_node;
            },
        }
    }
    if (expect_fn) {
        try warn(ast, allocator.e, .expected_fn);
        return error.ParseError;
    }
    const thread_local_token = eatToken(ast, .keyword_threadlocal);
    const var_decl = try parseVarDecl(ast, allocator, array_s);
    if (var_decl != 0) {
        try expectSemicolon(ast, allocator.e, .expected_semi_after_decl, false);
        return var_decl;
    }
    if (thread_local_token != null) {
        return fail(ast, allocator.e, .expected_var_decl);
    }
    if (expect_var_or_fn) {
        return fail(ast, allocator.e, .expected_var_decl_or_fn);
    }
    if (readTagAhead(ast) != .keyword_usingnamespace) {
        return fail(ast, allocator.e, .expected_pub_item);
    }
    return expectUsingNamespace(ast, allocator, array_s);
}
fn expectTopLevelDeclRecoverable(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    return expectTopLevelDecl(ast, allocator, array_s) catch |err| switch (err) {
        error.ParseError => {
            findNextContainerMember(ast);
            return null_node;
        },
        else => |mem_error| return mem_error,
    };
}
fn expectUsingNamespace(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const usingnamespace_token = assertToken(ast, .keyword_usingnamespace);
    const expr = try expectExpr(ast, allocator, array_s);
    try expectSemicolon(ast, allocator.e, .expected_semi_after_decl, false);
    return addNode(ast, allocator.n, .{
        .tag = .@"usingnamespace",
        .main_token = usingnamespace_token,
        .data = .{ .lhs = expr, .rhs = undefined },
    });
}
fn expectUsingNamespaceRecoverable(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    return expectUsingNamespace(ast, allocator, array_s) catch |err| switch (err) {
        error.ParseError => {
            findNextContainerMember(ast);
            return null_node;
        },
        else => |mem_error| return mem_error,
    };
}
/// FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? AddrSpace? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr
fn parseFnProto(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const fn_token = eatToken(ast, .keyword_fn) orelse return null_node;
    // We want the fn proto node to be before its children in the array.
    const fn_proto_index = try reserveNode(ast, allocator.n, .fn_proto);
    errdefer unreserveNode(ast, allocator.n, fn_proto_index);
    _ = eatToken(ast, .identifier);
    const params = try parseParamDeclList(ast, allocator, array_s);
    const align_expr = try parseByteAlign(ast, allocator, array_s);
    const addrspace_expr = try parseAddrSpace(ast, allocator, array_s);
    const section_expr = try parseLinkSection(ast, allocator, array_s);
    const callconv_expr = try parseCallconv(ast, allocator, array_s);
    _ = eatToken(ast, .bang);
    const return_type_expr = try parseTypeExpr(ast, allocator, array_s);
    if (return_type_expr == 0) {
        // most likely the user forgot to specify the return type.
        // Mark return type as invalid and try to continue.
        try warn(ast, allocator.e, .expected_return_type);
    }
    if (align_expr == 0 and section_expr == 0 and callconv_expr == 0 and addrspace_expr == 0) {
        switch (params) {
            .zero_or_one => |param| return setNode(ast, allocator.n, fn_proto_index, .{
                .tag = .fn_proto_simple,
                .main_token = fn_token,
                .data = .{ .lhs = param, .rhs = return_type_expr },
            }),
            .multi => |span| {
                return setNode(ast, allocator.n, fn_proto_index, .{
                    .tag = .fn_proto_multi,
                    .main_token = fn_token,
                    .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.SubRange{
                        .start = span.start,
                        .end = span.end,
                    }), .rhs = return_type_expr },
                });
            },
        }
    }
    switch (params) {
        .zero_or_one => |param| return setNode(ast, allocator.n, fn_proto_index, .{
            .tag = .fn_proto_one,
            .main_token = fn_token,
            .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.FnProtoOne{
                .param = param,
                .align_expr = align_expr,
                .addrspace_expr = addrspace_expr,
                .section_expr = section_expr,
                .callconv_expr = callconv_expr,
            }), .rhs = return_type_expr },
        }),
        .multi => |span| {
            return setNode(ast, allocator.n, fn_proto_index, .{
                .tag = .fn_proto,
                .main_token = fn_token,
                .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.FnProto{
                    .params_start = span.start,
                    .params_end = span.end,
                    .align_expr = align_expr,
                    .addrspace_expr = addrspace_expr,
                    .section_expr = section_expr,
                    .callconv_expr = callconv_expr,
                }), .rhs = return_type_expr },
            });
        },
    }
}
/// VarDecl <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? AddrSpace? LinkSection? (EQUAL Expr)? SEMICOLON
fn parseVarDecl(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const mut_token = eatToken(ast, .keyword_const) orelse
        eatToken(ast, .keyword_var) orelse
        return null_node;
    _ = try expectToken(ast, allocator.e, .identifier);
    const type_node: zig.Index = if (eatToken(ast, .colon) == null) 0 else try expectTypeExpr(ast, allocator, array_s);
    const align_node = try parseByteAlign(ast, allocator, array_s);
    const addrspace_node = try parseAddrSpace(ast, allocator, array_s);
    const section_node = try parseLinkSection(ast, allocator, array_s);
    const init_node: zig.Index = switch (readTagAhead(ast)) {
        .equal_equal => blk: {
            try warn(ast, allocator.e, .wrong_equal_var_decl);
            ast.tokens.stream(1);
            break :blk try expectExpr(ast, allocator, array_s);
        },
        .equal => blk: {
            ast.tokens.stream(1);
            break :blk try expectExpr(ast, allocator, array_s);
        },
        else => 0,
    };
    if (section_node == 0 and addrspace_node == 0) {
        if (align_node == 0) {
            return addNode(ast, allocator.n, .{
                .tag = .simple_var_decl,
                .main_token = mut_token,
                .data = .{ .lhs = type_node, .rhs = init_node },
            });
        } else if (type_node == 0) {
            return addNode(ast, allocator.n, .{
                .tag = .aligned_var_decl,
                .main_token = mut_token,
                .data = .{ .lhs = align_node, .rhs = init_node },
            });
        } else {
            return addNode(ast, allocator.n, .{
                .tag = .local_var_decl,
                .main_token = mut_token,
                .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.LocalVarDecl{
                    .type_node = type_node,
                    .align_node = align_node,
                }), .rhs = init_node },
            });
        }
    } else {
        return addNode(ast, allocator.n, .{
            .tag = .global_var_decl,
            .main_token = mut_token,
            .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.GlobalVarDecl{
                .type_node = type_node,
                .align_node = align_node,
                .addrspace_node = addrspace_node,
                .section_node = section_node,
            }), .rhs = init_node },
        });
    }
}
/// ContainerField <- KEYWORD_comptime? IDENTIFIER (COLON TypeExpr ByteAlign?)? (EQUAL Expr)?
fn expectContainerField(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    var main_token = tokenIndex(ast);
    _ = eatToken(ast, .keyword_comptime);
    const tuple_like: bool = readTagAhead(ast) != .identifier or relativeTagAhead(ast, 1) != .colon;
    if (!tuple_like) {
        main_token = assertToken(ast, .identifier);
    }
    var align_expr: zig.Index = 0;
    var type_expr: zig.Index = 0;
    if (eatToken(ast, .colon) != null or tuple_like) {
        type_expr = try expectTypeExpr(ast, allocator, array_s);
        align_expr = try parseByteAlign(ast, allocator, array_s);
    }
    const value_expr: zig.Index = if (eatToken(ast, .equal) == null) 0 else try expectExpr(ast, allocator, array_s);
    if (align_expr == 0) {
        return addNode(ast, allocator.n, .{
            .tag = .container_field_init,
            .main_token = main_token,
            .data = .{ .lhs = type_expr, .rhs = value_expr },
        });
    } else if (value_expr == 0) {
        return addNode(ast, allocator.n, .{
            .tag = .container_field_align,
            .main_token = main_token,
            .data = .{ .lhs = type_expr, .rhs = align_expr },
        });
    } else {
        return addNode(ast, allocator.n, .{
            .tag = .container_field,
            .main_token = main_token,
            .data = .{
                .lhs = type_expr,
                .rhs = try addExtra(ast, allocator.x, zig.AstNode.ContainerField{
                    .value_expr = value_expr,
                    .align_expr = align_expr,
                }),
            },
        });
    }
}
/// Statement
///     <- KEYWORD_comptime? VarDecl
///      / KEYWORD_comptime BlockExprStatement
///      / KEYWORD_nosuspend BlockExprStatement
///      / KEYWORD_suspend BlockExprStatement
///      / KEYWORD_defer BlockExprStatement
///      / KEYWORD_errdefer Payload? BlockExprStatement
///      / IfStatement
///      / LabeledStatement
///      / SwitchExpr
///      / AssignExpr SEMICOLON
fn parseStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
    allow_defer_var: bool,
) Error!zig.Index {
    const comptime_token = eatToken(ast, .keyword_comptime);
    if (allow_defer_var) {
        const var_decl = try parseVarDecl(ast, allocator, array_s);
        if (var_decl != 0) {
            try expectSemicolon(ast, allocator.e, .expected_semi_after_decl, true);
            return var_decl;
        }
    }
    if (comptime_token) |token| {
        return addNode(ast, allocator.n, .{
            .tag = .@"comptime",
            .main_token = token,
            .data = .{ .lhs = try expectBlockExprStatement(ast, allocator, array_s), .rhs = undefined },
        });
    }
    switch (readTagAhead(ast)) {
        .keyword_nosuspend => {
            return addNode(ast, allocator.n, .{
                .tag = .@"nosuspend",
                .main_token = nextToken(ast),
                .data = .{ .lhs = try expectBlockExprStatement(ast, allocator, array_s), .rhs = undefined },
            });
        },
        .keyword_suspend => {
            const token = nextToken(ast);
            const block_expr = try expectBlockExprStatement(ast, allocator, array_s);
            return addNode(ast, allocator.n, .{
                .tag = .@"suspend",
                .main_token = token,
                .data = .{ .lhs = block_expr, .rhs = undefined },
            });
        },
        .keyword_defer => if (allow_defer_var) return addNode(ast, allocator.n, .{
            .tag = .@"defer",
            .main_token = nextToken(ast),
            .data = .{ .lhs = undefined, .rhs = try expectBlockExprStatement(ast, allocator, array_s) },
        }),
        .keyword_errdefer => if (allow_defer_var) return addNode(ast, allocator.n, .{
            .tag = .@"errdefer",
            .main_token = nextToken(ast),
            .data = .{ .lhs = try parsePayload(ast, allocator.e), .rhs = try expectBlockExprStatement(ast, allocator, array_s) },
        }),
        .keyword_switch => return expectSwitchExpr(ast, allocator, array_s),
        .keyword_if => return expectIfStatement(ast, allocator, array_s),
        .keyword_enum, .keyword_struct, .keyword_union => {
            const identifier = tokenIndex(ast) + 1;
            if (try parseCStyleContainer(ast, allocator, array_s)) {
                // Return something so that `expectStatement` is happy.
                return addNode(ast, allocator.n, .{
                    .tag = .identifier,
                    .main_token = identifier,
                    .data = .{ .lhs = undefined, .rhs = undefined },
                });
            }
        },
        else => {},
    }
    const labeled_statement = try parseLabeledStatement(ast, allocator, array_s);
    if (labeled_statement != 0) return labeled_statement;
    const assign_expr = try parseAssignExpr(ast, allocator, array_s);
    if (assign_expr != 0) {
        try expectSemicolon(ast, allocator.e, .expected_semi_after_stmt, true);
        return assign_expr;
    }
    return null_node;
}
fn expectStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
    allow_defer_var: bool,
) Error!zig.Index {
    const statement = try parseStatement(ast, allocator, array_s, allow_defer_var);
    if (statement == 0) {
        return fail(ast, allocator.e, .expected_statement);
    }
    return statement;
}
/// If a parse error occurs, reports an error, but then finds the next statement
/// and returns that one instead. If a parse error occurs but there is no following
/// statement, returns 0.
fn expectStatementRecoverable(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    while (true) {
        return expectStatement(ast, allocator, array_s, true) catch |err| switch (err) {
            error.ParseError => {
                findNextStmt(
                    ast,
                ); // Try to skip to the next statement.
                switch (readTagAhead(ast)) {
                    .r_brace => return null_node,
                    .eof => return error.ParseError,
                    else => continue,
                }
            },
            else => |mem_error| return mem_error,
        };
    }
}
/// IfStatement
///     <- IfPrefix BlockExpr ( KEYWORD_else Payload? Statement )?
///      / IfPrefix AssignExpr ( SEMICOLON / KEYWORD_else Payload? Statement )
fn expectIfStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const if_token = assertToken(ast, .keyword_if);
    _ = try expectToken(ast, allocator.e, .l_paren);
    const condition = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try parsePtrPayload(ast, allocator.e);
    // TODO propose to change the syntax so that semicolons are always required
    // inside if statements, even if there is an `else`.
    var else_required = false;
    const then_expr = blk: {
        const block_expr = try parseBlockExpr(ast, allocator, array_s);
        if (block_expr != 0) break :blk block_expr;
        const assign_expr = try parseAssignExpr(ast, allocator, array_s);
        if (assign_expr == 0) {
            return fail(ast, allocator.e, .expected_block_or_assignment);
        }
        if (eatToken(ast, .semicolon)) |_| {
            return addNode(ast, allocator.n, .{
                .tag = .if_simple,
                .main_token = if_token,
                .data = .{ .lhs = condition, .rhs = assign_expr },
            });
        }
        else_required = true;
        break :blk assign_expr;
    };
    _ = eatToken(ast, .keyword_else) orelse {
        if (else_required) {
            try warn(ast, allocator.e, .expected_semi_or_else);
        }
        return addNode(ast, allocator.n, .{
            .tag = .if_simple,
            .main_token = if_token,
            .data = .{ .lhs = condition, .rhs = then_expr },
        });
    };
    _ = try parsePayload(ast, allocator.e);
    const else_expr = try expectStatement(ast, allocator, array_s, false);
    return addNode(ast, allocator.n, .{
        .tag = .@"if",
        .main_token = if_token,
        .data = .{
            .lhs = condition,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.If{
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// LabeledStatement <- BlockLabel? (Block / LoopStatement)
fn parseLabeledStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const label_token = parseBlockLabel(
        ast,
    );
    const block = try parseBlock(ast, allocator, array_s);
    if (block != 0) return block;
    const loop_stmt = try parseLoopStatement(ast, allocator, array_s);
    if (loop_stmt != 0) return loop_stmt;
    if (label_token != 0) {
        const after_colon = tokenIndex(ast);
        const node = try parseTypeExpr(ast, allocator, array_s);
        if (node != 0) {
            const a = try parseByteAlign(ast, allocator, array_s);
            const b = try parseAddrSpace(ast, allocator, array_s);
            const c = try parseLinkSection(ast, allocator, array_s);
            const d = if (eatToken(ast, .equal) == null) 0 else try expectExpr(ast, allocator, array_s);
            if (a != 0 or b != 0 or c != 0 or d != 0) {
                return failMsg(ast, allocator.e, .{ .tag = .expected_var_const, .token = label_token });
            }
        }
        return failMsg(ast, allocator.e, .{ .tag = .expected_labelable, .token = after_colon });
    }
    return null_node;
}
/// LoopStatement <- KEYWORD_inline? (ForStatement / WhileStatement)
fn parseLoopStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const inline_token = eatToken(ast, .keyword_inline);
    const for_statement = try parseForStatement(ast, allocator, array_s);
    if (for_statement != 0) return for_statement;
    const while_statement = try parseWhileStatement(ast, allocator, array_s);
    if (while_statement != 0) return while_statement;
    if (inline_token == null) return null_node;
    // If we've seen "inline", there should have been a "for" or "while"
    return fail(ast, allocator.e, .expected_inlinable);
}
/// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
/// ForStatement
///     <- ForPrefix BlockExpr ( KEYWORD_else Statement )?
///      / ForPrefix AssignExpr ( SEMICOLON / KEYWORD_else Statement )
fn parseForStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const for_token = eatToken(ast, .keyword_for) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const array_expr = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    const found_payload = try parsePtrIndexPayload(ast, allocator.e);
    if (found_payload == 0) try warn(ast, allocator.e, .expected_loop_payload);
    // TODO propose to change the syntax so that semicolons are always required
    // inside while statements, even if there is an `else`.
    var else_required = false;
    const then_expr = blk: {
        const block_expr = try parseBlockExpr(ast, allocator, array_s);
        if (block_expr != 0) break :blk block_expr;
        const assign_expr = try parseAssignExpr(ast, allocator, array_s);
        if (assign_expr == 0) {
            return fail(ast, allocator.e, .expected_block_or_assignment);
        }
        if (eatToken(ast, .semicolon)) |_| {
            return addNode(ast, allocator.n, .{
                .tag = .for_simple,
                .main_token = for_token,
                .data = .{ .lhs = array_expr, .rhs = assign_expr },
            });
        }
        else_required = true;
        break :blk assign_expr;
    };
    _ = eatToken(ast, .keyword_else) orelse {
        if (else_required) {
            try warn(ast, allocator.e, .expected_semi_or_else);
        }
        return addNode(ast, allocator.n, .{
            .tag = .for_simple,
            .main_token = for_token,
            .data = .{ .lhs = array_expr, .rhs = then_expr },
        });
    };
    return addNode(ast, allocator.n, .{
        .tag = .@"for",
        .main_token = for_token,
        .data = .{
            .lhs = array_expr,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.If{
                .then_expr = then_expr,
                .else_expr = try expectStatement(ast, allocator, array_s, false),
            }),
        },
    });
}
/// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
/// WhileStatement
///     <- WhilePrefix BlockExpr ( KEYWORD_else Payload? Statement )?
///      / WhilePrefix AssignExpr ( SEMICOLON / KEYWORD_else Payload? Statement )
fn parseWhileStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const while_token = eatToken(ast, .keyword_while) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const condition = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try parsePtrPayload(ast, allocator.e);
    const cont_expr = try parseWhileContinueExpr(ast, allocator, array_s);
    // TODO propose to change the syntax so that semicolons are always required
    // inside while statements, even if there is an `else`.
    var else_required = false;
    const then_expr = blk: {
        const block_expr = try parseBlockExpr(ast, allocator, array_s);
        if (block_expr != 0) break :blk block_expr;
        const assign_expr = try parseAssignExpr(ast, allocator, array_s);
        if (assign_expr == 0) {
            return fail(ast, allocator.e, .expected_block_or_assignment);
        }
        if (eatToken(ast, .semicolon)) |_| {
            if (cont_expr == 0) {
                return addNode(ast, allocator.n, .{
                    .tag = .while_simple,
                    .main_token = while_token,
                    .data = .{ .lhs = condition, .rhs = assign_expr },
                });
            } else {
                return addNode(ast, allocator.n, .{
                    .tag = .while_cont,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = try addExtra(ast, allocator.x, zig.AstNode.WhileCont{
                            .cont_expr = cont_expr,
                            .then_expr = assign_expr,
                        }),
                    },
                });
            }
        }
        else_required = true;
        break :blk assign_expr;
    };
    _ = eatToken(ast, .keyword_else) orelse {
        if (else_required) {
            try warn(ast, allocator.e, .expected_semi_or_else);
        }
        if (cont_expr == 0) {
            return addNode(ast, allocator.n, .{
                .tag = .while_simple,
                .main_token = while_token,
                .data = .{ .lhs = condition, .rhs = then_expr },
            });
        } else {
            return addNode(ast, allocator.n, .{
                .tag = .while_cont,
                .main_token = while_token,
                .data = .{
                    .lhs = condition,
                    .rhs = try addExtra(ast, allocator.x, zig.AstNode.WhileCont{
                        .cont_expr = cont_expr,
                        .then_expr = then_expr,
                    }),
                },
            });
        }
    };
    _ = try parsePayload(ast, allocator.e);
    const else_expr = try expectStatement(ast, allocator, array_s, false);
    return addNode(ast, allocator.n, .{
        .tag = .@"while",
        .main_token = while_token,
        .data = .{
            .lhs = condition,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.While{
                .cont_expr = cont_expr,
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// BlockExprStatement
///     <- BlockExpr
///      / AssignExpr SEMICOLON
fn parseBlockExprStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const block_expr = try parseBlockExpr(ast, allocator, array_s);
    if (block_expr != 0) {
        return block_expr;
    }
    const assign_expr = try parseAssignExpr(ast, allocator, array_s);
    if (assign_expr != 0) {
        try expectSemicolon(ast, allocator.e, .expected_semi_after_stmt, true);
        return assign_expr;
    }
    return null_node;
}
fn expectBlockExprStatement(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const node = try parseBlockExprStatement(ast, allocator, array_s);
    if (node == 0) {
        return fail(ast, allocator.e, .expected_block_or_expr);
    }
    return node;
}
/// BlockExpr <- BlockLabel? Block
fn parseBlockExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    switch (readTagAhead(ast)) {
        .identifier => {
            if (relativeTagAhead(ast, 1) == .colon and
                relativeTagAhead(ast, 2) == .l_brace)
            {
                ast.tokens.stream(2);
                return parseBlock(ast, allocator, array_s);
            } else {
                return null_node;
            }
        },
        .l_brace => return parseBlock(ast, allocator, array_s),
        else => return null_node,
    }
}
/// AssignExpr <- Expr (AssignOp Expr)?
/// AssignOp
///     <- ASTERISKEQUAL
///      / SLASHEQUAL
///      / PERCENTEQUAL
///      / PLUSEQUAL
///      / MINUSEQUAL
///      / LARROW2EQUAL
///      / RARROW2EQUAL
///      / AMPERSANDEQUAL
///      / CARETEQUAL
///      / PIPEEQUAL
///      / ASTERISKPERCENTEQUAL
///      / PLUSPERCENTEQUAL
///      / MINUSPERCENTEQUAL
///      / EQUAL
fn parseAssignExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const expr = try parseExpr(ast, allocator, array_s);
    if (expr == 0) return null_node;
    const tag: zig.AstNode.Tag = switch (readTagAhead(ast)) {
        .asterisk_equal => .assign_mul,
        .slash_equal => .assign_div,
        .percent_equal => .assign_mod,
        .plus_equal => .assign_add,
        .minus_equal => .assign_sub,
        .angle_bracket_angle_bracket_left_equal => .assign_shl,
        .angle_bracket_angle_bracket_left_pipe_equal => .assign_shl_sat,
        .angle_bracket_angle_bracket_right_equal => .assign_shr,
        .ampersand_equal => .assign_bit_and,
        .caret_equal => .assign_bit_xor,
        .pipe_equal => .assign_bit_or,
        .asterisk_percent_equal => .assign_mul_wrap,
        .plus_percent_equal => .assign_add_wrap,
        .minus_percent_equal => .assign_sub_wrap,
        .asterisk_pipe_equal => .assign_mul_sat,
        .plus_pipe_equal => .assign_add_sat,
        .minus_pipe_equal => .assign_sub_sat,
        .equal => .assign,
        else => return expr,
    };
    return addNode(ast, allocator.n, .{
        .tag = tag,
        .main_token = nextToken(ast),
        .data = .{ .lhs = expr, .rhs = try expectExpr(ast, allocator, array_s) },
    });
}
fn expectAssignExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const expr = try parseAssignExpr(ast, allocator, array_s);
    if (expr == 0) {
        return fail(ast, allocator.e, .expected_expr_or_assignment);
    }
    return expr;
}
fn parseExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    return parseExprPrecedence(ast, allocator, array_s, 0);
}
fn expectExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const node = try parseExpr(ast, allocator, array_s);
    if (node == 0) {
        return fail(ast, allocator.e, .expected_expr);
    } else {
        return node;
    }
}
const Assoc = enum {
    left,
    none,
};
const OperInfo = struct {
    prec: i8,
    tag: zig.AstNode.Tag,
    assoc: Assoc = Assoc.left,
};
// A table of binary operator information. Higher precedence numbers are
// stickier. All operators at the same precedence level should have the same
// associativity.
const operTable = directEnumArrayDefault(zig.Token.Tag, OperInfo, .{ .prec = -1, .tag = zig.AstNode.Tag.root }, 0, .{
    .keyword_or = .{ .prec = 10, .tag = .bool_or },
    .keyword_and = .{ .prec = 20, .tag = .bool_and },
    .equal_equal = .{ .prec = 30, .tag = .equal_equal, .assoc = Assoc.none },
    .bang_equal = .{ .prec = 30, .tag = .bang_equal, .assoc = Assoc.none },
    .angle_bracket_left = .{ .prec = 30, .tag = .less_than, .assoc = Assoc.none },
    .angle_bracket_right = .{ .prec = 30, .tag = .greater_than, .assoc = Assoc.none },
    .angle_bracket_left_equal = .{ .prec = 30, .tag = .less_or_equal, .assoc = Assoc.none },
    .angle_bracket_right_equal = .{ .prec = 30, .tag = .greater_or_equal, .assoc = Assoc.none },
    .ampersand = .{ .prec = 40, .tag = .bit_and },
    .caret = .{ .prec = 40, .tag = .bit_xor },
    .pipe = .{ .prec = 40, .tag = .bit_or },
    .keyword_orelse = .{ .prec = 40, .tag = .@"orelse" },
    .keyword_catch = .{ .prec = 40, .tag = .@"catch" },
    .angle_bracket_angle_bracket_left = .{ .prec = 50, .tag = .shl },
    .angle_bracket_angle_bracket_left_pipe = .{ .prec = 50, .tag = .shl_sat },
    .angle_bracket_angle_bracket_right = .{ .prec = 50, .tag = .shr },
    .plus = .{ .prec = 60, .tag = .add },
    .minus = .{ .prec = 60, .tag = .sub },
    .plus_plus = .{ .prec = 60, .tag = .array_cat },
    .plus_percent = .{ .prec = 60, .tag = .add_wrap },
    .minus_percent = .{ .prec = 60, .tag = .sub_wrap },
    .plus_pipe = .{ .prec = 60, .tag = .add_sat },
    .minus_pipe = .{ .prec = 60, .tag = .sub_sat },
    .pipe_pipe = .{ .prec = 70, .tag = .merge_error_sets },
    .asterisk = .{ .prec = 70, .tag = .mul },
    .slash = .{ .prec = 70, .tag = .div },
    .percent = .{ .prec = 70, .tag = .mod },
    .asterisk_asterisk = .{ .prec = 70, .tag = .array_mult },
    .asterisk_percent = .{ .prec = 70, .tag = .mul_wrap },
    .asterisk_pipe = .{ .prec = 70, .tag = .mul_sat },
});
fn parseExprPrecedence(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
    min_prec: i32,
) Error!zig.Index {
    debug.assert(min_prec >= 0);
    var node = try parsePrefixExpr(ast, allocator, array_s);
    if (node == 0) {
        return null_node;
    }
    var banned_prec: i8 = -1;
    while (true) {
        const tok_tag = readTagAhead(ast);
        const info = operTable[@as(usize, @intCast(@intFromEnum(tok_tag)))];
        if (info.prec < min_prec) {
            break;
        }
        if (info.prec == banned_prec) {
            return fail(ast, allocator.e, .chained_comparison_operators);
        }
        const oper_token = nextToken(ast);
        // Special-case handling for "catch"
        if (tok_tag == .keyword_catch) {
            _ = try parsePayload(ast, allocator.e);
        }
        const rhs = try parseExprPrecedence(ast, allocator, array_s, info.prec + 1);
        if (rhs == 0) {
            try warn(ast, allocator.e, .expected_expr);
            return node;
        }
        const tok_len = tok_tag.lexeme().?.len;
        const b_idx: u64 = ast.tokens.readOneAt(oper_token).start - 1;
        const a_idx: u64 = ast.tokens.readOneAt(oper_token).start + tok_len;
        const b_char: u8 = ast.source.readOneAt(b_idx);
        const a_char: u8 = ast.source.readOneAt(a_idx);
        if (tok_tag == .ampersand and a_char == '&') {
            try warnMsg(ast, allocator.e, .{ .tag = .invalid_ampersand_ampersand, .token = oper_token });
        } else if (fmt.ascii.isWhitespace(b_char) != fmt.ascii.isWhitespace(a_char)) {
            try warnMsg(ast, allocator.e, .{ .tag = .mismatched_binary_op_whitespace, .token = oper_token });
        }
        node = try addNode(ast, allocator.n, .{
            .tag = info.tag,
            .main_token = oper_token,
            .data = .{ .lhs = node, .rhs = rhs },
        });
        if (info.assoc == Assoc.none) {
            banned_prec = info.prec;
        }
    }
    return node;
}
/// PrefixExpr <- PrefixOp* PrimaryExpr
/// PrefixOp
///     <- EXCLAMATIONMARK
///      / MINUS
///      / TILDE
///      / MINUSPERCENT
///      / AMPERSAND
///      / KEYWORD_try
///      / KEYWORD_await
fn parsePrefixExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const tag: zig.AstNode.Tag = switch (readTagAhead(ast)) {
        .bang => .bool_not,
        .minus => .negation,
        .tilde => .bit_not,
        .minus_percent => .negation_wrap,
        .ampersand => .address_of,
        .keyword_try => .@"try",
        .keyword_await => .@"await",
        else => return parsePrimaryExpr(ast, allocator, array_s),
    };
    return addNode(ast, allocator.n, .{
        .tag = tag,
        .main_token = nextToken(ast),
        .data = .{ .lhs = try expectPrefixExpr(ast, allocator, array_s), .rhs = undefined },
    });
}
fn expectPrefixExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const node = try parsePrefixExpr(ast, allocator, array_s);
    if (node == 0) {
        return fail(ast, allocator.e, .expected_prefix_expr);
    }
    return node;
}
/// TypeExpr <- PrefixTypeOp* ErrorUnionExpr
/// PrefixTypeOp
///     <- QUESTIONMARK
///      / KEYWORD_anyframe MINUSRARROW
///      / SliceTypeStart (ByteAlign / AddrSpace / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
///      / PtrTypeStart (AddrSpace / KEYWORD_align LPAREN Expr (COLON INTEGER COLON INTEGER)? RPAREN / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
///      / ArrayTypeStart
/// SliceTypeStart <- LBRACKET (COLON Expr)? RBRACKET
/// PtrTypeStart
///     <- ASTERISK
///      / ASTERISK2
///      / LBRACKET ASTERISK (LETTERC / COLON Expr)? RBRACKET
/// ArrayTypeStart <- LBRACKET Expr (COLON Expr)? RBRACKET
fn parseTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    switch (readTagAhead(ast)) {
        .question_mark => return addNode(ast, allocator.n, .{
            .tag = .optional_type,
            .main_token = nextToken(ast),
            .data = .{ .lhs = try expectTypeExpr(ast, allocator, array_s), .rhs = undefined },
        }),
        .keyword_anyframe => switch (relativeTagAhead(ast, 1)) {
            .arrow => return addNode(ast, allocator.n, .{
                .tag = .anyframe_type,
                .main_token = nextToken(ast),
                .data = .{ .lhs = nextToken(ast), .rhs = try expectTypeExpr(ast, allocator, array_s) },
            }),
            else => return parseErrorUnionExpr(ast, allocator, array_s),
        },
        .asterisk => {
            const asterisk = nextToken(ast);
            const mods = try parsePtrModifiers(ast, allocator, array_s);
            const elem_type = try expectTypeExpr(ast, allocator, array_s);
            if (mods.bit_range_start != 0) {
                return addNode(ast, allocator.n, .{
                    .tag = .ptr_type_bit_range,
                    .main_token = asterisk,
                    .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrTypeBitRange{
                        .sentinel = 0,
                        .align_node = mods.align_node,
                        .addrspace_node = mods.addrspace_node,
                        .bit_range_start = mods.bit_range_start,
                        .bit_range_end = mods.bit_range_end,
                    }), .rhs = elem_type },
                });
            } else if (mods.addrspace_node != 0) {
                return addNode(ast, allocator.n, .{
                    .tag = .ptr_type,
                    .main_token = asterisk,
                    .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrType{
                        .sentinel = 0,
                        .align_node = mods.align_node,
                        .addrspace_node = mods.addrspace_node,
                    }), .rhs = elem_type },
                });
            } else {
                return addNode(ast, allocator.n, .{
                    .tag = .ptr_type_aligned,
                    .main_token = asterisk,
                    .data = .{ .lhs = mods.align_node, .rhs = elem_type },
                });
            }
        },
        .asterisk_asterisk => {
            const asterisk = nextToken(ast);
            const mods = try parsePtrModifiers(ast, allocator, array_s);
            const elem_type = try expectTypeExpr(ast, allocator, array_s);
            const inner: zig.Index = inner: {
                if (mods.bit_range_start != 0) {
                    break :inner try addNode(ast, allocator.n, .{
                        .tag = .ptr_type_bit_range,
                        .main_token = asterisk,
                        .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrTypeBitRange{
                            .sentinel = 0,
                            .align_node = mods.align_node,
                            .addrspace_node = mods.addrspace_node,
                            .bit_range_start = mods.bit_range_start,
                            .bit_range_end = mods.bit_range_end,
                        }), .rhs = elem_type },
                    });
                } else if (mods.addrspace_node != 0) {
                    break :inner try addNode(ast, allocator.n, .{
                        .tag = .ptr_type,
                        .main_token = asterisk,
                        .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrType{
                            .sentinel = 0,
                            .align_node = mods.align_node,
                            .addrspace_node = mods.addrspace_node,
                        }), .rhs = elem_type },
                    });
                } else {
                    break :inner try addNode(ast, allocator.n, .{
                        .tag = .ptr_type_aligned,
                        .main_token = asterisk,
                        .data = .{ .lhs = mods.align_node, .rhs = elem_type },
                    });
                }
            };
            return addNode(ast, allocator.n, .{
                .tag = .ptr_type_aligned,
                .main_token = asterisk,
                .data = .{ .lhs = 0, .rhs = inner },
            });
        },
        .l_bracket => {
            switch (ast.tokens.readOneAt(ast.tokens.index() + 1).tag) {
                .asterisk => {
                    _ = nextToken(ast);
                    const asterisk: zig.Index = nextToken(ast);
                    var sentinel: zig.Index = 0;
                    if (eatToken(ast, .identifier)) |ident| {
                        const start: usize = ast.tokens.readOneAt(ident).start;
                        const end: usize = ast.tokens.readOneAt(ident + 1).start;
                        const ident_slice: []const u8 = ast.source.readAll()[start..end];
                        if (!mem.testEqualMany(u8, "c", trimRight(u8, &lit.whitespace, ident_slice))) {
                            ast.tokens.unstream(1);
                        }
                    } else if (eatToken(ast, .colon)) |_| {
                        sentinel = try expectExpr(ast, allocator, array_s);
                    }
                    _ = try expectToken(ast, allocator.e, .r_bracket);
                    const mods = try parsePtrModifiers(ast, allocator, array_s);
                    const elem_type = try expectTypeExpr(ast, allocator, array_s);
                    if (mods.bit_range_start == 0) {
                        if (sentinel == 0 and mods.addrspace_node == 0) {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type_aligned,
                                .main_token = asterisk,
                                .data = .{ .lhs = mods.align_node, .rhs = elem_type },
                            });
                        } else if (mods.align_node == 0 and mods.addrspace_node == 0) {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type_sentinel,
                                .main_token = asterisk,
                                .data = .{ .lhs = sentinel, .rhs = elem_type },
                            });
                        } else {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type,
                                .main_token = asterisk,
                                .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrType{
                                    .sentinel = sentinel,
                                    .align_node = mods.align_node,
                                    .addrspace_node = mods.addrspace_node,
                                }), .rhs = elem_type },
                            });
                        }
                    } else {
                        return addNode(ast, allocator.n, .{
                            .tag = .ptr_type_bit_range,
                            .main_token = asterisk,
                            .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrTypeBitRange{
                                .sentinel = sentinel,
                                .align_node = mods.align_node,
                                .addrspace_node = mods.addrspace_node,
                                .bit_range_start = mods.bit_range_start,
                                .bit_range_end = mods.bit_range_end,
                            }), .rhs = elem_type },
                        });
                    }
                },
                else => {
                    const lbracket = nextToken(ast);
                    const len_expr = try parseExpr(ast, allocator, array_s);
                    const sentinel: zig.Index = if (eatToken(ast, .colon)) |_|
                        try expectExpr(ast, allocator, array_s)
                    else
                        0;
                    _ = try expectToken(ast, allocator.e, .r_bracket);
                    if (len_expr == 0) {
                        const mods = try parsePtrModifiers(ast, allocator, array_s);
                        const elem_type = try expectTypeExpr(ast, allocator, array_s);
                        if (mods.bit_range_start != 0) {
                            try warnMsg(ast, allocator.e, .{
                                .tag = .invalid_bit_range,
                                .token = ast.nodes.readOneAt(allocator.n.*, mods.bit_range_start).main_token,
                            });
                        }
                        if (sentinel == 0 and mods.addrspace_node == 0) {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type_aligned,
                                .main_token = lbracket,
                                .data = .{ .lhs = mods.align_node, .rhs = elem_type },
                            });
                        } else if (mods.align_node == 0 and mods.addrspace_node == 0) {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type_sentinel,
                                .main_token = lbracket,
                                .data = .{ .lhs = sentinel, .rhs = elem_type },
                            });
                        } else {
                            return addNode(ast, allocator.n, .{
                                .tag = .ptr_type,
                                .main_token = lbracket,
                                .data = .{ .lhs = try addExtra(ast, allocator.x, zig.AstNode.PtrType{
                                    .sentinel = sentinel,
                                    .align_node = mods.align_node,
                                    .addrspace_node = mods.addrspace_node,
                                }), .rhs = elem_type },
                            });
                        }
                    } else {
                        switch (readTagAhead(ast)) {
                            .keyword_align,
                            .keyword_const,
                            .keyword_volatile,
                            .keyword_allowzero,
                            .keyword_addrspace,
                            => return fail(ast, allocator.e, .ptr_mod_on_array_child_type),
                            else => {},
                        }
                        const elem_type = try expectTypeExpr(ast, allocator, array_s);
                        if (sentinel == 0) {
                            return addNode(ast, allocator.n, .{
                                .tag = .array_type,
                                .main_token = lbracket,
                                .data = .{ .lhs = len_expr, .rhs = elem_type },
                            });
                        } else {
                            return addNode(ast, allocator.n, .{
                                .tag = .array_type_sentinel,
                                .main_token = lbracket,
                                .data = .{
                                    .lhs = len_expr,
                                    .rhs = try addExtra(ast, allocator.x, .{
                                        .elem_type = elem_type,
                                        .sentinel = sentinel,
                                    }),
                                },
                            });
                        }
                    }
                },
            }
        },
        else => return parseErrorUnionExpr(ast, allocator, array_s),
    }
}
fn expectTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const node = try parseTypeExpr(ast, allocator, array_s);
    if (node == 0) {
        return fail(ast, allocator.e, .expected_type_expr);
    }
    return node;
}
/// PrimaryExpr
///     <- AsmExpr
///      / IfExpr
///      / KEYWORD_break BreakLabel? Expr?
///      / KEYWORD_comptime Expr
///      / KEYWORD_nosuspend Expr
///      / KEYWORD_continue BreakLabel?
///      / KEYWORD_resume Expr
///      / KEYWORD_return Expr?
///      / BlockLabel? LoopExpr
///      / Block
///      / CurlySuffixExpr
fn parsePrimaryExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    switch (readTagAhead(ast)) {
        .keyword_asm => return expectAsmExpr(ast, allocator, array_s),
        .keyword_if => return parseIfExpr(ast, allocator, array_s),
        .keyword_break => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"break",
                .main_token = @as(zig.Index, @intCast(tokenIndex(ast) - 1)),
                .data = .{ .lhs = try parseBreakLabel(ast, allocator.e), .rhs = try parseExpr(ast, allocator, array_s) },
            });
        },
        .keyword_continue => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"continue",
                .main_token = tokenIndex(ast) - 1,
                .data = .{ .lhs = try parseBreakLabel(ast, allocator.e), .rhs = undefined },
            });
        },
        .keyword_comptime => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"comptime",
                .main_token = tokenIndex(ast) - 1,
                .data = .{ .lhs = try expectExpr(ast, allocator, array_s), .rhs = undefined },
            });
        },
        .keyword_nosuspend => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"nosuspend",
                .main_token = tokenIndex(ast) - 1,
                .data = .{ .lhs = try expectExpr(ast, allocator, array_s), .rhs = undefined },
            });
        },
        .keyword_resume => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"resume",
                .main_token = tokenIndex(ast) - 1,
                .data = .{ .lhs = try expectExpr(ast, allocator, array_s), .rhs = undefined },
            });
        },
        .keyword_return => {
            ast.tokens.stream(1);
            return addNode(ast, allocator.n, .{
                .tag = .@"return",
                .main_token = tokenIndex(ast) - 1,
                .data = .{ .lhs = try parseExpr(ast, allocator, array_s), .rhs = undefined },
            });
        },
        .identifier => {
            if (relativeTagAhead(ast, 1) == .colon) {
                switch (relativeTagAhead(ast, 2)) {
                    .keyword_inline => {
                        ast.tokens.stream(3);
                        switch (readTagAhead(ast)) {
                            .keyword_for => return parseForExpr(ast, allocator, array_s),
                            .keyword_while => return parseWhileExpr(ast, allocator, array_s),
                            else => return fail(ast, allocator.e, .expected_inlinable),
                        }
                    },
                    .keyword_for => {
                        ast.tokens.stream(2);
                        return parseForExpr(ast, allocator, array_s);
                    },
                    .keyword_while => {
                        ast.tokens.stream(2);
                        return parseWhileExpr(ast, allocator, array_s);
                    },
                    .l_brace => {
                        ast.tokens.stream(2);
                        return parseBlock(ast, allocator, array_s);
                    },
                    else => return parseCurlySuffixExpr(ast, allocator, array_s),
                }
            } else {
                return parseCurlySuffixExpr(ast, allocator, array_s);
            }
        },
        .keyword_inline => {
            ast.tokens.stream(1);
            switch (readTagAhead(ast)) {
                .keyword_for => return parseForExpr(ast, allocator, array_s),
                .keyword_while => return parseWhileExpr(ast, allocator, array_s),
                else => return fail(ast, allocator.e, .expected_inlinable),
            }
        },
        .keyword_for => return parseForExpr(ast, allocator, array_s),
        .keyword_while => return parseWhileExpr(ast, allocator, array_s),
        .l_brace => return parseBlock(ast, allocator, array_s),
        else => return parseCurlySuffixExpr(ast, allocator, array_s),
    }
}
/// IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?
fn parseIfExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    return parseIf(ast, allocator, array_s, expectExpr);
}
/// Block <- LBRACE Statement* RBRACE
fn parseBlock(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const lbrace = eatToken(ast, .l_brace) orelse return null_node;
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    while (true) {
        if (readTagAhead(ast) == .r_brace) break;
        const statement = try expectStatementRecoverable(ast, allocator, array_s);
        if (statement == 0) break;
        try array_s.appendOne(allocator.s, statement);
    }
    _ = try expectToken(ast, allocator.e, .r_brace);
    const semicolon = (relativeTagBehind(ast, 2) == .semicolon);
    const statements = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
    switch (statements.len) {
        0 => return addNode(ast, allocator.n, .{
            .tag = .block_two,
            .main_token = lbrace,
            .data = .{ .lhs = 0, .rhs = 0 },
        }),
        1 => return addNode(ast, allocator.n, .{
            .tag = if (semicolon) .block_two_semicolon else .block_two,
            .main_token = lbrace,
            .data = .{ .lhs = statements[0], .rhs = 0 },
        }),
        2 => return addNode(ast, allocator.n, .{
            .tag = if (semicolon) .block_two_semicolon else .block_two,
            .main_token = lbrace,
            .data = .{ .lhs = statements[0], .rhs = statements[1] },
        }),
        else => {
            const span = try listToSpan(ast, allocator.x, statements);
            return addNode(ast, allocator.n, .{
                .tag = if (semicolon) .block_semicolon else .block,
                .main_token = lbrace,
                .data = .{ .lhs = span.start, .rhs = span.end },
            });
        },
    }
}
/// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
/// ForExpr <- ForPrefix Expr (KEYWORD_else Expr)?
fn parseForExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const for_token = eatToken(ast, .keyword_for) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const array_expr = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    const found_payload = try parsePtrIndexPayload(ast, allocator.e);
    if (found_payload == 0) try warn(ast, allocator.e, .expected_loop_payload);
    const then_expr = try expectExpr(ast, allocator, array_s);
    _ = eatToken(ast, .keyword_else) orelse {
        return addNode(ast, allocator.n, .{
            .tag = .for_simple,
            .main_token = for_token,
            .data = .{ .lhs = array_expr, .rhs = then_expr },
        });
    };
    const else_expr = try expectExpr(ast, allocator, array_s);
    return addNode(ast, allocator.n, .{
        .tag = .@"for",
        .main_token = for_token,
        .data = .{
            .lhs = array_expr,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.If{
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
/// WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?
fn parseWhileExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const while_token = eatToken(ast, .keyword_while) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const condition = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try parsePtrPayload(ast, allocator.e);
    const cont_expr = try parseWhileContinueExpr(ast, allocator, array_s);
    const then_expr = try expectExpr(ast, allocator, array_s);
    _ = eatToken(ast, .keyword_else) orelse {
        if (cont_expr == 0) {
            return addNode(ast, allocator.n, .{
                .tag = .while_simple,
                .main_token = while_token,
                .data = .{ .lhs = condition, .rhs = then_expr },
            });
        } else {
            return addNode(ast, allocator.n, .{
                .tag = .while_cont,
                .main_token = while_token,
                .data = .{
                    .lhs = condition,
                    .rhs = try addExtra(ast, allocator.x, zig.AstNode.WhileCont{
                        .cont_expr = cont_expr,
                        .then_expr = then_expr,
                    }),
                },
            });
        }
    };
    _ = try parsePayload(ast, allocator.e);
    const else_expr = try expectExpr(ast, allocator, array_s);
    return addNode(ast, allocator.n, .{
        .tag = .@"while",
        .main_token = while_token,
        .data = .{
            .lhs = condition,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.While{
                .cont_expr = cont_expr,
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// CurlySuffixExpr <- TypeExpr InitList?
/// InitList
///     <- LBRACE FieldInit (COMMA FieldInit)* COMMA? RBRACE
///      / LBRACE Expr (COMMA Expr)* COMMA? RBRACE
///      / LBRACE RBRACE
fn parseCurlySuffixExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const lhs = try parseTypeExpr(ast, allocator, array_s);
    if (lhs == 0) return null_node;
    const lbrace = eatToken(ast, .l_brace) orelse return lhs;
    // If there are 0 or 1 items, we can use ArrayInitOne/StructInitOne;
    // otherwise we use the full ArrayInit/StructInit.
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    const field_init = try parseFieldInit(ast, allocator, array_s);
    if (field_init != 0) {
        try array_s.appendOne(allocator.s, field_init);
        while (true) {
            switch (readTagAhead(ast)) {
                .comma => ast.tokens.stream(1),
                .r_brace => {
                    ast.tokens.stream(1);
                    break;
                },
                .colon, .r_paren, .r_bracket => return failExpected(ast, allocator.e, .r_brace),
                // Likely just a missing comma; give error but continue parsing.
                else => try warn(ast, allocator.e, .expected_comma_after_initializer),
            }
            if (eatToken(ast, .r_brace)) |_| break;
            const next = try expectFieldInit(ast, allocator, array_s);
            try array_s.appendOne(allocator.s, next);
        }
        const comma = (relativeTagBehind(ast, 2) == .comma);
        const inits = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
        switch (inits.len) {
            0 => unreachable,
            1 => return addNode(ast, allocator.n, .{
                .tag = if (comma) .struct_init_one_comma else .struct_init_one,
                .main_token = lbrace,
                .data = .{ .lhs = lhs, .rhs = inits[0] },
            }),
            else => return addNode(ast, allocator.n, .{
                .tag = if (comma) .struct_init_comma else .struct_init,
                .main_token = lbrace,
                .data = .{ .lhs = lhs, .rhs = try addExtra(ast, allocator.x, try listToSpan(ast, allocator.x, inits)) },
            }),
        }
    }
    while (true) {
        if (eatToken(ast, .r_brace)) |_| break;
        const elem_init = try expectExpr(ast, allocator, array_s);
        try array_s.appendOne(allocator.s, elem_init);
        switch (readTagAhead(ast)) {
            .comma => ast.tokens.stream(1),
            .r_brace => {
                ast.tokens.stream(1);
                break;
            },
            .colon, .r_paren, .r_bracket => return failExpected(ast, allocator.e, .r_brace),
            // Likely just a missing comma; give error but continue parsing.
            else => try warn(ast, allocator.e, .expected_comma_after_initializer),
        }
    }
    const comma = (relativeTagBehind(ast, 2) == .comma);
    const inits = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
    switch (inits.len) {
        0 => return addNode(ast, allocator.n, .{
            .tag = .struct_init_one,
            .main_token = lbrace,
            .data = .{ .lhs = lhs, .rhs = 0 },
        }),
        1 => return addNode(ast, allocator.n, .{
            .tag = if (comma) .array_init_one_comma else .array_init_one,
            .main_token = lbrace,
            .data = .{ .lhs = lhs, .rhs = inits[0] },
        }),
        else => return addNode(ast, allocator.n, .{
            .tag = if (comma) .array_init_comma else .array_init,
            .main_token = lbrace,
            .data = .{ .lhs = lhs, .rhs = try addExtra(ast, allocator.x, try listToSpan(ast, allocator.x, inits)) },
        }),
    }
}
/// ErrorUnionExpr <- SuffixExpr (EXCLAMATIONMARK TypeExpr)?
fn parseErrorUnionExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const suffix_expr = try parseSuffixExpr(ast, allocator, array_s);
    if (suffix_expr == 0) return null_node;
    const bang = eatToken(ast, .bang) orelse return suffix_expr;
    return addNode(ast, allocator.n, .{
        .tag = .error_union,
        .main_token = bang,
        .data = .{ .lhs = suffix_expr, .rhs = try expectTypeExpr(ast, allocator, array_s) },
    });
}
/// SuffixExpr
///     <- KEYWORD_async PrimaryTypeExpr SuffixOp* FnCallArguments
///      / PrimaryTypeExpr (SuffixOp / FnCallArguments)*
/// FnCallArguments <- LPAREN ExprList RPAREN
/// ExprList <- (Expr COMMA)* Expr?
fn parseSuffixExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    if (eatToken(ast, .keyword_async)) |_| {
        var res = try expectPrimaryTypeExpr(ast, allocator, array_s);
        while (true) {
            const node = try parseSuffixOp(ast, allocator, array_s, res);
            if (node == 0) break;
            res = node;
        }
        const lparen = eatToken(ast, .l_paren) orelse {
            try warn(ast, allocator.e, .expected_param_list);
            return res;
        };
        const state_top: usize = array_s.len(allocator.s.*);
        defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
        while (true) {
            if (eatToken(ast, .r_paren)) |_| break;
            const param = try expectExpr(ast, allocator, array_s);
            try array_s.appendOne(allocator.s, param);
            switch (readTagAhead(ast)) {
                .comma => ast.tokens.stream(1),
                .r_paren => {
                    ast.tokens.stream(1);
                    break;
                },
                .colon, .r_brace, .r_bracket => return failExpected(ast, allocator.e, .r_paren),
                // Likely just a missing comma; give error but continue parsing.
                else => try warn(ast, allocator.e, .expected_comma_after_arg),
            }
        }
        const comma = (relativeTagBehind(ast, 2) == .comma);
        const params = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
        switch (params.len) {
            0 => return addNode(ast, allocator.n, .{
                .tag = if (comma) .async_call_one_comma else .async_call_one,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = 0 },
            }),
            1 => return addNode(ast, allocator.n, .{
                .tag = if (comma) .async_call_one_comma else .async_call_one,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = params[0] },
            }),
            else => return addNode(ast, allocator.n, .{
                .tag = if (comma) .async_call_comma else .async_call,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = try addExtra(ast, allocator.x, try listToSpan(ast, allocator.x, params)) },
            }),
        }
    }
    var res = try parsePrimaryTypeExpr(ast, allocator, array_s);
    if (res == 0) return res;
    while (true) {
        const suffix_op = try parseSuffixOp(ast, allocator, array_s, res);
        if (suffix_op != 0) {
            res = suffix_op;
            continue;
        }
        const lparen = eatToken(ast, .l_paren) orelse return res;
        const state_top: usize = array_s.len(allocator.s.*);
        defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
        while (true) {
            if (eatToken(ast, .r_paren)) |_| break;
            const param = try expectExpr(ast, allocator, array_s);
            try array_s.appendOne(allocator.s, param);
            switch (readTagAhead(ast)) {
                .comma => ast.tokens.stream(1),
                .r_paren => {
                    ast.tokens.stream(1);
                    break;
                },
                .colon, .r_brace, .r_bracket => return failExpected(ast, allocator.e, .r_paren),
                // Likely just a missing comma; give error but continue parsing.
                else => try warn(ast, allocator.e, .expected_comma_after_arg),
            }
        }
        const comma = (relativeTagBehind(ast, 2) == .comma);
        const params = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
        res = switch (params.len) {
            0 => try addNode(ast, allocator.n, .{
                .tag = if (comma) .call_one_comma else .call_one,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = 0 },
            }),
            1 => try addNode(ast, allocator.n, .{
                .tag = if (comma) .call_one_comma else .call_one,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = params[0] },
            }),
            else => try addNode(ast, allocator.n, .{
                .tag = if (comma) .call_comma else .call,
                .main_token = lparen,
                .data = .{ .lhs = res, .rhs = try addExtra(ast, allocator.x, try listToSpan(ast, allocator.x, params)) },
            }),
        };
    }
}
/// PrimaryTypeExpr
///     <- BUILTINIDENTIFIER FnCallArguments
///      / CHAR_LITERAL
///      / ContainerDecl
///      / DOT IDENTIFIER
///      / DOT InitList
///      / ErrorSetDecl
///      / FLOAT
///      / FnProto
///      / GroupedExpr
///      / LabeledTypeExpr
///      / IDENTIFIER
///      / IfTypeExpr
///      / INTEGER
///      / KEYWORD_comptime TypeExpr
///      / KEYWORD_error DOT IDENTIFIER
///      / KEYWORD_anyframe
///      / KEYWORD_unreachable
///      / STRINGLITERAL
///      / SwitchExpr
/// ContainerDecl <- (KEYWORD_extern / KEYWORD_packed)? ContainerDeclAuto
/// ContainerDeclAuto <- ContainerDeclType LBRACE ContainerMembers RBRACE
/// InitList
///     <- LBRACE FieldInit (COMMA FieldInit)* COMMA? RBRACE
///      / LBRACE Expr (COMMA Expr)* COMMA? RBRACE
///      / LBRACE RBRACE
/// ErrorSetDecl <- KEYWORD_error LBRACE IdentifierList RBRACE
/// GroupedExpr <- LPAREN Expr RPAREN
/// IfTypeExpr <- IfPrefix TypeExpr (KEYWORD_else Payload? TypeExpr)?
/// LabeledTypeExpr
///     <- BlockLabel Block
///      / BlockLabel? LoopTypeExpr
/// LoopTypeExpr <- KEYWORD_inline? (ForTypeExpr / WhileTypeExpr)
fn parsePrimaryTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    switch (readTagAhead(ast)) {
        .char_literal => return addNode(ast, allocator.n, .{
            .tag = .char_literal,
            .main_token = nextToken(ast),
            .data = .{ .lhs = undefined, .rhs = undefined },
        }),
        .number_literal => return addNode(ast, allocator.n, .{
            .tag = .number_literal,
            .main_token = nextToken(ast),
            .data = .{ .lhs = undefined, .rhs = undefined },
        }),
        .keyword_unreachable => return addNode(ast, allocator.n, .{
            .tag = .unreachable_literal,
            .main_token = nextToken(ast),
            .data = .{ .lhs = undefined, .rhs = undefined },
        }),
        .keyword_anyframe => return addNode(ast, allocator.n, .{
            .tag = .anyframe_literal,
            .main_token = nextToken(ast),
            .data = .{ .lhs = undefined, .rhs = undefined },
        }),
        .string_literal => {
            const main_token = nextToken(ast);
            return addNode(ast, allocator.n, .{
                .tag = .string_literal,
                .main_token = main_token,
                .data = .{ .lhs = undefined, .rhs = undefined },
            });
        },
        .builtin => return parseBuiltinCall(ast, allocator, array_s),
        .keyword_fn => return parseFnProto(ast, allocator, array_s),
        .keyword_if => return parseIf(ast, allocator, array_s, expectTypeExpr),
        .keyword_switch => return expectSwitchExpr(ast, allocator, array_s),
        .keyword_extern,
        .keyword_packed,
        => {
            ast.tokens.stream(1);
            return parseContainerDeclAuto(ast, allocator, array_s);
        },
        .keyword_struct,
        .keyword_opaque,
        .keyword_enum,
        .keyword_union,
        => return parseContainerDeclAuto(ast, allocator, array_s),
        .keyword_comptime => return addNode(ast, allocator.n, .{
            .tag = .@"comptime",
            .main_token = nextToken(ast),
            .data = .{ .lhs = try expectTypeExpr(ast, allocator, array_s), .rhs = undefined },
        }),
        .multiline_string_literal_line => {
            const first_line = nextToken(ast);
            while (readTagAhead(ast) == .multiline_string_literal_line) {
                ast.tokens.stream(1);
            }
            return addNode(ast, allocator.n, .{
                .tag = .multiline_string_literal,
                .main_token = first_line,
                .data = .{ .lhs = first_line, .rhs = tokenIndex(ast) - 1 },
            });
        },
        .identifier => switch (relativeTagAhead(ast, 1)) {
            .colon => switch (relativeTagAhead(ast, 2)) {
                .keyword_inline => {
                    ast.tokens.stream(3);
                    switch (readTagAhead(ast)) {
                        .keyword_for => return parseForTypeExpr(ast, allocator, array_s),
                        .keyword_while => return parseWhileTypeExpr(ast, allocator, array_s),
                        else => return fail(ast, allocator.e, .expected_inlinable),
                    }
                },
                .keyword_for => {
                    ast.tokens.stream(2);
                    return parseForTypeExpr(ast, allocator, array_s);
                },
                .keyword_while => {
                    ast.tokens.stream(2);
                    return parseWhileTypeExpr(ast, allocator, array_s);
                },
                .l_brace => {
                    ast.tokens.stream(2);
                    return parseBlock(ast, allocator, array_s);
                },
                else => return addNode(ast, allocator.n, .{
                    .tag = .identifier,
                    .main_token = nextToken(ast),
                    .data = .{ .lhs = undefined, .rhs = undefined },
                }),
            },
            else => return addNode(ast, allocator.n, .{
                .tag = .identifier,
                .main_token = nextToken(ast),
                .data = .{ .lhs = undefined, .rhs = undefined },
            }),
        },
        .keyword_inline => {
            ast.tokens.stream(1);
            switch (readTagAhead(ast)) {
                .keyword_for => return parseForTypeExpr(ast, allocator, array_s),
                .keyword_while => return parseWhileTypeExpr(ast, allocator, array_s),
                else => return fail(ast, allocator.e, .expected_inlinable),
            }
        },
        .keyword_for => return parseForTypeExpr(ast, allocator, array_s),
        .keyword_while => return parseWhileTypeExpr(ast, allocator, array_s),
        .period => switch (relativeTagAhead(ast, 1)) {
            .identifier => return addNode(ast, allocator.n, .{
                .tag = .enum_literal,
                .data = .{
                    .lhs = nextToken(ast), // dot
                    .rhs = undefined,
                },
                .main_token = nextToken(ast), // identifier
            }),
            .l_brace => {
                const lbrace = tokenIndex(ast) + 1;
                // tokenIndex(ast) = lbrace + 1;
                ast.tokens.stream(2);
                // If there are 0, 1, or 2 items, we can use ArrayInitDotTwo/StructInitDotTwo;
                // otherwise we use the full ArrayInitDot/StructInitDot.
                const state_top: usize = array_s.len(allocator.s.*);
                defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
                const field_init = try parseFieldInit(ast, allocator, array_s);
                if (field_init != 0) {
                    try array_s.appendOne(allocator.s, field_init);
                    while (true) {
                        switch (readTagAhead(ast)) {
                            .comma => ast.tokens.stream(1),
                            .r_brace => {
                                ast.tokens.stream(1);
                                break;
                            },
                            .colon, .r_paren, .r_bracket => return failExpected(ast, allocator.e, .r_brace),
                            // Likely just a missing comma; give error but continue parsing.
                            else => try warn(ast, allocator.e, .expected_comma_after_initializer),
                        }
                        if (eatToken(ast, .r_brace)) |_| break;
                        const next = try expectFieldInit(ast, allocator, array_s);
                        try array_s.appendOne(allocator.s, next);
                    }
                    const comma = (relativeTagBehind(ast, 2) == .comma);
                    const inits = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
                    switch (inits.len) {
                        0 => unreachable,
                        1 => return addNode(ast, allocator.n, .{
                            .tag = if (comma) .struct_init_dot_two_comma else .struct_init_dot_two,
                            .main_token = lbrace,
                            .data = .{ .lhs = inits[0], .rhs = 0 },
                        }),
                        2 => return addNode(ast, allocator.n, .{
                            .tag = if (comma) .struct_init_dot_two_comma else .struct_init_dot_two,
                            .main_token = lbrace,
                            .data = .{ .lhs = inits[0], .rhs = inits[1] },
                        }),
                        else => {
                            const span = try listToSpan(ast, allocator.x, inits);
                            return addNode(ast, allocator.n, .{
                                .tag = if (comma) .struct_init_dot_comma else .struct_init_dot,
                                .main_token = lbrace,
                                .data = .{ .lhs = span.start, .rhs = span.end },
                            });
                        },
                    }
                }
                while (true) {
                    if (eatToken(ast, .r_brace)) |_| break;
                    const elem_init = try expectExpr(ast, allocator, array_s);
                    try array_s.appendOne(allocator.s, elem_init);
                    switch (readTagAhead(ast)) {
                        .comma => ast.tokens.stream(1),
                        .r_brace => {
                            ast.tokens.stream(1);
                            break;
                        },
                        .colon, .r_paren, .r_bracket => return failExpected(ast, allocator.e, .r_brace),
                        // Likely just a missing comma; give error but continue parsing.
                        else => try warn(ast, allocator.e, .expected_comma_after_initializer),
                    }
                }
                const comma = (relativeTagBehind(ast, 2) == .comma);
                const inits = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
                switch (inits.len) {
                    0 => return addNode(ast, allocator.n, .{
                        .tag = .struct_init_dot_two,
                        .main_token = lbrace,
                        .data = .{ .lhs = 0, .rhs = 0 },
                    }),
                    1 => return addNode(ast, allocator.n, .{
                        .tag = if (comma) .array_init_dot_two_comma else .array_init_dot_two,
                        .main_token = lbrace,
                        .data = .{ .lhs = inits[0], .rhs = 0 },
                    }),
                    2 => return addNode(ast, allocator.n, .{
                        .tag = if (comma) .array_init_dot_two_comma else .array_init_dot_two,
                        .main_token = lbrace,
                        .data = .{ .lhs = inits[0], .rhs = inits[1] },
                    }),
                    else => {
                        const span = try listToSpan(ast, allocator.x, inits);
                        return addNode(ast, allocator.n, .{
                            .tag = if (comma) .array_init_dot_comma else .array_init_dot,
                            .main_token = lbrace,
                            .data = .{ .lhs = span.start, .rhs = span.end },
                        });
                    },
                }
            },
            else => return null_node,
        },
        .keyword_error => switch (relativeTagAhead(ast, 1)) {
            .l_brace => {
                const error_token = tokenIndex(ast);
                ast.tokens.stream(2);
                while (true) {
                    if (eatToken(ast, .r_brace)) |_| break;
                    _ = try eatDocComments(ast, allocator.e);
                    _ = try expectToken(ast, allocator.e, .identifier);
                    switch (readTagAhead(ast)) {
                        .comma => ast.tokens.stream(1),
                        .r_brace => {
                            ast.tokens.stream(1);
                            break;
                        },
                        .colon, .r_paren, .r_bracket => return failExpected(ast, allocator.e, .r_brace),
                        // Likely just a missing comma; give error but continue parsing.
                        else => try warn(ast, allocator.e, .expected_comma_after_field),
                    }
                }
                return addNode(ast, allocator.n, .{
                    .tag = .error_set_decl,
                    .main_token = error_token,
                    .data = .{
                        .lhs = undefined,
                        .rhs = tokenIndex(ast) - 1, // rbrace
                    },
                });
            },
            else => {
                const main_token = nextToken(ast);
                const period = eatToken(ast, .period);
                if (period == null) try warnExpected(ast, allocator.e, .period);
                const identifier = eatToken(ast, .identifier);
                if (identifier == null) try warnExpected(ast, allocator.e, .identifier);
                return addNode(ast, allocator.n, .{
                    .tag = .error_value,
                    .main_token = main_token,
                    .data = .{ .lhs = period orelse 0, .rhs = identifier orelse 0 },
                });
            },
        },
        .l_paren => return addNode(ast, allocator.n, .{
            .tag = .grouped_expression,
            .main_token = nextToken(ast),
            .data = .{ .lhs = try expectExpr(ast, allocator, array_s), .rhs = try expectToken(ast, allocator.e, .r_paren) },
        }),
        else => return null_node,
    }
}
fn expectPrimaryTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const node = try parsePrimaryTypeExpr(ast, allocator, array_s);
    if (node == 0) {
        return fail(ast, allocator.e, .expected_primary_type_expr);
    }
    return node;
}
/// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
/// ForTypeExpr <- ForPrefix TypeExpr (KEYWORD_else TypeExpr)?
fn parseForTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const for_token = eatToken(ast, .keyword_for) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const array_expr = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    const found_payload = try parsePtrIndexPayload(ast, allocator.e);
    if (found_payload == 0) try warn(ast, allocator.e, .expected_loop_payload);
    const then_expr = try expectTypeExpr(ast, allocator, array_s);
    _ = eatToken(ast, .keyword_else) orelse {
        return addNode(ast, allocator.n, .{
            .tag = .for_simple,
            .main_token = for_token,
            .data = .{ .lhs = array_expr, .rhs = then_expr },
        });
    };
    const else_expr = try expectTypeExpr(ast, allocator, array_s);
    return addNode(ast, allocator.n, .{
        .tag = .@"for",
        .main_token = for_token,
        .data = .{
            .lhs = array_expr,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.If{
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
/// WhileTypeExpr <- WhilePrefix TypeExpr (KEYWORD_else Payload? TypeExpr)?
fn parseWhileTypeExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const while_token = eatToken(ast, .keyword_while) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const condition = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try parsePtrPayload(ast, allocator.e);
    const cont_expr = try parseWhileContinueExpr(ast, allocator, array_s);
    const then_expr = try expectTypeExpr(ast, allocator, array_s);
    _ = eatToken(ast, .keyword_else) orelse {
        if (cont_expr == 0) {
            return addNode(ast, allocator.n, .{
                .tag = .while_simple,
                .main_token = while_token,
                .data = .{ .lhs = condition, .rhs = then_expr },
            });
        } else {
            return addNode(ast, allocator.n, .{
                .tag = .while_cont,
                .main_token = while_token,
                .data = .{
                    .lhs = condition,
                    .rhs = try addExtra(ast, allocator.x, zig.AstNode.WhileCont{
                        .cont_expr = cont_expr,
                        .then_expr = then_expr,
                    }),
                },
            });
        }
    };
    _ = try parsePayload(ast, allocator.e);
    const else_expr = try expectTypeExpr(ast, allocator, array_s);
    return addNode(ast, allocator.n, .{
        .tag = .@"while",
        .main_token = while_token,
        .data = .{
            .lhs = condition,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.While{
                .cont_expr = cont_expr,
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
/// SwitchExpr <- KEYWORD_switch LPAREN Expr RPAREN LBRACE SwitchProngList RBRACE
fn expectSwitchExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const switch_token = assertToken(ast, .keyword_switch);
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr_node = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try expectToken(ast, allocator.e, .l_brace);
    const cases = try parseSwitchProngList(ast, allocator, array_s);
    const trailing_comma = relativeTagBehind(ast, 1) == .comma;
    _ = try expectToken(ast, allocator.e, .r_brace);
    return addNode(ast, allocator.n, .{
        .tag = if (trailing_comma) .switch_comma else .@"switch",
        .main_token = switch_token,
        .data = .{
            .lhs = expr_node,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.SubRange{
                .start = cases.start,
                .end = cases.end,
            }),
        },
    });
}
/// AsmExpr <- KEYWORD_asm KEYWORD_volatile? LPAREN Expr AsmOutput? RPAREN
/// AsmOutput <- COLON AsmOutputList AsmInput?
/// AsmInput <- COLON AsmInputList AsmClobbers?
/// AsmClobbers <- COLON StringList
/// StringList <- (STRINGLITERAL COMMA)* STRINGLITERAL?
/// AsmOutputList <- (AsmOutputItem COMMA)* AsmOutputItem?
/// AsmInputList <- (AsmInputItem COMMA)* AsmInputItem?
fn expectAsmExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const asm_token = assertToken(ast, .keyword_asm);
    _ = eatToken(ast, .keyword_volatile);
    _ = try expectToken(ast, allocator.e, .l_paren);
    const template = try expectExpr(ast, allocator, array_s);
    if (eatToken(ast, .r_paren)) |rparen| {
        return addNode(ast, allocator.n, .{
            .tag = .asm_simple,
            .main_token = asm_token,
            .data = .{ .lhs = template, .rhs = rparen },
        });
    }
    _ = try expectToken(ast, allocator.e, .colon);
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    while (true) {
        const output_item = try parseAsmOutputItem(ast, allocator, array_s);
        if (output_item == 0) break;
        try array_s.appendOne(allocator.s, output_item);
        switch (readTagAhead(ast)) {
            .comma => ast.tokens.stream(1),
            // All possible delimiters.
            .colon, .r_paren, .r_brace, .r_bracket => break,
            // Likely just a missing comma; give error but continue parsing.
            else => try warnExpected(ast, allocator.e, .comma),
        }
    }
    if (eatToken(ast, .colon)) |_| {
        while (true) {
            const input_item = try parseAsmInputItem(ast, allocator, array_s);
            if (input_item == 0) break;
            try array_s.appendOne(allocator.s, input_item);
            switch (readTagAhead(ast)) {
                .comma => ast.tokens.stream(1),
                // All possible delimiters.
                .colon, .r_paren, .r_brace, .r_bracket => break,
                // Likely just a missing comma; give error but continue parsing.
                else => try warnExpected(ast, allocator.e, .comma),
            }
        }
        if (eatToken(ast, .colon)) |_| {
            while (eatToken(ast, .string_literal)) |_| {
                switch (readTagAhead(ast)) {
                    .comma => ast.tokens.stream(1),
                    .colon, .r_paren, .r_brace, .r_bracket => break,
                    // Likely just a missing comma; give error but continue parsing.
                    else => try warnExpected(ast, allocator.e, .comma),
                }
            }
        }
    }
    const rparen = try expectToken(ast, allocator.e, .r_paren);
    // XXX: Maybe trouble:
    const span = try listToSpan(ast, allocator.x, array_s.readManyAt(allocator.s.*, state_top));
    return addNode(ast, allocator.n, .{
        .tag = .@"asm",
        .main_token = asm_token,
        .data = .{
            .lhs = template,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.Asm{
                .items_start = span.start,
                .items_end = span.end,
                .rparen = rparen,
            }),
        },
    });
}
/// AsmOutputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN (MINUSRARROW TypeExpr / IDENTIFIER) RPAREN
fn parseAsmOutputItem(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .l_bracket) orelse return null_node;
    const identifier = try expectToken(ast, allocator.e, .identifier);
    _ = try expectToken(ast, allocator.e, .r_bracket);
    _ = try expectToken(ast, allocator.e, .string_literal);
    _ = try expectToken(ast, allocator.e, .l_paren);
    const type_expr: zig.Index = blk: {
        if (eatToken(ast, .arrow)) |_| {
            break :blk try expectTypeExpr(ast, allocator, array_s);
        } else {
            _ = try expectToken(ast, allocator.e, .identifier);
            break :blk null_node;
        }
    };
    const rparen = try expectToken(ast, allocator.e, .r_paren);
    return addNode(ast, allocator.n, .{
        .tag = .asm_output,
        .main_token = identifier,
        .data = .{ .lhs = type_expr, .rhs = rparen },
    });
}
/// AsmInputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN Expr RPAREN
fn parseAsmInputItem(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .l_bracket) orelse return null_node;
    const identifier = try expectToken(ast, allocator.e, .identifier);
    _ = try expectToken(ast, allocator.e, .r_bracket);
    _ = try expectToken(ast, allocator.e, .string_literal);
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr = try expectExpr(ast, allocator, array_s);
    const rparen = try expectToken(ast, allocator.e, .r_paren);
    return addNode(ast, allocator.n, .{
        .tag = .asm_input,
        .main_token = identifier,
        .data = .{ .lhs = expr, .rhs = rparen },
    });
}
/// BreakLabel <- COLON IDENTIFIER
fn parseBreakLabel(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE) Error!zig.Index {
    _ = eatToken(ast, .colon) orelse return @as(zig.Index, 0);
    return expectToken(ast, allocator_e, .identifier);
}
/// BlockLabel <- IDENTIFIER COLON
fn parseBlockLabel(ast: *abstract.ProtoSyntaxTree) zig.Index {
    if (readTagAhead(ast) == .identifier and
        relativeTagAhead(ast, 1) == .colon)
    {
        const identifier = tokenIndex(ast);
        ast.tokens.stream(2);
        return identifier;
    }
    return null_node;
}
/// FieldInit <- DOT IDENTIFIER EQUAL Expr
fn parseFieldInit(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    if (relativeTagAhead(ast, 0) == .period and
        relativeTagAhead(ast, 1) == .identifier and
        relativeTagAhead(ast, 2) == .equal)
    {
        ast.tokens.stream(3);
        return expectExpr(ast, allocator, array_s);
    } else {
        return null_node;
    }
}
fn expectFieldInit(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    if (readTagAhead(ast) != .period or
        relativeTagAhead(ast, 1) != .identifier or
        relativeTagAhead(ast, 2) != .equal)
        return fail(ast, allocator.e, .expected_initializer);
    ast.tokens.stream(3);
    return expectExpr(ast, allocator, array_s);
}
/// WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN
fn parseWhileContinueExpr(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .colon) orelse {
        if (readTagAhead(ast) == .l_paren and
            tokensOnSameLine(ast, tokenIndex(ast) - 1, tokenIndex(ast)))
            return fail(ast, allocator.e, .expected_continue_expr);
        return null_node;
    };
    _ = try expectToken(ast, allocator.e, .l_paren);
    const node = try parseAssignExpr(ast, allocator, array_s);
    if (node == 0) return fail(ast, allocator.e, .expected_expr_or_assignment);
    _ = try expectToken(ast, allocator.e, .r_paren);
    return node;
}
/// LinkSection <- KEYWORD_linksection LPAREN Expr RPAREN
fn parseLinkSection(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .keyword_linksection) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr_node = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    return expr_node;
}
/// CallConv <- KEYWORD_callconv LPAREN Expr RPAREN
fn parseCallconv(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .keyword_callconv) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr_node = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    return expr_node;
}
/// AddrSpace <- KEYWORD_addrspace LPAREN Expr RPAREN
fn parseAddrSpace(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .keyword_addrspace) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr_node = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    return expr_node;
}
fn relativeTagAhead(ast: *abstract.ProtoSyntaxTree, offset: u64) zig.Token.Tag {
    return ast.tokens.readOneAt(tokenIndex(ast) +% offset).tag;
}
fn relativeTagBehind(ast: *abstract.ProtoSyntaxTree, offset: u64) zig.Token.Tag {
    return ast.tokens.readOneAt(tokenIndex(ast) -% offset).tag;
}
fn relativeStartAhead(ast: *abstract.ProtoSyntaxTree, offset: u64) zig.Token.Tag {
    return ast.tokens.readOneAt(tokenIndex(ast) +% offset).start;
}
fn relativeStartBehind(ast: *abstract.ProtoSyntaxTree, offset: u64) zig.Token.Tag {
    return ast.tokens.readOneAt(tokenIndex(ast) -% offset).start;
}
/// ParamDecl
///     <- (KEYWORD_noalias / KEYWORD_comptime)? (IDENTIFIER COLON)? ParamType
///     / DOT3
/// ParamType
///     <- Keyword_anytype
///      / TypeExpr
/// This function can return null nodes and then still return nodes afterwards,
/// such as in the case of anytype and `...`. Caller must look for rparen to find
/// out when there are no more param decls left.
fn expectParamDecl(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = try eatDocComments(ast, allocator.e);
    switch (readTagAhead(ast)) {
        .keyword_noalias, .keyword_comptime => ast.tokens.stream(1),
        .ellipsis3 => {
            ast.tokens.stream(1);
            return null_node;
        },
        else => {},
    }
    if (readTagAhead(ast) == .identifier and
        relativeTagAhead(ast, 1) == .colon)
    {
        ast.tokens.stream(2);
    }
    switch (readTagAhead(ast)) {
        .keyword_anytype => {
            ast.tokens.stream(1);
            return null_node;
        },
        else => return expectTypeExpr(ast, allocator, array_s),
    }
}
/// Payload <- PIPE IDENTIFIER PIPE
fn parsePayload(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE) Error!zig.Index {
    _ = eatToken(ast, .pipe) orelse return @as(zig.Index, 0);
    const identifier = try expectToken(ast, allocator_e, .identifier);
    _ = try expectToken(ast, allocator_e, .pipe);
    return identifier;
}
/// PtrPayload <- PIPE ASTERISK? IDENTIFIER PIPE
fn parsePtrPayload(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE) Error!zig.Index {
    _ = eatToken(ast, .pipe) orelse return @as(zig.Index, 0);
    _ = eatToken(ast, .asterisk);
    const identifier = try expectToken(ast, allocator_e, .identifier);
    _ = try expectToken(ast, allocator_e, .pipe);
    return identifier;
}
/// PtrIndexPayload <- PIPE ASTERISK? IDENTIFIER (COMMA IDENTIFIER)? PIPE
/// Returns the first identifier token, if any.
fn parsePtrIndexPayload(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE) Error!zig.Index {
    _ = eatToken(ast, .pipe) orelse return @as(zig.Index, 0);
    _ = eatToken(ast, .asterisk);
    const identifier = try expectToken(ast, allocator_e, .identifier);
    if (eatToken(ast, .comma) != null) {
        _ = try expectToken(ast, allocator_e, .identifier);
    }
    _ = try expectToken(ast, allocator_e, .pipe);
    return identifier;
}
/// SwitchProng <- KEYWORD_inline? SwitchCase EQUALRARROW PtrIndexPayload? AssignExpr
/// SwitchCase
///     <- SwitchItem (COMMA SwitchItem)* COMMA?
///      / KEYWORD_else
fn parseSwitchProng(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    const is_inline = eatToken(ast, .keyword_inline) != null;
    if (eatToken(ast, .keyword_else) == null) {
        while (true) {
            const item = try parseSwitchItem(ast, allocator, array_s);
            if (item == 0) break;
            try array_s.appendOne(allocator.s, item);
            if (eatToken(ast, .comma) == null) break;
        }
        if (state_top == array_s.len(allocator.s.*)) {
            if (is_inline) ast.tokens.unstream(1);
            return null_node;
        }
    }
    const arrow_token = try expectToken(ast, allocator.e, .equal_angle_bracket_right);
    _ = try parsePtrIndexPayload(ast, allocator.e);
    const items = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
    switch (items.len) {
        0 => return addNode(ast, allocator.n, .{
            .tag = if (is_inline) .switch_case_inline_one else .switch_case_one,
            .main_token = arrow_token,
            .data = .{ .lhs = 0, .rhs = try expectAssignExpr(ast, allocator, array_s) },
        }),
        1 => return addNode(ast, allocator.n, .{
            .tag = if (is_inline) .switch_case_inline_one else .switch_case_one,
            .main_token = arrow_token,
            .data = .{ .lhs = items[0], .rhs = try expectAssignExpr(ast, allocator, array_s) },
        }),
        else => return addNode(ast, allocator.n, .{
            .tag = if (is_inline) .switch_case_inline else .switch_case,
            .main_token = arrow_token,
            .data = .{ .lhs = try addExtra(ast, allocator.x, try listToSpan(ast, allocator.x, items)), .rhs = try expectAssignExpr(ast, allocator, array_s) },
        }),
    }
}
/// SwitchItem <- Expr (DOT3 Expr)?
fn parseSwitchItem(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const expr = try parseExpr(ast, allocator, array_s);
    if (expr == 0) return null_node;
    if (eatToken(ast, .ellipsis3)) |token| {
        return addNode(ast, allocator.n, .{
            .tag = .switch_range,
            .main_token = token,
            .data = .{ .lhs = expr, .rhs = try expectExpr(ast, allocator, array_s) },
        });
    }
    return expr;
}
const PtrModifiers = struct {
    align_node: zig.Index,
    addrspace_node: zig.Index,
    bit_range_start: zig.Index,
    bit_range_end: zig.Index,
};
fn parsePtrModifiers(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) !PtrModifiers {
    var result: PtrModifiers = .{
        .align_node = 0,
        .addrspace_node = 0,
        .bit_range_start = 0,
        .bit_range_end = 0,
    };
    var saw_const = false;
    var saw_volatile = false;
    var saw_allowzero = false;
    var saw_addrspace = false;
    while (true) {
        switch (readTagAhead(ast)) {
            .keyword_align => {
                if (result.align_node != 0) {
                    try warn(ast, allocator.e, .extra_align_qualifier);
                }
                ast.tokens.stream(1);
                _ = try expectToken(ast, allocator.e, .l_paren);
                result.align_node = try expectExpr(ast, allocator, array_s);
                if (eatToken(ast, .colon)) |_| {
                    result.bit_range_start = try expectExpr(ast, allocator, array_s);
                    _ = try expectToken(ast, allocator.e, .colon);
                    result.bit_range_end = try expectExpr(ast, allocator, array_s);
                }
                _ = try expectToken(ast, allocator.e, .r_paren);
            },
            .keyword_const => {
                if (saw_const) {
                    try warn(ast, allocator.e, .extra_const_qualifier);
                }
                ast.tokens.stream(1);
                saw_const = true;
            },
            .keyword_volatile => {
                if (saw_volatile) {
                    try warn(ast, allocator.e, .extra_volatile_qualifier);
                }
                ast.tokens.stream(1);
                saw_volatile = true;
            },
            .keyword_allowzero => {
                if (saw_allowzero) {
                    try warn(ast, allocator.e, .extra_allowzero_qualifier);
                }
                ast.tokens.stream(1);
                saw_allowzero = true;
            },
            .keyword_addrspace => {
                if (saw_addrspace) {
                    try warn(ast, allocator.e, .extra_addrspace_qualifier);
                }
                result.addrspace_node = try parseAddrSpace(ast, allocator, array_s);
            },
            else => return result,
        }
    }
}
/// SuffixOp
///     <- LBRACKET Expr (DOT2 (Expr? (COLON Expr)?)?)? RBRACKET
///      / DOT IDENTIFIER
///      / DOTASTERISK
///      / DOTQUESTIONMARK
fn parseSuffixOp(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
    lhs: zig.Index,
) Error!zig.Index {
    switch (readTagAhead(ast)) {
        .l_bracket => {
            const lbracket = nextToken(ast);
            const index_expr = try expectExpr(ast, allocator, array_s);
            if (eatToken(ast, .ellipsis2)) |_| {
                const end_expr = try parseExpr(ast, allocator, array_s);
                if (eatToken(ast, .colon)) |_| {
                    const sentinel = try expectExpr(ast, allocator, array_s);
                    _ = try expectToken(ast, allocator.e, .r_bracket);
                    return addNode(ast, allocator.n, .{
                        .tag = .slice_sentinel,
                        .main_token = lbracket,
                        .data = .{
                            .lhs = lhs,
                            .rhs = try addExtra(ast, allocator.x, zig.AstNode.SliceSentinel{
                                .start = index_expr,
                                .end = end_expr,
                                .sentinel = sentinel,
                            }),
                        },
                    });
                }
                _ = try expectToken(ast, allocator.e, .r_bracket);
                if (end_expr == 0) {
                    return addNode(ast, allocator.n, .{
                        .tag = .slice_open,
                        .main_token = lbracket,
                        .data = .{ .lhs = lhs, .rhs = index_expr },
                    });
                }
                return addNode(ast, allocator.n, .{
                    .tag = .slice,
                    .main_token = lbracket,
                    .data = .{
                        .lhs = lhs,
                        .rhs = try addExtra(ast, allocator.x, zig.AstNode.Slice{
                            .start = index_expr,
                            .end = end_expr,
                        }),
                    },
                });
            }
            _ = try expectToken(ast, allocator.e, .r_bracket);
            return addNode(ast, allocator.n, .{
                .tag = .array_access,
                .main_token = lbracket,
                .data = .{ .lhs = lhs, .rhs = index_expr },
            });
        },
        .period_asterisk => return addNode(ast, allocator.n, .{
            .tag = .deref,
            .main_token = nextToken(ast),
            .data = .{ .lhs = lhs, .rhs = undefined },
        }),
        .invalid_periodasterisks => {
            try warn(ast, allocator.e, .asterisk_after_ptr_deref);
            return addNode(ast, allocator.n, .{
                .tag = .deref,
                .main_token = nextToken(ast),
                .data = .{ .lhs = lhs, .rhs = undefined },
            });
        },
        .period => switch (relativeTagAhead(ast, 1)) {
            .identifier => return addNode(ast, allocator.n, .{
                .tag = .field_access,
                .main_token = nextToken(ast),
                .data = .{ .lhs = lhs, .rhs = nextToken(ast) },
            }),
            .question_mark => return addNode(ast, allocator.n, .{
                .tag = .unwrap_optional,
                .main_token = nextToken(ast),
                .data = .{ .lhs = lhs, .rhs = nextToken(ast) },
            }),
            .l_brace => {
                // this a misplaced `.{`, handle the error somewhere else
                return null_node;
            },
            else => {
                ast.tokens.stream(1);
                try warn(ast, allocator.e, .expected_suffix_op);
                return null_node;
            },
        },
        else => return null_node,
    }
}
/// Caller must have already verified the first token.
/// ContainerDeclAuto <- ContainerDeclType LBRACE container_doc_comment? ContainerMembers RBRACE
///
/// ContainerDeclType
///     <- KEYWORD_struct (LPAREN Expr RPAREN)?
///      / KEYWORD_opaque
///      / KEYWORD_enum (LPAREN Expr RPAREN)?
///      / KEYWORD_union (LPAREN (KEYWORD_enum (LPAREN Expr RPAREN)? / Expr) RPAREN)?
fn parseContainerDeclAuto(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const main_token = nextToken(ast);
    const arg_expr = switch (readTagAt(ast, main_token)) {
        .keyword_opaque => null_node,
        .keyword_struct, .keyword_enum => blk: {
            if (eatToken(ast, .l_paren)) |_| {
                const expr = try expectExpr(ast, allocator, array_s);
                _ = try expectToken(ast, allocator.e, .r_paren);
                break :blk expr;
            } else {
                break :blk null_node;
            }
        },
        .keyword_union => blk: {
            if (eatToken(ast, .l_paren)) |_| {
                if (eatToken(ast, .keyword_enum)) |_| {
                    if (eatToken(ast, .l_paren)) |_| {
                        const enum_tag_expr = try expectExpr(ast, allocator, array_s);
                        _ = try expectToken(ast, allocator.e, .r_paren);
                        _ = try expectToken(ast, allocator.e, .r_paren);
                        _ = try expectToken(ast, allocator.e, .l_brace);
                        const members = try parseContainerMembers(ast, allocator, array_s);
                        const members_span = try members.toSpan(ast, allocator.x);
                        _ = try expectToken(ast, allocator.e, .r_brace);
                        return addNode(ast, allocator.n, .{
                            .tag = switch (members.trailing) {
                                true => .tagged_union_enum_tag_trailing,
                                false => .tagged_union_enum_tag,
                            },
                            .main_token = main_token,
                            .data = .{ .lhs = enum_tag_expr, .rhs = try addExtra(ast, allocator.x, members_span) },
                        });
                    } else {
                        _ = try expectToken(ast, allocator.e, .r_paren);
                        _ = try expectToken(ast, allocator.e, .l_brace);
                        const members = try parseContainerMembers(ast, allocator, array_s);
                        _ = try expectToken(ast, allocator.e, .r_brace);
                        if (members.len <= 2) {
                            return addNode(ast, allocator.n, .{
                                .tag = switch (members.trailing) {
                                    true => .tagged_union_two_trailing,
                                    false => .tagged_union_two,
                                },
                                .main_token = main_token,
                                .data = .{ .lhs = members.lhs, .rhs = members.rhs },
                            });
                        } else {
                            const span = try members.toSpan(ast, allocator.x);
                            return addNode(ast, allocator.n, .{
                                .tag = switch (members.trailing) {
                                    true => .tagged_union_trailing,
                                    false => .tagged_union,
                                },
                                .main_token = main_token,
                                .data = .{ .lhs = span.start, .rhs = span.end },
                            });
                        }
                    }
                } else {
                    const expr = try expectExpr(ast, allocator, array_s);
                    _ = try expectToken(ast, allocator.e, .r_paren);
                    break :blk expr;
                }
            } else {
                break :blk null_node;
            }
        },
        else => {
            ast.tokens.unstream(1);
            return fail(ast, allocator.e, .expected_container);
        },
    };
    _ = try expectToken(ast, allocator.e, .l_brace);
    const members = try parseContainerMembers(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_brace);
    if (arg_expr == 0) {
        if (members.len <= 2) {
            return addNode(ast, allocator.n, .{
                .tag = switch (members.trailing) {
                    true => .container_decl_two_trailing,
                    false => .container_decl_two,
                },
                .main_token = main_token,
                .data = .{ .lhs = members.lhs, .rhs = members.rhs },
            });
        } else {
            const span = try members.toSpan(ast, allocator.x);
            return addNode(ast, allocator.n, .{
                .tag = switch (members.trailing) {
                    true => .container_decl_trailing,
                    false => .container_decl,
                },
                .main_token = main_token,
                .data = .{ .lhs = span.start, .rhs = span.end },
            });
        }
    } else {
        const span = try members.toSpan(ast, allocator.x);
        return addNode(ast, allocator.n, .{
            .tag = switch (members.trailing) {
                true => .container_decl_arg_trailing,
                false => .container_decl_arg,
            },
            .main_token = main_token,
            .data = .{
                .lhs = arg_expr,
                .rhs = try addExtra(ast, allocator.x, zig.AstNode.SubRange{
                    .start = span.start,
                    .end = span.end,
                }),
            },
        });
    }
}
/// Give a helpful error message for those transitioning from
/// C's 'struct Foo {};' to Zig's 'const Foo = struct {};'.
fn parseCStyleContainer(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) !bool {
    const main_token = tokenIndex(ast);
    switch (readTagAhead(ast)) {
        .keyword_enum, .keyword_union, .keyword_struct => {},
        else => return false,
    }
    const identifier = tokenIndex(ast) + 1;
    if (readTagAt(ast, identifier) != .identifier) return false;
    ast.tokens.stream(2);
    try warnMsg(ast, allocator.e, .{
        .tag = .c_style_container,
        .token = identifier,
        .extra = .{ .expected_tag = readTagAt(ast, main_token) },
    });
    try warnMsg(ast, allocator.e, .{
        .tag = .zig_style_container,
        .is_note = true,
        .token = identifier,
        .extra = .{ .expected_tag = readTagAt(ast, main_token) },
    });
    _ = try expectToken(ast, allocator.e, .l_brace);
    _ = try parseContainerMembers(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_brace);
    try expectSemicolon(ast, allocator.e, .expected_semi_after_decl, true);
    return true;
}
/// Holds temporary data until we are ready to construct the full ContainerDecl AST node.
/// ByteAlign <- KEYWORD_align LPAREN Expr RPAREN
fn parseByteAlign(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    _ = eatToken(ast, .keyword_align) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const expr = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    return expr;
}
/// SwitchProngList <- (SwitchProng COMMA)* SwitchProng?
fn parseSwitchProngList(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) !zig.AstNode.SubRange {
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    while (true) {
        const item = try parseSwitchProng(ast, allocator, array_s);
        if (item == 0) break;
        try array_s.appendOne(allocator.s, item);
        switch (readTagAhead(ast)) {
            .comma => ast.tokens.stream(1),
            // All possible delimiters.
            .colon, .r_paren, .r_brace, .r_bracket => break,
            // Likely just a missing comma; give error but continue parsing.
            else => try warn(ast, allocator.e, .expected_comma_after_switch_prong),
        }
    }
    return listToSpan(ast, allocator.x, array_s.readManyAt(allocator.s.*, state_top));
}
/// ParamDeclList <- (ParamDecl COMMA)* ParamDecl?
fn parseParamDeclList(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) !zig.AstNode.SmallSpan {
    _ = try expectToken(ast, allocator.e, .l_paren);
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    var varargs: union(enum) { none, seen, nonfinal: zig.Index } = .none;
    while (true) {
        if (eatToken(ast, .r_paren)) |_| break;
        if (varargs == .seen) varargs = .{ .nonfinal = tokenIndex(ast) };
        const param = try expectParamDecl(ast, allocator, array_s);
        if (param != 0) {
            try array_s.appendOne(allocator.s, param);
        } else if (relativeTagBehind(ast, 1) == .ellipsis3) {
            if (varargs == .none) varargs = .seen;
        }
        switch (readTagAhead(ast)) {
            .comma => ast.tokens.stream(1),
            .r_paren => {
                ast.tokens.stream(1);
                break;
            },
            .colon, .r_brace, .r_bracket => return failExpected(ast, allocator.e, .r_paren),
            // Likely just a missing comma; give error but continue parsing.
            else => try warn(ast, allocator.e, .expected_comma_after_param),
        }
    }
    if (varargs == .nonfinal) {
        try warnMsg(ast, allocator.e, .{ .tag = .varargs_nonfinal, .token = varargs.nonfinal });
    }
    const params = array_s.readManyAt(allocator.s.*, state_top); // XXX: Maybe trouble
    return switch (params.len) {
        0 => zig.AstNode.SmallSpan{ .zero_or_one = 0 },
        1 => zig.AstNode.SmallSpan{ .zero_or_one = params[0] },
        else => zig.AstNode.SmallSpan{ .multi = try listToSpan(ast, allocator.x, params) },
    };
}
/// FnCallArguments <- LPAREN ExprList RPAREN
/// ExprList <- (Expr COMMA)* Expr?
fn parseBuiltinCall(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
) Error!zig.Index {
    const builtin_token = assertToken(ast, .builtin);
    if (readTagAt(ast, nextToken(ast)) != .l_paren) {
        ast.tokens.unstream(1);
        try warn(ast, allocator.e, .expected_param_list);
        // Pretend this was an identifier so we can continue parsing.
        return addNode(ast, allocator.n, .{ .tag = .identifier, .main_token = builtin_token, .data = .{ .lhs = undefined, .rhs = undefined } });
    }
    const state_top: usize = array_s.len(allocator.s.*);
    defer array_s.undefine(array_s.len(allocator.s.*) - state_top);
    while (true) {
        if (eatToken(ast, .r_paren)) |_| break;
        const param = try expectExpr(ast, allocator, array_s);
        try array_s.appendOne(allocator.s, param);
        switch (readTagAhead(ast)) {
            .comma => ast.tokens.stream(1),
            .r_paren => {
                ast.tokens.stream(1);
                break;
            },
            // Likely just a missing comma; give error but continue parsing.
            else => try warn(ast, allocator.e, .expected_comma_after_arg),
        }
    }
    const comma = (relativeTagBehind(ast, 2) == .comma);
    // XXX: Maybe trouble
    const params = array_s.readManyAt(allocator.s.*, state_top);
    switch (params.len) {
        0 => return addNode(ast, allocator.n, .{ .tag = .builtin_call_two, .main_token = builtin_token, .data = .{ .lhs = 0, .rhs = 0 } }),
        1 => return addNode(ast, allocator.n, .{ .tag = if (comma) .builtin_call_two_comma else .builtin_call_two, .main_token = builtin_token, .data = .{ .lhs = params[0], .rhs = 0 } }),
        2 => return addNode(ast, allocator.n, .{ .tag = if (comma) .builtin_call_two_comma else .builtin_call_two, .main_token = builtin_token, .data = .{ .lhs = params[0], .rhs = params[1] } }),
        else => {
            const span = try listToSpan(ast, allocator.x, params);
            return addNode(ast, allocator.n, .{ .tag = if (comma) .builtin_call_comma else .builtin_call, .main_token = builtin_token, .data = .{ .lhs = span.start, .rhs = span.end } });
        },
    }
}
/// KEYWORD_if LPAREN Expr RPAREN PtrPayload? Body (KEYWORD_else Payload? Body)?
fn parseIf(
    ast: *abstract.ProtoSyntaxTree,
    allocator: *AllocatorNEXS,
    array_s: *zig.StateArray,
    comptime bodyParseFn: fn (
        ast: *abstract.ProtoSyntaxTree,
        allocator: *AllocatorNEXS,
        array_s: *zig.StateArray,
    ) Error!zig.Index,
) Error!zig.Index {
    const if_token = eatToken(ast, .keyword_if) orelse return null_node;
    _ = try expectToken(ast, allocator.e, .l_paren);
    const condition = try expectExpr(ast, allocator, array_s);
    _ = try expectToken(ast, allocator.e, .r_paren);
    _ = try parsePtrPayload(ast, allocator.e);
    const then_expr = try bodyParseFn(ast, allocator, array_s);
    debug.assert(then_expr != 0);
    _ = eatToken(ast, .keyword_else) orelse return addNode(ast, allocator.n, .{
        .tag = .if_simple,
        .main_token = if_token,
        .data = .{ .lhs = condition, .rhs = then_expr },
    });
    _ = try parsePayload(ast, allocator.e);
    const else_expr = try bodyParseFn(ast, allocator, array_s);
    debug.assert(then_expr != 0);
    return addNode(ast, allocator.n, .{
        .tag = .@"if",
        .main_token = if_token,
        .data = .{
            .lhs = condition,
            .rhs = try addExtra(ast, allocator.x, zig.AstNode.If{
                .then_expr = then_expr,
                .else_expr = else_expr,
            }),
        },
    });
}
fn eatDocComments(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE) !?zig.Index {
    if (eatToken(ast, .doc_comment)) |tok| {
        var first_line = tok;
        if (tok > 0 and tokensOnSameLine(ast, tok - 1, tok)) {
            try warnMsg(ast, allocator_e, .{
                .tag = .same_line_doc_comment,
                .token = tok,
            });
            first_line = eatToken(ast, .doc_comment) orelse return null;
        }
        while (eatToken(ast, .doc_comment)) |_| {}
        return first_line;
    }
    return null;
}
fn tokensOnSameLine(ast: *abstract.ProtoSyntaxTree, token1: zig.Index, token2: zig.Index) bool {
    const start_1: zig.Index = ast.tokens.readOneAt(token1).start;
    const start_2: zig.Index = ast.tokens.readOneAt(token2).start;
    return mem.indexOfFirstEqualOne(u8, '\n', ast.source.readAll()[start_1..start_2]) == null;
}
fn tokenIndex(ast: *abstract.ProtoSyntaxTree) zig.Index {
    return @as(zig.Index, @intCast(ast.tokens.index()));
}
fn readTagAhead(ast: *abstract.ProtoSyntaxTree) zig.Token.Tag {
    return ast.tokens.readOneAhead().tag;
}
fn readStartAhead(ast: *abstract.ProtoSyntaxTree) zig.Token.Tag {
    return ast.tokens.readOneAhead().start;
}
fn readTagAt(ast: *abstract.ProtoSyntaxTree, index: usize) zig.Token.Tag {
    return ast.tokens.readOneAt(index).tag;
}
fn eatToken(ast: *abstract.ProtoSyntaxTree, tag: zig.Token.Tag) ?zig.Index {
    return if (readTagAhead(ast) == tag) nextToken(ast) else null;
}
fn assertToken(ast: *abstract.ProtoSyntaxTree, tag: zig.Token.Tag) zig.Index {
    const token = nextToken(ast);
    debug.assert(readTagAt(ast, token) == tag);
    return token;
}
fn expectToken(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, tag: zig.Token.Tag) Error!zig.Index {
    if (readTagAhead(ast) != tag) {
        return failMsg(ast, allocator_e, .{
            .tag = .expected_token,
            .token = tokenIndex(ast),
            .extra = .{ .expected_tag = tag },
        });
    }
    return nextToken(ast);
}
fn expectSemicolon(ast: *abstract.ProtoSyntaxTree, allocator_e: *AllocatorE, error_tag: zig.AstError.Tag, recoverable: bool) !void {
    if (readTagAhead(ast) == .semicolon) {
        _ = nextToken(ast);
        return;
    }
    try warn(ast, allocator_e, error_tag);
    if (!recoverable) return error.ParseError;
}
fn nextToken(ast: *abstract.ProtoSyntaxTree) zig.Index {
    const result = tokenIndex(ast);
    ast.tokens.stream(1);
    return @as(zig.Index, @intCast(result));
}
pub fn directEnumArrayDefault(
    comptime E: type,
    comptime Data: type,
    comptime default: ?Data,
    comptime max_unused_slots: comptime_int,
    init_values: EnumFieldStruct(E, Data, default),
) [directEnumArrayLen(E, max_unused_slots)]Data {
    const len = comptime directEnumArrayLen(E, max_unused_slots);
    var result: [len]Data = if (default) |d| [_]Data{d} ** len else undefined;
    inline for (@typeInfo(@TypeOf(init_values)).Struct.fields) |f| {
        const enum_value = @field(E, f.name);
        const index = @as(usize, @intCast(@intFromEnum(enum_value)));
        result[index] = @field(init_values, f.name);
    }
    return result;
}
pub fn EnumFieldStruct(comptime E: type, comptime Data: type, comptime field_default: ?Data) type {
    const StructField = builtin.Type.StructField;
    var fields: []const StructField = &[_]StructField{};
    for (meta.resolve(@typeInfo(E)).fields) |field| {
        fields = fields ++ &[_]StructField{.{
            .name = field.name,
            .type = Data,
            .default_value = if (field_default) |d| @as(?*const anyopaque, @ptrCast(&d)) else null,
            .is_comptime = false,
            .alignment = if (@sizeOf(Data) > 0) @alignOf(Data) else 0,
        }};
    }
    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
pub fn directEnumArrayLen(comptime E: type, comptime max_unused_slots: comptime_int) comptime_int {
    var max_value: comptime_int = -1;
    const max_usize: comptime_int = ~@as(usize, 0);
    const fields = meta.resolve(@typeInfo(E)).fields;
    for (fields) |f| {
        if (f.value < 0) {
            @compileError("Cannot create a direct enum array for " ++ @typeName(E) ++ ", field ." ++ f.name ++ " has a negative value.");
        }
        if (f.value > max_value) {
            if (f.value > max_usize) {
                @compileError("Cannot create a direct enum array for " ++ @typeName(E) ++ ", field ." ++ f.name ++ " is larger than the max value of usize.");
            }
            max_value = f.value;
        }
    }
    const unused_slots = max_value + 1 - fields.len;
    if (unused_slots > max_unused_slots) {
        @compileError("???");
    }
    return max_value + 1;
}
pub fn trimLeft(comptime T: type, slice: []const T, values_to_strip: []const T) []const T {
    var begin: usize = 0;
    while (begin < slice.len and mem.indexOfFirstEqualOne(T, values_to_strip, slice[begin]) != null) : (begin += 1) {}
    return slice[begin..];
}
pub fn trimRight(comptime T: type, slice: []const T, values_to_strip: []const T) []const T {
    var end: usize = slice.len;
    while (end > 0 and mem.indexOfFirstEqualOne(T, slice[end - 1], values_to_strip) != null) : (end -= 1) {}
    return slice[0..end];
}
