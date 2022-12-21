const mem = @import("./mem.zig");
const zig = @import("./zig.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
const abstract = @import("./abstract.zig");
const tokenizer = @import("./tokenizer.zig");

pub const Parser = struct {
    ast: *abstract.SyntaxTree,
    state: zig.StateArray,

    const SubRange = zig.AstNode.SubRange;
    const SmallSpan = union(enum) {
        zero_or_one: u32,
        multi: SubRange,
    };
    const AllocatorN: type = zig.Allocator.Node;
    const AllocatorE: type = zig.Allocator.Error;
    const AllocatorX: type = zig.Allocator.Extra;
    const AllocatorS: type = zig.Allocator.State;

    const Error = meta.ReturnErrorSet(.{
        AllocatorN.allocate_void,
        AllocatorE.allocate_void,
        AllocatorX.allocate_void,
        AllocatorS.allocate_void,
        error{ParseError},
    });

    const null_node: u32 = 0;

    pub const Members = struct {
        len: usize,
        lhs: u32,
        rhs: u32,
        trailing: bool,

        pub fn toSpan(self: Members, parser: *Parser, allocator_x: *AllocatorX) !zig.AstNode.SubRange {
            if (self.len <= 2) {
                const nodes = [2]u32{ self.lhs, self.rhs };
                return parser.listToSpan(allocator_x, nodes[0..self.len]);
            } else {
                return SubRange{ .start = self.lhs, .end = self.rhs };
            }
        }
    };

    fn listToSpan(parser: *Parser, allocator_x: *AllocatorX, list: []const u32) !SubRange {
        try parser.ast.extras.appendMany(allocator_x, list);
        return SubRange{
            .start = @intCast(u32, parser.ast.extras.len(allocator_x.*) - list.len),
            .end = @intCast(u32, parser.ast.extras.len(allocator_x.*)),
        };
    }

    fn addNode(parser: *Parser, allocator_n: *AllocatorN, elem: zig.AstNode) Error!u32 {
        const result = @intCast(u32, parser.ast.nodes.len(allocator_n.*));
        try parser.ast.nodes.appendOne(allocator_n, elem);
        return result;
    }

    fn setNode(parser: *Parser, allocator_n: *AllocatorN, i: usize, elem: zig.AstNode) u32 {
        parser.ast.nodes.overwriteOneAt(allocator_n.*, i, elem);
        return @intCast(u32, i);
    }

    fn reserveNode(parser: *Parser, allocator_n: *AllocatorN, tag: zig.AstNode.Tag) Error!usize {
        try parser.ast.nodes.increment(allocator_n, 1);
        parser.ast.nodes.define(1);
        parser.ast.nodes.referOneBack().tag = tag;
        return parser.ast.nodes.len(allocator_n.*) - 1;
    }

    fn unreserveNode(parser: *Parser, allocator_n: *AllocatorN, node_index: usize) void {
        if (parser.ast.nodes.len(allocator_n.*) == node_index) {
            // XXX: Maybe trouble
            // Not a thing to holders
            parser.ast.nodes.undefine(1);
            // parser.ast.nodes.shrink(allocator_n, parser.ast.nodes.len(allocator_n.*) - 1) catch unreachable;
        } else {
            // There is zombie node left in the tree, let's make it as inoffensive as possible
            // (sadly there's no no-op node)
            // XXX: Maybe trouble
            parser.ast.nodes.referOneAt(allocator_n.*, node_index).tag = .unreachable_literal;
            parser.ast.nodes.referOneAt(allocator_n.*, node_index).main_token = parser.tokenIndex();
        }
    }

    fn addExtra(parser: *Parser, allocator_x: *AllocatorX, extra: anytype) Error!u32 {
        const result = @intCast(u32, parser.ast.extras.len(allocator_x.*));
        try parser.ast.extras.appendAny(.{}, allocator_x, extra);
        return result;
    }

    pub fn warnExpected(parser: *Parser, allocator_e: *AllocatorE, expected_token: zig.Token.Tag) !void {
        @setCold(true);
        try parser.warnMsg(allocator_e, .{
            .tag = .expected_token,
            .token = parser.tokenIndex(),
            .extra = .{ .expected_tag = expected_token },
        });
    }

    fn warn(parser: *Parser, allocator_e: *AllocatorE, error_tag: zig.AstError.Tag) !void {
        @setCold(true);
        try parser.warnMsg(allocator_e, .{ .tag = error_tag, .token = parser.tokenIndex() });
    }

    fn warnMsg(parser: *Parser, allocator_e: *AllocatorE, msg: zig.AstError) !void {
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
            => if (msg.token != 0 and !parser.ast.tokensOnSameLine(msg.token - 1, msg.token)) {
                var copy = msg;
                copy.token_is_prev = true;
                copy.token -= 1;
                return parser.ast.errors.appendOne(allocator_e, copy);
            },
            else => {},
        }
        try parser.ast.errors.appendOne(allocator_e, msg);
    }

    fn fail(parser: *Parser, allocator_e: *AllocatorE, tag: zig.AstError.Tag) Error {
        @setCold(true);
        return parser.failMsg(allocator_e, .{ .tag = tag, .token = parser.tokenIndex() });
    }

    fn failExpected(parser: *Parser, allocator_e: *AllocatorE, expected_token: zig.Token.Tag) Error {
        @setCold(true);
        return parser.failMsg(allocator_e, .{
            .tag = .expected_token,
            .token = parser.tokenIndex(),
            .extra = .{ .expected_tag = expected_token },
        });
    }

    fn failMsg(parser: *Parser, allocator_e: *AllocatorE, msg: zig.AstError) Error {
        @setCold(true);
        try parser.warnMsg(allocator_e, msg);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!Members {
        const state_top: u64 = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
        var field_state: union(enum) { none, seen, end: u32, err } = .none;

        var last_field: u32 = undefined;

        // Skip container doc comments.
        while (parser.eatToken(.container_doc_comment)) |_| {}

        var trailing = false;
        while (true) {
            const doc_comment = try parser.eatDocComments(allocator_e);

            switch (parser.readTagAhead()) {
                .keyword_test => {
                    if (doc_comment) |some| {
                        try parser.warnMsg(allocator_e, .{ .tag = .test_doc_comment, .token = some });
                    }
                    const test_decl_node = try parser.expectTestDeclRecoverable(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (test_decl_node != 0) {
                        if (field_state == .seen) {
                            field_state = .{ .end = test_decl_node };
                        }
                        try parser.state.appendOne(allocator_s, test_decl_node);
                    }
                    trailing = false;
                },
                .keyword_comptime => switch (parser.relativeTagAhead(1)) {
                    .l_brace => {
                        if (doc_comment) |some| {
                            try parser.warnMsg(allocator_e, .{ .tag = .comptime_doc_comment, .token = some });
                        }
                        const comptime_token = parser.nextToken();
                        const block = parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
                            error.ParseError => blk: {
                                parser.findNextContainerMember();
                                break :blk null_node;
                            },
                            else => |mem_err| return mem_err,
                        };
                        if (block != 0) {
                            const comptime_node = try parser.addNode(allocator_n, .{
                                .tag = .@"comptime",
                                .main_token = comptime_token,
                                .data = .{
                                    .lhs = block,
                                    .rhs = undefined,
                                },
                            });
                            if (field_state == .seen) {
                                field_state = .{ .end = comptime_node };
                            }
                            try parser.state.appendOne(allocator_s, comptime_node);
                        }
                        trailing = false;
                    },
                    else => {
                        parser.ast.tokens.stream(1);
                        const identifier = parser.tokenIndex();
                        defer last_field = identifier;
                        const container_field = parser.expectContainerField(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
                            error.ParseError => {
                                parser.findNextContainerMember();
                                continue;
                            },
                            else => |mem_err| return mem_err,
                        };
                        switch (field_state) {
                            .none => field_state = .seen,
                            .err, .seen => {},
                            .end => |node| {
                                try parser.warnMsg(allocator_e, .{
                                    .tag = .decl_between_fields,
                                    .token = parser.ast.nodes.readOneAt(allocator_n.*, node).main_token,
                                });
                                try parser.warnMsg(allocator_e, .{
                                    .tag = .previous_field,
                                    .is_note = true,
                                    .token = last_field,
                                });
                                try parser.warnMsg(allocator_e, .{
                                    .tag = .next_field,
                                    .is_note = true,
                                    .token = identifier,
                                });
                                // Continue parsing; error will be reported later.
                                field_state = .err;
                            },
                        }
                        try parser.state.appendOne(allocator_s, container_field);
                        switch (parser.readTagAhead()) {
                            .comma => {
                                parser.ast.tokens.stream(1);
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
                        try parser.warn(allocator_e, .expected_comma_after_field);
                        parser.findNextContainerMember();
                    },
                },
                .keyword_pub => {
                    parser.ast.tokens.stream(1);
                    const top_level_decl = try parser.expectTopLevelDeclRecoverable(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (top_level_decl != 0) {
                        if (field_state == .seen) {
                            field_state = .{ .end = top_level_decl };
                        }
                        try parser.state.appendOne(allocator_s, top_level_decl);
                    }
                    trailing = parser.relativeTagBehind(1) == .semicolon;
                },
                .keyword_usingnamespace => {
                    const node = try parser.expectUsingNamespaceRecoverable(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (node != 0) {
                        if (field_state == .seen) {
                            field_state = .{ .end = node };
                        }
                        try parser.state.appendOne(allocator_s, node);
                    }
                    trailing = parser.relativeTagBehind(1) == .semicolon;
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
                    const top_level_decl = try parser.expectTopLevelDeclRecoverable(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (top_level_decl != 0) {
                        if (field_state == .seen) {
                            field_state = .{ .end = top_level_decl };
                        }
                        try parser.state.appendOne(allocator_s, top_level_decl);
                    }
                    trailing = parser.relativeTagBehind(1) == .semicolon;
                },
                .eof, .r_brace => {
                    if (doc_comment) |tok| {
                        try parser.warnMsg(allocator_e, .{
                            .tag = .unattached_doc_comment,
                            .token = tok,
                        });
                    }
                    break;
                },
                else => {
                    const c_container = parser.parseCStyleContainer(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
                        error.ParseError => false,
                        else => |mem_error| return mem_error,
                    };
                    if (c_container) continue;

                    const identifier = parser.tokenIndex();
                    defer last_field = identifier;
                    const container_field = parser.expectContainerField(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
                        error.ParseError => {
                            parser.findNextContainerMember();
                            continue;
                        },
                        else => |mem_error| return mem_error,
                    };
                    switch (field_state) {
                        .none => field_state = .seen,
                        .err, .seen => {},
                        .end => |node| {
                            try parser.warnMsg(allocator_e, .{
                                .tag = .decl_between_fields,
                                .token = parser.ast.nodes.readOneAt(allocator_n.*, node).main_token,
                            });
                            try parser.warnMsg(allocator_e, .{
                                .tag = .previous_field,
                                .is_note = true,
                                .token = last_field,
                            });
                            try parser.warnMsg(allocator_e, .{
                                .tag = .next_field,
                                .is_note = true,
                                .token = identifier,
                            });
                            // Continue parsing; error will be reported later.
                            field_state = .err;
                        },
                    }
                    try parser.state.appendOne(allocator_s, container_field);
                    switch (parser.readTagAhead()) {
                        .comma => {
                            parser.ast.tokens.stream(1);
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
                    try parser.warn(allocator_e, .expected_comma_after_field);
                    parser.findNextContainerMember();
                    continue;
                },
            }
        }

        const items = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
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
                const span = try parser.listToSpan(allocator_x, items);
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
    fn findNextContainerMember(parser: *Parser) void {
        var level: u32 = 0;
        while (true) {
            const tok = parser.nextToken();
            switch (parser.readTagAt(tok)) {
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
                        parser.ast.tokens.unstream(1);
                        return;
                    }
                },
                .identifier => {
                    if (parser.readTagAt(tok + 1) == .comma and level == 0) {
                        parser.ast.tokens.unstream(1);
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
                        parser.ast.tokens.unstream(1);
                        return;
                    }
                    level -= 1;
                },
                .eof => {
                    parser.ast.tokens.unstream(1);
                    return;
                },
                else => {},
            }
        }
    }

    /// Attempts to find the next statement by searching for a semicolon
    fn findNextStmt(parser: *Parser) void {
        var level: u32 = 0;
        while (true) {
            const tok = parser.nextToken();
            switch (parser.readTagAt(tok)) {
                .l_brace => level += 1,
                .r_brace => {
                    if (level == 0) {
                        parser.ast.tokens.unstream(1);
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
                    parser.ast.tokens.unstream(1);
                    return;
                },
                else => {},
            }
        }
    }

    /// TestDecl <- KEYWORD_test (STRINGLITERALSINGLE / IDENTIFIER)? Block
    fn expectTestDecl(parser: *Parser, allocator_n: *AllocatorN, allocator_e: *AllocatorE, allocator_x: *AllocatorX, allocator_s: *AllocatorS) Error!u32 {
        const test_token = parser.assertToken(.keyword_test);
        const name_token = switch (parser.readTagAt(parser.nextToken())) {
            .string_literal, .identifier => parser.tokenIndex() - 1,
            else => blk: {
                parser.ast.tokens.unstream(1);
                break :blk null;
            },
        };
        const block_node = try parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
        if (block_node == 0) return parser.fail(allocator_e, .expected_block);
        return parser.addNode(allocator_n, .{
            .tag = .test_decl,
            .main_token = test_token,
            .data = .{
                .lhs = name_token orelse 0,
                .rhs = block_node,
            },
        });
    }

    fn expectTestDeclRecoverable(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        return parser.expectTestDecl(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
            error.ParseError => {
                parser.findNextContainerMember();
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const extern_export_inline_token = parser.nextToken();
        var is_extern: bool = false;
        var expect_fn: bool = false;
        var expect_var_or_fn: bool = false;
        switch (parser.readTagAt(extern_export_inline_token)) {
            .keyword_extern => {
                _ = parser.eatToken(.string_literal);
                is_extern = true;
                expect_var_or_fn = true;
            },
            .keyword_export => expect_var_or_fn = true,
            .keyword_inline, .keyword_noinline => expect_fn = true,
            else => parser.ast.tokens.unstream(1),
        }
        const fn_proto = try parser.parseFnProto(allocator_n, allocator_e, allocator_x, allocator_s);
        if (fn_proto != 0) {
            switch (parser.readTagAhead()) {
                .semicolon => {
                    parser.ast.tokens.stream(1);
                    return fn_proto;
                },
                .l_brace => {
                    if (is_extern) {
                        try parser.warnMsg(allocator_e, .{ .tag = .extern_fn_body, .token = extern_export_inline_token });
                        return null_node;
                    }
                    const fn_decl_index = try parser.reserveNode(allocator_n, .fn_decl);
                    errdefer parser.unreserveNode(allocator_n, fn_decl_index);

                    const body_block = try parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
                    builtin.assert(body_block != 0);
                    return parser.setNode(allocator_n, fn_decl_index, .{
                        .tag = .fn_decl,
                        .main_token = parser.ast.nodes.readOneAt(allocator_n.*, fn_proto).main_token,
                        .data = .{
                            .lhs = fn_proto,
                            .rhs = body_block,
                        },
                    });
                },
                else => {
                    // Since parseBlock only return error.ParseError on
                    // a missing '}' we can assume this function was
                    // supposed to end here.
                    try parser.warn(allocator_e, .expected_semi_or_lbrace);
                    return null_node;
                },
            }
        }
        if (expect_fn) {
            try parser.warn(allocator_e, .expected_fn);
            return error.ParseError;
        }

        const thread_local_token = parser.eatToken(.keyword_threadlocal);
        const var_decl = try parser.parseVarDecl(allocator_n, allocator_e, allocator_x, allocator_s);
        if (var_decl != 0) {
            try parser.expectSemicolon(allocator_e, .expected_semi_after_decl, false);
            return var_decl;
        }
        if (thread_local_token != null) {
            return parser.fail(allocator_e, .expected_var_decl);
        }
        if (expect_var_or_fn) {
            return parser.fail(allocator_e, .expected_var_decl_or_fn);
        }
        if (parser.readTagAhead() != .keyword_usingnamespace) {
            return parser.fail(allocator_e, .expected_pub_item);
        }
        return parser.expectUsingNamespace(allocator_n, allocator_e, allocator_x, allocator_s);
    }

    fn expectTopLevelDeclRecoverable(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        return parser.expectTopLevelDecl(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
            error.ParseError => {
                parser.findNextContainerMember();
                return null_node;
            },
            else => |mem_error| return mem_error,
        };
    }

    fn expectUsingNamespace(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const usingnamespace_token = parser.assertToken(.keyword_usingnamespace);
        const expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        try parser.expectSemicolon(allocator_e, .expected_semi_after_decl, false);
        return parser.addNode(allocator_n, .{
            .tag = .@"usingnamespace",
            .main_token = usingnamespace_token,
            .data = .{
                .lhs = expr,
                .rhs = undefined,
            },
        });
    }

    fn expectUsingNamespaceRecoverable(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        return parser.expectUsingNamespace(allocator_n, allocator_e, allocator_x, allocator_s) catch |err| switch (err) {
            error.ParseError => {
                parser.findNextContainerMember();
                return null_node;
            },
            else => |mem_error| return mem_error,
        };
    }

    /// FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? AddrSpace? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr
    fn parseFnProto(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const fn_token = parser.eatToken(.keyword_fn) orelse return null_node;

        // We want the fn proto node to be before its children in the array.
        const fn_proto_index = try parser.reserveNode(allocator_n, .fn_proto);
        errdefer parser.unreserveNode(allocator_n, fn_proto_index);

        _ = parser.eatToken(.identifier);
        const params = try parser.parseParamDeclList(allocator_n, allocator_e, allocator_x, allocator_s);
        const align_expr = try parser.parseByteAlign(allocator_n, allocator_e, allocator_x, allocator_s);
        const addrspace_expr = try parser.parseAddrSpace(allocator_n, allocator_e, allocator_x, allocator_s);
        const section_expr = try parser.parseLinkSection(allocator_n, allocator_e, allocator_x, allocator_s);
        const callconv_expr = try parser.parseCallconv(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = parser.eatToken(.bang);

        const return_type_expr = try parser.parseTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (return_type_expr == 0) {
            // most likely the user forgot to specify the return type.
            // Mark return type as invalid and try to continue.
            try parser.warn(allocator_e, .expected_return_type);
        }

        if (align_expr == 0 and section_expr == 0 and callconv_expr == 0 and addrspace_expr == 0) {
            switch (params) {
                .zero_or_one => |param| return parser.setNode(allocator_n, fn_proto_index, .{
                    .tag = .fn_proto_simple,
                    .main_token = fn_token,
                    .data = .{
                        .lhs = param,
                        .rhs = return_type_expr,
                    },
                }),
                .multi => |span| {
                    return parser.setNode(allocator_n, fn_proto_index, .{
                        .tag = .fn_proto_multi,
                        .main_token = fn_token,
                        .data = .{
                            .lhs = try parser.addExtra(allocator_x, SubRange{
                                .start = span.start,
                                .end = span.end,
                            }),
                            .rhs = return_type_expr,
                        },
                    });
                },
            }
        }
        switch (params) {
            .zero_or_one => |param| return parser.setNode(allocator_n, fn_proto_index, .{
                .tag = .fn_proto_one,
                .main_token = fn_token,
                .data = .{
                    .lhs = try parser.addExtra(allocator_x, zig.AstNode.FnProtoOne{
                        .param = param,
                        .align_expr = align_expr,
                        .addrspace_expr = addrspace_expr,
                        .section_expr = section_expr,
                        .callconv_expr = callconv_expr,
                    }),
                    .rhs = return_type_expr,
                },
            }),
            .multi => |span| {
                return parser.setNode(allocator_n, fn_proto_index, .{
                    .tag = .fn_proto,
                    .main_token = fn_token,
                    .data = .{
                        .lhs = try parser.addExtra(allocator_x, zig.AstNode.FnProto{
                            .params_start = span.start,
                            .params_end = span.end,
                            .align_expr = align_expr,
                            .addrspace_expr = addrspace_expr,
                            .section_expr = section_expr,
                            .callconv_expr = callconv_expr,
                        }),
                        .rhs = return_type_expr,
                    },
                });
            },
        }
    }

    /// VarDecl <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? AddrSpace? LinkSection? (EQUAL Expr)? SEMICOLON
    fn parseVarDecl(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const mut_token = parser.eatToken(.keyword_const) orelse
            parser.eatToken(.keyword_var) orelse
            return null_node;

        _ = try parser.expectToken(allocator_e, .identifier);
        const type_node: u32 = if (parser.eatToken(.colon) == null) 0 else try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        const align_node = try parser.parseByteAlign(allocator_n, allocator_e, allocator_x, allocator_s);
        const addrspace_node = try parser.parseAddrSpace(allocator_n, allocator_e, allocator_x, allocator_s);
        const section_node = try parser.parseLinkSection(allocator_n, allocator_e, allocator_x, allocator_s);
        const init_node: u32 = switch (parser.readTagAhead()) {
            .equal_equal => blk: {
                try parser.warn(allocator_e, .wrong_equal_var_decl);
                parser.ast.tokens.stream(1);
                break :blk try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            },
            .equal => blk: {
                parser.ast.tokens.stream(1);
                break :blk try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            },
            else => 0,
        };
        if (section_node == 0 and addrspace_node == 0) {
            if (align_node == 0) {
                return parser.addNode(allocator_n, .{
                    .tag = .simple_var_decl,
                    .main_token = mut_token,
                    .data = .{
                        .lhs = type_node,
                        .rhs = init_node,
                    },
                });
            } else if (type_node == 0) {
                return parser.addNode(allocator_n, .{
                    .tag = .aligned_var_decl,
                    .main_token = mut_token,
                    .data = .{
                        .lhs = align_node,
                        .rhs = init_node,
                    },
                });
            } else {
                return parser.addNode(allocator_n, .{
                    .tag = .local_var_decl,
                    .main_token = mut_token,
                    .data = .{
                        .lhs = try parser.addExtra(allocator_x, zig.AstNode.LocalVarDecl{
                            .type_node = type_node,
                            .align_node = align_node,
                        }),
                        .rhs = init_node,
                    },
                });
            }
        } else {
            return parser.addNode(allocator_n, .{
                .tag = .global_var_decl,
                .main_token = mut_token,
                .data = .{
                    .lhs = try parser.addExtra(allocator_x, zig.AstNode.GlobalVarDecl{
                        .type_node = type_node,
                        .align_node = align_node,
                        .addrspace_node = addrspace_node,
                        .section_node = section_node,
                    }),
                    .rhs = init_node,
                },
            });
        }
    }

    /// ContainerField <- KEYWORD_comptime? IDENTIFIER (COLON TypeExpr ByteAlign?)? (EQUAL Expr)?
    fn expectContainerField(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        var main_token = parser.tokenIndex();
        _ = parser.eatToken(.keyword_comptime);
        const tuple_like = parser.readTagAhead() != .identifier or parser.relativeTagAhead(1) != .colon;
        if (!tuple_like) {
            main_token = parser.assertToken(.identifier);
        }

        var align_expr: u32 = 0;
        var type_expr: u32 = 0;
        if (parser.eatToken(.colon) != null or tuple_like) {
            type_expr = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            align_expr = try parser.parseByteAlign(allocator_n, allocator_e, allocator_x, allocator_s);
        }

        const value_expr: u32 = if (parser.eatToken(.equal) == null) 0 else try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);

        if (align_expr == 0) {
            return parser.addNode(allocator_n, .{
                .tag = .container_field_init,
                .main_token = main_token,
                .data = .{
                    .lhs = type_expr,
                    .rhs = value_expr,
                },
            });
        } else if (value_expr == 0) {
            return parser.addNode(allocator_n, .{
                .tag = .container_field_align,
                .main_token = main_token,
                .data = .{
                    .lhs = type_expr,
                    .rhs = align_expr,
                },
            });
        } else {
            return parser.addNode(allocator_n, .{
                .tag = .container_field,
                .main_token = main_token,
                .data = .{
                    .lhs = type_expr,
                    .rhs = try parser.addExtra(allocator_x, zig.AstNode.ContainerField{
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        allow_defer_var: bool,
    ) Error!u32 {
        const comptime_token = parser.eatToken(.keyword_comptime);

        if (allow_defer_var) {
            const var_decl = try parser.parseVarDecl(allocator_n, allocator_e, allocator_x, allocator_s);
            if (var_decl != 0) {
                try parser.expectSemicolon(allocator_e, .expected_semi_after_decl, true);
                return var_decl;
            }
        }

        if (comptime_token) |token| {
            return parser.addNode(allocator_n, .{
                .tag = .@"comptime",
                .main_token = token,
                .data = .{
                    .lhs = try parser.expectBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s),
                    .rhs = undefined,
                },
            });
        }

        switch (parser.readTagAhead()) {
            .keyword_nosuspend => {
                return parser.addNode(allocator_n, .{
                    .tag = .@"nosuspend",
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = try parser.expectBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s),
                        .rhs = undefined,
                    },
                });
            },
            .keyword_suspend => {
                const token = parser.nextToken();
                const block_expr = try parser.expectBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s);
                return parser.addNode(allocator_n, .{
                    .tag = .@"suspend",
                    .main_token = token,
                    .data = .{
                        .lhs = block_expr,
                        .rhs = undefined,
                    },
                });
            },
            .keyword_defer => if (allow_defer_var) return parser.addNode(allocator_n, .{
                .tag = .@"defer",
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = undefined,
                    .rhs = try parser.expectBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            }),
            .keyword_errdefer => if (allow_defer_var) return parser.addNode(allocator_n, .{
                .tag = .@"errdefer",
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = try parser.parsePayload(allocator_e),
                    .rhs = try parser.expectBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            }),
            .keyword_switch => return parser.expectSwitchExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_if => return parser.expectIfStatement(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_enum, .keyword_struct, .keyword_union => {
                const identifier = parser.tokenIndex() + 1;
                if (try parser.parseCStyleContainer(allocator_n, allocator_e, allocator_x, allocator_s)) {
                    // Return something so that `expectStatement` is happy.
                    return parser.addNode(allocator_n, .{
                        .tag = .identifier,
                        .main_token = identifier,
                        .data = .{
                            .lhs = undefined,
                            .rhs = undefined,
                        },
                    });
                }
            },
            else => {},
        }

        const labeled_statement = try parser.parseLabeledStatement(allocator_n, allocator_e, allocator_x, allocator_s);
        if (labeled_statement != 0) return labeled_statement;

        const assign_expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (assign_expr != 0) {
            try parser.expectSemicolon(allocator_e, .expected_semi_after_stmt, true);
            return assign_expr;
        }

        return null_node;
    }

    fn expectStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        allow_defer_var: bool,
    ) Error!u32 {
        const statement = try parser.parseStatement(allocator_n, allocator_e, allocator_x, allocator_s, allow_defer_var);
        if (statement == 0) {
            return parser.fail(allocator_e, .expected_statement);
        }
        return statement;
    }

    /// If a parse error occurs, reports an error, but then finds the next statement
    /// and returns that one instead. If a parse error occurs but there is no following
    /// statement, returns 0.
    fn expectStatementRecoverable(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        while (true) {
            return parser.expectStatement(allocator_n, allocator_e, allocator_x, allocator_s, true) catch |err| switch (err) {
                error.ParseError => {
                    parser.findNextStmt(); // Try to skip to the next statement.
                    switch (parser.readTagAhead()) {
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const if_token = parser.assertToken(.keyword_if);
        _ = try parser.expectToken(allocator_e, .l_paren);
        const condition = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.parsePtrPayload(allocator_e);

        // TODO propose to change the syntax so that semicolons are always required
        // inside if statements, even if there is an `else`.
        var else_required = false;
        const then_expr = blk: {
            const block_expr = try parser.parseBlockExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (block_expr != 0) break :blk block_expr;
            const assign_expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (assign_expr == 0) {
                return parser.fail(allocator_e, .expected_block_or_assignment);
            }
            if (parser.eatToken(.semicolon)) |_| {
                return parser.addNode(allocator_n, .{
                    .tag = .if_simple,
                    .main_token = if_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = assign_expr,
                    },
                });
            }
            else_required = true;
            break :blk assign_expr;
        };
        _ = parser.eatToken(.keyword_else) orelse {
            if (else_required) {
                try parser.warn(allocator_e, .expected_semi_or_else);
            }
            return parser.addNode(allocator_n, .{
                .tag = .if_simple,
                .main_token = if_token,
                .data = .{
                    .lhs = condition,
                    .rhs = then_expr,
                },
            });
        };
        _ = try parser.parsePayload(allocator_e);
        const else_expr = try parser.expectStatement(allocator_n, allocator_e, allocator_x, allocator_s, false);
        return parser.addNode(allocator_n, .{
            .tag = .@"if",
            .main_token = if_token,
            .data = .{
                .lhs = condition,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.If{
                    .then_expr = then_expr,
                    .else_expr = else_expr,
                }),
            },
        });
    }

    /// LabeledStatement <- BlockLabel? (Block / LoopStatement)
    fn parseLabeledStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const label_token = parser.parseBlockLabel();
        const block = try parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
        if (block != 0) return block;

        const loop_stmt = try parser.parseLoopStatement(allocator_n, allocator_e, allocator_x, allocator_s);
        if (loop_stmt != 0) return loop_stmt;

        if (label_token != 0) {
            const after_colon = parser.tokenIndex();
            const node = try parser.parseTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (node != 0) {
                const a = try parser.parseByteAlign(allocator_n, allocator_e, allocator_x, allocator_s);
                const b = try parser.parseAddrSpace(allocator_n, allocator_e, allocator_x, allocator_s);
                const c = try parser.parseLinkSection(allocator_n, allocator_e, allocator_x, allocator_s);
                const d = if (parser.eatToken(.equal) == null) 0 else try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                if (a != 0 or b != 0 or c != 0 or d != 0) {
                    return parser.failMsg(allocator_e, .{ .tag = .expected_var_const, .token = label_token });
                }
            }
            return parser.failMsg(allocator_e, .{ .tag = .expected_labelable, .token = after_colon });
        }

        return null_node;
    }

    /// LoopStatement <- KEYWORD_inline? (ForStatement / WhileStatement)
    fn parseLoopStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const inline_token = parser.eatToken(.keyword_inline);

        const for_statement = try parser.parseForStatement(allocator_n, allocator_e, allocator_x, allocator_s);
        if (for_statement != 0) return for_statement;

        const while_statement = try parser.parseWhileStatement(allocator_n, allocator_e, allocator_x, allocator_s);
        if (while_statement != 0) return while_statement;

        if (inline_token == null) return null_node;

        // If we've seen "inline", there should have been a "for" or "while"
        return parser.fail(allocator_e, .expected_inlinable);
    }

    /// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
    /// ForStatement
    ///     <- ForPrefix BlockExpr ( KEYWORD_else Statement )?
    ///      / ForPrefix AssignExpr ( SEMICOLON / KEYWORD_else Statement )
    fn parseForStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const for_token = parser.eatToken(.keyword_for) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const array_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        const found_payload = try parser.parsePtrIndexPayload(allocator_e);
        if (found_payload == 0) try parser.warn(allocator_e, .expected_loop_payload);

        // TODO propose to change the syntax so that semicolons are always required
        // inside while statements, even if there is an `else`.
        var else_required = false;
        const then_expr = blk: {
            const block_expr = try parser.parseBlockExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (block_expr != 0) break :blk block_expr;
            const assign_expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (assign_expr == 0) {
                return parser.fail(allocator_e, .expected_block_or_assignment);
            }
            if (parser.eatToken(.semicolon)) |_| {
                return parser.addNode(allocator_n, .{
                    .tag = .for_simple,
                    .main_token = for_token,
                    .data = .{
                        .lhs = array_expr,
                        .rhs = assign_expr,
                    },
                });
            }
            else_required = true;
            break :blk assign_expr;
        };
        _ = parser.eatToken(.keyword_else) orelse {
            if (else_required) {
                try parser.warn(allocator_e, .expected_semi_or_else);
            }
            return parser.addNode(allocator_n, .{
                .tag = .for_simple,
                .main_token = for_token,
                .data = .{
                    .lhs = array_expr,
                    .rhs = then_expr,
                },
            });
        };
        return parser.addNode(allocator_n, .{
            .tag = .@"for",
            .main_token = for_token,
            .data = .{
                .lhs = array_expr,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.If{
                    .then_expr = then_expr,
                    .else_expr = try parser.expectStatement(allocator_n, allocator_e, allocator_x, allocator_s, false),
                }),
            },
        });
    }

    /// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    /// WhileStatement
    ///     <- WhilePrefix BlockExpr ( KEYWORD_else Payload? Statement )?
    ///      / WhilePrefix AssignExpr ( SEMICOLON / KEYWORD_else Payload? Statement )
    fn parseWhileStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const while_token = parser.eatToken(.keyword_while) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const condition = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.parsePtrPayload(allocator_e);
        const cont_expr = try parser.parseWhileContinueExpr(allocator_n, allocator_e, allocator_x, allocator_s);

        // TODO propose to change the syntax so that semicolons are always required
        // inside while statements, even if there is an `else`.
        var else_required = false;
        const then_expr = blk: {
            const block_expr = try parser.parseBlockExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (block_expr != 0) break :blk block_expr;
            const assign_expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            if (assign_expr == 0) {
                return parser.fail(allocator_e, .expected_block_or_assignment);
            }
            if (parser.eatToken(.semicolon)) |_| {
                if (cont_expr == 0) {
                    return parser.addNode(allocator_n, .{
                        .tag = .while_simple,
                        .main_token = while_token,
                        .data = .{
                            .lhs = condition,
                            .rhs = assign_expr,
                        },
                    });
                } else {
                    return parser.addNode(allocator_n, .{
                        .tag = .while_cont,
                        .main_token = while_token,
                        .data = .{
                            .lhs = condition,
                            .rhs = try parser.addExtra(allocator_x, zig.AstNode.WhileCont{
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
        _ = parser.eatToken(.keyword_else) orelse {
            if (else_required) {
                try parser.warn(allocator_e, .expected_semi_or_else);
            }
            if (cont_expr == 0) {
                return parser.addNode(allocator_n, .{
                    .tag = .while_simple,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = then_expr,
                    },
                });
            } else {
                return parser.addNode(allocator_n, .{
                    .tag = .while_cont,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = try parser.addExtra(allocator_x, zig.AstNode.WhileCont{
                            .cont_expr = cont_expr,
                            .then_expr = then_expr,
                        }),
                    },
                });
            }
        };
        _ = try parser.parsePayload(allocator_e);
        const else_expr = try parser.expectStatement(allocator_n, allocator_e, allocator_x, allocator_s, false);
        return parser.addNode(allocator_n, .{
            .tag = .@"while",
            .main_token = while_token,
            .data = .{
                .lhs = condition,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.While{
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const block_expr = try parser.parseBlockExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (block_expr != 0) {
            return block_expr;
        }
        const assign_expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (assign_expr != 0) {
            try parser.expectSemicolon(allocator_e, .expected_semi_after_stmt, true);
            return assign_expr;
        }
        return null_node;
    }

    fn expectBlockExprStatement(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const node = try parser.parseBlockExprStatement(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return parser.fail(allocator_e, .expected_block_or_expr);
        }
        return node;
    }

    /// BlockExpr <- BlockLabel? Block
    fn parseBlockExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        switch (parser.readTagAhead()) {
            .identifier => {
                if (parser.relativeTagAhead(1) == .colon and
                    parser.relativeTagAhead(2) == .l_brace)
                {
                    parser.ast.tokens.stream(2);
                    return parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
                } else {
                    return null_node;
                }
            },
            .l_brace => return parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s),
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const expr = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (expr == 0) return null_node;

        const tag: zig.AstNode.Tag = switch (parser.readTagAhead()) {
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
        return parser.addNode(allocator_n, .{
            .tag = tag,
            .main_token = parser.nextToken(),
            .data = .{
                .lhs = expr,
                .rhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            },
        });
    }

    fn expectAssignExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const expr = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (expr == 0) {
            return parser.fail(allocator_e, .expected_expr_or_assignment);
        }
        return expr;
    }

    fn parseExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        return parser.parseExprPrecedence(allocator_n, allocator_e, allocator_x, allocator_s, 0);
    }

    fn expectExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const node = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return parser.fail(allocator_e, .expected_expr);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        min_prec: i32,
    ) Error!u32 {
        builtin.assert(min_prec >= 0);
        var node = try parser.parsePrefixExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return null_node;
        }

        var banned_prec: i8 = -1;

        while (true) {
            const tok_tag = parser.readTagAhead();
            const info = operTable[@intCast(usize, @enumToInt(tok_tag))];
            if (info.prec < min_prec) {
                break;
            }
            if (info.prec == banned_prec) {
                return parser.fail(allocator_e, .chained_comparison_operators);
            }

            const oper_token = parser.nextToken();
            // Special-case handling for "catch"
            if (tok_tag == .keyword_catch) {
                _ = try parser.parsePayload(allocator_e);
            }
            const rhs = try parser.parseExprPrecedence(allocator_n, allocator_e, allocator_x, allocator_s, info.prec + 1);
            if (rhs == 0) {
                try parser.warn(allocator_e, .expected_expr);
                return node;
            }

            {
                const tok_len = tok_tag.lexeme().?.len;
                const b_idx: u64 = parser.ast.tokens.readOneAt(oper_token).start - 1;
                const a_idx: u64 = parser.ast.tokens.readOneAt(oper_token).start + tok_len;
                const b_char: u8 = parser.ast.source[b_idx];
                const a_char: u8 = parser.ast.source[a_idx];

                // const char_before = parser.ast.source[parser.token_starts[oper_token] - 1];
                // const char_after = parser.ast.source[parser.token_starts[oper_token] + tok_len];

                if (tok_tag == .ampersand and a_char == '&') {
                    // without types we don't know if '&&' was intended as 'bitwise_and address_of', or a c-style logical_and
                    // The best the parser can do is recommend changing it to 'and' or ' & &'
                    try parser.warnMsg(allocator_e, .{ .tag = .invalid_ampersand_ampersand, .token = oper_token });
                } else if (tokenizer.isWhitespace(b_char) != tokenizer.isWhitespace(a_char)) {
                    try parser.warnMsg(allocator_e, .{ .tag = .mismatched_binary_op_whitespace, .token = oper_token });
                }
            }

            node = try parser.addNode(allocator_n, .{
                .tag = info.tag,
                .main_token = oper_token,
                .data = .{
                    .lhs = node,
                    .rhs = rhs,
                },
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const tag: zig.AstNode.Tag = switch (parser.readTagAhead()) {
            .bang => .bool_not,
            .minus => .negation,
            .tilde => .bit_not,
            .minus_percent => .negation_wrap,
            .ampersand => .address_of,
            .keyword_try => .@"try",
            .keyword_await => .@"await",
            else => return parser.parsePrimaryExpr(allocator_n, allocator_e, allocator_x, allocator_s),
        };
        return parser.addNode(allocator_n, .{
            .tag = tag,
            .main_token = parser.nextToken(),
            .data = .{
                .lhs = try parser.expectPrefixExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                .rhs = undefined,
            },
        });
    }

    fn expectPrefixExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const node = try parser.parsePrefixExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return parser.fail(allocator_e, .expected_prefix_expr);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        switch (parser.readTagAhead()) {
            .question_mark => return parser.addNode(allocator_n, .{
                .tag = .optional_type,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    .rhs = undefined,
                },
            }),
            .keyword_anyframe => switch (parser.relativeTagAhead(1)) {
                .arrow => return parser.addNode(allocator_n, .{
                    .tag = .anyframe_type,
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = parser.nextToken(),
                        .rhs = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    },
                }),
                else => return parser.parseErrorUnionExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            },
            .asterisk => {
                const asterisk = parser.nextToken();
                const mods = try parser.parsePtrModifiers(allocator_n, allocator_e, allocator_x, allocator_s);
                const elem_type = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                if (mods.bit_range_start != 0) {
                    return parser.addNode(allocator_n, .{
                        .tag = .ptr_type_bit_range,
                        .main_token = asterisk,
                        .data = .{
                            .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrTypeBitRange{
                                .sentinel = 0,
                                .align_node = mods.align_node,
                                .addrspace_node = mods.addrspace_node,
                                .bit_range_start = mods.bit_range_start,
                                .bit_range_end = mods.bit_range_end,
                            }),
                            .rhs = elem_type,
                        },
                    });
                } else if (mods.addrspace_node != 0) {
                    return parser.addNode(allocator_n, .{
                        .tag = .ptr_type,
                        .main_token = asterisk,
                        .data = .{
                            .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrType{
                                .sentinel = 0,
                                .align_node = mods.align_node,
                                .addrspace_node = mods.addrspace_node,
                            }),
                            .rhs = elem_type,
                        },
                    });
                } else {
                    return parser.addNode(allocator_n, .{
                        .tag = .ptr_type_aligned,
                        .main_token = asterisk,
                        .data = .{
                            .lhs = mods.align_node,
                            .rhs = elem_type,
                        },
                    });
                }
            },
            .asterisk_asterisk => {
                const asterisk = parser.nextToken();
                const mods = try parser.parsePtrModifiers(allocator_n, allocator_e, allocator_x, allocator_s);
                const elem_type = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                const inner: u32 = inner: {
                    if (mods.bit_range_start != 0) {
                        break :inner try parser.addNode(allocator_n, .{
                            .tag = .ptr_type_bit_range,
                            .main_token = asterisk,
                            .data = .{
                                .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrTypeBitRange{
                                    .sentinel = 0,
                                    .align_node = mods.align_node,
                                    .addrspace_node = mods.addrspace_node,
                                    .bit_range_start = mods.bit_range_start,
                                    .bit_range_end = mods.bit_range_end,
                                }),
                                .rhs = elem_type,
                            },
                        });
                    } else if (mods.addrspace_node != 0) {
                        break :inner try parser.addNode(allocator_n, .{
                            .tag = .ptr_type,
                            .main_token = asterisk,
                            .data = .{
                                .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrType{
                                    .sentinel = 0,
                                    .align_node = mods.align_node,
                                    .addrspace_node = mods.addrspace_node,
                                }),
                                .rhs = elem_type,
                            },
                        });
                    } else {
                        break :inner try parser.addNode(allocator_n, .{
                            .tag = .ptr_type_aligned,
                            .main_token = asterisk,
                            .data = .{
                                .lhs = mods.align_node,
                                .rhs = elem_type,
                            },
                        });
                    }
                };
                return parser.addNode(allocator_n, .{
                    .tag = .ptr_type_aligned,
                    .main_token = asterisk,
                    .data = .{
                        .lhs = 0,
                        .rhs = inner,
                    },
                });
            },
            .l_bracket => {
                switch (parser.ast.tokens.readOneAt(parser.ast.tokens.index() + 1).tag) {
                    .asterisk => {
                        _ = parser.nextToken();
                        const asterisk: u32 = parser.nextToken();
                        var sentinel: u32 = 0;
                        if (parser.eatToken(.identifier)) |ident| {
                            const start: usize = parser.ast.tokens.readOneAt(ident).start;
                            const end: usize = parser.ast.tokens.readOneAt(ident + 1).start;
                            const ident_slice: []const u8 = parser.ast.source[start..end];
                            // XXX: Maybe trouble
                            // const ident_slice = parser.ast.source[parser.token_starts[ident]..parser.token_starts[ident + 1]];

                            if (!mem.testEqualMany(u8, trimRight(u8, &tokenizer.whitespace, ident_slice), "c")) {
                                parser.ast.tokens.unstream(1);
                            }
                        } else if (parser.eatToken(.colon)) |_| {
                            sentinel = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        }
                        _ = try parser.expectToken(allocator_e, .r_bracket);
                        const mods = try parser.parsePtrModifiers(allocator_n, allocator_e, allocator_x, allocator_s);
                        const elem_type = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        if (mods.bit_range_start == 0) {
                            if (sentinel == 0 and mods.addrspace_node == 0) {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type_aligned,
                                    .main_token = asterisk,
                                    .data = .{
                                        .lhs = mods.align_node,
                                        .rhs = elem_type,
                                    },
                                });
                            } else if (mods.align_node == 0 and mods.addrspace_node == 0) {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type_sentinel,
                                    .main_token = asterisk,
                                    .data = .{
                                        .lhs = sentinel,
                                        .rhs = elem_type,
                                    },
                                });
                            } else {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type,
                                    .main_token = asterisk,
                                    .data = .{
                                        .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrType{
                                            .sentinel = sentinel,
                                            .align_node = mods.align_node,
                                            .addrspace_node = mods.addrspace_node,
                                        }),
                                        .rhs = elem_type,
                                    },
                                });
                            }
                        } else {
                            return parser.addNode(allocator_n, .{
                                .tag = .ptr_type_bit_range,
                                .main_token = asterisk,
                                .data = .{
                                    .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrTypeBitRange{
                                        .sentinel = sentinel,
                                        .align_node = mods.align_node,
                                        .addrspace_node = mods.addrspace_node,
                                        .bit_range_start = mods.bit_range_start,
                                        .bit_range_end = mods.bit_range_end,
                                    }),
                                    .rhs = elem_type,
                                },
                            });
                        }
                    },
                    else => {
                        const lbracket = parser.nextToken();
                        const len_expr = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        const sentinel: u32 = if (parser.eatToken(.colon)) |_|
                            try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s)
                        else
                            0;
                        _ = try parser.expectToken(allocator_e, .r_bracket);
                        if (len_expr == 0) {
                            const mods = try parser.parsePtrModifiers(allocator_n, allocator_e, allocator_x, allocator_s);
                            const elem_type = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                            if (mods.bit_range_start != 0) {
                                try parser.warnMsg(allocator_e, .{
                                    .tag = .invalid_bit_range,
                                    .token = parser.ast.nodes.readOneAt(allocator_n.*, mods.bit_range_start).main_token,
                                });
                            }
                            if (sentinel == 0 and mods.addrspace_node == 0) {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type_aligned,
                                    .main_token = lbracket,
                                    .data = .{
                                        .lhs = mods.align_node,
                                        .rhs = elem_type,
                                    },
                                });
                            } else if (mods.align_node == 0 and mods.addrspace_node == 0) {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type_sentinel,
                                    .main_token = lbracket,
                                    .data = .{
                                        .lhs = sentinel,
                                        .rhs = elem_type,
                                    },
                                });
                            } else {
                                return parser.addNode(allocator_n, .{
                                    .tag = .ptr_type,
                                    .main_token = lbracket,
                                    .data = .{
                                        .lhs = try parser.addExtra(allocator_x, zig.AstNode.PtrType{
                                            .sentinel = sentinel,
                                            .align_node = mods.align_node,
                                            .addrspace_node = mods.addrspace_node,
                                        }),
                                        .rhs = elem_type,
                                    },
                                });
                            }
                        } else {
                            switch (parser.readTagAhead()) {
                                .keyword_align,
                                .keyword_const,
                                .keyword_volatile,
                                .keyword_allowzero,
                                .keyword_addrspace,
                                => return parser.fail(allocator_e, .ptr_mod_on_array_child_type),
                                else => {},
                            }
                            const elem_type = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                            if (sentinel == 0) {
                                return parser.addNode(allocator_n, .{
                                    .tag = .array_type,
                                    .main_token = lbracket,
                                    .data = .{
                                        .lhs = len_expr,
                                        .rhs = elem_type,
                                    },
                                });
                            } else {
                                return parser.addNode(allocator_n, .{
                                    .tag = .array_type_sentinel,
                                    .main_token = lbracket,
                                    .data = .{
                                        .lhs = len_expr,
                                        .rhs = try parser.addExtra(allocator_x, .{
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
            else => return parser.parseErrorUnionExpr(allocator_n, allocator_e, allocator_x, allocator_s),
        }
    }
    fn expectTypeExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const node = try parser.parseTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return parser.fail(allocator_e, .expected_type_expr);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        switch (parser.readTagAhead()) {
            .keyword_asm => return parser.expectAsmExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_if => return parser.parseIfExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_break => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"break",
                    .main_token = @intCast(u32, parser.tokenIndex() - 1),
                    .data = .{
                        .lhs = try parser.parseBreakLabel(allocator_e),
                        .rhs = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    },
                });
            },
            .keyword_continue => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"continue",
                    .main_token = parser.tokenIndex() - 1,
                    .data = .{
                        .lhs = try parser.parseBreakLabel(allocator_e),
                        .rhs = undefined,
                    },
                });
            },
            .keyword_comptime => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"comptime",
                    .main_token = parser.tokenIndex() - 1,
                    .data = .{
                        .lhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                        .rhs = undefined,
                    },
                });
            },
            .keyword_nosuspend => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"nosuspend",
                    .main_token = parser.tokenIndex() - 1,
                    .data = .{
                        .lhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                        .rhs = undefined,
                    },
                });
            },
            .keyword_resume => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"resume",
                    .main_token = parser.tokenIndex() - 1,
                    .data = .{
                        .lhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                        .rhs = undefined,
                    },
                });
            },
            .keyword_return => {
                parser.ast.tokens.stream(1);
                return parser.addNode(allocator_n, .{
                    .tag = .@"return",
                    .main_token = parser.tokenIndex() - 1,
                    .data = .{
                        .lhs = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                        .rhs = undefined,
                    },
                });
            },
            .identifier => {
                if (parser.relativeTagAhead(1) == .colon) {
                    switch (parser.relativeTagAhead(2)) {
                        .keyword_inline => {
                            parser.ast.tokens.stream(3);
                            switch (parser.readTagAhead()) {
                                .keyword_for => return parser.parseForExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                                .keyword_while => return parser.parseWhileExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                                else => return parser.fail(allocator_e, .expected_inlinable),
                            }
                        },
                        .keyword_for => {
                            parser.ast.tokens.stream(2);
                            return parser.parseForExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        },
                        .keyword_while => {
                            parser.ast.tokens.stream(2);
                            return parser.parseWhileExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        },
                        .l_brace => {
                            parser.ast.tokens.stream(2);
                            return parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
                        },
                        else => return parser.parseCurlySuffixExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    }
                } else {
                    return parser.parseCurlySuffixExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                }
            },
            .keyword_inline => {
                parser.ast.tokens.stream(1);
                switch (parser.readTagAhead()) {
                    .keyword_for => return parser.parseForExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    .keyword_while => return parser.parseWhileExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    else => return parser.fail(allocator_e, .expected_inlinable),
                }
            },
            .keyword_for => return parser.parseForExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_while => return parser.parseWhileExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .l_brace => return parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s),
            else => return parser.parseCurlySuffixExpr(allocator_n, allocator_e, allocator_x, allocator_s),
        }
    }

    /// IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?
    fn parseIfExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        return parser.parseIf(allocator_n, allocator_e, allocator_x, allocator_s, expectExpr);
    }

    /// Block <- LBRACE Statement* RBRACE
    fn parseBlock(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const lbrace = parser.eatToken(.l_brace) orelse return null_node;
        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
        while (true) {
            if (parser.readTagAhead() == .r_brace) break;
            const statement = try parser.expectStatementRecoverable(allocator_n, allocator_e, allocator_x, allocator_s);
            if (statement == 0) break;
            try parser.state.appendOne(allocator_s, statement);
        }
        _ = try parser.expectToken(allocator_e, .r_brace);
        const semicolon = (parser.relativeTagBehind(2) == .semicolon);
        const statements = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
        switch (statements.len) {
            0 => return parser.addNode(allocator_n, .{
                .tag = .block_two,
                .main_token = lbrace,
                .data = .{
                    .lhs = 0,
                    .rhs = 0,
                },
            }),
            1 => return parser.addNode(allocator_n, .{
                .tag = if (semicolon) .block_two_semicolon else .block_two,
                .main_token = lbrace,
                .data = .{
                    .lhs = statements[0],
                    .rhs = 0,
                },
            }),
            2 => return parser.addNode(allocator_n, .{
                .tag = if (semicolon) .block_two_semicolon else .block_two,
                .main_token = lbrace,
                .data = .{
                    .lhs = statements[0],
                    .rhs = statements[1],
                },
            }),
            else => {
                const span = try parser.listToSpan(allocator_x, statements);
                return parser.addNode(allocator_n, .{
                    .tag = if (semicolon) .block_semicolon else .block,
                    .main_token = lbrace,
                    .data = .{
                        .lhs = span.start,
                        .rhs = span.end,
                    },
                });
            },
        }
    }

    /// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
    /// ForExpr <- ForPrefix Expr (KEYWORD_else Expr)?
    fn parseForExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const for_token = parser.eatToken(.keyword_for) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const array_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        const found_payload = try parser.parsePtrIndexPayload(allocator_e);
        if (found_payload == 0) try parser.warn(allocator_e, .expected_loop_payload);

        const then_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = parser.eatToken(.keyword_else) orelse {
            return parser.addNode(allocator_n, .{
                .tag = .for_simple,
                .main_token = for_token,
                .data = .{
                    .lhs = array_expr,
                    .rhs = then_expr,
                },
            });
        };
        const else_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        return parser.addNode(allocator_n, .{
            .tag = .@"for",
            .main_token = for_token,
            .data = .{
                .lhs = array_expr,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.If{
                    .then_expr = then_expr,
                    .else_expr = else_expr,
                }),
            },
        });
    }

    /// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    /// WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?
    fn parseWhileExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const while_token = parser.eatToken(.keyword_while) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const condition = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.parsePtrPayload(allocator_e);
        const cont_expr = try parser.parseWhileContinueExpr(allocator_n, allocator_e, allocator_x, allocator_s);

        const then_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = parser.eatToken(.keyword_else) orelse {
            if (cont_expr == 0) {
                return parser.addNode(allocator_n, .{
                    .tag = .while_simple,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = then_expr,
                    },
                });
            } else {
                return parser.addNode(allocator_n, .{
                    .tag = .while_cont,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = try parser.addExtra(allocator_x, zig.AstNode.WhileCont{
                            .cont_expr = cont_expr,
                            .then_expr = then_expr,
                        }),
                    },
                });
            }
        };
        _ = try parser.parsePayload(allocator_e);
        const else_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        return parser.addNode(allocator_n, .{
            .tag = .@"while",
            .main_token = while_token,
            .data = .{
                .lhs = condition,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.While{
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const lhs = try parser.parseTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (lhs == 0) return null_node;
        const lbrace = parser.eatToken(.l_brace) orelse return lhs;

        // If there are 0 or 1 items, we can use ArrayInitOne/StructInitOne;
        // otherwise we use the full ArrayInit/StructInit.

        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
        const field_init = try parser.parseFieldInit(allocator_n, allocator_e, allocator_x, allocator_s);
        if (field_init != 0) {
            try parser.state.appendOne(allocator_s, field_init);
            while (true) {
                switch (parser.readTagAhead()) {
                    .comma => parser.ast.tokens.stream(1),
                    .r_brace => {
                        parser.ast.tokens.stream(1);
                        break;
                    },
                    .colon, .r_paren, .r_bracket => return parser.failExpected(allocator_e, .r_brace),
                    // Likely just a missing comma; give error but continue parsing.
                    else => try parser.warn(allocator_e, .expected_comma_after_initializer),
                }
                if (parser.eatToken(.r_brace)) |_| break;
                const next = try parser.expectFieldInit(allocator_n, allocator_e, allocator_x, allocator_s);
                try parser.state.appendOne(allocator_s, next);
            }
            const comma = (parser.relativeTagBehind(2) == .comma);
            const inits = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
            switch (inits.len) {
                0 => unreachable,
                1 => return parser.addNode(allocator_n, .{
                    .tag = if (comma) .struct_init_one_comma else .struct_init_one,
                    .main_token = lbrace,
                    .data = .{
                        .lhs = lhs,
                        .rhs = inits[0],
                    },
                }),
                else => return parser.addNode(allocator_n, .{
                    .tag = if (comma) .struct_init_comma else .struct_init,
                    .main_token = lbrace,
                    .data = .{
                        .lhs = lhs,
                        .rhs = try parser.addExtra(allocator_x, try parser.listToSpan(allocator_x, inits)),
                    },
                }),
            }
        }

        while (true) {
            if (parser.eatToken(.r_brace)) |_| break;
            const elem_init = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            try parser.state.appendOne(allocator_s, elem_init);
            switch (parser.readTagAhead()) {
                .comma => parser.ast.tokens.stream(1),
                .r_brace => {
                    parser.ast.tokens.stream(1);
                    break;
                },
                .colon, .r_paren, .r_bracket => return parser.failExpected(allocator_e, .r_brace),
                // Likely just a missing comma; give error but continue parsing.
                else => try parser.warn(allocator_e, .expected_comma_after_initializer),
            }
        }
        const comma = (parser.relativeTagBehind(2) == .comma);
        const inits = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
        switch (inits.len) {
            0 => return parser.addNode(allocator_n, .{
                .tag = .struct_init_one,
                .main_token = lbrace,
                .data = .{
                    .lhs = lhs,
                    .rhs = 0,
                },
            }),
            1 => return parser.addNode(allocator_n, .{
                .tag = if (comma) .array_init_one_comma else .array_init_one,
                .main_token = lbrace,
                .data = .{
                    .lhs = lhs,
                    .rhs = inits[0],
                },
            }),
            else => return parser.addNode(allocator_n, .{
                .tag = if (comma) .array_init_comma else .array_init,
                .main_token = lbrace,
                .data = .{
                    .lhs = lhs,
                    .rhs = try parser.addExtra(allocator_x, try parser.listToSpan(allocator_x, inits)),
                },
            }),
        }
    }

    /// ErrorUnionExpr <- SuffixExpr (EXCLAMATIONMARK TypeExpr)?
    fn parseErrorUnionExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const suffix_expr = try parser.parseSuffixExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (suffix_expr == 0) return null_node;
        const bang = parser.eatToken(.bang) orelse return suffix_expr;
        return parser.addNode(allocator_n, .{
            .tag = .error_union,
            .main_token = bang,
            .data = .{
                .lhs = suffix_expr,
                .rhs = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            },
        });
    }

    /// SuffixExpr
    ///     <- KEYWORD_async PrimaryTypeExpr SuffixOp* FnCallArguments
    ///      / PrimaryTypeExpr (SuffixOp / FnCallArguments)*
    /// FnCallArguments <- LPAREN ExprList RPAREN
    /// ExprList <- (Expr COMMA)* Expr?
    fn parseSuffixExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        if (parser.eatToken(.keyword_async)) |_| {
            var res = try parser.expectPrimaryTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            while (true) {
                const node = try parser.parseSuffixOp(allocator_n, allocator_e, allocator_x, allocator_s, res);
                if (node == 0) break;
                res = node;
            }
            const lparen = parser.eatToken(.l_paren) orelse {
                try parser.warn(allocator_e, .expected_param_list);
                return res;
            };
            const state_top: usize = parser.state.len(allocator_s.*);
            defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
            while (true) {
                if (parser.eatToken(.r_paren)) |_| break;
                const param = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                try parser.state.appendOne(allocator_s, param);
                switch (parser.readTagAhead()) {
                    .comma => parser.ast.tokens.stream(1),
                    .r_paren => {
                        parser.ast.tokens.stream(1);
                        break;
                    },
                    .colon, .r_brace, .r_bracket => return parser.failExpected(allocator_e, .r_paren),
                    // Likely just a missing comma; give error but continue parsing.
                    else => try parser.warn(allocator_e, .expected_comma_after_arg),
                }
            }
            const comma = (parser.relativeTagBehind(2) == .comma);
            const params = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
            switch (params.len) {
                0 => return parser.addNode(allocator_n, .{
                    .tag = if (comma) .async_call_one_comma else .async_call_one,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = 0,
                    },
                }),
                1 => return parser.addNode(allocator_n, .{
                    .tag = if (comma) .async_call_one_comma else .async_call_one,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = params[0],
                    },
                }),
                else => return parser.addNode(allocator_n, .{
                    .tag = if (comma) .async_call_comma else .async_call,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = try parser.addExtra(allocator_x, try parser.listToSpan(allocator_x, params)),
                    },
                }),
            }
        }

        var res = try parser.parsePrimaryTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (res == 0) return res;
        while (true) {
            const suffix_op = try parser.parseSuffixOp(allocator_n, allocator_e, allocator_x, allocator_s, res);
            if (suffix_op != 0) {
                res = suffix_op;
                continue;
            }
            const lparen = parser.eatToken(.l_paren) orelse return res;
            const state_top: usize = parser.state.len(allocator_s.*);
            defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
            while (true) {
                if (parser.eatToken(.r_paren)) |_| break;
                const param = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                try parser.state.appendOne(allocator_s, param);
                switch (parser.readTagAhead()) {
                    .comma => parser.ast.tokens.stream(1),
                    .r_paren => {
                        parser.ast.tokens.stream(1);
                        break;
                    },
                    .colon, .r_brace, .r_bracket => return parser.failExpected(allocator_e, .r_paren),
                    // Likely just a missing comma; give error but continue parsing.
                    else => try parser.warn(allocator_e, .expected_comma_after_arg),
                }
            }
            const comma = (parser.relativeTagBehind(2) == .comma);
            const params = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
            res = switch (params.len) {
                0 => try parser.addNode(allocator_n, .{
                    .tag = if (comma) .call_one_comma else .call_one,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = 0,
                    },
                }),
                1 => try parser.addNode(allocator_n, .{
                    .tag = if (comma) .call_one_comma else .call_one,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = params[0],
                    },
                }),
                else => try parser.addNode(allocator_n, .{
                    .tag = if (comma) .call_comma else .call,
                    .main_token = lparen,
                    .data = .{
                        .lhs = res,
                        .rhs = try parser.addExtra(allocator_x, try parser.listToSpan(allocator_x, params)),
                    },
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        switch (parser.readTagAhead()) {
            .char_literal => return parser.addNode(allocator_n, .{
                .tag = .char_literal,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = undefined,
                    .rhs = undefined,
                },
            }),
            .number_literal => return parser.addNode(allocator_n, .{
                .tag = .number_literal,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = undefined,
                    .rhs = undefined,
                },
            }),
            .keyword_unreachable => return parser.addNode(allocator_n, .{
                .tag = .unreachable_literal,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = undefined,
                    .rhs = undefined,
                },
            }),
            .keyword_anyframe => return parser.addNode(allocator_n, .{
                .tag = .anyframe_literal,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = undefined,
                    .rhs = undefined,
                },
            }),
            .string_literal => {
                const main_token = parser.nextToken();
                return parser.addNode(allocator_n, .{
                    .tag = .string_literal,
                    .main_token = main_token,
                    .data = .{
                        .lhs = undefined,
                        .rhs = undefined,
                    },
                });
            },

            .builtin => return parser.parseBuiltinCall(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_fn => return parser.parseFnProto(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_if => return parser.parseIf(allocator_n, allocator_e, allocator_x, allocator_s, expectTypeExpr),
            .keyword_switch => return parser.expectSwitchExpr(allocator_n, allocator_e, allocator_x, allocator_s),

            .keyword_extern,
            .keyword_packed,
            => {
                parser.ast.tokens.stream(1);
                return parser.parseContainerDeclAuto(allocator_n, allocator_e, allocator_x, allocator_s);
            },

            .keyword_struct,
            .keyword_opaque,
            .keyword_enum,
            .keyword_union,
            => return parser.parseContainerDeclAuto(allocator_n, allocator_e, allocator_x, allocator_s),

            .keyword_comptime => return parser.addNode(allocator_n, .{
                .tag = .@"comptime",
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    .rhs = undefined,
                },
            }),
            .multiline_string_literal_line => {
                const first_line = parser.nextToken();
                while (parser.readTagAhead() == .multiline_string_literal_line) {
                    parser.ast.tokens.stream(1);
                }
                return parser.addNode(allocator_n, .{
                    .tag = .multiline_string_literal,
                    .main_token = first_line,
                    .data = .{
                        .lhs = first_line,
                        .rhs = parser.tokenIndex() - 1,
                    },
                });
            },
            .identifier => switch (parser.relativeTagAhead(1)) {
                .colon => switch (parser.relativeTagAhead(2)) {
                    .keyword_inline => {
                        parser.ast.tokens.stream(3);
                        switch (parser.readTagAhead()) {
                            .keyword_for => return parser.parseForTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                            .keyword_while => return parser.parseWhileTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                            else => return parser.fail(allocator_e, .expected_inlinable),
                        }
                    },
                    .keyword_for => {
                        parser.ast.tokens.stream(2);
                        return parser.parseForTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                    },
                    .keyword_while => {
                        parser.ast.tokens.stream(2);
                        return parser.parseWhileTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                    },
                    .l_brace => {
                        parser.ast.tokens.stream(2);
                        return parser.parseBlock(allocator_n, allocator_e, allocator_x, allocator_s);
                    },
                    else => return parser.addNode(allocator_n, .{
                        .tag = .identifier,
                        .main_token = parser.nextToken(),
                        .data = .{
                            .lhs = undefined,
                            .rhs = undefined,
                        },
                    }),
                },
                else => return parser.addNode(allocator_n, .{
                    .tag = .identifier,
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = undefined,
                        .rhs = undefined,
                    },
                }),
            },
            .keyword_inline => {
                parser.ast.tokens.stream(1);
                switch (parser.readTagAhead()) {
                    .keyword_for => return parser.parseForTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    .keyword_while => return parser.parseWhileTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    else => return parser.fail(allocator_e, .expected_inlinable),
                }
            },
            .keyword_for => return parser.parseForTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .keyword_while => return parser.parseWhileTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
            .period => switch (parser.relativeTagAhead(1)) {
                .identifier => return parser.addNode(allocator_n, .{
                    .tag = .enum_literal,
                    .data = .{
                        .lhs = parser.nextToken(), // dot
                        .rhs = undefined,
                    },
                    .main_token = parser.nextToken(), // identifier
                }),
                .l_brace => {
                    const lbrace = parser.tokenIndex() + 1;
                    // parser.tokenIndex() = lbrace + 1;
                    parser.ast.tokens.stream(2);

                    // If there are 0, 1, or 2 items, we can use ArrayInitDotTwo/StructInitDotTwo;
                    // otherwise we use the full ArrayInitDot/StructInitDot.

                    const state_top: usize = parser.state.len(allocator_s.*);
                    defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
                    const field_init = try parser.parseFieldInit(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (field_init != 0) {
                        try parser.state.appendOne(allocator_s, field_init);
                        while (true) {
                            switch (parser.readTagAhead()) {
                                .comma => parser.ast.tokens.stream(1),
                                .r_brace => {
                                    parser.ast.tokens.stream(1);
                                    break;
                                },
                                .colon, .r_paren, .r_bracket => return parser.failExpected(allocator_e, .r_brace),
                                // Likely just a missing comma; give error but continue parsing.
                                else => try parser.warn(allocator_e, .expected_comma_after_initializer),
                            }
                            if (parser.eatToken(.r_brace)) |_| break;
                            const next = try parser.expectFieldInit(allocator_n, allocator_e, allocator_x, allocator_s);
                            try parser.state.appendOne(allocator_s, next);
                        }
                        const comma = (parser.relativeTagBehind(2) == .comma);
                        const inits = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
                        switch (inits.len) {
                            0 => unreachable,
                            1 => return parser.addNode(allocator_n, .{
                                .tag = if (comma) .struct_init_dot_two_comma else .struct_init_dot_two,
                                .main_token = lbrace,
                                .data = .{
                                    .lhs = inits[0],
                                    .rhs = 0,
                                },
                            }),
                            2 => return parser.addNode(allocator_n, .{
                                .tag = if (comma) .struct_init_dot_two_comma else .struct_init_dot_two,
                                .main_token = lbrace,
                                .data = .{
                                    .lhs = inits[0],
                                    .rhs = inits[1],
                                },
                            }),
                            else => {
                                const span = try parser.listToSpan(allocator_x, inits);
                                return parser.addNode(allocator_n, .{
                                    .tag = if (comma) .struct_init_dot_comma else .struct_init_dot,
                                    .main_token = lbrace,
                                    .data = .{
                                        .lhs = span.start,
                                        .rhs = span.end,
                                    },
                                });
                            },
                        }
                    }

                    while (true) {
                        if (parser.eatToken(.r_brace)) |_| break;
                        const elem_init = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        try parser.state.appendOne(allocator_s, elem_init);
                        switch (parser.readTagAhead()) {
                            .comma => parser.ast.tokens.stream(1),
                            .r_brace => {
                                parser.ast.tokens.stream(1);
                                break;
                            },
                            .colon, .r_paren, .r_bracket => return parser.failExpected(allocator_e, .r_brace),
                            // Likely just a missing comma; give error but continue parsing.
                            else => try parser.warn(allocator_e, .expected_comma_after_initializer),
                        }
                    }
                    const comma = (parser.relativeTagBehind(2) == .comma);
                    const inits = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
                    switch (inits.len) {
                        0 => return parser.addNode(allocator_n, .{
                            .tag = .struct_init_dot_two,
                            .main_token = lbrace,
                            .data = .{
                                .lhs = 0,
                                .rhs = 0,
                            },
                        }),
                        1 => return parser.addNode(allocator_n, .{
                            .tag = if (comma) .array_init_dot_two_comma else .array_init_dot_two,
                            .main_token = lbrace,
                            .data = .{
                                .lhs = inits[0],
                                .rhs = 0,
                            },
                        }),
                        2 => return parser.addNode(allocator_n, .{
                            .tag = if (comma) .array_init_dot_two_comma else .array_init_dot_two,
                            .main_token = lbrace,
                            .data = .{
                                .lhs = inits[0],
                                .rhs = inits[1],
                            },
                        }),
                        else => {
                            const span = try parser.listToSpan(allocator_x, inits);
                            return parser.addNode(allocator_n, .{
                                .tag = if (comma) .array_init_dot_comma else .array_init_dot,
                                .main_token = lbrace,
                                .data = .{
                                    .lhs = span.start,
                                    .rhs = span.end,
                                },
                            });
                        },
                    }
                },
                else => return null_node,
            },
            .keyword_error => switch (parser.relativeTagAhead(1)) {
                .l_brace => {
                    const error_token = parser.tokenIndex();
                    parser.ast.tokens.stream(2);
                    while (true) {
                        if (parser.eatToken(.r_brace)) |_| break;
                        _ = try parser.eatDocComments(allocator_e);
                        _ = try parser.expectToken(allocator_e, .identifier);
                        switch (parser.readTagAhead()) {
                            .comma => parser.ast.tokens.stream(1),
                            .r_brace => {
                                parser.ast.tokens.stream(1);
                                break;
                            },
                            .colon, .r_paren, .r_bracket => return parser.failExpected(allocator_e, .r_brace),
                            // Likely just a missing comma; give error but continue parsing.
                            else => try parser.warn(allocator_e, .expected_comma_after_field),
                        }
                    }
                    return parser.addNode(allocator_n, .{
                        .tag = .error_set_decl,
                        .main_token = error_token,
                        .data = .{
                            .lhs = undefined,
                            .rhs = parser.tokenIndex() - 1, // rbrace
                        },
                    });
                },
                else => {
                    const main_token = parser.nextToken();
                    const period = parser.eatToken(.period);
                    if (period == null) try parser.warnExpected(allocator_e, .period);
                    const identifier = parser.eatToken(.identifier);
                    if (identifier == null) try parser.warnExpected(allocator_e, .identifier);
                    return parser.addNode(allocator_n, .{
                        .tag = .error_value,
                        .main_token = main_token,
                        .data = .{
                            .lhs = period orelse 0,
                            .rhs = identifier orelse 0,
                        },
                    });
                },
            },
            .l_paren => return parser.addNode(allocator_n, .{
                .tag = .grouped_expression,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                    .rhs = try parser.expectToken(allocator_e, .r_paren),
                },
            }),
            else => return null_node,
        }
    }

    fn expectPrimaryTypeExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const node = try parser.parsePrimaryTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) {
            return parser.fail(allocator_e, .expected_primary_type_expr);
        }
        return node;
    }

    /// ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload
    /// ForTypeExpr <- ForPrefix TypeExpr (KEYWORD_else TypeExpr)?
    fn parseForTypeExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const for_token = parser.eatToken(.keyword_for) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const array_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        const found_payload = try parser.parsePtrIndexPayload(allocator_e);
        if (found_payload == 0) try parser.warn(allocator_e, .expected_loop_payload);

        const then_expr = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = parser.eatToken(.keyword_else) orelse {
            return parser.addNode(allocator_n, .{
                .tag = .for_simple,
                .main_token = for_token,
                .data = .{
                    .lhs = array_expr,
                    .rhs = then_expr,
                },
            });
        };
        const else_expr = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        return parser.addNode(allocator_n, .{
            .tag = .@"for",
            .main_token = for_token,
            .data = .{
                .lhs = array_expr,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.If{
                    .then_expr = then_expr,
                    .else_expr = else_expr,
                }),
            },
        });
    }

    /// WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    /// WhileTypeExpr <- WhilePrefix TypeExpr (KEYWORD_else Payload? TypeExpr)?
    fn parseWhileTypeExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const while_token = parser.eatToken(.keyword_while) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const condition = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.parsePtrPayload(allocator_e);
        const cont_expr = try parser.parseWhileContinueExpr(allocator_n, allocator_e, allocator_x, allocator_s);

        const then_expr = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = parser.eatToken(.keyword_else) orelse {
            if (cont_expr == 0) {
                return parser.addNode(allocator_n, .{
                    .tag = .while_simple,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = then_expr,
                    },
                });
            } else {
                return parser.addNode(allocator_n, .{
                    .tag = .while_cont,
                    .main_token = while_token,
                    .data = .{
                        .lhs = condition,
                        .rhs = try parser.addExtra(allocator_x, zig.AstNode.WhileCont{
                            .cont_expr = cont_expr,
                            .then_expr = then_expr,
                        }),
                    },
                });
            }
        };
        _ = try parser.parsePayload(allocator_e);
        const else_expr = try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        return parser.addNode(allocator_n, .{
            .tag = .@"while",
            .main_token = while_token,
            .data = .{
                .lhs = condition,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.While{
                    .cont_expr = cont_expr,
                    .then_expr = then_expr,
                    .else_expr = else_expr,
                }),
            },
        });
    }

    /// SwitchExpr <- KEYWORD_switch LPAREN Expr RPAREN LBRACE SwitchProngList RBRACE
    fn expectSwitchExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const switch_token = parser.assertToken(.keyword_switch);
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr_node = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.expectToken(allocator_e, .l_brace);
        const cases = try parser.parseSwitchProngList(allocator_n, allocator_e, allocator_x, allocator_s);
        const trailing_comma = parser.relativeTagBehind(1) == .comma;
        _ = try parser.expectToken(allocator_e, .r_brace);

        return parser.addNode(allocator_n, .{
            .tag = if (trailing_comma) .switch_comma else .@"switch",
            .main_token = switch_token,
            .data = .{
                .lhs = expr_node,
                .rhs = try parser.addExtra(allocator_x, SubRange{
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const asm_token = parser.assertToken(.keyword_asm);
        _ = parser.eatToken(.keyword_volatile);
        _ = try parser.expectToken(allocator_e, .l_paren);
        const template = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);

        if (parser.eatToken(.r_paren)) |rparen| {
            return parser.addNode(allocator_n, .{
                .tag = .asm_simple,
                .main_token = asm_token,
                .data = .{
                    .lhs = template,
                    .rhs = rparen,
                },
            });
        }

        _ = try parser.expectToken(allocator_e, .colon);

        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);

        while (true) {
            const output_item = try parser.parseAsmOutputItem(allocator_n, allocator_e, allocator_x, allocator_s);
            if (output_item == 0) break;
            try parser.state.appendOne(allocator_s, output_item);
            switch (parser.readTagAhead()) {
                .comma => parser.ast.tokens.stream(1),
                // All possible delimiters.
                .colon, .r_paren, .r_brace, .r_bracket => break,
                // Likely just a missing comma; give error but continue parsing.
                else => try parser.warnExpected(allocator_e, .comma),
            }
        }
        if (parser.eatToken(.colon)) |_| {
            while (true) {
                const input_item = try parser.parseAsmInputItem(allocator_n, allocator_e, allocator_x, allocator_s);
                if (input_item == 0) break;
                try parser.state.appendOne(allocator_s, input_item);
                switch (parser.readTagAhead()) {
                    .comma => parser.ast.tokens.stream(1),
                    // All possible delimiters.
                    .colon, .r_paren, .r_brace, .r_bracket => break,
                    // Likely just a missing comma; give error but continue parsing.
                    else => try parser.warnExpected(allocator_e, .comma),
                }
            }
            if (parser.eatToken(.colon)) |_| {
                while (parser.eatToken(.string_literal)) |_| {
                    switch (parser.readTagAhead()) {
                        .comma => parser.ast.tokens.stream(1),
                        .colon, .r_paren, .r_brace, .r_bracket => break,
                        // Likely just a missing comma; give error but continue parsing.
                        else => try parser.warnExpected(allocator_e, .comma),
                    }
                }
            }
        }
        const rparen = try parser.expectToken(allocator_e, .r_paren);
        // XXX: Maybe trouble:
        const span = try parser.listToSpan(allocator_x, parser.state.readManyAt(allocator_s.*, state_top));
        return parser.addNode(allocator_n, .{
            .tag = .@"asm",
            .main_token = asm_token,
            .data = .{
                .lhs = template,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.Asm{
                    .items_start = span.start,
                    .items_end = span.end,
                    .rparen = rparen,
                }),
            },
        });
    }

    /// AsmOutputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN (MINUSRARROW TypeExpr / IDENTIFIER) RPAREN
    fn parseAsmOutputItem(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.l_bracket) orelse return null_node;
        const identifier = try parser.expectToken(allocator_e, .identifier);
        _ = try parser.expectToken(allocator_e, .r_bracket);
        _ = try parser.expectToken(allocator_e, .string_literal);
        _ = try parser.expectToken(allocator_e, .l_paren);
        const type_expr: u32 = blk: {
            if (parser.eatToken(.arrow)) |_| {
                break :blk try parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            } else {
                _ = try parser.expectToken(allocator_e, .identifier);
                break :blk null_node;
            }
        };
        const rparen = try parser.expectToken(allocator_e, .r_paren);
        return parser.addNode(allocator_n, .{
            .tag = .asm_output,
            .main_token = identifier,
            .data = .{
                .lhs = type_expr,
                .rhs = rparen,
            },
        });
    }

    /// AsmInputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN Expr RPAREN
    fn parseAsmInputItem(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.l_bracket) orelse return null_node;
        const identifier = try parser.expectToken(allocator_e, .identifier);
        _ = try parser.expectToken(allocator_e, .r_bracket);
        _ = try parser.expectToken(allocator_e, .string_literal);
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        const rparen = try parser.expectToken(allocator_e, .r_paren);
        return parser.addNode(allocator_n, .{
            .tag = .asm_input,
            .main_token = identifier,
            .data = .{
                .lhs = expr,
                .rhs = rparen,
            },
        });
    }

    /// BreakLabel <- COLON IDENTIFIER
    fn parseBreakLabel(parser: *Parser, allocator_e: *AllocatorE) Error!u32 {
        _ = parser.eatToken(.colon) orelse return @as(u32, 0);
        return parser.expectToken(allocator_e, .identifier);
    }

    /// BlockLabel <- IDENTIFIER COLON
    fn parseBlockLabel(parser: *Parser) u32 {
        if (parser.readTagAhead() == .identifier and
            parser.relativeTagAhead(1) == .colon)
        {
            const identifier = parser.tokenIndex();
            parser.ast.tokens.stream(2);
            return identifier;
        }
        return null_node;
    }

    /// FieldInit <- DOT IDENTIFIER EQUAL Expr
    fn parseFieldInit(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        if (parser.relativeTagAhead(0) == .period and
            parser.relativeTagAhead(1) == .identifier and
            parser.relativeTagAhead(2) == .equal)
        {
            parser.ast.tokens.stream(3);
            return parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        } else {
            return null_node;
        }
    }

    fn expectFieldInit(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        if (parser.readTagAhead() != .period or
            parser.relativeTagAhead(1) != .identifier or
            parser.relativeTagAhead(2) != .equal)
            return parser.fail(allocator_e, .expected_initializer);

        parser.ast.tokens.stream(3);
        return parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
    }

    /// WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN
    fn parseWhileContinueExpr(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.colon) orelse {
            if (parser.readTagAhead() == .l_paren and
                parser.ast.tokensOnSameLine(parser.tokenIndex() - 1, parser.tokenIndex()))
                return parser.fail(allocator_e, .expected_continue_expr);
            return null_node;
        };
        _ = try parser.expectToken(allocator_e, .l_paren);
        const node = try parser.parseAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (node == 0) return parser.fail(allocator_e, .expected_expr_or_assignment);
        _ = try parser.expectToken(allocator_e, .r_paren);
        return node;
    }

    /// LinkSection <- KEYWORD_linksection LPAREN Expr RPAREN
    fn parseLinkSection(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.keyword_linksection) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr_node = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        return expr_node;
    }

    /// CallConv <- KEYWORD_callconv LPAREN Expr RPAREN
    fn parseCallconv(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.keyword_callconv) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr_node = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        return expr_node;
    }

    /// AddrSpace <- KEYWORD_addrspace LPAREN Expr RPAREN
    fn parseAddrSpace(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.keyword_addrspace) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr_node = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        return expr_node;
    }

    fn relativeTagAhead(parser: *Parser, offset: u64) zig.Token.Tag {
        return parser.ast.tokens.readOneAt(parser.tokenIndex() +% offset).tag;
    }
    fn relativeTagBehind(parser: *Parser, offset: u64) zig.Token.Tag {
        return parser.ast.tokens.readOneAt(parser.tokenIndex() -% offset).tag;
    }
    fn relativeStartAhead(parser: *Parser, offset: u64) zig.Token.Tag {
        return parser.ast.tokens.readOneAt(parser.tokenIndex() +% offset).start;
    }
    fn relativeStartBehind(parser: *Parser, offset: u64) zig.Token.Tag {
        return parser.ast.tokens.readOneAt(parser.tokenIndex() -% offset).start;
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = try parser.eatDocComments(allocator_e);
        switch (parser.readTagAhead()) {
            .keyword_noalias, .keyword_comptime => parser.ast.tokens.stream(1),
            .ellipsis3 => {
                parser.ast.tokens.stream(1);
                return null_node;
            },
            else => {},
        }
        if (parser.readTagAhead() == .identifier and
            parser.relativeTagAhead(1) == .colon)
        {
            parser.ast.tokens.stream(2);
        }
        switch (parser.readTagAhead()) {
            .keyword_anytype => {
                parser.ast.tokens.stream(1);
                return null_node;
            },
            else => return parser.expectTypeExpr(allocator_n, allocator_e, allocator_x, allocator_s),
        }
    }

    /// Payload <- PIPE IDENTIFIER PIPE
    fn parsePayload(parser: *Parser, allocator_e: *AllocatorE) Error!u32 {
        _ = parser.eatToken(.pipe) orelse return @as(u32, 0);
        const identifier = try parser.expectToken(allocator_e, .identifier);
        _ = try parser.expectToken(allocator_e, .pipe);
        return identifier;
    }

    /// PtrPayload <- PIPE ASTERISK? IDENTIFIER PIPE
    fn parsePtrPayload(parser: *Parser, allocator_e: *AllocatorE) Error!u32 {
        _ = parser.eatToken(.pipe) orelse return @as(u32, 0);
        _ = parser.eatToken(.asterisk);
        const identifier = try parser.expectToken(allocator_e, .identifier);
        _ = try parser.expectToken(allocator_e, .pipe);
        return identifier;
    }

    /// PtrIndexPayload <- PIPE ASTERISK? IDENTIFIER (COMMA IDENTIFIER)? PIPE
    /// Returns the first identifier token, if any.
    fn parsePtrIndexPayload(parser: *Parser, allocator_e: *AllocatorE) Error!u32 {
        _ = parser.eatToken(.pipe) orelse return @as(u32, 0);
        _ = parser.eatToken(.asterisk);
        const identifier = try parser.expectToken(allocator_e, .identifier);
        if (parser.eatToken(.comma) != null) {
            _ = try parser.expectToken(allocator_e, .identifier);
        }
        _ = try parser.expectToken(allocator_e, .pipe);
        return identifier;
    }

    /// SwitchProng <- KEYWORD_inline? SwitchCase EQUALRARROW PtrIndexPayload? AssignExpr
    /// SwitchCase
    ///     <- SwitchItem (COMMA SwitchItem)* COMMA?
    ///      / KEYWORD_else
    fn parseSwitchProng(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);

        const is_inline = parser.eatToken(.keyword_inline) != null;

        if (parser.eatToken(.keyword_else) == null) {
            while (true) {
                const item = try parser.parseSwitchItem(allocator_n, allocator_e, allocator_x, allocator_s);
                if (item == 0) break;
                try parser.state.appendOne(allocator_s, item);
                if (parser.eatToken(.comma) == null) break;
            }
            if (state_top == parser.state.len(allocator_s.*)) {
                if (is_inline) parser.ast.tokens.unstream(1);
                return null_node;
            }
        }
        const arrow_token = try parser.expectToken(allocator_e, .equal_angle_bracket_right);
        _ = try parser.parsePtrIndexPayload(allocator_e);

        const items = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
        switch (items.len) {
            0 => return parser.addNode(allocator_n, .{
                .tag = if (is_inline) .switch_case_inline_one else .switch_case_one,
                .main_token = arrow_token,
                .data = .{
                    .lhs = 0,
                    .rhs = try parser.expectAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            }),
            1 => return parser.addNode(allocator_n, .{
                .tag = if (is_inline) .switch_case_inline_one else .switch_case_one,
                .main_token = arrow_token,
                .data = .{
                    .lhs = items[0],
                    .rhs = try parser.expectAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            }),
            else => return parser.addNode(allocator_n, .{
                .tag = if (is_inline) .switch_case_inline else .switch_case,
                .main_token = arrow_token,
                .data = .{
                    .lhs = try parser.addExtra(allocator_x, try parser.listToSpan(allocator_x, items)),
                    .rhs = try parser.expectAssignExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            }),
        }
    }

    /// SwitchItem <- Expr (DOT3 Expr)?
    fn parseSwitchItem(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const expr = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        if (expr == 0) return null_node;

        if (parser.eatToken(.ellipsis3)) |token| {
            return parser.addNode(allocator_n, .{
                .tag = .switch_range,
                .main_token = token,
                .data = .{
                    .lhs = expr,
                    .rhs = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s),
                },
            });
        }
        return expr;
    }

    const PtrModifiers = struct {
        align_node: u32,
        addrspace_node: u32,
        bit_range_start: u32,
        bit_range_end: u32,
    };

    fn parsePtrModifiers(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
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
            switch (parser.readTagAhead()) {
                .keyword_align => {
                    if (result.align_node != 0) {
                        try parser.warn(allocator_e, .extra_align_qualifier);
                    }
                    parser.ast.tokens.stream(1);
                    _ = try parser.expectToken(allocator_e, .l_paren);
                    result.align_node = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);

                    if (parser.eatToken(.colon)) |_| {
                        result.bit_range_start = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        _ = try parser.expectToken(allocator_e, .colon);
                        result.bit_range_end = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                    }

                    _ = try parser.expectToken(allocator_e, .r_paren);
                },
                .keyword_const => {
                    if (saw_const) {
                        try parser.warn(allocator_e, .extra_const_qualifier);
                    }
                    parser.ast.tokens.stream(1);
                    saw_const = true;
                },
                .keyword_volatile => {
                    if (saw_volatile) {
                        try parser.warn(allocator_e, .extra_volatile_qualifier);
                    }
                    parser.ast.tokens.stream(1);
                    saw_volatile = true;
                },
                .keyword_allowzero => {
                    if (saw_allowzero) {
                        try parser.warn(allocator_e, .extra_allowzero_qualifier);
                    }
                    parser.ast.tokens.stream(1);
                    saw_allowzero = true;
                },
                .keyword_addrspace => {
                    if (saw_addrspace) {
                        try parser.warn(allocator_e, .extra_addrspace_qualifier);
                    }
                    result.addrspace_node = try parser.parseAddrSpace(allocator_n, allocator_e, allocator_x, allocator_s);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        lhs: u32,
    ) Error!u32 {
        switch (parser.readTagAhead()) {
            .l_bracket => {
                const lbracket = parser.nextToken();
                const index_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);

                if (parser.eatToken(.ellipsis2)) |_| {
                    const end_expr = try parser.parseExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                    if (parser.eatToken(.colon)) |_| {
                        const sentinel = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        _ = try parser.expectToken(allocator_e, .r_bracket);
                        return parser.addNode(allocator_n, .{
                            .tag = .slice_sentinel,
                            .main_token = lbracket,
                            .data = .{
                                .lhs = lhs,
                                .rhs = try parser.addExtra(allocator_x, zig.AstNode.SliceSentinel{
                                    .start = index_expr,
                                    .end = end_expr,
                                    .sentinel = sentinel,
                                }),
                            },
                        });
                    }
                    _ = try parser.expectToken(allocator_e, .r_bracket);
                    if (end_expr == 0) {
                        return parser.addNode(allocator_n, .{
                            .tag = .slice_open,
                            .main_token = lbracket,
                            .data = .{
                                .lhs = lhs,
                                .rhs = index_expr,
                            },
                        });
                    }
                    return parser.addNode(allocator_n, .{
                        .tag = .slice,
                        .main_token = lbracket,
                        .data = .{
                            .lhs = lhs,
                            .rhs = try parser.addExtra(allocator_x, zig.AstNode.Slice{
                                .start = index_expr,
                                .end = end_expr,
                            }),
                        },
                    });
                }
                _ = try parser.expectToken(allocator_e, .r_bracket);
                return parser.addNode(allocator_n, .{
                    .tag = .array_access,
                    .main_token = lbracket,
                    .data = .{
                        .lhs = lhs,
                        .rhs = index_expr,
                    },
                });
            },
            .period_asterisk => return parser.addNode(allocator_n, .{
                .tag = .deref,
                .main_token = parser.nextToken(),
                .data = .{
                    .lhs = lhs,
                    .rhs = undefined,
                },
            }),
            .invalid_periodasterisks => {
                try parser.warn(allocator_e, .asterisk_after_ptr_deref);
                return parser.addNode(allocator_n, .{
                    .tag = .deref,
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = lhs,
                        .rhs = undefined,
                    },
                });
            },
            .period => switch (parser.relativeTagAhead(1)) {
                .identifier => return parser.addNode(allocator_n, .{
                    .tag = .field_access,
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = lhs,
                        .rhs = parser.nextToken(),
                    },
                }),
                .question_mark => return parser.addNode(allocator_n, .{
                    .tag = .unwrap_optional,
                    .main_token = parser.nextToken(),
                    .data = .{
                        .lhs = lhs,
                        .rhs = parser.nextToken(),
                    },
                }),
                .l_brace => {
                    // this a misplaced `.{`, handle the error somewhere else
                    return null_node;
                },
                else => {
                    parser.ast.tokens.stream(1);
                    try parser.warn(allocator_e, .expected_suffix_op);
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const main_token = parser.nextToken();
        const arg_expr = switch (parser.readTagAt(main_token)) {
            .keyword_opaque => null_node,
            .keyword_struct, .keyword_enum => blk: {
                if (parser.eatToken(.l_paren)) |_| {
                    const expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                    _ = try parser.expectToken(allocator_e, .r_paren);
                    break :blk expr;
                } else {
                    break :blk null_node;
                }
            },
            .keyword_union => blk: {
                if (parser.eatToken(.l_paren)) |_| {
                    if (parser.eatToken(.keyword_enum)) |_| {
                        if (parser.eatToken(.l_paren)) |_| {
                            const enum_tag_expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                            _ = try parser.expectToken(allocator_e, .r_paren);
                            _ = try parser.expectToken(allocator_e, .r_paren);

                            _ = try parser.expectToken(allocator_e, .l_brace);
                            const members = try parser.parseContainerMembers(allocator_n, allocator_e, allocator_x, allocator_s);
                            const members_span = try members.toSpan(parser, allocator_x);
                            _ = try parser.expectToken(allocator_e, .r_brace);
                            return parser.addNode(allocator_n, .{
                                .tag = switch (members.trailing) {
                                    true => .tagged_union_enum_tag_trailing,
                                    false => .tagged_union_enum_tag,
                                },
                                .main_token = main_token,
                                .data = .{
                                    .lhs = enum_tag_expr,
                                    .rhs = try parser.addExtra(allocator_x, members_span),
                                },
                            });
                        } else {
                            _ = try parser.expectToken(allocator_e, .r_paren);

                            _ = try parser.expectToken(allocator_e, .l_brace);
                            const members = try parser.parseContainerMembers(allocator_n, allocator_e, allocator_x, allocator_s);
                            _ = try parser.expectToken(allocator_e, .r_brace);
                            if (members.len <= 2) {
                                return parser.addNode(allocator_n, .{
                                    .tag = switch (members.trailing) {
                                        true => .tagged_union_two_trailing,
                                        false => .tagged_union_two,
                                    },
                                    .main_token = main_token,
                                    .data = .{
                                        .lhs = members.lhs,
                                        .rhs = members.rhs,
                                    },
                                });
                            } else {
                                const span = try members.toSpan(parser, allocator_x);
                                return parser.addNode(allocator_n, .{
                                    .tag = switch (members.trailing) {
                                        true => .tagged_union_trailing,
                                        false => .tagged_union,
                                    },
                                    .main_token = main_token,
                                    .data = .{
                                        .lhs = span.start,
                                        .rhs = span.end,
                                    },
                                });
                            }
                        }
                    } else {
                        const expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
                        _ = try parser.expectToken(allocator_e, .r_paren);
                        break :blk expr;
                    }
                } else {
                    break :blk null_node;
                }
            },
            else => {
                parser.ast.tokens.unstream(1);
                return parser.fail(allocator_e, .expected_container);
            },
        };
        _ = try parser.expectToken(allocator_e, .l_brace);
        const members = try parser.parseContainerMembers(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_brace);
        if (arg_expr == 0) {
            if (members.len <= 2) {
                return parser.addNode(allocator_n, .{
                    .tag = switch (members.trailing) {
                        true => .container_decl_two_trailing,
                        false => .container_decl_two,
                    },
                    .main_token = main_token,
                    .data = .{
                        .lhs = members.lhs,
                        .rhs = members.rhs,
                    },
                });
            } else {
                const span = try members.toSpan(parser, allocator_x);
                return parser.addNode(allocator_n, .{
                    .tag = switch (members.trailing) {
                        true => .container_decl_trailing,
                        false => .container_decl,
                    },
                    .main_token = main_token,
                    .data = .{
                        .lhs = span.start,
                        .rhs = span.end,
                    },
                });
            }
        } else {
            const span = try members.toSpan(parser, allocator_x);
            return parser.addNode(allocator_n, .{
                .tag = switch (members.trailing) {
                    true => .container_decl_arg_trailing,
                    false => .container_decl_arg,
                },
                .main_token = main_token,
                .data = .{
                    .lhs = arg_expr,
                    .rhs = try parser.addExtra(allocator_x, SubRange{
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
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) !bool {
        const main_token = parser.tokenIndex();
        switch (parser.readTagAhead()) {
            .keyword_enum, .keyword_union, .keyword_struct => {},
            else => return false,
        }
        const identifier = parser.tokenIndex() + 1;
        if (parser.readTagAt(identifier) != .identifier) return false;
        parser.ast.tokens.stream(2);

        try parser.warnMsg(allocator_e, .{
            .tag = .c_style_container,
            .token = identifier,
            .extra = .{ .expected_tag = parser.readTagAt(main_token) },
        });
        try parser.warnMsg(allocator_e, .{
            .tag = .zig_style_container,
            .is_note = true,
            .token = identifier,
            .extra = .{ .expected_tag = parser.readTagAt(main_token) },
        });

        _ = try parser.expectToken(allocator_e, .l_brace);
        _ = try parser.parseContainerMembers(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_brace);
        try parser.expectSemicolon(allocator_e, .expected_semi_after_decl, true);
        return true;
    }

    /// Holds temporary data until we are ready to construct the full ContainerDecl AST node.
    /// ByteAlign <- KEYWORD_align LPAREN Expr RPAREN
    fn parseByteAlign(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        _ = parser.eatToken(.keyword_align) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const expr = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        return expr;
    }

    /// SwitchProngList <- (SwitchProng COMMA)* SwitchProng?
    fn parseSwitchProngList(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) !SubRange {
        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);

        while (true) {
            const item = try parser.parseSwitchProng(allocator_n, allocator_e, allocator_x, allocator_s);
            if (item == 0) break;

            try parser.state.appendOne(allocator_s, item);

            switch (parser.readTagAhead()) {
                .comma => parser.ast.tokens.stream(1),
                // All possible delimiters.
                .colon, .r_paren, .r_brace, .r_bracket => break,
                // Likely just a missing comma; give error but continue parsing.
                else => try parser.warn(allocator_e, .expected_comma_after_switch_prong),
            }
        }
        return parser.listToSpan(allocator_x, parser.state.readManyAt(allocator_s.*, state_top));
    }

    /// ParamDeclList <- (ParamDecl COMMA)* ParamDecl?
    fn parseParamDeclList(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) !SmallSpan {
        _ = try parser.expectToken(allocator_e, .l_paren);
        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
        var varargs: union(enum) { none, seen, nonfinal: u32 } = .none;
        while (true) {
            if (parser.eatToken(.r_paren)) |_| break;
            if (varargs == .seen) varargs = .{ .nonfinal = parser.tokenIndex() };
            const param = try parser.expectParamDecl(allocator_n, allocator_e, allocator_x, allocator_s);
            if (param != 0) {
                try parser.state.appendOne(allocator_s, param);
            } else if (parser.relativeTagBehind(1) == .ellipsis3) {
                if (varargs == .none) varargs = .seen;
            }
            switch (parser.readTagAhead()) {
                .comma => parser.ast.tokens.stream(1),
                .r_paren => {
                    parser.ast.tokens.stream(1);
                    break;
                },
                .colon, .r_brace, .r_bracket => return parser.failExpected(allocator_e, .r_paren),
                // Likely just a missing comma; give error but continue parsing.
                else => try parser.warn(allocator_e, .expected_comma_after_param),
            }
        }
        if (varargs == .nonfinal) {
            try parser.warnMsg(allocator_e, .{ .tag = .varargs_nonfinal, .token = varargs.nonfinal });
        }
        const params = parser.state.readManyAt(allocator_s.*, state_top); // XXX: Maybe trouble
        return switch (params.len) {
            0 => SmallSpan{ .zero_or_one = 0 },
            1 => SmallSpan{ .zero_or_one = params[0] },
            else => SmallSpan{ .multi = try parser.listToSpan(allocator_x, params) },
        };
    }

    /// FnCallArguments <- LPAREN ExprList RPAREN
    /// ExprList <- (Expr COMMA)* Expr?
    fn parseBuiltinCall(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
    ) Error!u32 {
        const builtin_token = parser.assertToken(.builtin);
        if (parser.readTagAt(parser.nextToken()) != .l_paren) {
            parser.ast.tokens.unstream(1);
            try parser.warn(allocator_e, .expected_param_list);
            // Pretend this was an identifier so we can continue parsing.
            return parser.addNode(allocator_n, .{
                .tag = .identifier,
                .main_token = builtin_token,
                .data = .{
                    .lhs = undefined,
                    .rhs = undefined,
                },
            });
        }
        const state_top: usize = parser.state.len(allocator_s.*);
        defer parser.state.undefine(parser.state.len(allocator_s.*) - state_top);
        while (true) {
            if (parser.eatToken(.r_paren)) |_| break;
            const param = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
            try parser.state.appendOne(allocator_s, param);
            switch (parser.readTagAhead()) {
                .comma => parser.ast.tokens.stream(1),
                .r_paren => {
                    parser.ast.tokens.stream(1);
                    break;
                },
                // Likely just a missing comma; give error but continue parsing.
                else => try parser.warn(allocator_e, .expected_comma_after_arg),
            }
        }
        const comma = (parser.relativeTagBehind(2) == .comma);
        // XXX: Maybe trouble
        const params = parser.state.readManyAt(allocator_s.*, state_top);
        switch (params.len) {
            0 => return parser.addNode(allocator_n, .{
                .tag = .builtin_call_two,
                .main_token = builtin_token,
                .data = .{
                    .lhs = 0,
                    .rhs = 0,
                },
            }),
            1 => return parser.addNode(allocator_n, .{
                .tag = if (comma) .builtin_call_two_comma else .builtin_call_two,
                .main_token = builtin_token,
                .data = .{
                    .lhs = params[0],
                    .rhs = 0,
                },
            }),
            2 => return parser.addNode(allocator_n, .{
                .tag = if (comma) .builtin_call_two_comma else .builtin_call_two,
                .main_token = builtin_token,
                .data = .{
                    .lhs = params[0],
                    .rhs = params[1],
                },
            }),
            else => {
                const span = try parser.listToSpan(allocator_x, params);
                return parser.addNode(allocator_n, .{
                    .tag = if (comma) .builtin_call_comma else .builtin_call,
                    .main_token = builtin_token,
                    .data = .{
                        .lhs = span.start,
                        .rhs = span.end,
                    },
                });
            },
        }
    }

    /// KEYWORD_if LPAREN Expr RPAREN PtrPayload? Body (KEYWORD_else Payload? Body)?
    fn parseIf(
        parser: *Parser,
        allocator_n: *AllocatorN,
        allocator_e: *AllocatorE,
        allocator_x: *AllocatorX,
        allocator_s: *AllocatorS,
        comptime bodyParseFn: fn (
            parser: *Parser,
            allocator_n: *AllocatorN,
            allocator_e: *AllocatorE,
            allocator_x: *AllocatorX,
            allocator_s: *AllocatorS,
        ) Error!u32,
    ) Error!u32 {
        const if_token = parser.eatToken(.keyword_if) orelse return null_node;
        _ = try parser.expectToken(allocator_e, .l_paren);
        const condition = try parser.expectExpr(allocator_n, allocator_e, allocator_x, allocator_s);
        _ = try parser.expectToken(allocator_e, .r_paren);
        _ = try parser.parsePtrPayload(allocator_e);

        const then_expr = try bodyParseFn(parser, allocator_n, allocator_e, allocator_x, allocator_s);
        builtin.assert(then_expr != 0);

        _ = parser.eatToken(.keyword_else) orelse return parser.addNode(allocator_n, .{
            .tag = .if_simple,
            .main_token = if_token,
            .data = .{
                .lhs = condition,
                .rhs = then_expr,
            },
        });
        _ = try parser.parsePayload(allocator_e);
        const else_expr = try bodyParseFn(parser, allocator_n, allocator_e, allocator_x, allocator_s);
        builtin.assert(then_expr != 0);

        return parser.addNode(allocator_n, .{
            .tag = .@"if",
            .main_token = if_token,
            .data = .{
                .lhs = condition,
                .rhs = try parser.addExtra(allocator_x, zig.AstNode.If{
                    .then_expr = then_expr,
                    .else_expr = else_expr,
                }),
            },
        });
    }

    /// Skips over doc comment tokens. Returns the first one, if any.
    fn eatDocComments(parser: *Parser, allocator_e: *AllocatorE) !?u32 {
        if (parser.eatToken(.doc_comment)) |tok| {
            var first_line = tok;
            if (tok > 0 and tokensOnSameLine(parser, tok - 1, tok)) {
                try parser.warnMsg(allocator_e, .{
                    .tag = .same_line_doc_comment,
                    .token = tok,
                });
                first_line = parser.eatToken(.doc_comment) orelse return null;
            }
            while (parser.eatToken(.doc_comment)) |_| {}
            return first_line;
        }
        return null;
    }
    fn tokensOnSameLine(parser: *Parser, token1: u32, token2: u32) bool {
        const start_1: u32 = parser.ast.tokens.readOneAt(token1).start;
        const start_2: u32 = parser.ast.tokens.readOneAt(token2).start;
        return mem.indexOfFirstEqualOne(u8, '\n', parser.ast.source[start_1..start_2]) == null;
    }
    fn tokenIndex(parser: *Parser) u32 {
        return @intCast(u32, parser.ast.tokens.index());
    }
    fn readTagAhead(parser: *Parser) zig.Token.Tag {
        return parser.ast.tokens.readOneAhead().tag;
    }
    fn readStartAhead(parser: *Parser) zig.Token.Tag {
        return parser.ast.tokens.readOneAhead().start;
    }
    fn readTagAt(parser: *Parser, index: usize) zig.Token.Tag {
        return parser.ast.tokens.readOneAt(index).tag;
    }

    fn eatToken(parser: *Parser, tag: zig.Token.Tag) ?u32 {
        return if (parser.readTagAhead() == tag) parser.nextToken() else null;
    }

    fn assertToken(parser: *Parser, tag: zig.Token.Tag) u32 {
        const token = parser.nextToken();
        builtin.assert(parser.readTagAt(token) == tag);
        return token;
    }

    fn expectToken(parser: *Parser, allocator_e: *AllocatorE, tag: zig.Token.Tag) Error!u32 {
        if (parser.readTagAhead() != tag) {
            return parser.failMsg(allocator_e, .{
                .tag = .expected_token,
                .token = parser.tokenIndex(),
                .extra = .{ .expected_tag = tag },
            });
        }
        return parser.nextToken();
    }
    fn expectSemicolon(parser: *Parser, allocator_e: *AllocatorE, error_tag: zig.AstError.Tag, recoverable: bool) !void {
        if (parser.readTagAhead() == .semicolon) {
            _ = parser.nextToken();
            return;
        }
        try parser.warn(allocator_e, error_tag);
        if (!recoverable) return error.ParseError;
    }
    fn nextToken(parser: *Parser) u32 {
        const result = parser.tokenIndex();
        parser.ast.tokens.stream(1);
        return @intCast(u32, result);
    }

    pub fn init(ast: *abstract.SyntaxTree, allocator_s: *zig.Allocator.State) !Parser {
        return .{ .ast = ast, .state = zig.StateArray.init(allocator_s) };
    }
    pub fn deinit(parser: *Parser, allocator_s: *zig.Allocator.State) void {
        parser.state.deinit(allocator_s);
    }
};

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
        const index = @intCast(usize, @enumToInt(enum_value));
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
            .field_type = Data,
            .default_value = if (field_default) |d| @ptrCast(?*const anyopaque, &d) else null,
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
