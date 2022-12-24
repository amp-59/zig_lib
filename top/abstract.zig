const zig = @import("./zig.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const parse = @import("./parse.zig");
const builtin = @import("./builtin.zig");
const tokenizer = @import("./tokenizer.zig");

const Token = zig.Token;
const AllocatorN: type = zig.Allocator.Node;
const AllocatorE: type = zig.Allocator.Error;
const AllocatorX: type = zig.Allocator.Extra;
const AllocatorS: type = zig.Allocator.State;

pub const ProtoSyntaxTree = struct {
    source: zig.SourceArray,
    tokens: zig.TokenArray,
    nodes: zig.ProtoNodeArray,
    extras: zig.ProtoExtraArray,
    errors: zig.ProtoErrorArray,
    pub fn convert(
        proto_ast: *ProtoSyntaxTree,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
    ) !SyntaxTree {
        return .{
            .source = proto_ast.source,
            .tokens = proto_ast.tokens,
            .nodes = try proto_ast.nodes.dynamic(allocator_n, zig.NodeArray),
            .extras = try proto_ast.extras.dynamic(allocator_x, zig.ExtraArray),
            .errors = try proto_ast.errors.dynamic(allocator_e, zig.ErrorArray),
        };
    }
};

pub const SyntaxTree = struct {
    source: zig.SourceArray,
    tokens: zig.TokenArray,
    nodes: zig.NodeArray,
    extras: zig.ExtraArray,
    errors: zig.ErrorArray,

    pub const Location = struct {
        line: usize,
        column: usize,
        line_start: usize,
        line_end: usize,
    };
    pub fn deinit(ast: *SyntaxTree, allocator_n: *AllocatorN, allocator_e: *AllocatorE, allocator_x: *AllocatorX) void {
        ast.extras.deinit(allocator_x);
        ast.errors.deinit(allocator_e);
        ast.nodes.deinit(allocator_n);
        ast.tokens.deinit(allocator_n);
        ast.source.deinit(allocator_n);
        ast.* = undefined;
    }
    pub fn init(
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        array_n: zig.SourceArray,
    ) !SyntaxTree {
        const source: [:0]const u8 = array_n.readAllWithSentinel(0);
        const tokens: zig.TokenArray = try tokenizer.Tokenizer.init(allocator_n, source);
        var nodes: zig.ProtoNodeArray = zig.ProtoNodeArray.init(allocator_n);
        try nodes.increment(allocator_n, tokens.len() * 8);
        var ret: ProtoSyntaxTree = .{
            .source = array_n,
            .tokens = tokens,
            .nodes = nodes,
            .errors = zig.ProtoErrorArray.init(allocator_e),
            .extras = zig.ProtoExtraArray.init(allocator_x),
        };
        var array_s: zig.StateArray = zig.StateArray.init(allocator_s);
        defer {
            array_s.deinit(allocator_s);
            allocator_s.discard();
        }
        try ret.nodes.increment(allocator_n, ret.tokens.len() * 8);
        ret.nodes.define(1);
        const root_members: parse.Members = try parse.parseContainerMembers(
            &ret,
            allocator_n,
            allocator_e,
            allocator_x,
            allocator_s,
            &array_s,
        );
        const root_decls: zig.AstNode.SubRange = try root_members.toSpan(&ret, allocator_x);
        if (ret.tokens.readOneAhead().tag != .eof) {
            try parse.warnExpected(&ret, allocator_e, .eof);
        }
        ret.nodes.referOneAt(allocator_n.*, 0).* = .{
            .tag = .root,
            .main_token = 0,
            .data = .{ .lhs = root_decls.start, .rhs = root_decls.end },
        };
        return ret.convert(allocator_n, allocator_e, allocator_x);
    }
    pub fn errorOffset(ast: SyntaxTree, parse_error: zig.AstError) u32 {
        return if (parse_error.token_is_prev)
            @intCast(zig.Index, ast.tokenSlice(parse_error.token).len)
        else
            0;
    }
    pub fn tokenLocation(ast: SyntaxTree, start_offset: zig.Offset, token_index: zig.Index) Location {
        var loc: Location = .{
            .line = 0,
            .column = 0,
            .line_start = start_offset,
            .line_end = ast.source.len(),
        };
        const token_start: zig.Index = ast.tokens.items(.start)[token_index];
        for (ast.source.readManyAt(start_offset)) |c, i| {
            if (i + start_offset == token_start) {
                loc.line_end = i + start_offset;
                while (loc.line_end < ast.source.len() and ast.source.readOneAt(loc.line_end) != '\n') {
                    loc.line_end += 1;
                }
                return loc;
            }
            if (c == '\n') {
                loc.line += 1;
                loc.column = 0;
                loc.line_start = i + 1;
            } else {
                loc.column += 1;
            }
        }
        return loc;
    }
    pub fn tokenSlice(ast: SyntaxTree, token_index: zig.Index) []const u8 {
        const token_tag = ast.tokenTag(token_index);
        if (token_tag.lexeme()) |lexeme| {
            return lexeme;
        }
        var tk: tokenizer.Tokenizer = .{
            .buffer = ast.source.readAllWithSentinel(0),
            .index = ast.tokenStart(token_index),
            .pending_invalid_token = null,
        };
        const token = tk.next();
        builtin.assert(token.tag == token_tag);
        return ast.source.readAll()[token.loc.start..token.loc.end];
    }
    pub fn extraData(ast: SyntaxTree, index: usize, comptime T: type) T {
        var result: T = undefined;
        inline for (meta.resolve(@typeInfo(T)).fields) |field, i| {
            builtin.static.assert(field.field_type == zig.Index);
            @field(result, field.name) = ast.extraDataAt(index + i);
        }
        return result;
    }
    pub fn rootDecls(ast: SyntaxTree) []const zig.Index {
        return ast.extras.readAll(zig.Index)[ast.nodeLHS(0)..ast.nodeRHS(0)];
    }
    pub fn renderError(ast: SyntaxTree, parse_error: zig.AstError, stream: anytype) !void {
        switch (parse_error.tag) {
            .asterisk_after_ptr_deref => {
                return stream.writeAll("'.*' cannot be followed by '*'. Are you missing a space?");
            },
            .chained_comparison_operators => {
                return stream.writeAll("comparison operators cannot be chained");
            },
            .decl_between_fields => {
                return stream.writeAll("declarations are not allowed between container fields");
            },
            .expected_block => {
                return stream.print("expected block or field, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_block_or_assignment => {
                return stream.print("expected block or assignment, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_block_or_expr => {
                return stream.print("expected block or expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_block_or_field => {
                return stream.print("expected block or field, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_container_members => {
                return stream.print("expected test, comptime, var decl, or container field, found '{s}'", .{
                    ast.tokenTag(parse_error.token).symbol(),
                });
            },
            .expected_expr => {
                return stream.print("expected expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_expr_or_assignment => {
                return stream.print("expected expression or assignment, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_fn => {
                return stream.print("expected function, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_inlinable => {
                return stream.print("expected 'while' or 'for', found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_labelable => {
                return stream.print("expected 'while', 'for', 'inline', or '{{', found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_param_list => {
                return stream.print("expected parameter list, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_prefix_expr => {
                return stream.print("expected prefix expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_primary_type_expr => {
                return stream.print("expected primary type expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_pub_item => {
                return stream.writeAll("expected function or variable declaration after pub");
            },
            .expected_return_type => {
                return stream.print("expected return type expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_semi_or_else => {
                return stream.writeAll("expected ';' or 'else' after statement");
            },
            .expected_semi_or_lbrace => {
                return stream.writeAll("expected ';' or block after function prototype");
            },
            .expected_statement => {
                return stream.print("expected statement, found '{s}'", .{
                    ast.tokenTag(parse_error.token).symbol(),
                });
            },
            .expected_suffix_op => {
                return stream.print("expected pointer dereference, optional unwrap, or field access, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_type_expr => {
                return stream.print("expected type expression, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_var_decl => {
                return stream.print("expected variable declaration, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_var_decl_or_fn => {
                return stream.print("expected variable declaration or function, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_loop_payload => {
                return stream.print("expected loop payload, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .expected_container => {
                return stream.print("expected a struct, enum or union, found '{s}'", .{
                    ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev)).symbol(),
                });
            },
            .extern_fn_body => {
                return stream.writeAll("extern functions have no body");
            },
            .extra_addrspace_qualifier => {
                return stream.writeAll("extra addrspace qualifier");
            },
            .extra_align_qualifier => {
                return stream.writeAll("extra align qualifier");
            },
            .extra_allowzero_qualifier => {
                return stream.writeAll("extra allowzero qualifier");
            },
            .extra_const_qualifier => {
                return stream.writeAll("extra const qualifier");
            },
            .extra_volatile_qualifier => {
                return stream.writeAll("extra volatile qualifier");
            },
            .ptr_mod_on_array_child_type => {
                return stream.print("pointer modifier '{s}' not allowed on array child type", .{
                    ast.tokenTag(parse_error.token).symbol(),
                });
            },
            .invalid_bit_range => {
                return stream.writeAll("bit range not allowed on slices and arrays");
            },
            .same_line_doc_comment => {
                return stream.writeAll("same line documentation comment");
            },
            .unattached_doc_comment => {
                return stream.writeAll("unattached documentation comment");
            },
            .test_doc_comment => {
                return stream.writeAll("documentation comments cannot be attached to tests");
            },
            .comptime_doc_comment => {
                return stream.writeAll("documentation comments cannot be attached to comptime blocks");
            },
            .varargs_nonfinal => {
                return stream.writeAll("function prototype has parameter after varargs");
            },
            .expected_continue_expr => {
                return stream.writeAll("expected ':' before while continue expression");
            },
            .expected_semi_after_decl => {
                return stream.writeAll("expected ';' after declaration");
            },
            .expected_semi_after_stmt => {
                return stream.writeAll("expected ';' after statement");
            },
            .expected_comma_after_field => {
                return stream.writeAll("expected ',' after field");
            },
            .expected_comma_after_arg => {
                return stream.writeAll("expected ',' after argument");
            },
            .expected_comma_after_param => {
                return stream.writeAll("expected ',' after parameter");
            },
            .expected_comma_after_initializer => {
                return stream.writeAll("expected ',' after initializer");
            },
            .expected_comma_after_switch_prong => {
                return stream.writeAll("expected ',' after switch prong");
            },
            .expected_initializer => {
                return stream.writeAll("expected field initializer");
            },
            .mismatched_binary_op_whitespace => {
                return stream.print("binary operator `{s}` has whitespace on one side, but not the other.", .{ast.tokenTag(parse_error.token).lexeme().?});
            },
            .invalid_ampersand_ampersand => {
                return stream.writeAll("ambiguous use of '&&'; use 'and' for logical AND, or change whitespace to ' & &' for bitwise AND");
            },
            .c_style_container => {
                return stream.print("'{s} {s}' is invalid", .{
                    parse_error.extra.expected_tag.symbol(), ast.tokenSlice(parse_error.token),
                });
            },
            .zig_style_container => {
                return stream.print("to declare a container do 'const {s} = {s}'", .{
                    ast.tokenSlice(parse_error.token), parse_error.extra.expected_tag.symbol(),
                });
            },
            .previous_field => {
                return stream.writeAll("field before declarations here");
            },
            .next_field => {
                return stream.writeAll("field after declarations here");
            },
            .expected_var_const => {
                return stream.writeAll("expected 'var' or 'const' before variable declaration");
            },
            .wrong_equal_var_decl => {
                return stream.writeAll("variable initialized with '==' instead of '='");
            },
            .expected_token => {
                const found_tag = ast.tokenTag(parse_error.token + @boolToInt(parse_error.token_is_prev));
                const expected_symbol = parse_error.extra.expected_tag.symbol();
                switch (found_tag) {
                    .invalid => return stream.print("expected '{s}', found invalid bytes", .{
                        expected_symbol,
                    }),
                    else => return stream.print("expected '{s}', found '{s}'", .{
                        expected_symbol, found_tag.symbol(),
                    }),
                }
            },
        }
    }
    fn nodeData(ast: SyntaxTree, index: zig.Index) zig.AstNode.Data {
        return ast.nodes.readOneAt(index).data;
    }
    fn nodeTag(ast: SyntaxTree, index: zig.Index) zig.AstNode.Tag {
        return ast.nodes.readOneAt(index).tag;
    }
    fn nodeMainToken(ast: SyntaxTree, index: zig.Index) zig.Index {
        return ast.nodes.readOneAt(index).main_token;
    }
    fn tokenStart(ast: SyntaxTree, index: zig.Index) zig.Index {
        return ast.tokens.readOneAt(index).start;
    }
    fn tokenTag(ast: SyntaxTree, index: zig.Index) zig.Token.Tag {
        return ast.tokens.readOneAt(index).tag;
    }
    fn nodeLHS(ast: SyntaxTree, index: zig.Index) zig.Index {
        return ast.nodes.readOneAt(index).data.lhs;
    }
    fn nodeRHS(ast: SyntaxTree, index: zig.Index) zig.Index {
        return ast.nodes.readOneAt(index).data.rhs;
    }
    fn extraDataAt(ast: SyntaxTree, index: usize) zig.Index {
        return ast.extras.readOneAt(zig.Index, .{ .count = index });
    }
    pub fn firstToken(ast: SyntaxTree, node: zig.Index) zig.Index {
        var end_offset: zig.Index = 0;
        var n = node;
        while (true) switch (ast.nodeTag(n)) {
            .root => return 0,
            .test_decl,
            .@"errdefer",
            .@"defer",
            .bool_not,
            .negation,
            .bit_not,
            .negation_wrap,
            .address_of,
            .@"try",
            .@"await",
            .optional_type,
            .@"switch",
            .switch_comma,
            .if_simple,
            .@"if",
            .@"suspend",
            .@"resume",
            .@"continue",
            .@"break",
            .@"return",
            .anyframe_type,
            .identifier,
            .anyframe_literal,
            .char_literal,
            .number_literal,
            .unreachable_literal,
            .string_literal,
            .multiline_string_literal,
            .grouped_expression,
            .builtin_call_two,
            .builtin_call_two_comma,
            .builtin_call,
            .builtin_call_comma,
            .error_set_decl,
            .@"comptime",
            .@"nosuspend",
            .asm_simple,
            .@"asm",
            .array_type,
            .array_type_sentinel,
            .error_value,
            => return ast.nodeMainToken(n) - end_offset,
            .array_init_dot,
            .array_init_dot_comma,
            .array_init_dot_two,
            .array_init_dot_two_comma,
            .struct_init_dot,
            .struct_init_dot_comma,
            .struct_init_dot_two,
            .struct_init_dot_two_comma,
            .enum_literal,
            => return ast.nodeMainToken(n) - 1 - end_offset,
            .@"catch",
            .field_access,
            .unwrap_optional,
            .equal_equal,
            .bang_equal,
            .less_than,
            .greater_than,
            .less_or_equal,
            .greater_or_equal,
            .assign_mul,
            .assign_div,
            .assign_mod,
            .assign_add,
            .assign_sub,
            .assign_shl,
            .assign_shl_sat,
            .assign_shr,
            .assign_bit_and,
            .assign_bit_xor,
            .assign_bit_or,
            .assign_mul_wrap,
            .assign_add_wrap,
            .assign_sub_wrap,
            .assign_mul_sat,
            .assign_add_sat,
            .assign_sub_sat,
            .assign,
            .merge_error_sets,
            .mul,
            .div,
            .mod,
            .array_mult,
            .mul_wrap,
            .mul_sat,
            .add,
            .sub,
            .array_cat,
            .add_wrap,
            .sub_wrap,
            .add_sat,
            .sub_sat,
            .shl,
            .shl_sat,
            .shr,
            .bit_and,
            .bit_xor,
            .bit_or,
            .@"orelse",
            .bool_and,
            .bool_or,
            .slice_open,
            .slice,
            .slice_sentinel,
            .deref,
            .array_access,
            .array_init_one,
            .array_init_one_comma,
            .array_init,
            .array_init_comma,
            .struct_init_one,
            .struct_init_one_comma,
            .struct_init,
            .struct_init_comma,
            .call_one,
            .call_one_comma,
            .call,
            .call_comma,
            .switch_range,
            .error_union,
            => n = ast.nodeLHS(n),
            .fn_decl,
            .fn_proto_simple,
            .fn_proto_multi,
            .fn_proto_one,
            .fn_proto,
            => {
                var i = ast.nodeMainToken(n); // fn token
                while (i > 0) {
                    i -= 1;
                    switch (ast.tokenTag(i)) {
                        .keyword_extern,
                        .keyword_export,
                        .keyword_pub,
                        .keyword_inline,
                        .keyword_noinline,
                        .string_literal,
                        => continue,
                        else => return i + 1 - end_offset,
                    }
                }
                return i - end_offset;
            },
            .@"usingnamespace" => {
                const main_token = ast.nodeMainToken(n);
                if (main_token > 0 and ast.tokenTag(main_token - 1) == .keyword_pub) {
                    end_offset += 1;
                }
                return main_token - end_offset;
            },
            .async_call_one,
            .async_call_one_comma,
            .async_call,
            .async_call_comma,
            => {
                end_offset += 1; // async token
                n = ast.nodeLHS(n);
            },
            .container_field_init,
            .container_field_align,
            .container_field,
            => {
                const name_token = ast.nodeMainToken(n);
                if (ast.tokenTag(name_token + 1) != .colon) return name_token - end_offset;
                if (name_token > 0 and ast.tokenTag(name_token - 1) == .keyword_comptime) {
                    end_offset += 1;
                }
                return name_token - end_offset;
            },
            .global_var_decl,
            .local_var_decl,
            .simple_var_decl,
            .aligned_var_decl,
            => {
                var i = ast.nodeMainToken(n); // mut token
                while (i > 0) {
                    i -= 1;
                    switch (ast.tokenTag(i)) {
                        .keyword_extern,
                        .keyword_export,
                        .keyword_comptime,
                        .keyword_pub,
                        .keyword_threadlocal,
                        .string_literal,
                        => continue,
                        else => return i + 1 - end_offset,
                    }
                }
                return i - end_offset;
            },
            .block,
            .block_semicolon,
            .block_two,
            .block_two_semicolon,
            => {
                // Look for a label.
                const lbrace = ast.nodeMainToken(n);
                if (ast.tokenTag(lbrace - 1) == .colon and
                    ast.tokenTag(lbrace - 2) == .identifier)
                {
                    end_offset += 2;
                }
                return lbrace - end_offset;
            },
            .container_decl,
            .container_decl_trailing,
            .container_decl_two,
            .container_decl_two_trailing,
            .container_decl_arg,
            .container_decl_arg_trailing,
            .tagged_union,
            .tagged_union_trailing,
            .tagged_union_two,
            .tagged_union_two_trailing,
            .tagged_union_enum_tag,
            .tagged_union_enum_tag_trailing,
            => {
                const main_token = ast.nodeMainToken(n);
                switch (ast.tokenTag(main_token - 1)) {
                    .keyword_packed, .keyword_extern => end_offset += 1,
                    else => {},
                }
                return main_token - end_offset;
            },
            .ptr_type_aligned,
            .ptr_type_sentinel,
            .ptr_type,
            .ptr_type_bit_range,
            => {
                const main_token = ast.nodeMainToken(n);
                return switch (ast.tokenTag(main_token)) {
                    .asterisk,
                    .asterisk_asterisk,
                    => switch (ast.tokenTag(main_token - 1)) {
                        .l_bracket => main_token - 1,
                        else => main_token,
                    },
                    .l_bracket => main_token,
                    else => unreachable,
                } - end_offset;
            },
            .switch_case_one => {
                if (ast.nodeLHS(n) == 0) {
                    return ast.nodeMainToken(n) - 1 - end_offset; // else token
                } else {
                    n = ast.nodeLHS(n);
                }
            },
            .switch_case_inline_one => {
                if (ast.nodeLHS(n) == 0) {
                    return ast.nodeMainToken(n) - 2 - end_offset; // else token
                } else {
                    return ast.firstToken(ast.nodeLHS(n)) - 1;
                }
            },
            .switch_case => {
                const extra: zig.AstNode.SubRange =
                    ast.extraData(ast.nodeLHS(n), zig.AstNode.SubRange);
                builtin.assert(extra.end - extra.start > 0);
                n = ast.extraDataAt(extra.start);
            },
            .switch_case_inline => {
                const extra: zig.AstNode.SubRange =
                    ast.extraData(ast.nodeLHS(n), zig.AstNode.SubRange);
                builtin.assert(extra.end - extra.start > 0);
                return ast.firstToken(ast.extraDataAt(extra.start)) - 1;
            },
            .asm_output, .asm_input => {
                builtin.assert(ast.tokenTag(ast.nodeMainToken(n) - 1) == .l_bracket);
                return ast.nodeMainToken(n) - 1 - end_offset;
            },
            .while_simple,
            .while_cont,
            .@"while",
            .for_simple,
            .@"for",
            => {
                // Look for a label and inline.
                const main_token = ast.nodeMainToken(n);
                var result = main_token;
                if (ast.tokenTag(result - 1) == .keyword_inline) {
                    result -= 1;
                }
                if (ast.tokenTag(result - 1) == .colon) {
                    result -= 2;
                }
                return result - end_offset;
            },
        };
    }
    pub fn lastToken(ast: SyntaxTree, node: zig.Index) zig.Index {
        var n = node;
        var end_offset: zig.Index = 0;
        while (true) switch (ast.nodeTag(n)) {
            .root => return @intCast(zig.Index, ast.tokens.len() - 1),
            .@"usingnamespace",
            .bool_not,
            .negation,
            .bit_not,
            .negation_wrap,
            .address_of,
            .@"try",
            .@"await",
            .optional_type,
            .@"resume",
            .@"nosuspend",
            .@"comptime",
            => n = ast.nodeLHS(n),
            .test_decl,
            .@"errdefer",
            .@"defer",
            .@"catch",
            .equal_equal,
            .bang_equal,
            .less_than,
            .greater_than,
            .less_or_equal,
            .greater_or_equal,
            .assign_mul,
            .assign_div,
            .assign_mod,
            .assign_add,
            .assign_sub,
            .assign_shl,
            .assign_shl_sat,
            .assign_shr,
            .assign_bit_and,
            .assign_bit_xor,
            .assign_bit_or,
            .assign_mul_wrap,
            .assign_add_wrap,
            .assign_sub_wrap,
            .assign_mul_sat,
            .assign_add_sat,
            .assign_sub_sat,
            .assign,
            .merge_error_sets,
            .mul,
            .div,
            .mod,
            .array_mult,
            .mul_wrap,
            .mul_sat,
            .add,
            .sub,
            .array_cat,
            .add_wrap,
            .sub_wrap,
            .add_sat,
            .sub_sat,
            .shl,
            .shl_sat,
            .shr,
            .bit_and,
            .bit_xor,
            .bit_or,
            .@"orelse",
            .bool_and,
            .bool_or,
            .anyframe_type,
            .error_union,
            .if_simple,
            .while_simple,
            .for_simple,
            .fn_proto_simple,
            .fn_proto_multi,
            .ptr_type_aligned,
            .ptr_type_sentinel,
            .ptr_type,
            .ptr_type_bit_range,
            .array_type,
            .switch_case_one,
            .switch_case_inline_one,
            .switch_case,
            .switch_case_inline,
            .switch_range,
            => n = ast.nodeRHS(n),
            .field_access,
            .unwrap_optional,
            .grouped_expression,
            .multiline_string_literal,
            .error_set_decl,
            .asm_simple,
            .asm_output,
            .asm_input,
            .error_value,
            => return ast.nodeRHS(n) + end_offset,
            .anyframe_literal,
            .char_literal,
            .number_literal,
            .unreachable_literal,
            .identifier,
            .deref,
            .enum_literal,
            .string_literal,
            => return ast.nodeMainToken(n) + end_offset,
            .@"return" => if (ast.nodeLHS(n) != 0) {
                n = ast.nodeLHS(n);
            } else {
                return ast.nodeMainToken(n) + end_offset;
            },
            .call, .async_call => {
                end_offset += 1; // for the rparen
                const params = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                if (params.end - params.start == 0) {
                    return ast.nodeMainToken(n) + end_offset;
                }
                n = ast.extraDataAt(params.end - 1); // last parameter
            },
            .tagged_union_enum_tag => {
                const members = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                if (members.end - members.start == 0) {
                    end_offset += 4; // for the rparen + rparen + lbrace + rbrace
                    n = ast.nodeLHS(n);
                } else {
                    end_offset += 1; // for the rbrace
                    n = ast.extraDataAt(members.end - 1); // last parameter
                }
            },
            .call_comma,
            .async_call_comma,
            .tagged_union_enum_tag_trailing,
            => {
                end_offset += 2; // for the comma/semicolon + rparen/rbrace
                const params = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                builtin.assert(params.end > params.start);
                n = ast.extraDataAt(params.end - 1); // last parameter
            },
            .@"switch" => {
                const cases = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                if (cases.end - cases.start == 0) {
                    end_offset += 3; // rparen, lbrace, rbrace
                    n = ast.nodeLHS(n); // condition expression
                } else {
                    end_offset += 1; // for the rbrace
                    n = ast.extraDataAt(cases.end - 1); // last case
                }
            },
            .container_decl_arg => {
                const members = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                if (members.end - members.start == 0) {
                    end_offset += 3; // for the rparen + lbrace + rbrace
                    n = ast.nodeLHS(n);
                } else {
                    end_offset += 1; // for the rbrace
                    n = ast.extraDataAt(members.end - 1); // last parameter
                }
            },
            .@"asm" => {
                const extra: zig.AstNode.Asm =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.Asm);
                return extra.rparen + end_offset;
            },
            .array_init,
            .struct_init,
            => {
                const elements = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                builtin.assert(elements.end - elements.start > 0);
                end_offset += 1; // for the rbrace
                n = ast.extraDataAt(elements.end - 1); // last element
            },
            .array_init_comma,
            .struct_init_comma,
            .container_decl_arg_trailing,
            .switch_comma,
            => {
                const members = ast.extraData(ast.nodeRHS(n), zig.AstNode.SubRange);
                builtin.assert(members.end - members.start > 0);
                end_offset += 2; // for the comma + rbrace
                n = ast.extraDataAt(members.end - 1); // last parameter
            },
            .array_init_dot,
            .struct_init_dot,
            .block,
            .container_decl,
            .tagged_union,
            .builtin_call,
            => {
                builtin.assert(ast.nodeRHS(n) - ast.nodeLHS(n) > 0);
                end_offset += 1; // for the rbrace
                n = ast.extraDataAt(ast.nodeRHS(n) - 1); // last statement
            },
            .array_init_dot_comma,
            .struct_init_dot_comma,
            .block_semicolon,
            .container_decl_trailing,
            .tagged_union_trailing,
            .builtin_call_comma,
            => {
                builtin.assert(ast.nodeRHS(n) - ast.nodeLHS(n) > 0);
                end_offset += 2; // for the comma/semicolon + rbrace/rparen
                n = ast.extraDataAt(ast.nodeRHS(n) - 1); // last member
            },
            .call_one,
            .async_call_one,
            .array_access,
            => {
                end_offset += 1; // for the rparen/rbracket
                if (ast.nodeRHS(n) == 0) {
                    return ast.nodeMainToken(n) + end_offset;
                }
                n = ast.nodeRHS(n);
            },
            .array_init_dot_two,
            .block_two,
            .builtin_call_two,
            .struct_init_dot_two,
            .container_decl_two,
            .tagged_union_two,
            => {
                if (ast.nodeRHS(n) != 0) {
                    end_offset += 1; // for the rparen/rbrace
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    end_offset += 1; // for the rparen/rbrace
                    n = ast.nodeLHS(n);
                } else {
                    switch (ast.nodeTag(n)) {
                        .array_init_dot_two,
                        .block_two,
                        .struct_init_dot_two,
                        => end_offset += 1, // rbrace
                        .builtin_call_two => end_offset += 2, // lparen/lbrace + rparen/rbrace
                        .container_decl_two => {
                            var i: u32 = 2; // lbrace + rbrace
                            while (ast.tokenTag(ast.nodeMainToken(n) + i) == .container_doc_comment) i += 1;
                            end_offset += i;
                        },
                        .tagged_union_two => {
                            var i: u32 = 5; // (enum) {}
                            while (ast.tokenTag(ast.nodeMainToken(n) + i) == .container_doc_comment) i += 1;
                            end_offset += i;
                        },
                        else => unreachable,
                    }
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .array_init_dot_two_comma,
            .builtin_call_two_comma,
            .block_two_semicolon,
            .struct_init_dot_two_comma,
            .container_decl_two_trailing,
            .tagged_union_two_trailing,
            => {
                end_offset += 2; // for the comma/semicolon + rbrace/rparen
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    unreachable;
                }
            },
            .simple_var_decl => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    end_offset += 1; // from mut token to name
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .aligned_var_decl => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    end_offset += 1; // for the rparen
                    n = ast.nodeLHS(n);
                } else {
                    end_offset += 1; // from mut token to name
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .global_var_decl => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else {
                    const extra: zig.AstNode.GlobalVarDecl =
                        ast.extraData(ast.nodeLHS(n), zig.AstNode.GlobalVarDecl);
                    if (extra.section_node != 0) {
                        end_offset += 1; // for the rparen
                        n = extra.section_node;
                    } else if (extra.align_node != 0) {
                        end_offset += 1; // for the rparen
                        n = extra.align_node;
                    } else if (extra.type_node != 0) {
                        n = extra.type_node;
                    } else {
                        end_offset += 1; // from mut token to name
                        return ast.nodeMainToken(n) + end_offset;
                    }
                }
            },
            .local_var_decl => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else {
                    const extra: zig.AstNode.LocalVarDecl =
                        ast.extraData(ast.nodeLHS(n), zig.AstNode.LocalVarDecl);
                    if (extra.align_node != 0) {
                        end_offset += 1; // for the rparen
                        n = extra.align_node;
                    } else if (extra.type_node != 0) {
                        n = extra.type_node;
                    } else {
                        end_offset += 1; // from mut token to name
                        return ast.nodeMainToken(n) + end_offset;
                    }
                }
            },
            .container_field_init => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .container_field_align => {
                if (ast.nodeRHS(n) != 0) {
                    end_offset += 1; // for the rparen
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .container_field => {
                const extra: zig.AstNode.ContainerField =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.ContainerField);
                if (extra.value_expr != 0) {
                    n = extra.value_expr;
                } else if (extra.align_expr != 0) {
                    end_offset += 1; // for the rparen
                    n = extra.align_expr;
                } else if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .array_init_one,
            .struct_init_one,
            => {
                end_offset += 1; // rbrace
                if (ast.nodeRHS(n) == 0) {
                    return ast.nodeMainToken(n) + end_offset;
                } else {
                    n = ast.nodeRHS(n);
                }
            },
            .slice_open,
            .call_one_comma,
            .async_call_one_comma,
            .array_init_one_comma,
            .struct_init_one_comma,
            => {
                end_offset += 2; // ellipsis2 + rbracket, or comma + rparen
                n = ast.nodeRHS(n);
                builtin.assert(n != 0);
            },
            .slice => {
                const extra: zig.AstNode.Slice =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.Slice);
                builtin.assert(extra.end != 0); // should have used slice_open
                end_offset += 1; // rbracket
                n = extra.end;
            },
            .slice_sentinel => {
                const extra: zig.AstNode.SliceSentinel =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.SliceSentinel);
                builtin.assert(extra.sentinel != 0); // should have used slice
                end_offset += 1; // rbracket
                n = extra.sentinel;
            },
            .@"continue" => {
                if (ast.nodeLHS(n) != 0) {
                    return ast.nodeLHS(n) + end_offset;
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .@"break" => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else if (ast.nodeLHS(n) != 0) {
                    return ast.nodeLHS(n) + end_offset;
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .fn_decl => {
                if (ast.nodeRHS(n) != 0) {
                    n = ast.nodeRHS(n);
                } else {
                    n = ast.nodeLHS(n);
                }
            },
            .fn_proto_one => {
                const extra: zig.AstNode.FnProtoOne =
                    ast.extraData(ast.nodeLHS(n), zig.AstNode.FnProtoOne);
                // addrspace, linksection, callconv, align can appear in any order, so we
                // find the last one here.
                var max_node: zig.Index = ast.nodeRHS(n);
                var max_start: zig.Index = ast.tokenStart(ast.nodeMainToken(max_node));
                var max_offset: zig.Index = 0;
                if (extra.align_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.align_expr));
                    if (start > max_start) {
                        max_node = extra.align_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.addrspace_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.addrspace_expr));
                    if (start > max_start) {
                        max_node = extra.addrspace_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.section_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.section_expr));
                    if (start > max_start) {
                        max_node = extra.section_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.callconv_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.callconv_expr));
                    if (start > max_start) {
                        max_node = extra.callconv_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                n = max_node;
                end_offset += max_offset;
            },
            .fn_proto => {
                const extra: zig.AstNode.FnProto =
                    ast.extraData(ast.nodeLHS(n), zig.AstNode.FnProto);
                // addrspace, linksection, callconv, align can appear in any order, so we
                // find the last one here.
                var max_node: zig.Index = ast.nodeRHS(n);
                var max_start: zig.Index = ast.tokenStart(ast.nodeMainToken(max_node));
                var max_offset: zig.Index = 0;
                if (extra.align_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.align_expr));
                    if (start > max_start) {
                        max_node = extra.align_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.addrspace_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.addrspace_expr));
                    if (start > max_start) {
                        max_node = extra.addrspace_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.section_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.section_expr));
                    if (start > max_start) {
                        max_node = extra.section_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                if (extra.callconv_expr != 0) {
                    const start: zig.Index = ast.tokenStart(ast.nodeMainToken(extra.callconv_expr));
                    if (start > max_start) {
                        max_node = extra.callconv_expr;
                        max_start = start;
                        max_offset = 1; // for the rparen
                    }
                }
                n = max_node;
                end_offset += max_offset;
            },
            .while_cont => {
                const extra: zig.AstNode.WhileCont =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.WhileCont);
                builtin.assert(extra.then_expr != 0);
                n = extra.then_expr;
            },
            .@"while" => {
                const extra: zig.AstNode.While =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.While);
                builtin.assert(extra.else_expr != 0);
                n = extra.else_expr;
            },
            .@"if", .@"for" => {
                const extra: zig.AstNode.If =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.If);
                builtin.assert(extra.else_expr != 0);
                n = extra.else_expr;
            },
            .@"suspend" => {
                if (ast.nodeLHS(n) != 0) {
                    n = ast.nodeLHS(n);
                } else {
                    return ast.nodeMainToken(n) + end_offset;
                }
            },
            .array_type_sentinel => {
                const extra: zig.AstNode.ArrayTypeSentinel =
                    ast.extraData(ast.nodeRHS(n), zig.AstNode.ArrayTypeSentinel);
                n = extra.elem_type;
            },
        };
    }
    pub fn tokensOnSameLine(ast: SyntaxTree, token1: zig.Index, token2: zig.Index) bool {
        const source: []const u8 = ast.source.readAll()[ast.tokenStart(token1)..ast.tokenStart(token2)];
        return mem.indexOfFirstEqualOne(u8, '\n', source) == null;
    }
    pub fn getNodeSource(ast: SyntaxTree, node: zig.Index) []const u8 {
        const first_token: zig.Index = ast.firstToken(node);
        const last_token: zig.Index = ast.lastToken(node);
        const start: usize = ast.tokenStart(first_token);
        const end: usize = ast.tokenStart(last_token) + ast.tokenSlice(last_token).len;
        return ast.source.readAll()[start..end];
    }
    pub fn globalVarDecl(ast: SyntaxTree, node: zig.Index) full.VarDecl {
        builtin.assert(ast.nodeTag(node) == .global_var_decl);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.GlobalVarDecl =
            ast.extraData(data.lhs, zig.AstNode.GlobalVarDecl);
        return ast.fullVarDecl(.{
            .type_node = extra.type_node,
            .align_node = extra.align_node,
            .addrspace_node = extra.addrspace_node,
            .section_node = extra.section_node,
            .init_node = data.rhs,
            .mut_token = ast.nodeMainToken(node),
        });
    }
    pub fn localVarDecl(ast: SyntaxTree, node: zig.Index) full.VarDecl {
        builtin.assert(ast.nodeTag(node) == .local_var_decl);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.LocalVarDecl =
            ast.extraData(data.lhs, zig.AstNode.LocalVarDecl);
        return ast.fullVarDecl(.{
            .type_node = extra.type_node,
            .align_node = extra.align_node,
            .addrspace_node = 0,
            .section_node = 0,
            .init_node = data.rhs,
            .mut_token = ast.nodeMainToken(node),
        });
    }
    pub fn simpleVarDecl(ast: SyntaxTree, node: zig.Index) full.VarDecl {
        builtin.assert(ast.nodeTag(node) == .simple_var_decl);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullVarDecl(.{
            .type_node = data.lhs,
            .align_node = 0,
            .addrspace_node = 0,
            .section_node = 0,
            .init_node = data.rhs,
            .mut_token = ast.nodeMainToken(node),
        });
    }
    pub fn alignedVarDecl(ast: SyntaxTree, node: zig.Index) full.VarDecl {
        builtin.assert(ast.nodeTag(node) == .aligned_var_decl);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullVarDecl(.{
            .type_node = 0,
            .align_node = data.lhs,
            .addrspace_node = 0,
            .section_node = 0,
            .init_node = data.rhs,
            .mut_token = ast.nodeMainToken(node),
        });
    }
    pub fn ifSimple(ast: SyntaxTree, node: zig.Index) full.If {
        builtin.assert(ast.nodeTag(node) == .if_simple);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullIf(.{
            .cond_expr = data.lhs,
            .then_expr = data.rhs,
            .else_expr = 0,
            .if_token = ast.nodeMainToken(node),
        });
    }
    pub fn ifFull(ast: SyntaxTree, node: zig.Index) full.If {
        builtin.assert(ast.nodeTag(node) == .@"if");
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.If =
            ast.extraData(data.rhs, zig.AstNode.If);
        return ast.fullIf(.{
            .cond_expr = data.lhs,
            .then_expr = extra.then_expr,
            .else_expr = extra.else_expr,
            .if_token = ast.nodeMainToken(node),
        });
    }
    pub fn containerField(ast: SyntaxTree, node: zig.Index) full.ContainerField {
        builtin.assert(ast.nodeTag(node) == .container_field);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.ContainerField =
            ast.extraData(data.rhs, zig.AstNode.ContainerField);
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerField(.{
            .main_token = main_token,
            .type_expr = data.lhs,
            .value_expr = extra.value_expr,
            .align_expr = extra.align_expr,
            .tuple_like = ast.tokens.items(.tag)[main_token + 1] != .colon,
        });
    }
    pub fn containerFieldInit(ast: SyntaxTree, node: zig.Index) full.ContainerField {
        builtin.assert(ast.nodeTag(node) == .container_field_init);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerField(.{
            .main_token = main_token,
            .type_expr = data.lhs,
            .value_expr = data.rhs,
            .align_expr = 0,
            .tuple_like = ast.tokens.items(.tag)[main_token + 1] != .colon,
        });
    }
    pub fn containerFieldAlign(ast: SyntaxTree, node: zig.Index) full.ContainerField {
        builtin.assert(ast.nodeTag(node) == .container_field_align);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerField(.{
            .main_token = main_token,
            .type_expr = data.lhs,
            .value_expr = 0,
            .align_expr = data.rhs,
            .tuple_like = ast.tokens.items(.tag)[main_token + 1] != .colon,
        });
    }
    pub fn fnProtoSimple(ast: SyntaxTree, buffer: *[1]zig.Index, node: zig.Index) full.FnProto {
        builtin.assert(ast.nodeTag(node) == .fn_proto_simple);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer[0] = data.lhs;
        const params = if (data.lhs == 0) buffer[0..0] else buffer[0..1];
        return ast.fullFnProto(.{
            .proto_node = node,
            .fn_token = ast.nodeMainToken(node),
            .return_type = data.rhs,
            .params = params,
            .align_expr = 0,
            .addrspace_expr = 0,
            .section_expr = 0,
            .callconv_expr = 0,
        });
    }
    pub fn fnProtoMulti(ast: SyntaxTree, node: zig.Index) full.FnProto {
        builtin.assert(ast.nodeTag(node) == .fn_proto_multi);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const params_range = ast.extraData(data.lhs, zig.AstNode.SubRange);
        const params = ast.extras.readAll(zig.Index)[params_range.start..params_range.end];
        return ast.fullFnProto(.{
            .proto_node = node,
            .fn_token = ast.nodeMainToken(node),
            .return_type = data.rhs,
            .params = params,
            .align_expr = 0,
            .addrspace_expr = 0,
            .section_expr = 0,
            .callconv_expr = 0,
        });
    }
    pub fn fnProtoOne(ast: SyntaxTree, buffer: *[1]zig.Index, node: zig.Index) full.FnProto {
        builtin.assert(ast.nodeTag(node) == .fn_proto_one);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.FnProtoOne =
            ast.extraData(data.lhs, zig.AstNode.FnProtoOne);
        buffer[0] = extra.param;
        const params = if (extra.param == 0) buffer[0..0] else buffer[0..1];
        return ast.fullFnProto(.{
            .proto_node = node,
            .fn_token = ast.nodeMainToken(node),
            .return_type = data.rhs,
            .params = params,
            .align_expr = extra.align_expr,
            .addrspace_expr = extra.addrspace_expr,
            .section_expr = extra.section_expr,
            .callconv_expr = extra.callconv_expr,
        });
    }
    pub fn fnProto(ast: SyntaxTree, node: zig.Index) full.FnProto {
        builtin.assert(ast.nodeTag(node) == .fn_proto);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.FnProto =
            ast.extraData(data.lhs, zig.AstNode.FnProto);
        const params = ast.extras.readAll(zig.Index)[extra.params_start..extra.params_end];
        return ast.fullFnProto(.{
            .proto_node = node,
            .fn_token = ast.nodeMainToken(node),
            .return_type = data.rhs,
            .params = params,
            .align_expr = extra.align_expr,
            .addrspace_expr = extra.addrspace_expr,
            .section_expr = extra.section_expr,
            .callconv_expr = extra.callconv_expr,
        });
    }
    pub fn structInitOne(ast: SyntaxTree, buffer: *[1]zig.Index, node: zig.Index) full.StructInit {
        builtin.assert(ast.nodeTag(node) == .struct_init_one or
            ast.nodeTag(node) == .struct_init_one_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer[0] = data.rhs;
        const fields = if (data.rhs == 0) buffer[0..0] else buffer[0..1];
        return ast.fullStructInit(.{
            .lbrace = ast.nodeMainToken(node),
            .fields = fields,
            .type_expr = data.lhs,
        });
    }
    pub fn structInitDotTwo(ast: SyntaxTree, buffer: *[2]zig.Index, node: zig.Index) full.StructInit {
        builtin.assert(ast.nodeTag(node) == .struct_init_dot_two or
            ast.nodeTag(node) == .struct_init_dot_two_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer.* = .{ data.lhs, data.rhs };
        const fields = if (data.rhs != 0)
            buffer[0..2]
        else if (data.lhs != 0)
            buffer[0..1]
        else
            buffer[0..0];
        return ast.fullStructInit(.{
            .lbrace = ast.nodeMainToken(node),
            .fields = fields,
            .type_expr = 0,
        });
    }
    pub fn structInitDot(ast: SyntaxTree, node: zig.Index) full.StructInit {
        builtin.assert(ast.nodeTag(node) == .struct_init_dot or
            ast.nodeTag(node) == .struct_init_dot_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullStructInit(.{
            .lbrace = ast.nodeMainToken(node),
            .fields = ast.extras.readAll(zig.Index)[data.lhs..data.rhs],
            .type_expr = 0,
        });
    }
    pub fn structInit(ast: SyntaxTree, node: zig.Index) full.StructInit {
        builtin.assert(ast.nodeTag(node) == .struct_init or
            ast.nodeTag(node) == .struct_init_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const fields_range = ast.extraData(data.rhs, zig.AstNode.SubRange);
        return ast.fullStructInit(.{
            .lbrace = ast.nodeMainToken(node),
            .fields = ast.extras.readAll(zig.Index)[fields_range.start..fields_range.end],
            .type_expr = data.lhs,
        });
    }
    pub fn arrayInitOne(ast: SyntaxTree, buffer: *[1]zig.Index, node: zig.Index) full.ArrayInit {
        builtin.assert(ast.nodeTag(node) == .array_init_one or
            ast.nodeTag(node) == .array_init_one_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer[0] = data.rhs;
        const elements = if (data.rhs == 0) buffer[0..0] else buffer[0..1];
        return .{
            .ast = .{
                .lbrace = ast.nodeMainToken(node),
                .elements = elements,
                .type_expr = data.lhs,
            },
        };
    }
    pub fn arrayInitDotTwo(ast: SyntaxTree, buffer: *[2]zig.Index, node: zig.Index) full.ArrayInit {
        builtin.assert(ast.nodeTag(node) == .array_init_dot_two or
            ast.nodeTag(node) == .array_init_dot_two_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer.* = .{ data.lhs, data.rhs };
        const elements = if (data.rhs != 0)
            buffer[0..2]
        else if (data.lhs != 0)
            buffer[0..1]
        else
            buffer[0..0];
        return .{
            .ast = .{
                .lbrace = ast.nodeMainToken(node),
                .elements = elements,
                .type_expr = 0,
            },
        };
    }
    pub fn arrayInitDot(ast: SyntaxTree, node: zig.Index) full.ArrayInit {
        builtin.assert(ast.nodeTag(node) == .array_init_dot or
            ast.nodeTag(node) == .array_init_dot_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return .{
            .ast = .{
                .lbrace = ast.nodeMainToken(node),
                .elements = ast.extras.readAll(zig.Index)[data.lhs..data.rhs],
                .type_expr = 0,
            },
        };
    }
    pub fn arrayInit(ast: SyntaxTree, node: zig.Index) full.ArrayInit {
        builtin.assert(ast.nodeTag(node) == .array_init or
            ast.nodeTag(node) == .array_init_comma);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const elem_range = ast.extraData(data.rhs, zig.AstNode.SubRange);
        return .{
            .ast = .{
                .lbrace = ast.nodeMainToken(node),
                .elements = ast.extras.readAll(zig.Index)[elem_range.start..elem_range.end],
                .type_expr = data.lhs,
            },
        };
    }
    pub fn arrayType(ast: SyntaxTree, node: zig.Index) full.ArrayType {
        builtin.assert(ast.nodeTag(node) == .array_type);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return .{
            .ast = .{
                .lbracket = ast.nodeMainToken(node),
                .elem_count = data.lhs,
                .sentinel = 0,
                .elem_type = data.rhs,
            },
        };
    }
    pub fn arrayTypeSentinel(ast: SyntaxTree, node: zig.Index) full.ArrayType {
        builtin.assert(ast.nodeTag(node) == .array_type_sentinel);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.ArrayTypeSentinel =
            ast.extraData(data.rhs, zig.AstNode.ArrayTypeSentinel);
        builtin.assert(extra.sentinel != 0);
        return .{
            .ast = .{
                .lbracket = ast.nodeMainToken(node),
                .elem_count = data.lhs,
                .sentinel = extra.sentinel,
                .elem_type = extra.elem_type,
            },
        };
    }
    pub fn ptrTypeAligned(ast: SyntaxTree, node: zig.Index) full.PtrType {
        builtin.assert(ast.nodeTag(node) == .ptr_type_aligned);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullPtrType(.{
            .main_token = ast.nodeMainToken(node),
            .align_node = data.lhs,
            .addrspace_node = 0,
            .sentinel = 0,
            .bit_range_start = 0,
            .bit_range_end = 0,
            .child_type = data.rhs,
        });
    }
    pub fn ptrTypeSentinel(ast: SyntaxTree, node: zig.Index) full.PtrType {
        builtin.assert(ast.nodeTag(node) == .ptr_type_sentinel);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullPtrType(.{
            .main_token = ast.nodeMainToken(node),
            .align_node = 0,
            .addrspace_node = 0,
            .sentinel = data.lhs,
            .bit_range_start = 0,
            .bit_range_end = 0,
            .child_type = data.rhs,
        });
    }
    pub fn ptrType(ast: SyntaxTree, node: zig.Index) full.PtrType {
        builtin.assert(ast.nodeTag(node) == .ptr_type);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.PtrType =
            ast.extraData(data.lhs, zig.AstNode.PtrType);
        return ast.fullPtrType(.{
            .main_token = ast.nodeMainToken(node),
            .align_node = extra.align_node,
            .addrspace_node = extra.addrspace_node,
            .sentinel = extra.sentinel,
            .bit_range_start = 0,
            .bit_range_end = 0,
            .child_type = data.rhs,
        });
    }
    pub fn ptrTypeBitRange(ast: SyntaxTree, node: zig.Index) full.PtrType {
        builtin.assert(ast.nodeTag(node) == .ptr_type_bit_range);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.PtrTypeBitRange =
            ast.extraData(data.lhs, zig.AstNode.PtrTypeBitRange);
        return ast.fullPtrType(.{
            .main_token = ast.nodeMainToken(node),
            .align_node = extra.align_node,
            .addrspace_node = extra.addrspace_node,
            .sentinel = extra.sentinel,
            .bit_range_start = extra.bit_range_start,
            .bit_range_end = extra.bit_range_end,
            .child_type = data.rhs,
        });
    }
    pub fn sliceOpen(ast: SyntaxTree, node: zig.Index) full.Slice {
        builtin.assert(ast.nodeTag(node) == .slice_open);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return .{
            .ast = .{
                .sliced = data.lhs,
                .lbracket = ast.nodeMainToken(node),
                .start = data.rhs,
                .end = 0,
                .sentinel = 0,
            },
        };
    }
    pub fn slice(ast: SyntaxTree, node: zig.Index) full.Slice {
        builtin.assert(ast.nodeTag(node) == .slice);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.Slice =
            ast.extraData(data.rhs, zig.AstNode.Slice);
        return .{
            .ast = .{
                .sliced = data.lhs,
                .lbracket = ast.nodeMainToken(node),
                .start = extra.start,
                .end = extra.end,
                .sentinel = 0,
            },
        };
    }
    pub fn sliceSentinel(ast: SyntaxTree, node: zig.Index) full.Slice {
        builtin.assert(ast.nodeTag(node) == .slice_sentinel);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.SliceSentinel =
            ast.extraData(data.rhs, zig.AstNode.SliceSentinel);
        return .{
            .ast = .{
                .sliced = data.lhs,
                .lbracket = ast.nodeMainToken(node),
                .start = extra.start,
                .end = extra.end,
                .sentinel = extra.sentinel,
            },
        };
    }
    pub fn containerDeclTwo(ast: SyntaxTree, buffer: *[2]zig.Index, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .container_decl_two or
            ast.nodeTag(node) == .container_decl_two_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer.* = .{ data.lhs, data.rhs };
        const members = if (data.rhs != 0)
            buffer[0..2]
        else if (data.lhs != 0)
            buffer[0..1]
        else
            buffer[0..0];
        return ast.fullContainerDecl(.{
            .main_token = ast.nodeMainToken(node),
            .enum_token = null,
            .members = members,
            .arg = 0,
        });
    }
    pub fn containerDecl(ast: SyntaxTree, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .container_decl or
            ast.nodeTag(node) == .container_decl_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullContainerDecl(.{
            .main_token = ast.nodeMainToken(node),
            .enum_token = null,
            .members = ast.extras.readAll(zig.Index)[data.lhs..data.rhs],
            .arg = 0,
        });
    }
    pub fn containerDeclArg(ast: SyntaxTree, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .container_decl_arg or
            ast.nodeTag(node) == .container_decl_arg_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const members_range = ast.extraData(data.rhs, zig.AstNode.SubRange);
        return ast.fullContainerDecl(.{
            .main_token = ast.nodeMainToken(node),
            .enum_token = null,
            .members = ast.extras.readAll(zig.Index)[members_range.start..members_range.end],
            .arg = data.lhs,
        });
    }
    pub fn containerDeclRoot(ast: SyntaxTree) full.ContainerDecl {
        return .{
            .layout_token = null,
            .ast = .{
                .main_token = undefined,
                .enum_token = null,
                .members = ast.rootDecls(),
                .arg = 0,
            },
        };
    }
    pub fn taggedUnionTwo(ast: SyntaxTree, buffer: *[2]zig.Index, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .tagged_union_two or
            ast.nodeTag(node) == .tagged_union_two_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer.* = .{ data.lhs, data.rhs };
        const members = if (data.rhs != 0)
            buffer[0..2]
        else if (data.lhs != 0)
            buffer[0..1]
        else
            buffer[0..0];
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerDecl(.{
            .main_token = main_token,
            .enum_token = main_token + 2, // union lparen enum
            .members = members,
            .arg = 0,
        });
    }
    pub fn taggedUnion(ast: SyntaxTree, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .tagged_union or
            ast.nodeTag(node) == .tagged_union_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerDecl(.{
            .main_token = main_token,
            .enum_token = main_token + 2, // union lparen enum
            .members = ast.extras.readAll(zig.Index)[data.lhs..data.rhs],
            .arg = 0,
        });
    }
    pub fn taggedUnionEnumTag(ast: SyntaxTree, node: zig.Index) full.ContainerDecl {
        builtin.assert(ast.nodeTag(node) == .tagged_union_enum_tag or
            ast.nodeTag(node) == .tagged_union_enum_tag_trailing);
        const data: zig.AstNode.Data = ast.nodeData(node);
        const members_range = ast.extraData(data.rhs, zig.AstNode.SubRange);
        const main_token = ast.nodeMainToken(node);
        return ast.fullContainerDecl(.{
            .main_token = main_token,
            .enum_token = main_token + 2, // union lparen enum
            .members = ast.extras.readAll(zig.Index)[members_range.start..members_range.end],
            .arg = data.lhs,
        });
    }
    pub fn switchCaseOne(ast: SyntaxTree, node: zig.Index) full.SwitchCase {
        const data: *zig.AstNode.Data = &ast.nodes.referOneAt(node).data;
        const values: *[1]zig.Index = &data.lhs;
        return ast.fullSwitchCase(.{
            .values = if (data.lhs == 0) values[0..0] else values[0..1],
            .arrow_token = ast.nodeMainToken(node),
            .target_expr = data.rhs,
        }, node);
    }
    pub fn switchCase(ast: SyntaxTree, node: zig.Index) full.SwitchCase {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.SubRange =
            ast.extraData(data.lhs, zig.AstNode.SubRange);
        return ast.fullSwitchCase(.{
            .values = ast.extras.readAll(zig.Index)[extra.start..extra.end],
            .arrow_token = ast.nodeMainToken(node),
            .target_expr = data.rhs,
        }, node);
    }
    pub fn asmSimple(ast: SyntaxTree, node: zig.Index) full.Asm {
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullAsm(.{
            .asm_token = ast.nodeMainToken(node),
            .template = data.lhs,
            .items = &.{},
            .rparen = data.rhs,
        });
    }
    pub fn asmFull(ast: SyntaxTree, node: zig.Index) full.Asm {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.Asm =
            ast.extraData(data.rhs, zig.AstNode.Asm);
        return ast.fullAsm(.{
            .asm_token = ast.nodeMainToken(node),
            .template = data.lhs,
            .items = ast.extras.readAll(zig.Index)[extra.items_start..extra.items_end],
            .rparen = extra.rparen,
        });
    }
    pub fn whileSimple(ast: SyntaxTree, node: zig.Index) full.While {
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullWhile(.{
            .while_token = ast.nodeMainToken(node),
            .cond_expr = data.lhs,
            .cont_expr = 0,
            .then_expr = data.rhs,
            .else_expr = 0,
        });
    }
    pub fn whileCont(ast: SyntaxTree, node: zig.Index) full.While {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.WhileCont =
            ast.extraData(data.rhs, zig.AstNode.WhileCont);
        return ast.fullWhile(.{
            .while_token = ast.nodeMainToken(node),
            .cond_expr = data.lhs,
            .cont_expr = extra.cont_expr,
            .then_expr = extra.then_expr,
            .else_expr = 0,
        });
    }
    pub fn whileFull(ast: SyntaxTree, node: zig.Index) full.While {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.While =
            ast.extraData(data.rhs, zig.AstNode.While);
        return ast.fullWhile(.{
            .while_token = ast.nodeMainToken(node),
            .cond_expr = data.lhs,
            .cont_expr = extra.cont_expr,
            .then_expr = extra.then_expr,
            .else_expr = extra.else_expr,
        });
    }
    pub fn forSimple(ast: SyntaxTree, node: zig.Index) full.While {
        const data: zig.AstNode.Data = ast.nodeData(node);
        return ast.fullWhile(.{
            .while_token = ast.nodeMainToken(node),
            .cond_expr = data.lhs,
            .cont_expr = 0,
            .then_expr = data.rhs,
            .else_expr = 0,
        });
    }
    pub fn forFull(ast: SyntaxTree, node: zig.Index) full.While {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.If =
            ast.extraData(data.rhs, zig.AstNode.If);
        return ast.fullWhile(.{
            .while_token = ast.nodeMainToken(node),
            .cond_expr = data.lhs,
            .cont_expr = 0,
            .then_expr = extra.then_expr,
            .else_expr = extra.else_expr,
        });
    }
    pub fn callOne(ast: SyntaxTree, buffer: *[1]zig.Index, node: zig.Index) full.Call {
        const data: zig.AstNode.Data = ast.nodeData(node);
        buffer.* = .{data.rhs};
        const params: []const zig.Index = if (data.rhs != 0) buffer[0..1] else buffer[0..0];
        return ast.fullCall(.{
            .lparen = ast.nodeMainToken(node),
            .fn_expr = data.lhs,
            .params = params,
        });
    }
    pub fn callFull(ast: SyntaxTree, node: zig.Index) full.Call {
        const data: zig.AstNode.Data = ast.nodeData(node);
        const extra: zig.AstNode.SubRange =
            ast.extraData(data.rhs, zig.AstNode.SubRange);
        return ast.fullCall(.{
            .lparen = ast.nodeMainToken(node),
            .fn_expr = data.lhs,
            .params = ast.extras.readAll(zig.Index)[extra.start..extra.end],
        });
    }
    fn fullVarDecl(ast: SyntaxTree, info: full.VarDecl.Components) full.VarDecl {
        var result: full.VarDecl = .{
            .ast = info,
            .visib_token = null,
            .extern_export_token = null,
            .lib_name = null,
            .threadlocal_token = null,
            .comptime_token = null,
        };
        var i = info.mut_token;
        while (i > 0) {
            i -= 1;
            switch (ast.tokenTag(i)) {
                .keyword_extern, .keyword_export => result.extern_export_token = i,
                .keyword_comptime => result.comptime_token = i,
                .keyword_pub => result.visib_token = i,
                .keyword_threadlocal => result.threadlocal_token = i,
                .string_literal => result.lib_name = i,
                else => break,
            }
        }
        return result;
    }
    fn fullIf(ast: SyntaxTree, info: full.If.Components) full.If {
        var result: full.If = .{
            .ast = info,
            .payload_token = null,
            .error_token = null,
            .else_token = undefined,
        };
        // if (cond_expr) |x|
        //              ^ ^
        const payload_pipe = ast.lastToken(info.cond_expr) + 2;
        if (ast.tokenTag(payload_pipe) == .pipe) {
            result.payload_token = payload_pipe + 1;
        }
        if (info.else_expr != 0) {
            // then_expr else |x|
            //           ^    ^
            result.else_token = ast.lastToken(info.then_expr) + 1;
            if (ast.tokenTag(result.else_token + 1) == .pipe) {
                result.error_token = result.else_token + 2;
            }
        }
        return result;
    }
    fn fullContainerField(ast: SyntaxTree, info: full.ContainerField.Components) full.ContainerField {
        var result: full.ContainerField = .{
            .ast = info,
            .comptime_token = null,
        };
        if (ast.tokenTag(info.main_token) == .keyword_comptime) {
            // comptime type = init,
            // ^
            result.comptime_token = info.main_token;
        } else if (info.main_token > 0 and ast.tokenTag(info.main_token - 1) == .keyword_comptime) {
            // comptime name: type = init,
            // ^
            result.comptime_token = info.main_token - 1;
        }
        return result;
    }
    fn fullFnProto(ast: SyntaxTree, info: full.FnProto.Components) full.FnProto {
        var result: full.FnProto = .{
            .ast = info,
            .visib_token = null,
            .extern_export_inline_token = null,
            .lib_name = null,
            .name_token = null,
            .lparen = undefined,
        };
        var i = info.fn_token;
        while (i > 0) {
            i -= 1;
            switch (ast.tokenTag(i)) {
                .keyword_extern,
                .keyword_export,
                .keyword_inline,
                .keyword_noinline,
                => result.extern_export_inline_token = i,
                .keyword_pub => result.visib_token = i,
                .string_literal => result.lib_name = i,
                else => break,
            }
        }
        const after_fn_token = info.fn_token + 1;
        if (ast.tokenTag(after_fn_token) == .identifier) {
            result.name_token = after_fn_token;
            result.lparen = after_fn_token + 1;
        } else {
            result.lparen = after_fn_token;
        }
        builtin.assert(ast.tokenTag(result.lparen) == .l_paren);
        return result;
    }
    fn fullStructInit(ast: SyntaxTree, info: full.StructInit.Components) full.StructInit {
        _ = ast;
        var result: full.StructInit = .{
            .ast = info,
        };
        return result;
    }
    fn fullPtrType(ast: SyntaxTree, info: full.PtrType.Components) full.PtrType {
        const Size = builtin.Type.Pointer.Size;
        const size: Size = switch (ast.tokenTag(info.main_token)) {
            .asterisk,
            .asterisk_asterisk,
            => switch (ast.tokenTag(info.main_token + 1)) {
                .r_bracket, .colon => .Many,
                .identifier => if (ast.tokenTag(info.main_token - 1) == .l_bracket) Size.C else .One,
                else => .One,
            },
            .l_bracket => Size.Slice,
            else => unreachable,
        };
        var result: full.PtrType = .{
            .size = size,
            .allowzero_token = null,
            .const_token = null,
            .volatile_token = null,
            .ast = info,
        };
        // We need to be careful that we don't iterate over any sub-expressions
        // here while looking for modifiers as that could result in false
        // positives. Therefore, start after a sentinel if there is one and
        // skip over any align node and bit range nodes.
        var i = if (info.sentinel != 0) ast.lastToken(info.sentinel) + 1 else info.main_token;
        const end = ast.lastToken(info.child_type);
        while (i < end) : (i += 1) {
            switch (ast.tokenTag(i)) {
                .keyword_allowzero => result.allowzero_token = i,
                .keyword_const => result.const_token = i,
                .keyword_volatile => result.volatile_token = i,
                .keyword_align => {
                    builtin.assert(info.align_node != 0);
                    if (info.bit_range_end != 0) {
                        builtin.assert(info.bit_range_start != 0);
                        i = ast.lastToken(info.bit_range_end) + 1;
                    } else {
                        i = ast.lastToken(info.align_node) + 1;
                    }
                },
                else => {},
            }
        }
        return result;
    }
    fn fullContainerDecl(ast: SyntaxTree, info: full.ContainerDecl.Components) full.ContainerDecl {
        var result: full.ContainerDecl = .{
            .ast = info,
            .layout_token = null,
        };
        switch (ast.tokenTag(info.main_token - 1)) {
            .keyword_extern, .keyword_packed => result.layout_token = info.main_token - 1,
            else => {},
        }
        return result;
    }
    fn fullSwitchCase(
        ast: SyntaxTree,
        info: full.SwitchCase.Components,
        node: zig.Index,
    ) full.SwitchCase {
        var result: full.SwitchCase = .{
            .ast = info,
            .payload_token = null,
            .inline_token = null,
        };
        if (ast.tokenTag(info.arrow_token + 1) == .pipe) {
            result.payload_token = info.arrow_token + 2;
        }
        switch (ast.nodeTag(node)) {
            .switch_case_inline, .switch_case_inline_one => result.inline_token = ast.firstToken(node),
            else => {},
        }
        return result;
    }
    fn fullAsm(ast: SyntaxTree, info: full.Asm.Components) full.Asm {
        var result: full.Asm = .{
            .ast = info,
            .volatile_token = null,
            .inputs = &.{},
            .outputs = &.{},
            .first_clobber = null,
        };
        if (ast.tokenTag(info.asm_token + 1) == .keyword_volatile) {
            result.volatile_token = info.asm_token + 1;
        }
        const outputs_end: usize = for (info.items) |item, i| {
            switch (ast.nodeTag(item)) {
                .asm_output => continue,
                else => break i,
            }
        } else info.items.len;
        result.outputs = info.items[0..outputs_end];
        result.inputs = info.items[outputs_end..];
        if (info.items.len == 0) {
            // asm ("foo" ::: "a", "b");
            const template_token = ast.lastToken(info.template);
            if (ast.tokenTag(template_token + 1) == .colon and
                ast.tokenTag(template_token + 2) == .colon and
                ast.tokenTag(template_token + 3) == .colon and
                ast.tokenTag(template_token + 4) == .string_literal)
            {
                result.first_clobber = template_token + 4;
            }
        } else if (result.inputs.len != 0) {
            // asm ("foo" :: [_] "" (y) : "a", "b");
            const last_input = result.inputs[result.inputs.len - 1];
            const rparen = ast.lastToken(last_input);
            var i = rparen + 1;
            // Allow a (useless) comma right after the closing parenthesis.
            if (ast.tokenTag(i) == .comma) i += 1;
            if (ast.tokenTag(i) == .colon and
                ast.tokenTag(i + 1) == .string_literal)
            {
                result.first_clobber = i + 1;
            }
        } else {
            // asm ("foo" : [_] "" (x) :: "a", "b");
            const last_output = result.outputs[result.outputs.len - 1];
            const rparen = ast.lastToken(last_output);
            var i = rparen + 1;
            // Allow a (useless) comma right after the closing parenthesis.
            if (ast.tokenTag(i) == .comma) i += 1;
            if (ast.tokenTag(i) == .colon and
                ast.tokenTag(i + 1) == .colon and
                ast.tokenTag(i + 2) == .string_literal)
            {
                result.first_clobber = i + 2;
            }
        }
        return result;
    }
    fn fullWhile(ast: SyntaxTree, info: full.While.Components) full.While {
        var result: full.While = .{
            .ast = info,
            .inline_token = null,
            .label_token = null,
            .payload_token = null,
            .else_token = undefined,
            .error_token = null,
        };
        var tok_i = info.while_token - 1;
        if (ast.tokenTag(tok_i) == .keyword_inline) {
            result.inline_token = tok_i;
            tok_i -= 1;
        }
        if (ast.tokenTag(tok_i) == .colon and
            ast.tokenTag(tok_i - 1) == .identifier)
        {
            result.label_token = tok_i - 1;
        }
        const last_cond_token = ast.lastToken(info.cond_expr);
        if (ast.tokenTag(last_cond_token + 2) == .pipe) {
            result.payload_token = last_cond_token + 3;
        }
        if (info.else_expr != 0) {
            // then_expr else |x|
            //           ^    ^
            result.else_token = ast.lastToken(info.then_expr) + 1;
            if (ast.tokenTag(result.else_token + 1) == .pipe) {
                result.error_token = result.else_token + 2;
            }
        }
        return result;
    }
    fn fullCall(ast: SyntaxTree, info: full.Call.Components) full.Call {
        var result: full.Call = .{
            .ast = info,
            .async_token = null,
        };
        const maybe_async_token = ast.lastToken(info.fn_expr) - 1;
        if (ast.tokenTag(maybe_async_token) == .keyword_async) {
            result.async_token = maybe_async_token;
        }
        return result;
    }
    /// Fully assembled AST node information.
    pub const full = struct {
        pub const VarDecl = struct {
            visib_token: ?zig.Index,
            extern_export_token: ?zig.Index,
            lib_name: ?zig.Index,
            threadlocal_token: ?zig.Index,
            comptime_token: ?zig.Index,
            ast: Components,
            pub const Components = struct {
                mut_token: zig.Index,
                type_node: zig.Index,
                align_node: zig.Index,
                addrspace_node: zig.Index,
                section_node: zig.Index,
                init_node: zig.Index,
            };
            pub fn lastToken(var_decl: VarDecl) zig.Index {
                return var_decl.visib_token orelse
                    var_decl.extern_export_token orelse
                    var_decl.threadlocal_token orelse
                    var_decl.comptime_token orelse
                    var_decl.ast.mut_token;
            }
        };
        pub const If = struct {
            /// Points to the first token after the `|`. Will either be an identifier or
            /// a `*` (with an identifier immediately after it).
            payload_token: ?zig.Index,
            /// Points to the identifier after the `|`.
            error_token: ?zig.Index,
            /// Populated only if else_expr != 0.
            else_token: zig.Index,
            ast: Components,
            pub const Components = struct {
                if_token: zig.Index,
                cond_expr: zig.Index,
                then_expr: zig.Index,
                else_expr: zig.Index,
            };
        };
        pub const While = struct {
            ast: Components,
            inline_token: ?zig.Index,
            label_token: ?zig.Index,
            payload_token: ?zig.Index,
            error_token: ?zig.Index,
            /// Populated only if else_expr != 0.
            else_token: zig.Index,
            pub const Components = struct {
                while_token: zig.Index,
                cond_expr: zig.Index,
                cont_expr: zig.Index,
                then_expr: zig.Index,
                else_expr: zig.Index,
            };
        };
        pub const ContainerField = struct {
            comptime_token: ?zig.Index,
            ast: Components,
            pub const Components = struct {
                main_token: zig.Index,
                type_expr: zig.Index,
                value_expr: zig.Index,
                align_expr: zig.Index,
                tuple_like: bool,
            };
            pub fn lastToken(cf: ContainerField) zig.Index {
                return cf.comptime_token orelse cf.ast.main_token;
            }
            pub fn convertToNonTupleLike(cf: *ContainerField, nodes: zig.NodeArray.Slice) void {
                if (!cf.ast.tuple_like) return;
                if (cf.ast.type_expr == 0) return;
                if (nodes.items(.tag)[cf.ast.type_expr] != .identifier) return;
                const ident = nodes.items(.main_token)[cf.ast.type_expr];
                cf.ast.tuple_like = false;
                cf.ast.main_token = ident;
                cf.ast.type_expr = 0;
            }
        };
        pub const FnProto = struct {
            visib_token: ?zig.Index,
            extern_export_inline_token: ?zig.Index,
            lib_name: ?zig.Index,
            name_token: ?zig.Index,
            lparen: zig.Index,
            ast: Components,
            pub const Components = struct {
                proto_node: zig.Index,
                fn_token: zig.Index,
                return_type: zig.Index,
                params: []const zig.Index,
                align_expr: zig.Index,
                addrspace_expr: zig.Index,
                section_expr: zig.Index,
                callconv_expr: zig.Index,
            };
            pub const Param = struct {
                first_doc_comment: ?zig.Index,
                name_token: ?zig.Index,
                comptime_noalias: ?zig.Index,
                anytype_ellipsis3: ?zig.Index,
                type_expr: zig.Index,
            };
            pub fn lastToken(fn_proto: FnProto) zig.Index {
                return fn_proto.visib_token orelse
                    fn_proto.extern_export_inline_token orelse
                    fn_proto.ast.fn_token;
            }
            /// Abstracts over the fact that anytype and ... are not included
            /// in the params slice, since they are simple identifiers and
            /// not sub-expressions.
            pub const Iterator = struct {
                ast: *const SyntaxTree,
                fn_proto: *const FnProto,
                param_i: usize,
                tok_i: zig.Index,
                tok_flag: bool,
                pub fn next(it: *Iterator) ?Param {
                    while (true) {
                        var first_doc_comment: ?zig.Index = null;
                        var comptime_noalias: ?zig.Index = null;
                        var name_token: ?zig.Index = null;
                        if (!it.tok_flag) {
                            if (it.param_i >= it.fn_proto.ast.params.len) {
                                return null;
                            }
                            const param_type = it.fn_proto.ast.params[it.param_i];
                            var tok_i = it.ast.lastToken(param_type) - 1;
                            while (true) : (tok_i -= 1) switch (it.ast.tokenTag(tok_i)) {
                                .colon => continue,
                                .identifier => name_token = tok_i,
                                .doc_comment => first_doc_comment = tok_i,
                                .keyword_comptime, .keyword_noalias => comptime_noalias = tok_i,
                                else => break,
                            };
                            it.param_i += 1;
                            it.tok_i = it.ast.lastToken(param_type) + 1;
                            // Look for anytype and ... params afterwards.
                            if (it.ast.tokenTag(it.tok_i) == .comma) {
                                it.tok_i += 1;
                            }
                            it.tok_flag = true;
                            return Param{
                                .first_doc_comment = first_doc_comment,
                                .comptime_noalias = comptime_noalias,
                                .name_token = name_token,
                                .anytype_ellipsis3 = null,
                                .type_expr = param_type,
                            };
                        }
                        if (it.ast.tokenTag(it.tok_i) == .comma) {
                            it.tok_i += 1;
                        }
                        if (it.ast.tokenTag(it.tok_i) == .r_paren) {
                            return null;
                        }
                        if (it.ast.tokenTag(it.tok_i) == .doc_comment) {
                            first_doc_comment = it.tok_i;
                            while (it.ast.tokenTag(it.tok_i) == .doc_comment) {
                                it.tok_i += 1;
                            }
                        }
                        switch (it.ast.tokenTag(it.tok_i)) {
                            .ellipsis3 => {
                                it.tok_flag = false; // Next iteration should return null.
                                return Param{
                                    .first_doc_comment = first_doc_comment,
                                    .comptime_noalias = null,
                                    .name_token = null,
                                    .anytype_ellipsis3 = it.tok_i,
                                    .type_expr = 0,
                                };
                            },
                            .keyword_noalias, .keyword_comptime => {
                                comptime_noalias = it.tok_i;
                                it.tok_i += 1;
                            },
                            else => {},
                        }
                        if (it.ast.tokenTag(it.tok_i) == .identifier and
                            it.ast.tokenTag(it.tok_i + 1) == .colon)
                        {
                            name_token = it.tok_i;
                            it.tok_i += 2;
                        }
                        if (it.ast.tokenTag(it.tok_i) == .keyword_anytype) {
                            it.tok_i += 1;
                            return Param{
                                .first_doc_comment = first_doc_comment,
                                .comptime_noalias = comptime_noalias,
                                .name_token = name_token,
                                .anytype_ellipsis3 = it.tok_i - 1,
                                .type_expr = 0,
                            };
                        }
                        it.tok_flag = false;
                    }
                }
            };
            pub fn iterate(fn_proto: *const FnProto, ast: *const SyntaxTree) Iterator {
                return .{
                    .ast = ast,
                    .fn_proto = fn_proto,
                    .param_i = 0,
                    .tok_i = fn_proto.lparen + 1,
                    .tok_flag = true,
                };
            }
        };
        pub const StructInit = struct {
            ast: Components,
            pub const Components = struct {
                lbrace: zig.Index,
                fields: []const zig.Index,
                type_expr: zig.Index,
            };
        };
        pub const ArrayInit = struct {
            ast: Components,
            pub const Components = struct {
                lbrace: zig.Index,
                elements: []const zig.Index,
                type_expr: zig.Index,
            };
        };
        pub const ArrayType = struct {
            ast: Components,
            pub const Components = struct {
                lbracket: zig.Index,
                elem_count: zig.Index,
                sentinel: zig.Index,
                elem_type: zig.Index,
            };
        };
        pub const PtrType = struct {
            size: builtin.Type.Pointer.Size,
            allowzero_token: ?zig.Index,
            const_token: ?zig.Index,
            volatile_token: ?zig.Index,
            ast: Components,
            pub const Components = struct {
                main_token: zig.Index,
                align_node: zig.Index,
                addrspace_node: zig.Index,
                sentinel: zig.Index,
                bit_range_start: zig.Index,
                bit_range_end: zig.Index,
                child_type: zig.Index,
            };
        };
        pub const Slice = struct {
            ast: Components,
            pub const Components = struct {
                sliced: zig.Index,
                lbracket: zig.Index,
                start: zig.Index,
                end: zig.Index,
                sentinel: zig.Index,
            };
        };
        pub const ContainerDecl = struct {
            layout_token: ?zig.Index,
            ast: Components,
            pub const Components = struct {
                main_token: zig.Index,
                /// Populated when main_token is Keyword_union.
                enum_token: ?zig.Index,
                members: []const zig.Index,
                arg: zig.Index,
            };
        };
        pub const SwitchCase = struct {
            inline_token: ?zig.Index,
            /// Points to the first token after the `|`. Will either be an identifier or
            /// a `*` (with an identifier immediately after it).
            payload_token: ?zig.Index,
            ast: Components,
            pub const Components = struct {
                /// If empty, this is an else case
                values: []const zig.Index,
                arrow_token: zig.Index,
                target_expr: zig.Index,
            };
        };
        pub const Asm = struct {
            ast: Components,
            volatile_token: ?zig.Index,
            first_clobber: ?zig.Index,
            outputs: []const zig.Index,
            inputs: []const zig.Index,
            pub const Components = struct {
                asm_token: zig.Index,
                template: zig.Index,
                items: []const zig.Index,
                rparen: zig.Index,
            };
        };
        pub const Call = struct {
            ast: Components,
            async_token: ?zig.Index,
            pub const Components = struct {
                lparen: zig.Index,
                fn_expr: zig.Index,
                params: []const zig.Index,
            };
        };
    };
};
