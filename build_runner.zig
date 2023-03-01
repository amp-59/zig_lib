const root = @import("@build");
const build_fn: fn (*build.Allocator, *build.Builder) anyerror!void = root.buildMain;

const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const mach = srg.mach;
const meta = srg.meta;
const build = srg.build;
const preset = srg.preset;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const is_verbose: bool = if (@hasDecl(root, "is_verbose")) root.is_verbose else false;
pub const is_silent: bool = if (@hasDecl(root, "is_silent")) root.is_silent else true;
pub const runtime_assertions: bool = if (@hasDecl(root, "runtime_assertions")) root.runtime_assertions else false;

pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 64,
    .logging = preset.address_space.logging.silent,
});
const Options = build.GlobalOptions;

fn showAllCommands(builder: *build.Builder) void {
    var buf: [1024 * 1024]u8 = undefined;
    builtin.debug.logAlways(buf[0..asmWriteAllCommands(builder, &buf, maxWidths(builder)[0])]);
}
fn showHelpAndCommands(builder: *build.Builder) void {
    builtin.debug.logAlways(help_s);
    showAllCommands(builder);
}
fn rewind(builder: *build.Builder) void {
    asmRewind(builder);
}
const release_fast_s: [:0]const u8 = "prioritise low runtime";
const release_small_s: [:0]const u8 = "prioritise small executable size";
const release_safe_s: [:0]const u8 = "prioritise correctness";
const debug_s: [:0]const u8 = "prioritise comptime performance";
const strip_s: [:0]const u8 = "do not emit debug symbols";
const no_strip_s: [:0]const u8 = "emit debug symbols";
const verbose_s: [:0]const u8 = "show compile commands when executing";
const silent_s: [:0]const u8 = "do not show compile commands when executing";
const run_cmd_s: [:0]const u8 = "run commands for subsequent targets";
const build_cmd_s: [:0]const u8 = "build commands for subsequent targets";
const fmt_cmd_s: [:0]const u8 = "fmt commands for subsequent targets";
const help_s: []const u8 = Options.Map.helpMessage(opts_map);

// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "mode",    .long = "--fast",       .assign = .{ .any = &(.ReleaseFast) },  .descr = release_fast_s },
    .{ .field_name = "mode",    .long = "--small",      .assign = .{ .any = &(.ReleaseSmall) }, .descr = release_small_s },
    .{ .field_name = "mode",    .long = "--safe",       .assign = .{ .any = &(.ReleaseSafe) },  .descr = release_safe_s },
    .{ .field_name = "mode",    .long = "--debug",      .assign = .{ .any = &(.Debug) },        .descr = debug_s },
    .{ .field_name = "strip",   .long = "--extra",      .assign = .{ .boolean = false },        .descr = debug_s },
    .{ .field_name = "cmd",     .long = "--run",        .assign = .{ .any = &(.run) },          .descr = run_cmd_s },
    .{ .field_name = "cmd",     .long = "--build",      .assign = .{ .any = &(.build) },        .descr = build_cmd_s },
    .{ .field_name = "cmd",     .long = "--fmt",        .assign = .{ .any = &(.fmt) },          .descr = fmt_cmd_s },
});
// zig fmt: on

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: build.Allocator = try build.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    if (args.len < 5) {
        builtin.debug.logAlways("Expected path to zig compiler, " ++
            "build root directory path, " ++
            "cache root directory path, " ++
            "global cache root directory path");
        sys.call(.exit, .{}, noreturn, .{2});
    }
    const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
    const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
    const cache_dir: [:0]const u8 = meta.manyToSlice(args[3]);
    const global_cache_dir: [:0]const u8 = meta.manyToSlice(args[4]);
    args = args[5..];
    const paths: build.Builder.Paths = .{
        .zig_exe = zig_exe,
        .build_root = build_root,
        .cache_dir = cache_dir,
        .global_cache_dir = global_cache_dir,
    };
    var builder: build.Builder = build.Builder.init(&allocator, paths, options, args, vars);
    _ = builder.addGroup(&allocator, "all");
    try build_fn(&allocator, &builder);
    rewind(&builder);
    var index: u64 = 0;
    while (index != args.len) {
        const name: [:0]const u8 = meta.manyToSlice(args[index]);
        if (mach.testEqualMany8(name, "show")) {
            return showHelpAndCommands(&builder);
        }
        if (mach.testEqualMany8(name, "--")) {
            break;
        }
        var groups: build.GroupList = builder.groups;
        group: while (groups.next()) |group_node| : (groups.node = group_node) {
            if (mach.testEqualMany8(name, groups.node.this.name)) {
                try invokeTargetGroup(&allocator, &builder, groups);
                break :group;
            } else {
                var targets: build.TargetList = groups.node.this.targets;
                while (targets.next()) |target_node| : (targets.node = target_node) {
                    if (mach.testEqualMany8(name, targets.node.this.name)) {
                        try invokeTarget(&allocator, &builder, targets.node.this);
                        break :group;
                    }
                }
            }
        } else {
            showHelpAndCommands(&builder);
            return error.CommandNotFound;
        }
        index +%= 1;
    }
}
fn invokeTargetGroup(allocator: *build.Allocator, builder: *build.Builder, groups: build.GroupList) !void {
    var targets: build.TargetList = groups.node.this.targets.itr();
    while (targets.next()) |target_node| : (targets.node = target_node) {
        try invokeTarget(allocator, builder, targets.node.this);
    }
}
fn invokeTarget(allocator: *build.Allocator, builder: *build.Builder, target: *build.Target) !void {
    const save: build.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    switch (builder.options.cmd) {
        .fmt => try target.format(),
        .run => try target.run(),
        .build => try target.build(),
    }
}
inline fn maxWidths(builder: *build.Builder) extern struct { u64, u64 } {
    return asmMaxWidths(builder);
}
extern fn asmMaxWidths(builder: *build.Builder) extern struct { u64, u64 };
comptime {
    asm (
        \\	.intel_syntax noprefix
        \\asmMaxWidths:
        \\	push	r15
        \\	push	r14
        \\	push	rbx
        \\	mov	rcx, qword ptr [rdi + 72]
        \\	mov	r8, qword ptr [rdi + 80]
        \\	mov	r9, qword ptr [rdi + 88]
        \\	xor	edx, edx
        \\	xor	eax, eax
        \\.asmMaxWidths_1:
        \\	cmp	r9, r8
        \\	je	.asmMaxWidths_2
        \\	mov	r10, qword ptr [rcx + 8]
        \\	test	r10, r10
        \\	je	.asmMaxWidths_3
        \\	mov	rsi, qword ptr [rcx]
        \\	mov	r15, rdx
        \\	mov	rdi, rax
        \\	mov	rcx, qword ptr [rsi + 24]
        \\	mov	r11, qword ptr [rsi + 32]
        \\	mov	r14, qword ptr [rsi + 40]
        \\.asmMaxWidths_6:
        \\	cmp	r14, r11
        \\	je	.asmMaxWidths_7
        \\	mov	rbx, qword ptr [rcx + 8]
        \\	test	rbx, rbx
        \\	je	.asmMaxWidths_9
        \\	mov	rcx, qword ptr [rcx]
        \\	mov	rsi, qword ptr [rcx + 8]
        \\	mov	rcx, qword ptr [rcx + 24]
        \\	cmp	rdi, rsi
        \\	cmovbe	rdi, rsi
        \\	cmp	r15, rcx
        \\	cmovbe	r15, rcx
        \\	mov	rcx, rbx
        \\	jmp	.asmMaxWidths_6
        \\.asmMaxWidths_7:
        \\	mov	rcx, r10
        \\	jmp	.asmMaxWidths_1
        \\.asmMaxWidths_9:
        \\	mov	rcx, r10
        \\	mov	rdx, r15
        \\	mov	rax, rdi
        \\	jmp	.asmMaxWidths_1
        \\.asmMaxWidths_2:
        \\	xor	edx, edx
        \\	xor	eax, eax
        \\.asmMaxWidths_3:
        \\	add	rax, 8
        \\	add	rdx, 8
        \\	and	rax, -8
        \\	and	rdx, -8
        \\	pop	rbx
        \\	pop	r14
        \\	pop	r15
        \\	ret
    );
}
extern fn asmWriteAllCommands(builder: *build.Builder, buf: *[1024 * 1024]u8, name_max_width: u64) callconv(.C) u64;
comptime {
    asm (
        \\	.intel_syntax noprefix
        \\asmWriteAllCommands:
        \\	push	rbp
        \\	push	r15
        \\	push	r14
        \\	push	r13
        \\	push	r12
        \\	push	rbx
        \\	mov	rax, qword ptr [rdi + 88]
        \\	cmp	rax, qword ptr [rdi + 80]
        \\	je	.asmWriteAllCommands58
        \\	mov	r9, qword ptr [rdi + 72]
        \\	mov	rcx, qword ptr [r9 + 8]
        \\	test	rcx, rcx
        \\	je	.asmWriteAllCommands58
        \\	lea	rdi, [rsi + 96]
        \\	lea	rbp, [rsi + rdx + 4]
        \\	lea	rax, [rsi + 4]
        \\	lea	r10, [rsi + 100]
        \\	xor	r8d, r8d
        \\	mov	qword ptr [rsp - 32], rdi
        \\	lea	rdi, [rsi + rdx + 100]
        \\	mov	qword ptr [rsp - 40], rax
        \\	mov	qword ptr [rsp - 16], r10
        \\	mov	qword ptr [rsp - 48], rbp
        \\	mov	qword ptr [rsp - 24], rdi
        \\	jmp	.asmWriteAllCommands4
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands3:
        \\	mov	r9, qword ptr [rsp - 8]
        \\	mov	rcx, qword ptr [r9 + 8]
        \\	test	rcx, rcx
        \\	je	.asmWriteAllCommands59
        \\.asmWriteAllCommands4:
        \\	mov	rax, qword ptr [r9]
        \\	mov	qword ptr [rsp - 8], rcx
        \\	lea	rcx, [rsi + r8]
        \\	mov	r10, qword ptr [rax + 8]
        \\	test	r10, r10
        \\	je	.asmWriteAllCommands18
        \\	mov	rbx, qword ptr [rax]
        \\	cmp	r10, 16
        \\	jb	.asmWriteAllCommands7
        \\	mov	rax, rcx
        \\	sub	rax, rbx
        \\	cmp	rax, 128
        \\	jae	.asmWriteAllCommands8
        \\.asmWriteAllCommands7:
        \\	xor	edi, edi
        \\	jmp	.asmWriteAllCommands16
        \\.asmWriteAllCommands8:
        \\	cmp	r10, 128
        \\	jae	.asmWriteAllCommands10
        \\	xor	edi, edi
        \\	jmp	.asmWriteAllCommands14
        \\.asmWriteAllCommands10:
        \\	mov	rax, qword ptr [rsp - 32]
        \\	mov	rdi, r10
        \\	xor	ebp, ebp
        \\	and	rdi, -128
        \\	add	rax, r8
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands11:
        \\	vmovups	ymm0, ymmword ptr [rbx + rbp]
        \\	vmovups	ymm1, ymmword ptr [rbx + rbp + 32]
        \\	vmovups	ymm2, ymmword ptr [rbx + rbp + 64]
        \\	vmovups	ymm3, ymmword ptr [rbx + rbp + 96]
        \\	vmovups	ymmword ptr [rax + rbp - 96], ymm0
        \\	vmovups	ymmword ptr [rax + rbp - 64], ymm1
        \\	vmovups	ymmword ptr [rax + rbp - 32], ymm2
        \\	vmovups	ymmword ptr [rax + rbp], ymm3
        \\	sub	rbp, -128
        \\	cmp	rdi, rbp
        \\	jne	.asmWriteAllCommands11
        \\	mov	rbp, qword ptr [rsp - 48]
        \\	cmp	r10, rdi
        \\	je	.asmWriteAllCommands18
        \\	test	r10b, 112
        \\	je	.asmWriteAllCommands16
        \\.asmWriteAllCommands14:
        \\	mov	rax, rdi
        \\	mov	rdi, r10
        \\	and	rdi, -16
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands15:
        \\	vmovups	xmm0, xmmword ptr [rbx + rax]
        \\	vmovups	xmmword ptr [rcx + rax], xmm0
        \\	add	rax, 16
        \\	cmp	rdi, rax
        \\	jne	.asmWriteAllCommands15
        \\	jmp	.asmWriteAllCommands17
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands16:
        \\	movzx	eax, byte ptr [rbx + rdi]
        \\	mov	byte ptr [rcx + rdi], al
        \\	inc	rdi
        \\.asmWriteAllCommands17:
        \\	cmp	r10, rdi
        \\	jne	.asmWriteAllCommands16
        \\.asmWriteAllCommands18:
        \\	mov	word ptr [rcx + r10], 2618
        \\	lea	r8, [r8 + r10 + 2]
        \\	mov	rax, qword ptr [r9]
        \\	mov	r13, qword ptr [rax + 32]
        \\	mov	r9, qword ptr [rax + 40]
        \\	cmp	r9, r13
        \\	je	.asmWriteAllCommands3
        \\	mov	r14, qword ptr [rax + 24]
        \\	jmp	.asmWriteAllCommands22
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands20:
        \\	xor	eax, eax
        \\.asmWriteAllCommands21:
        \\	lea	rcx, [rax + r15]
        \\	lea	r8, [rax + r15 + 1]
        \\	mov	r14, r10
        \\	mov	byte ptr [rsi + rcx], 10
        \\	cmp	r9, r13
        \\	je	.asmWriteAllCommands3
        \\.asmWriteAllCommands22:
        \\	mov	r10, qword ptr [r14 + 8]
        \\	test	r10, r10
        \\	je	.asmWriteAllCommands3
        \\	mov	dword ptr [rsi + r8], 538976288
        \\	lea	r15, [r8 + 4]
        \\	mov	rcx, qword ptr [r14]
        \\	mov	r11, qword ptr [rcx + 8]
        \\	test	r11, r11
        \\	je	.asmWriteAllCommands26
        \\	mov	rcx, qword ptr [rcx]
        \\	cmp	r11, 16
        \\	jb	.asmWriteAllCommands25
        \\	mov	rax, qword ptr [rsp - 40]
        \\	lea	r12, [rax + r8]
        \\	mov	rdi, r12
        \\	sub	rdi, rcx
        \\	cmp	rdi, 128
        \\	jae	.asmWriteAllCommands29
        \\.asmWriteAllCommands25:
        \\	xor	edi, edi
        \\.asmWriteAllCommands38:
        \\	mov	rax, qword ptr [rsp - 40]
        \\	lea	rbx, [rax + r8]
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands39:
        \\	movzx	eax, byte ptr [rcx + rdi]
        \\	mov	byte ptr [rbx + rdi], al
        \\	inc	rdi
        \\	cmp	r11, rdi
        \\	jne	.asmWriteAllCommands39
        \\.asmWriteAllCommands40:
        \\	mov	rax, qword ptr [r14]
        \\	mov	rdi, qword ptr [rax + 8]
        \\	jmp	.asmWriteAllCommands41
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands26:
        \\	xor	edi, edi
        \\.asmWriteAllCommands41:
        \\	mov	rcx, rdx
        \\	mov	al, 32
        \\	sub	rcx, rdi
        \\	add	rdi, r15
        \\	add	r15, rdx
        \\	add	rdi, rsi
        \\	#APP
        \\	rep		stosb	byte ptr es:[rdi], al
        \\	#NO_APP
        \\	mov	rcx, qword ptr [r14]
        \\	mov	rax, qword ptr [rcx + 24]
        \\	test	rax, rax
        \\	je	.asmWriteAllCommands20
        \\	mov	rcx, qword ptr [rcx + 16]
        \\	cmp	rax, 16
        \\	jb	.asmWriteAllCommands43
        \\	lea	r12, [rbp + r8]
        \\	mov	rdi, r12
        \\	sub	rdi, rcx
        \\	cmp	rdi, 128
        \\	jae	.asmWriteAllCommands46
        \\.asmWriteAllCommands43:
        \\	xor	edi, edi
        \\.asmWriteAllCommands55:
        \\	add	r8, rbp
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands56:
        \\	movzx	ebx, byte ptr [rcx + rdi]
        \\	mov	byte ptr [r8 + rdi], bl
        \\	inc	rdi
        \\	cmp	rax, rdi
        \\	jne	.asmWriteAllCommands56
        \\.asmWriteAllCommands57:
        \\	mov	rax, qword ptr [r14]
        \\	mov	rax, qword ptr [rax + 24]
        \\	jmp	.asmWriteAllCommands21
        \\.asmWriteAllCommands29:
        \\	cmp	r11, 128
        \\	jae	.asmWriteAllCommands31
        \\	xor	edi, edi
        \\	jmp	.asmWriteAllCommands35
        \\.asmWriteAllCommands46:
        \\	cmp	rax, 128
        \\	jae	.asmWriteAllCommands48
        \\	xor	edi, edi
        \\	jmp	.asmWriteAllCommands52
        \\.asmWriteAllCommands31:
        \\	mov	rax, qword ptr [rsp - 16]
        \\	mov	rdi, r11
        \\	xor	ebp, ebp
        \\	and	rdi, -128
        \\	lea	rbx, [rax + r8]
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands32:
        \\	vmovups	ymm0, ymmword ptr [rcx + rbp]
        \\	vmovups	ymm1, ymmword ptr [rcx + rbp + 32]
        \\	vmovups	ymm2, ymmword ptr [rcx + rbp + 64]
        \\	vmovups	ymm3, ymmword ptr [rcx + rbp + 96]
        \\	vmovups	ymmword ptr [rbx + rbp - 96], ymm0
        \\	vmovups	ymmword ptr [rbx + rbp - 64], ymm1
        \\	vmovups	ymmword ptr [rbx + rbp - 32], ymm2
        \\	vmovups	ymmword ptr [rbx + rbp], ymm3
        \\	sub	rbp, -128
        \\	cmp	rdi, rbp
        \\	jne	.asmWriteAllCommands32
        \\	mov	rbp, qword ptr [rsp - 48]
        \\	cmp	r11, rdi
        \\	je	.asmWriteAllCommands40
        \\	test	r11b, 112
        \\	je	.asmWriteAllCommands38
        \\.asmWriteAllCommands35:
        \\	mov	rbx, rdi
        \\	mov	rdi, r11
        \\	and	rdi, -16
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands36:
        \\	vmovups	xmm0, xmmword ptr [rcx + rbx]
        \\	vmovups	xmmword ptr [r12 + rbx], xmm0
        \\	add	rbx, 16
        \\	cmp	rdi, rbx
        \\	jne	.asmWriteAllCommands36
        \\	cmp	r11, rdi
        \\	je	.asmWriteAllCommands40
        \\	jmp	.asmWriteAllCommands38
        \\.asmWriteAllCommands48:
        \\	mov	rbp, qword ptr [rsp - 24]
        \\	mov	rdi, rax
        \\	xor	ebx, ebx
        \\	and	rdi, -128
        \\	add	rbp, r8
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands49:
        \\	vmovups	ymm0, ymmword ptr [rcx + rbx]
        \\	vmovups	ymm1, ymmword ptr [rcx + rbx + 32]
        \\	vmovups	ymm2, ymmword ptr [rcx + rbx + 64]
        \\	vmovups	ymm3, ymmword ptr [rcx + rbx + 96]
        \\	vmovups	ymmword ptr [rbp + rbx - 96], ymm0
        \\	vmovups	ymmword ptr [rbp + rbx - 64], ymm1
        \\	vmovups	ymmword ptr [rbp + rbx - 32], ymm2
        \\	vmovups	ymmword ptr [rbp + rbx], ymm3
        \\	sub	rbx, -128
        \\	cmp	rdi, rbx
        \\	jne	.asmWriteAllCommands49
        \\	mov	rbp, qword ptr [rsp - 48]
        \\	cmp	rax, rdi
        \\	je	.asmWriteAllCommands57
        \\	test	al, 112
        \\	je	.asmWriteAllCommands55
        \\.asmWriteAllCommands52:
        \\	mov	rbx, rdi
        \\	mov	rdi, rax
        \\	and	rdi, -16
        \\	.p2align	4, 0x90
        \\.asmWriteAllCommands53:
        \\	vmovups	xmm0, xmmword ptr [rcx + rbx]
        \\	vmovups	xmmword ptr [r12 + rbx], xmm0
        \\	add	rbx, 16
        \\	cmp	rdi, rbx
        \\	jne	.asmWriteAllCommands53
        \\	cmp	rax, rdi
        \\	je	.asmWriteAllCommands57
        \\	jmp	.asmWriteAllCommands55
        \\.asmWriteAllCommands58:
        \\	xor	r8d, r8d
        \\.asmWriteAllCommands59:
        \\	mov	rax, r8
        \\	pop	rbx
        \\	pop	r12
        \\	pop	r13
        \\	pop	r14
        \\	pop	r15
        \\	pop	rbp
        \\	vzeroupper
        \\	ret
    );
}
extern fn asmRewind(builder: *build.Builder) callconv(.C) void;
comptime {
    asm (
        \\	.intel_syntax noprefix
        \\asmRewind:
        \\	cmp	qword ptr [rdi + 80], 0
        \\	je	.asmRewind_4
        \\	mov	rax, qword ptr [rdi + 64]
        \\	mov	rcx, qword ptr [rax + 8]
        \\	test	rcx, rcx
        \\	je	.asmRewind_4
        \\	.p2align	4, 0x90
        \\.asmRewind_2:
        \\	mov	rax, qword ptr [rax]
        \\	mov	rdx, qword ptr [rax + 16]
        \\	mov	qword ptr [rax + 24], rdx
        \\	mov	qword ptr [rax + 40], 0
        \\	mov	rax, rcx
        \\	mov	rcx, qword ptr [rcx + 8]
        \\	test	rcx, rcx
        \\	jne	.asmRewind_2
        \\.asmRewind_4:
        \\	ret
    );
}
