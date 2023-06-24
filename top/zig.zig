const mem = @import("./mem.zig");
const spec = @import("./spec.zig");
const mach = @import("./mach.zig");
const utf8 = @import("./fmt/utf8.zig");
const ascii = @import("./fmt/ascii.zig");
const builtin = @import("./builtin.zig");

const style = struct {
    const red: [:0]const u8 = "\x1b[38;2;233;86;120m";
    const redwine: [:0]const u8 = "\x1b[38;2;209;109;158m";
    const orange: [:0]const u8 = "\x1b[38;2;233;127;73m";
    const yellow: [:0]const u8 = "\x1b[38;2;240;198;116m";
    const light_green: [:0]const u8 = "\x1b[38;2;51;229;96m";
    const green: [:0]const u8 = "\x1b[38;2;175;215;0m";
    const dark_green: [:0]const u8 = "\x1b[38;2;152;190;101m";
    const white: [:0]const u8 = "\x1b[38;2;255;255;255;1m";
    const cyan: [:0]const u8 = "\x1b[38;2;54;208;224m";
    const blue: [:0]const u8 = "\x1b[38;2;97;175;239m";
    const violet: [:0]const u8 = "\x1b[38;2;178;148;187m";
    const magenta: [:0]const u8 = "\x1b[38;2;198;120;221m";
    const teal: [:0]const u8 = "\x1b[38;2;26;188;156m";
    const grey: [:0]const u8 = "\x1b[38;2;146;131;116m";
    const brown: [:0]const u8 = "\x1b[38;2;199;134;101m";
    const black: [:0]const u8 = "\x1b[38;2;0;0;0m";
    const light_blue: [:0]const u8 = "\x1b[38;2;97;168;255m";
    const light_purple: [:0]const u8 = "\x1b[38;2;193;173;247m";
    const bracket: [:0]const u8 = "\x1b[38;2;128;160;194m";
    const cursor_bg: [:0]const u8 = "\x1b[38;2;79;91;102m";
    const offwhite0: [:0]const u8 = "\x1b[38;2;207;207;194m";
    const offwhite1: [:0]const u8 = "\x1b[38;2;221;218;214m";
    const numeric: [:0]const u8 = "\x1b[38;2;255;115;115m";
    const data_type: [:0]const u8 = "\x1b[38;2;255;255;255m";
    const attribute: [:0]const u8 = "\x1b[38;2;41;128;185m";
};
pub const Token = struct {
    tag: Tag,
    loc: Loc,
    pub const Loc = struct {
        start: usize,
        finish: usize,
    };
    pub const Keywords = struct {
        const Pair = struct {
            key: []const u8,
            value: Tag,
        };
        pub fn has(str: []const u8) bool {
            return get(str) != null;
        }
        const tab = [_]struct { []const u8, Tag }{
            .{ "or", .keyword_or },
            .{ "fn", .keyword_fn },
            .{ "if", .keyword_if },
            .{ "for", .keyword_for },
            .{ "and", .keyword_and },
            .{ "asm", .keyword_asm },
            .{ "var", .keyword_var },
            .{ "pub", .keyword_pub },
            .{ "try", .keyword_try },
            .{ "test", .keyword_test },
            .{ "union", .keyword_union },
            .{ "while", .keyword_while },
            .{ "else", .keyword_else },
            .{ "enum", .keyword_enum },
            .{ "error", .keyword_error },
            .{ "align", .keyword_align },
            .{ "async", .keyword_async },
            .{ "await", .keyword_await },
            .{ "break", .keyword_break },
            .{ "catch", .keyword_catch },
            .{ "const", .keyword_const },
            .{ "defer", .keyword_defer },
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
            .{ "anytype", .keyword_anytype },
            .{ "suspend", .keyword_suspend },
            .{ "noalias", .keyword_noalias },
            .{ "volatile", .keyword_volatile },
            .{ "errdefer", .keyword_errdefer },
            .{ "comptime", .keyword_comptime },
            .{ "callconv", .keyword_callconv },
            .{ "continue", .keyword_continue },
            .{ "noinline", .keyword_noinline },
            .{ "anyframe", .keyword_anyframe },
            .{ "addrspace", .keyword_addrspace },
            .{ "allowzero", .keyword_allowzero },
            .{ "nosuspend", .keyword_nosuspend },
            .{ "linksection", .keyword_linksection },
            .{ "threadlocal", .keyword_threadlocal },
            .{ "unreachable", .keyword_unreachable },
            .{ "usingnamespace", .keyword_usingnamespace },
        };
        pub fn get(str: []const u8) ?Tag {
            const min_len: comptime_int = 2;
            const max_len: comptime_int = 14;
            if (str.len < min_len or str.len > max_len) {
                return null;
            }
            for (tab) |pair| {
                if (mach.testEqualMany8(pair[0], str)) {
                    return pair[1];
                }
            }
            return null;
        }
    };
    pub fn getKeyword(bytes: []const u8) ?Tag {
        return Keywords.get(bytes);
    }
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
        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .invalid,
                .identifier,
                .string_literal,
                .multiline_string_literal_line,
                .eof,
                .builtin,
                .doc_comment,
                .container_doc_comment,
                .char_literal,
                .number_literal,
                => null,

                .invalid_periodasterisks => ".**",
                .bang => "!",
                .pipe => "|",
                .pipe_pipe => "||",
                .pipe_equal => "|=",
                .equal => "=",
                .equal_equal => "==",
                .equal_angle_bracket_right => "=>",
                .bang_equal => "!=",
                .l_paren => "(",
                .r_paren => ")",
                .semicolon => ";",
                .percent => "%",
                .percent_equal => "%=",
                .l_brace => "{",
                .r_brace => "}",
                .l_bracket => "[",
                .r_bracket => "]",
                .period => ".",
                .period_asterisk => ".*",
                .ellipsis2 => "..",
                .ellipsis3 => "...",
                .caret => "^",
                .caret_equal => "^=",
                .plus => "+",
                .plus_plus => "++",
                .plus_equal => "+=",
                .plus_percent => "+%",
                .plus_percent_equal => "+%=",
                .plus_pipe => "+|",
                .plus_pipe_equal => "+|=",
                .minus => "-",
                .minus_equal => "-=",
                .minus_percent => "-%",
                .minus_percent_equal => "-%=",
                .minus_pipe => "-|",
                .minus_pipe_equal => "-|=",
                .asterisk => "*",
                .asterisk_equal => "*=",
                .asterisk_asterisk => "**",
                .asterisk_percent => "*%",
                .asterisk_percent_equal => "*%=",
                .asterisk_pipe => "*|",
                .asterisk_pipe_equal => "*|=",
                .arrow => "->",
                .colon => ":",
                .slash => "/",
                .slash_equal => "/=",
                .comma => ",",
                .ampersand => "&",
                .ampersand_equal => "&=",
                .question_mark => "?",
                .angle_bracket_left => "<",
                .angle_bracket_left_equal => "<=",
                .angle_bracket_angle_bracket_left => "<<",
                .angle_bracket_angle_bracket_left_equal => "<<=",
                .angle_bracket_angle_bracket_left_pipe => "<<|",
                .angle_bracket_angle_bracket_left_pipe_equal => "<<|=",
                .angle_bracket_right => ">",
                .angle_bracket_right_equal => ">=",
                .angle_bracket_angle_bracket_right => ">>",
                .angle_bracket_angle_bracket_right_equal => ">>=",
                .tilde => "~",
                .keyword_addrspace => "addrspace",
                .keyword_align => "align",
                .keyword_allowzero => "allowzero",
                .keyword_and => "and",
                .keyword_anyframe => "anyframe",
                .keyword_anytype => "anytype",
                .keyword_asm => "asm",
                .keyword_async => "async",
                .keyword_await => "await",
                .keyword_break => "break",
                .keyword_callconv => "callconv",
                .keyword_catch => "catch",
                .keyword_comptime => "comptime",
                .keyword_const => "const",
                .keyword_continue => "continue",
                .keyword_defer => "defer",
                .keyword_else => "else",
                .keyword_enum => "enum",
                .keyword_errdefer => "errdefer",
                .keyword_error => "error",
                .keyword_export => "export",
                .keyword_extern => "extern",
                .keyword_fn => "fn",
                .keyword_for => "for",
                .keyword_if => "if",
                .keyword_inline => "inline",
                .keyword_noalias => "noalias",
                .keyword_noinline => "noinline",
                .keyword_nosuspend => "nosuspend",
                .keyword_opaque => "opaque",
                .keyword_or => "or",
                .keyword_orelse => "orelse",
                .keyword_packed => "packed",
                .keyword_pub => "pub",
                .keyword_resume => "resume",
                .keyword_return => "return",
                .keyword_linksection => "linksection",
                .keyword_struct => "struct",
                .keyword_suspend => "suspend",
                .keyword_switch => "switch",
                .keyword_test => "test",
                .keyword_threadlocal => "threadlocal",
                .keyword_try => "try",
                .keyword_union => "union",
                .keyword_unreachable => "unreachable",
                .keyword_usingnamespace => "usingnamespace",
                .keyword_var => "var",
                .keyword_volatile => "volatile",
                .keyword_while => "while",
            };
        }
        const Mapping = struct {
            tags: []const Tag,
            style: ?[]const u8,
        };
        const mappings: []const Mapping = &.{
            .{ .style = null, .tags = &[_]Tag{
                .invalid,      .identifier,
                .char_literal, .container_doc_comment,
                .doc_comment,  .invalid_periodasterisks,
                .period,       .comma,
                .colon,        .semicolon,
                .ellipsis2,    .ellipsis3,
                .eof,
            } },
            .{ .style = style.light_green, .tags = &[_]Tag{
                .string_literal, .multiline_string_literal_line,
            } },
            .{ .style = style.bracket, .tags = &[_]Tag{
                .l_brace,   .r_brace,
                .l_bracket, .r_bracket,
                .l_paren,   .r_paren,
            } },
            .{ .style = style.magenta, .tags = &[_]Tag{
                .arrow,               .bang,               .pipe,                   .pipe_pipe,
                .pipe_equal,          .equal,              .equal_equal,            .bang_equal,
                .percent,             .percent_equal,      .period_asterisk,        .caret,
                .caret_equal,         .plus,               .plus_plus,              .plus_equal,
                .plus_percent,        .plus_percent_equal, .plus_pipe,              .plus_pipe_equal,
                .minus,               .minus_equal,        .minus_percent,          .minus_percent_equal,
                .minus_pipe,          .minus_pipe_equal,   .asterisk,               .asterisk_equal,
                .asterisk_asterisk,   .asterisk_percent,   .asterisk_percent_equal, .asterisk_pipe,
                .asterisk_pipe_equal, .slash,              .slash_equal,            .ampersand,
                .ampersand_equal,     .question_mark,      .tilde,
            } ++ &[_]Tag{
                .angle_bracket_left,                          .equal_angle_bracket_right,
                .angle_bracket_left_equal,                    .angle_bracket_angle_bracket_left,
                .angle_bracket_angle_bracket_left_equal,      .angle_bracket_angle_bracket_left_pipe,
                .angle_bracket_angle_bracket_left_pipe_equal, .angle_bracket_right,
                .angle_bracket_right_equal,                   .angle_bracket_angle_bracket_right,
                .angle_bracket_angle_bracket_right_equal,
            } },
            .{ .style = style.cyan, .tags = &[_]Tag{
                .keyword_defer,     .keyword_async,
                .keyword_await,     .keyword_export,
                .keyword_extern,    .keyword_resume,
                .keyword_suspend,   .keyword_errdefer,
                .keyword_nosuspend, .keyword_unreachable,
            } },
            .{ .style = style.red, .tags = &[_]Tag{
                .builtin, .keyword_align,
            } },
            .{ .style = style.light_purple, .tags = &[_]Tag{
                .keyword_asm,      .keyword_catch,
                .keyword_inline,   .keyword_noalias,
                .keyword_noinline, .keyword_callconv,
            } },
            .{ .style = style.redwine, .tags = &.{
                .keyword_enum,   .keyword_packed,
                .keyword_opaque, .keyword_struct,
            } },
            .{ .style = style.white, .tags = &.{
                .keyword_fn,             .keyword_if,
                .keyword_or,             .keyword_for,
                .keyword_and,            .keyword_pub,
                .keyword_try,            .keyword_else,
                .keyword_test,           .keyword_error,
                .keyword_while,          .keyword_union,
                .keyword_switch,         .keyword_orelse,
                .keyword_anytype,        .keyword_anyframe,
                .keyword_volatile,       .keyword_allowzero,
                .keyword_addrspace,      .keyword_linksection,
                .keyword_usingnamespace,
            } },
            .{ .style = style.yellow, .tags = &.{
                .keyword_var,         .keyword_break,
                .keyword_const,       .keyword_return,
                .keyword_comptime,    .keyword_continue,
                .keyword_threadlocal,
            } },
        };
        pub fn highlight(s_tag: Tag) ?[]const u8 {
            for (mappings) |mapping| {
                for (mapping.tags) |t_tag| {
                    if (s_tag == t_tag) {
                        return mapping.style;
                    }
                }
            }
            return null;
        }
        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .invalid => "invalid bytes",
                .identifier => "an identifier",
                .string_literal, .multiline_string_literal_line => "a string literal",
                .char_literal => "a character literal",
                .eof => "EOF",
                .builtin => "a builtin function",
                .number_literal => "a number literal",
                .doc_comment, .container_doc_comment => "a document comment",
                else => unreachable,
            };
        }
    };
};
pub const Tokenizer = struct {
    buf: [:0]const u8,
    buf_pos: usize,
    pending_invalid_token: ?Token,
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
    /// This is a workaround to the fact that the tokenizer can queue up
    /// 'pending_invalid_token's when parsing literals, which means that we need
    /// to scan from the start of the current line to find a matching tag -% just
    /// in case it was an invalid character generated during literal
    /// tokenization. Ideally this processing of this would be pushed to the AST
    /// parser or another later stage, both to give more useful error messages
    /// with that extra context and in order to be able to remove this
    /// workaround.
    pub fn findTagAtCurrentIndex(tokenizer: *Tokenizer, tag: Token.Tag) Token {
        if (tag == .invalid) {
            const target_index = tokenizer.buf_pos;
            var starting_index = target_index;
            while (starting_index > 0) {
                if (tokenizer.buf[starting_index] == '\n') {
                    break;
                }
                starting_index -%= 1;
            }
            tokenizer.buf_pos = starting_index;
            while (tokenizer.buf_pos <= target_index or tokenizer.pending_invalid_token != null) {
                const result = tokenizer.next();
                if (result.loc.start == target_index and result.tag == tag) {
                    return result;
                }
            }
            unreachable;
        } else {
            return tokenizer.next();
        }
    }
    pub fn next(tokenizer: *Tokenizer) Token {
        @setRuntimeSafety(false);
        if (tokenizer.pending_invalid_token) |token| {
            tokenizer.pending_invalid_token = null;
            return token;
        }
        var state: State = .start;
        var result = Token{
            .tag = .eof,
            .loc = .{
                .start = tokenizer.buf_pos,
                .finish = undefined,
            },
        };
        var seen_escape_digits: usize = undefined;
        var remaining_code_units: usize = undefined;
        while (true) : (tokenizer.buf_pos +%= 1) {
            const c = tokenizer.buf[tokenizer.buf_pos];
            switch (state) {
                .start => switch (c) {
                    0 => {
                        if (tokenizer.buf_pos != tokenizer.buf.len) {
                            result.tag = .invalid;
                            result.loc.start = tokenizer.buf_pos;
                            tokenizer.buf_pos +%= 1;
                            result.loc.finish = tokenizer.buf_pos;
                            return result;
                        }
                        break;
                    },
                    ' ', '\n', '\t', '\r' => {
                        result.loc.start = tokenizer.buf_pos +% 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    ')' => {
                        result.tag = .r_paren;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '[' => {
                        result.tag = .l_bracket;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    ']' => {
                        result.tag = .r_bracket;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    ';' => {
                        result.tag = .semicolon;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    ',' => {
                        result.tag = .comma;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '?' => {
                        result.tag = .question_mark;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    ':' => {
                        result.tag = .colon;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '}' => {
                        result.tag = .r_brace;
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '~' => {
                        result.tag = .tilde;
                        tokenizer.buf_pos +%= 1;
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
                        result.loc.finish = tokenizer.buf_pos;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '*' => {
                        result.tag = .asterisk_asterisk;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '+' => {
                        result.tag = .plus_plus;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        if (Token.getKeyword(tokenizer.buf[result.loc.start..tokenizer.buf_pos])) |tag| {
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    0 => {
                        if (tokenizer.buf_pos == tokenizer.buf.len) {
                            result.tag = .invalid;
                            break;
                        } else {
                            tokenizer.checkLiteralCharacter();
                        }
                    },
                    '\n' => {
                        result.tag = .invalid;
                        break;
                    },
                    else => tokenizer.checkLiteralCharacter(),
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
                        seen_escape_digits +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        result.tag = .invalid;
                        break;
                    },
                },
                .char_literal_unicode => switch (c) {
                    0x80...0xbf => {
                        remaining_code_units -%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '\t' => {},
                    else => tokenizer.checkLiteralCharacter(),
                },
                .bang => switch (c) {
                    '=' => {
                        result.tag = .bang_equal;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '|' => {
                        result.tag = .pipe_pipe;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '>' => {
                        result.tag = .equal_angle_bracket_right;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    '=' => {
                        result.tag = .minus_equal;
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
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
                        tokenizer.buf_pos +%= 1;
                        break;
                    },
                    else => {
                        result.tag = .slash;
                        break;
                    },
                },
                .line_comment_start => switch (c) {
                    0 => {
                        if (tokenizer.buf_pos != tokenizer.buf.len) {
                            result.tag = .invalid;
                            tokenizer.buf_pos +%= 1;
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
                        result.loc.start = tokenizer.buf_pos +% 1;
                    },
                    '\t' => state = .line_comment,
                    else => {
                        state = .line_comment;
                        tokenizer.checkLiteralCharacter();
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
                    '\t' => {
                        state = .doc_comment;
                        result.tag = .doc_comment;
                    },
                    else => {
                        state = .doc_comment;
                        result.tag = .doc_comment;
                        tokenizer.checkLiteralCharacter();
                    },
                },
                .line_comment => switch (c) {
                    0 => {
                        if (tokenizer.buf_pos != tokenizer.buf.len) {
                            result.tag = .invalid;
                            tokenizer.buf_pos +%= 1;
                        }
                        break;
                    },
                    '\n' => {
                        state = .start;
                        result.loc.start = tokenizer.buf_pos +% 1;
                    },
                    '\t' => {},
                    else => tokenizer.checkLiteralCharacter(),
                },
                .doc_comment => switch (c) {
                    0, '\n' => break,
                    '\t' => {},
                    else => tokenizer.checkLiteralCharacter(),
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
                        tokenizer.buf_pos -%= 1;
                        state = .int;
                    },
                },
                .int_period => switch (c) {
                    '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {
                        state = .float;
                    },
                    'e', 'E', 'p', 'P' => state = .float_exponent,
                    else => {
                        tokenizer.buf_pos -%= 1;
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
                        tokenizer.buf_pos -%= 1;
                        state = .float;
                    },
                },
            }
        }
        if (result.tag == .eof) {
            if (tokenizer.pending_invalid_token) |token| {
                tokenizer.pending_invalid_token = null;
                return token;
            }
            result.loc.start = tokenizer.buf_pos;
        }
        result.loc.finish = tokenizer.buf_pos;
        return result;
    }
    fn checkLiteralCharacter(tokenizer: *Tokenizer) void {
        if (tokenizer.pending_invalid_token != null) return;
        const invalid_length = tokenizer.getInvalidCharacterLength();
        if (invalid_length == 0) return;
        tokenizer.pending_invalid_token = .{
            .tag = .invalid,
            .loc = .{
                .start = tokenizer.buf_pos,
                .finish = tokenizer.buf_pos +% invalid_length,
            },
        };
    }
    fn getInvalidCharacterLength(tokenizer: *Tokenizer) u8 {
        const c0 = tokenizer.buf[tokenizer.buf_pos];
        if (ascii.isASCII(c0)) {
            if (c0 == '\r') {
                if (tokenizer.buf_pos +% 1 < tokenizer.buf.len and
                    tokenizer.buf[tokenizer.buf_pos +% 1] == '\n')
                {
                    return 0;
                } else {
                    return 1;
                }
            } else if (ascii.isControl(c0)) {
                return 1;
            }
            return 0;
        } else {
            const length = utf8.byteSequenceLength(c0) catch return 1;
            if (tokenizer.buf_pos +% length > tokenizer.buf.len) {
                return @intCast(u3, tokenizer.buf.len -% tokenizer.buf_pos);
            }
            const bytes = tokenizer.buf[tokenizer.buf_pos .. tokenizer.buf_pos +% length];
            switch (length) {
                2 => {
                    const value = utf8.decode2(bytes) catch return length;
                    if (value == 0x85) {
                        return length;
                    }
                },
                3 => {
                    const value = utf8.decode3(bytes) catch return length;
                    if (value == 0x2028) {
                        return length;
                    }
                    if (value == 0x2029) {
                        return length;
                    }
                },
                4 => {
                    _ = utf8.decode4(bytes) catch return length;
                },
                else => unreachable,
            }
            tokenizer.buf_pos +%= length -% 1;
            return 0;
        }
    }
};
