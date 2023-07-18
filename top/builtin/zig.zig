/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const OutputMode = enum {
    Exe,
    Lib,
    Obj,
};
/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const LinkMode = enum {
    Static,
    Dynamic,
};
/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const CodeModel = enum {
    default,
    tiny,
    small,
    kernel,
    medium,
    large,
};
/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const ExportOptions = struct {
    name: []const u8,
    linkage: GlobalLinkage = .Strong,
    section: ?[]const u8 = null,
    visibility: SymbolVisibility = .default,
};
/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const SymbolVisibility = enum {
    default,
    hidden,
    protected,
};
/// This data structure is used by the Zig language code generation and
/// therefore must be kept in sync with the compiler implementation.
pub const GlobalLinkage = enum {
    Internal,
    Strong,
    Weak,
    LinkOnce,
};

const KV = struct { []const u8, Token.Tag };
const keywords: [49]KV = .{
    // 0
    // 1
    // 2
    .{ "or", .keyword_or },
    .{ "fn", .keyword_fn },
    .{ "if", .keyword_if },
    // 3
    .{ "for", .keyword_for },
    .{ "and", .keyword_and },
    .{ "asm", .keyword_asm },
    .{ "var", .keyword_var },
    .{ "pub", .keyword_pub },
    .{ "try", .keyword_try },
    // 4
    .{ "test", .keyword_test },
    .{ "else", .keyword_else },
    .{ "enum", .keyword_enum },
    // 5
    .{ "error", .keyword_error },
    .{ "union", .keyword_union },
    .{ "while", .keyword_while },
    .{ "align", .keyword_align },
    .{ "async", .keyword_async },
    .{ "await", .keyword_await },
    .{ "break", .keyword_break },
    .{ "catch", .keyword_catch },
    .{ "const", .keyword_const },
    .{ "defer", .keyword_defer },
    // 6
    .{ "struct", .keyword_struct },
    .{ "opaque", .keyword_opaque },
    .{ "orelse", .keyword_orelse },
    .{ "packed", .keyword_packed },
    .{ "resume", .keyword_resume },
    .{ "return", .keyword_return },
    .{ "export", .keyword_export },
    .{ "extern", .keyword_extern },
    .{ "inline", .keyword_inline },
    .{ "switch", .keyword_switch },
    // 7
    .{ "anytype", .keyword_anytype },
    .{ "suspend", .keyword_suspend },
    .{ "noalias", .keyword_noalias },
    // 8
    .{ "volatile", .keyword_volatile },
    .{ "errdefer", .keyword_errdefer },
    .{ "comptime", .keyword_comptime },
    .{ "callconv", .keyword_callconv },
    .{ "continue", .keyword_continue },
    .{ "noinline", .keyword_noinline },
    .{ "anyframe", .keyword_anyframe },
    // 9 -- Except for unreachable and usingnamespace, the following keywords
    //      are very cold.
    .{ "addrspace", .keyword_addrspace },
    .{ "allowzero", .keyword_allowzero },
    .{ "nosuspend", .keyword_nosuspend },
    // 12
    .{ "linksection", .keyword_linksection },
    .{ "threadlocal", .keyword_threadlocal },
    .{ "unreachable", .keyword_unreachable },
    // 13
    .{ "usingnamespace", .keyword_usingnamespace },
};
pub const Token = struct {
    tag: Tag,
    loc: Loc,
    pub const Loc = struct {
        start: usize = 0,
        finish: usize = 0,
    };
    pub const Tag = enum {
        invalid,
        invalid_periodasterisks,
        identifier,
        string_literal,
        multiline_string_literal_line,
        char_literal,
        eof,
        builtin,
        bang,
        pipe,
        pipe_pipe,
        pipe_equal,
        equal,
        equal_equal,
        equal_angle_bracket_right,
        bang_equal,
        l_paren,
        r_paren,
        semicolon,
        percent,
        percent_equal,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,
        period,
        period_asterisk,
        ellipsis2,
        ellipsis3,
        caret,
        caret_equal,
        plus,
        plus_plus,
        plus_equal,
        plus_percent,
        plus_percent_equal,
        plus_pipe,
        plus_pipe_equal,
        minus,
        minus_equal,
        minus_percent,
        minus_percent_equal,
        minus_pipe,
        minus_pipe_equal,
        asterisk,
        asterisk_equal,
        asterisk_asterisk,
        asterisk_percent,
        asterisk_percent_equal,
        asterisk_pipe,
        asterisk_pipe_equal,
        arrow,
        colon,
        slash,
        slash_equal,
        comma,
        ampersand,
        ampersand_equal,
        question_mark,
        angle_bracket_left,
        angle_bracket_left_equal,
        angle_bracket_angle_bracket_left,
        angle_bracket_angle_bracket_left_equal,
        angle_bracket_angle_bracket_left_pipe,
        angle_bracket_angle_bracket_left_pipe_equal,
        angle_bracket_right,
        angle_bracket_right_equal,
        angle_bracket_angle_bracket_right,
        angle_bracket_angle_bracket_right_equal,
        tilde,
        number_literal,
        doc_comment,
        container_doc_comment,
        keyword_addrspace,
        keyword_align,
        keyword_allowzero,
        keyword_and,
        keyword_anyframe,
        keyword_anytype,
        keyword_asm,
        keyword_async,
        keyword_await,
        keyword_break,
        keyword_callconv,
        keyword_catch,
        keyword_comptime,
        keyword_const,
        keyword_continue,
        keyword_defer,
        keyword_else,
        keyword_enum,
        keyword_errdefer,
        keyword_error,
        keyword_export,
        keyword_extern,
        keyword_fn,
        keyword_for,
        keyword_if,
        keyword_inline,
        keyword_noalias,
        keyword_noinline,
        keyword_nosuspend,
        keyword_opaque,
        keyword_or,
        keyword_orelse,
        keyword_packed,
        keyword_pub,
        keyword_resume,
        keyword_return,
        keyword_linksection,
        keyword_struct,
        keyword_suspend,
        keyword_switch,
        keyword_test,
        keyword_threadlocal,
        keyword_try,
        keyword_union,
        keyword_unreachable,
        keyword_usingnamespace,
        keyword_var,
        keyword_volatile,
        keyword_while,
        pub const strings: []const Token.Tag = &.{
            .string_literal,
            .multiline_string_literal_line,
        };
        pub const bracket: []const Token.Tag = &.{
            .l_brace,
            .r_brace,
            .l_bracket,
            .r_bracket,
            .l_paren,
            .r_paren,
        };
        pub const operator: []const Token.Tag = &.{
            .arrow,                  .bang,
            .pipe,                   .pipe_pipe,
            .pipe_equal,             .equal,
            .equal_equal,            .bang_equal,
            .percent,                .percent_equal,
            .period_asterisk,        .caret,
            .caret_equal,            .plus,
            .plus_plus,              .plus_equal,
            .plus_percent,           .plus_percent_equal,
            .plus_pipe,              .plus_pipe_equal,
            .minus,                  .minus_equal,
            .minus_percent,          .minus_percent_equal,
            .minus_pipe,             .minus_pipe_equal,
            .asterisk,               .asterisk_equal,
            .asterisk_asterisk,      .asterisk_percent,
            .asterisk_percent_equal, .asterisk_pipe,
            .asterisk_pipe_equal,    .slash,
            .slash_equal,            .ampersand,
            .ampersand_equal,        .question_mark,
            .tilde,                  .angle_bracket_left,
            .ellipsis2,              .ellipsis3,
            .equal_angle_bracket_right, //
            .angle_bracket_left_equal,
            .angle_bracket_angle_bracket_left,
            .angle_bracket_angle_bracket_left_equal,
            .angle_bracket_angle_bracket_left_pipe,
            .angle_bracket_angle_bracket_left_pipe_equal,
            .angle_bracket_right,
            .angle_bracket_right_equal,
            .angle_bracket_angle_bracket_right,
            .angle_bracket_angle_bracket_right_equal,
        };
        pub const builtin_fn: []const Token.Tag = &.{
            .builtin,
            .keyword_align,
            .keyword_addrspace,
            .keyword_linksection,
            .keyword_callconv,
        };
        pub const unwrap_keyword: []const Token.Tag = &.{
            .keyword_try,
            .keyword_catch,
        };
        pub const macro_keyword: []const Token.Tag = &.{
            .keyword_defer,
            .keyword_async,
            .keyword_await,
            .keyword_export,
            .keyword_extern,
            .keyword_resume,
            .keyword_suspend,
            .keyword_errdefer,
            .keyword_nosuspend,
            .keyword_unreachable,
        };
        pub const container_keyword: []const Token.Tag = &.{
            .keyword_enum,
            .keyword_packed,
            .keyword_opaque,
            .keyword_struct,
            .keyword_union,
            .keyword_error,
        };
        pub const qual_keyword: []const Token.Tag = &.{
            .keyword_volatile,
            .keyword_allowzero,
        };
        pub const call_keyword: []const Token.Tag = &.{
            .keyword_asm,
            .keyword_inline,
            .keyword_noalias,
            .keyword_noinline,
        };
        pub const cond_keyword: []const Token.Tag = &.{
            .keyword_fn,
            .keyword_if,
            .keyword_or,
            .keyword_for,
            .keyword_and,
            .keyword_try,
            .keyword_else,
            .keyword_test,
            .keyword_while,
            .keyword_switch,
            .keyword_orelse,
            .keyword_anytype,
            .keyword_anyframe,
        };
        pub const goto_keyword: []const Token.Tag = &.{
            .keyword_break,
            .keyword_return,
            .keyword_continue,
        };
        pub const value_keyword: []const Token.Tag = &.{
            .keyword_pub,
            .keyword_var,
            .keyword_const,
            .keyword_comptime,
            .keyword_threadlocal,
            .keyword_usingnamespace,
        };
        pub const other: []const Token.Tag = &.{
            .invalid,
            .identifier,
            .container_doc_comment,
            .doc_comment,
            .invalid_periodasterisks,
            .period,
            .comma,
            .colon,
            .semicolon,
            .eof,
        };
    };
};
pub const TokenIterator = struct {
    buf: [:0]const u8,
    buf_pos: usize,
    inval: ?Token,
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
    pub fn next(itr: *TokenIterator) Token {
        @setRuntimeSafety(false);
        if (itr.inval) |token| {
            itr.inval = null;
            return token;
        }
        var state: State = .start;
        var ret = Token{
            .tag = .eof,
            .loc = .{ .start = itr.buf_pos },
        };
        var esc_no: usize = undefined;
        var rem_cp: usize = undefined;
        while (true) : (itr.buf_pos +%= 1) {
            const c: u8 = itr.buf[itr.buf_pos];
            switch (state) {
                .start => switch (c) {
                    0 => {
                        if (itr.buf_pos != itr.buf.len) {
                            ret.tag = .invalid;
                            ret.loc.start = itr.buf_pos;
                            itr.buf_pos +%= 1;
                            ret.loc.finish = itr.buf_pos;
                            return ret;
                        }
                        break;
                    },
                    ' ', '\n', '\t', '\r' => ret.loc.start = itr.buf_pos +% 1,
                    '"' => {
                        state = .string_literal;
                        ret.tag = .string_literal;
                    },
                    '\'' => state = .char_literal,
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .identifier;
                        ret.tag = .identifier;
                    },
                    '@' => state = .saw_at_sign,
                    '=' => state = .equal,
                    '!' => state = .bang,
                    '|' => state = .pipe,
                    '(' => {
                        ret.tag = .l_paren;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    ')' => {
                        ret.tag = .r_paren;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '[' => {
                        ret.tag = .l_bracket;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    ']' => {
                        ret.tag = .r_bracket;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    ';' => {
                        ret.tag = .semicolon;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    ',' => {
                        ret.tag = .comma;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '?' => {
                        ret.tag = .question_mark;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    ':' => {
                        ret.tag = .colon;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '%' => state = .percent,
                    '*' => state = .asterisk,
                    '+' => state = .plus,
                    '<' => state = .angle_bracket_left,
                    '>' => state = .angle_bracket_right,
                    '^' => state = .caret,
                    '\\' => {
                        state = .backslash;
                        ret.tag = .multiline_string_literal_line;
                    },
                    '{' => {
                        ret.tag = .l_brace;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '}' => {
                        ret.tag = .r_brace;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '~' => {
                        ret.tag = .tilde;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '.' => state = .period,
                    '-' => state = .minus,
                    '/' => state = .slash,
                    '&' => state = .ampersand,
                    '0'...'9' => {
                        state = .int;
                        ret.tag = .number_literal;
                    },
                    else => {
                        ret.tag = .invalid;
                        ret.loc.finish = itr.buf_pos;
                        itr.buf_pos +%= 1;
                        return ret;
                    },
                },
                .saw_at_sign => switch (c) {
                    '"' => {
                        ret.tag = .identifier;
                        state = .string_literal;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .builtin;
                        ret.tag = .builtin;
                    },
                    else => {
                        ret.tag = .invalid;
                        break;
                    },
                },
                .ampersand => switch (c) {
                    '=' => {
                        ret.tag = .ampersand_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .ampersand;
                        break;
                    },
                },
                .asterisk => switch (c) {
                    '=' => {
                        ret.tag = .asterisk_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '*' => {
                        ret.tag = .asterisk_asterisk;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '%' => state = .asterisk_percent,
                    '|' => state = .asterisk_pipe,
                    else => {
                        ret.tag = .asterisk;
                        break;
                    },
                },
                .asterisk_percent => switch (c) {
                    '=' => {
                        ret.tag = .asterisk_percent_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .asterisk_percent;
                        break;
                    },
                },
                .asterisk_pipe => switch (c) {
                    '=' => {
                        ret.tag = .asterisk_pipe_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .asterisk_pipe;
                        break;
                    },
                },
                .percent => switch (c) {
                    '=' => {
                        ret.tag = .percent_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .percent;
                        break;
                    },
                },
                .plus => switch (c) {
                    '=' => {
                        ret.tag = .plus_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '+' => {
                        ret.tag = .plus_plus;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '%' => state = .plus_percent,
                    '|' => state = .plus_pipe,
                    else => {
                        ret.tag = .plus;
                        break;
                    },
                },
                .plus_percent => switch (c) {
                    '=' => {
                        ret.tag = .plus_percent_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .plus_percent;
                        break;
                    },
                },
                .plus_pipe => switch (c) {
                    '=' => {
                        ret.tag = .plus_pipe_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .plus_pipe;
                        break;
                    },
                },
                .caret => switch (c) {
                    '=' => {
                        ret.tag = .caret_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .caret;
                        break;
                    },
                },
                .identifier => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => {
                        if (keyword(itr.buf[ret.loc.start..itr.buf_pos])) |tag| {
                            ret.tag = tag;
                        }
                        break;
                    },
                },
                .builtin => switch (c) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                    else => break,
                },
                .backslash => switch (c) {
                    '\\' => state = .multiline_string_literal_line,
                    else => {
                        ret.tag = .invalid;
                        break;
                    },
                },
                .string_literal => switch (c) {
                    '\\' => state = .string_literal_backslash,
                    '"' => {
                        itr.buf_pos +%= 1;
                        break;
                    },
                    0 => {
                        if (itr.buf_pos == itr.buf.len) {
                            ret.tag = .invalid;
                            break;
                        } else {
                            itr.checkChar();
                        }
                    },
                    '\n' => {
                        ret.tag = .invalid;
                        break;
                    },
                    else => itr.checkChar(),
                },
                .string_literal_backslash => switch (c) {
                    0, '\n' => {
                        ret.tag = .invalid;
                        break;
                    },
                    else => state = .string_literal,
                },
                .char_literal => switch (c) {
                    0 => {
                        ret.tag = .invalid;
                        break;
                    },
                    '\\' => state = .char_literal_backslash,
                    '\'', 0x80...0xbf, 0xf8...0xff => {
                        ret.tag = .invalid;
                        break;
                    },
                    0xc0...0xdf => {
                        rem_cp = 1;
                        state = .char_literal_unicode;
                    },
                    0xe0...0xef => {
                        rem_cp = 2;
                        state = .char_literal_unicode;
                    },
                    0xf0...0xf7 => {
                        rem_cp = 3;
                        state = .char_literal_unicode;
                    },
                    '\n' => {
                        ret.tag = .invalid;
                        break;
                    },
                    else => state = .char_literal_end,
                },
                .char_literal_backslash => switch (c) {
                    0, '\n' => {
                        ret.tag = .invalid;
                        break;
                    },
                    'x' => {
                        state = .char_literal_hex_escape;
                        esc_no = 0;
                    },
                    'u' => state = .char_literal_unicode_escape_saw_u,
                    else => state = .char_literal_end,
                },
                .char_literal_hex_escape => switch (c) {
                    '0'...'9', 'a'...'f', 'A'...'F' => {
                        esc_no +%= 1;
                        if (esc_no == 2) {
                            state = .char_literal_end;
                        }
                    },
                    else => {
                        ret.tag = .invalid;
                        break;
                    },
                },
                .char_literal_unicode_escape_saw_u => switch (c) {
                    0 => {
                        ret.tag = .invalid;
                        break;
                    },
                    '{' => state = .char_literal_unicode_escape,
                    else => {
                        ret.tag = .invalid;
                        state = .char_literal_unicode_invalid;
                    },
                },
                .char_literal_unicode_escape => switch (c) {
                    0 => {
                        ret.tag = .invalid;
                        break;
                    },
                    '0'...'9', 'a'...'f', 'A'...'F' => {},
                    '}' => state = .char_literal_end,
                    else => {
                        ret.tag = .invalid;
                        state = .char_literal_unicode_invalid;
                    },
                },
                .char_literal_unicode_invalid => switch (c) {
                    '0'...'9', 'a'...'z', 'A'...'Z', '}' => {},
                    else => break,
                },
                .char_literal_end => switch (c) {
                    '\'' => {
                        ret.tag = .char_literal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .invalid;
                        break;
                    },
                },
                .char_literal_unicode => switch (c) {
                    0x80...0xbf => {
                        rem_cp -%= 1;
                        if (rem_cp == 0) {
                            state = .char_literal_end;
                        }
                    },
                    else => {
                        ret.tag = .invalid;
                        break;
                    },
                },
                .multiline_string_literal_line => switch (c) {
                    0 => break,
                    '\n' => {
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '\t' => {},
                    else => itr.checkChar(),
                },
                .bang => switch (c) {
                    '=' => {
                        ret.tag = .bang_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .bang;
                        break;
                    },
                },
                .pipe => switch (c) {
                    '=' => {
                        ret.tag = .pipe_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '|' => {
                        ret.tag = .pipe_pipe;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .pipe;
                        break;
                    },
                },
                .equal => switch (c) {
                    '=' => {
                        ret.tag = .equal_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '>' => {
                        ret.tag = .equal_angle_bracket_right;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .equal;
                        break;
                    },
                },
                .minus => switch (c) {
                    '>' => {
                        ret.tag = .arrow;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '=' => {
                        ret.tag = .minus_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '%' => state = .minus_percent,
                    '|' => state = .minus_pipe,
                    else => {
                        ret.tag = .minus;
                        break;
                    },
                },
                .minus_percent => switch (c) {
                    '=' => {
                        ret.tag = .minus_percent_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .minus_percent;
                        break;
                    },
                },
                .minus_pipe => switch (c) {
                    '=' => {
                        ret.tag = .minus_pipe_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .minus_pipe;
                        break;
                    },
                },
                .angle_bracket_left => switch (c) {
                    '<' => state = .angle_bracket_angle_bracket_left,
                    '=' => {
                        ret.tag = .angle_bracket_left_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .angle_bracket_left;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_left => switch (c) {
                    '=' => {
                        ret.tag = .angle_bracket_angle_bracket_left_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    '|' => state = .angle_bracket_angle_bracket_left_pipe,
                    else => {
                        ret.tag = .angle_bracket_angle_bracket_left;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_left_pipe => switch (c) {
                    '=' => {
                        ret.tag = .angle_bracket_angle_bracket_left_pipe_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .angle_bracket_angle_bracket_left_pipe;
                        break;
                    },
                },
                .angle_bracket_right => switch (c) {
                    '>' => state = .angle_bracket_angle_bracket_right,
                    '=' => {
                        ret.tag = .angle_bracket_right_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .angle_bracket_right;
                        break;
                    },
                },
                .angle_bracket_angle_bracket_right => switch (c) {
                    '=' => {
                        ret.tag = .angle_bracket_angle_bracket_right_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .angle_bracket_angle_bracket_right;
                        break;
                    },
                },
                .period => switch (c) {
                    '.' => state = .period_2,
                    '*' => state = .period_asterisk,
                    else => {
                        ret.tag = .period;
                        break;
                    },
                },
                .period_2 => switch (c) {
                    '.' => {
                        ret.tag = .ellipsis3;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .ellipsis2;
                        break;
                    },
                },
                .period_asterisk => switch (c) {
                    '*' => {
                        ret.tag = .invalid_periodasterisks;
                        break;
                    },
                    else => {
                        ret.tag = .period_asterisk;
                        break;
                    },
                },
                .slash => switch (c) {
                    '/' => state = .line_comment_start,
                    '=' => {
                        ret.tag = .slash_equal;
                        itr.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        ret.tag = .slash;
                        break;
                    },
                },
                .line_comment_start => switch (c) {
                    0 => {
                        if (itr.buf_pos != itr.buf.len) {
                            ret.tag = .invalid;
                            itr.buf_pos +%= 1;
                        }
                        break;
                    },
                    '/' => state = .doc_comment_start,
                    '!' => {
                        ret.tag = .container_doc_comment;
                        state = .doc_comment;
                    },
                    '\n' => {
                        state = .start;
                        ret.loc.start = itr.buf_pos +% 1;
                    },
                    '\t' => state = .line_comment,
                    else => {
                        state = .line_comment;
                        itr.checkChar();
                    },
                },
                .doc_comment_start => switch (c) {
                    '/' => state = .line_comment,
                    0, '\n' => {
                        ret.tag = .doc_comment;
                        break;
                    },
                    '\t' => {
                        state = .doc_comment;
                        ret.tag = .doc_comment;
                    },
                    else => {
                        state = .doc_comment;
                        ret.tag = .doc_comment;
                        itr.checkChar();
                    },
                },
                .line_comment => switch (c) {
                    0 => {
                        if (itr.buf_pos != itr.buf.len) {
                            ret.tag = .invalid;
                            itr.buf_pos +%= 1;
                        }
                        break;
                    },
                    '\n' => {
                        state = .start;
                        ret.loc.start = itr.buf_pos +% 1;
                    },
                    '\t' => {},
                    else => itr.checkChar(),
                },
                .doc_comment => switch (c) {
                    0, '\n' => break,
                    '\t' => {},
                    else => itr.checkChar(),
                },
                .int => switch (c) {
                    '.' => state = .int_period,
                    '_',
                    'a'...'d',
                    'f'...'o',
                    'q'...'z',
                    'A'...'D',
                    'F'...'O',
                    'Q'...'Z',
                    '0'...'9',
                    => {},
                    'e', 'E', 'p', 'P' => state = .int_exponent,
                    else => break,
                },
                .int_exponent => switch (c) {
                    '-', '+' => state = .float,
                    else => {
                        itr.buf_pos -%= 1;
                        state = .int;
                    },
                },
                .int_period => switch (c) {
                    '_',
                    'a'...'d',
                    'f'...'o',
                    'q'...'z',
                    'A'...'D',
                    'F'...'O',
                    'Q'...'Z',
                    '0'...'9',
                    => state = .float,
                    'e', 'E', 'p', 'P' => state = .float_exponent,
                    else => {
                        itr.buf_pos -%= 1;
                        break;
                    },
                },
                .float => switch (c) {
                    '_',
                    'a'...'d',
                    'f'...'o',
                    'q'...'z',
                    'A'...'D',
                    'F'...'O',
                    'Q'...'Z',
                    '0'...'9',
                    => {},
                    'e', 'E', 'p', 'P' => state = .float_exponent,
                    else => break,
                },
                .float_exponent => switch (c) {
                    '-', '+' => state = .float,
                    else => {
                        itr.buf_pos -%= 1;
                        state = .float;
                    },
                },
            }
        }
        if (ret.tag == .eof) {
            if (itr.inval) |token| {
                itr.inval = null;
                return token;
            }
            ret.loc.start = itr.buf_pos;
        }
        ret.loc.finish = itr.buf_pos;
        return ret;
    }
    fn checkChar(itr: *TokenIterator) void {
        if (itr.inval != null) {
            return;
        }
        const inval_len: u64 = itr.invalLen();
        if (inval_len == 0) {
            return;
        }
        itr.inval = .{
            .tag = .invalid,
            .loc = .{
                .start = itr.buf_pos,
                .finish = itr.buf_pos +% inval_len,
            },
        };
    }
    fn invalLen(itr: *TokenIterator) u8 {
        const byte: u8 = itr.buf[itr.buf_pos];
        if (byte < 0x80) {
            // Removed carriage return tolerance.
            return @intFromBool(byte <= 0x1F) | @intFromBool(byte == 0x7F);
        } else {
            const len: u8 = switch (byte) {
                0b0000_0000...0b0111_1111 => 1,
                0b1100_0000...0b1101_1111 => 2,
                0b1110_0000...0b1110_1111 => 3,
                0b1111_0000...0b1111_0111 => 4,
                else => return 1,
            };
            if (itr.buf_pos +% len > itr.buf.len) {
                return @as(u8, @intCast(itr.buf.len -% itr.buf_pos));
            }
            const bytes: []const u8 = itr.buf[itr.buf_pos .. itr.buf_pos +% len];
            if (len == 2) {
                var value: u32 = bytes[0] & 0b00011111;
                if (bytes[1] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[1] & 0b00111111;
                if (value < 0x80 or value == 0x85) {
                    return len;
                }
            } else //
            if (len == 3) {
                var value: u32 = bytes[0] & 0b00001111;
                if (bytes[1] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[1] & 0b00111111;
                if (bytes[2] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[2] & 0b00111111;
                if (value < 0x800) {
                    return len;
                }
                if (0xd800 <= value and value <= 0xdfff) {
                    return len;
                }
                if (value == 0x2028 or value == 0x2029) {
                    return len;
                }
            } else //
            if (len == 4) {
                var value: u32 = bytes[0] & 0b00000111;
                if (bytes[1] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[1] & 0b00111111;
                if (bytes[2] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[2] & 0b00111111;
                if (bytes[3] & 0b11000000 != 0b10000000) {
                    return len;
                }
                value <<= 6;
                value |= bytes[3] & 0b00111111;
                if (value < 0x10000 or value > 0x10FFFF) {
                    return len;
                }
            }
            itr.buf_pos +%= len -% 1;
        }
        return 0;
    }
};

pub fn lexeme(tag: Token.Tag) ?[]const u8 {
    switch (tag) {
        .invalid_periodasterisks => return ".**",
        .bang => return "!",
        .pipe => return "|",
        .pipe_pipe => return "||",
        .pipe_equal => return "|=",
        .equal => return "=",
        .equal_equal => return "==",
        .equal_angle_bracket_right => return "=>",
        .bang_equal => return "!=",
        .l_paren => return "(",
        .r_paren => return ")",
        .semicolon => return ";",
        .percent => return "%",
        .percent_equal => return "%=",
        .l_brace => return "{",
        .r_brace => return "}",
        .l_bracket => return "[",
        .r_bracket => return "]",
        .period => return ".",
        .period_asterisk => return ".*",
        .ellipsis2 => return "..",
        .ellipsis3 => return "...",
        .caret => return "^",
        .caret_equal => return "^=",
        .plus => return "+",
        .plus_plus => return "++",
        .plus_equal => return "+=",
        .plus_percent => return "+%",
        .plus_percent_equal => return "+%=",
        .plus_pipe => return "+|",
        .plus_pipe_equal => return "+|=",
        .minus => return "-",
        .minus_equal => return "-=",
        .minus_percent => return "-%",
        .minus_percent_equal => return "-%=",
        .minus_pipe => return "-|",
        .minus_pipe_equal => return "-|=",
        .asterisk => return "*",
        .asterisk_equal => return "*=",
        .asterisk_asterisk => return "**",
        .asterisk_percent => return "*%",
        .asterisk_percent_equal => return "*%=",
        .asterisk_pipe => return "*|",
        .asterisk_pipe_equal => return "*|=",
        .arrow => return "->",
        .colon => return ":",
        .slash => return "/",
        .slash_equal => return "/=",
        .comma => return ",",
        .ampersand => return "&",
        .ampersand_equal => return "&=",
        .question_mark => return "?",
        .angle_bracket_left => return "<",
        .angle_bracket_left_equal => return "<=",
        .angle_bracket_angle_bracket_left => return "<<",
        .angle_bracket_angle_bracket_left_equal => return "<<=",
        .angle_bracket_angle_bracket_left_pipe => return "<<|",
        .angle_bracket_angle_bracket_left_pipe_equal => return "<<|=",
        .angle_bracket_right => return ">",
        .angle_bracket_right_equal => return ">=",
        .angle_bracket_angle_bracket_right => return ">>",
        .angle_bracket_angle_bracket_right_equal => return ">>=",
        .tilde => return "~",
        .keyword_addrspace => return "addrspace",
        .keyword_align => return "align",
        .keyword_allowzero => return "allowzero",
        .keyword_and => return "and",
        .keyword_anyframe => return "anyframe",
        .keyword_anytype => return "anytype",
        .keyword_asm => return "asm",
        .keyword_async => return "async",
        .keyword_await => return "await",
        .keyword_break => return "break",
        .keyword_callconv => return "callconv",
        .keyword_catch => return "catch",
        .keyword_comptime => return "comptime",
        .keyword_const => return "const",
        .keyword_continue => return "continue",
        .keyword_defer => return "defer",
        .keyword_else => return "else",
        .keyword_enum => return "enum",
        .keyword_errdefer => return "errdefer",
        .keyword_error => return "error",
        .keyword_export => return "export",
        .keyword_extern => return "extern",
        .keyword_fn => return "fn",
        .keyword_for => return "for",
        .keyword_if => return "if",
        .keyword_inline => return "inline",
        .keyword_noalias => return "noalias",
        .keyword_noinline => return "noinline",
        .keyword_nosuspend => return "nosuspend",
        .keyword_opaque => return "opaque",
        .keyword_or => return "or",
        .keyword_orelse => return "orelse",
        .keyword_packed => return "packed",
        .keyword_pub => return "pub",
        .keyword_resume => return "resume",
        .keyword_return => return "return",
        .keyword_linksection => return "linksection",
        .keyword_struct => return "struct",
        .keyword_suspend => return "suspend",
        .keyword_switch => return "switch",
        .keyword_test => return "test",
        .keyword_threadlocal => return "threadlocal",
        .keyword_try => return "try",
        .keyword_union => return "union",
        .keyword_unreachable => return "unreachable",
        .keyword_usingnamespace => return "usingnamespace",
        .keyword_var => return "var",
        .keyword_volatile => return "volatile",
        .keyword_while => return "while",
        else => return null,
    }
}
pub fn symbol(tag: Token.Tag) []const u8 {
    switch (tag) {
        .invalid => return "invalid bytes",
        .identifier => return "an identifier",
        .char_literal => return "a character literal",
        .eof => return "EOF",
        .builtin => return "a builtin function",
        .number_literal => return "a number literal",
        .string_literal,
        .multiline_string_literal_line,
        => return "a string literal",
        .doc_comment,
        .container_doc_comment,
        => return "a document comment",
        else => return tag.lexeme(),
    }
}
pub fn keyword(str: []const u8) ?Token.Tag {
    lo: for (keywords) |kv| {
        if (kv[0].len != str.len) {
            continue;
        }
        for (str, kv[0]) |x, y| {
            if (x != y) {
                continue :lo;
            }
        }
        return kv[1];
    }
    return null;
}
