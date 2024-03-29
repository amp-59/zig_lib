const root = @import("@build");
const zl = blk: {
    if (@hasDecl(root, "zl")) {
        break :blk root.zl;
    }
    @compileError("Add the following declaration to build.zig:\n\n\rpub const zl = @import(\"./zig_lib/zig_lib.zig\");\n");
};
pub usingnamespace zl.start;
pub const is_safe: bool = enable_debugging;
pub const runtime_assertions: bool = enable_debugging;
pub const want_stack_traces: bool = enable_debugging;
pub const have_stack_traces: bool = false;
pub const AbsoluteState = struct {
    home: [:0]u8,
    cwd: [:0]u8,
    proj: [:0]u8,
    pid: u16,
};
pub const Builder =
    if (@hasDecl(root, "Builder")) root.Builder else zl.builder.GenericBuilder(.{});
pub const message_style: [:0]const u8 =
    if (@hasDecl(root, "message_style")) root.message_style else "\x1b[2m";
pub const enable_debugging: bool =
    if (@hasDecl(root, "enable_debugging")) root.enable_debugging else false;
pub const trace: zl.debug.Trace =
    if (@hasDecl(root, "trace")) root.trace else zl.builtin.zl_trace;
pub const logging_override: zl.debug.Logging.Override = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = true,
    .Fault = true,
};
pub const logging_default: zl.debug.Logging.Default = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = true,
    .Fault = true,
};
pub const signal_handlers = .{
    .IllegalInstruction = enable_debugging,
    .BusError = enable_debugging,
    .FloatingPointError = enable_debugging,
    .Trap = enable_debugging,
    .SegmentationFault = enable_debugging,
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    @setRuntimeSafety(false);
    if (args.len < 5) {
        zl.proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const arena = Builder.AddressSpace.arena(Builder.specification.options.max_thread_count);
    zl.mem.map(.{
        .errors = .{},
        .logging = .{ .Acquire = false },
    }, .{}, .{}, arena.lb_addr, 4096);
    var allocator: zl.builder.types.Allocator = .{
        .start = arena.lb_addr,
        .next = arena.lb_addr,
        .finish = arena.lb_addr +% 4096,
    };
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    const top: *Builder.Node = Builder.Node.init(&allocator, args, vars);
    top.sh.as.lock = &address_space;
    top.sh.ts.lock = &thread_space;
    try zl.meta.wrap(root.buildMain(&allocator, top));
    try zl.meta.wrap(Builder.processCommands(&address_space, &thread_space, &allocator, top));
    allocator.unmapAll();
}
