const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const x86 = zl.x86;
const math = zl.math;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

const tab = @import("./tab.zig");

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;
pub const runtime_assertions: bool = true;

fn testAssembler() !void {
    var as: x86.Assembler = x86.Assembler.init(tab.x86_asm.input);
    var buf: [32768]u8 = undefined;
    var pos: usize = 0;

    while (try as.parseNext()) |entry| {
        const instr = try x86.Instruction.new(.none, entry.mnemonic, &entry.ops);
        const len: usize = instr.encode(buf[pos..].ptr);
        try debug.expectEqualMemory([]const u8, tab.x86_asm.output[pos .. pos + len], buf[pos .. pos + len]);
        pos +%= len;
    }
    for (buf[0..pos], 0..) |val, idx| {
        try debug.expectEqual(u8, tab.x86_asm.output[idx], val);
    }
}
fn testDisassembler() !void {
    var disassembler = x86.Disassembler.init(tab.x86_dis.input);
    var buf: [32768]u8 = undefined;
    var ptr: [*]u8 = &buf;
    @memset(&buf, '@');
    while (try disassembler.next()) |inst| {
        ptr += inst.formatWriteBuf(ptr);
    }
    const len: usize = @intFromPtr(ptr) -% @intFromPtr(&buf);

    try debug.expectEqualMemory([]const u8, tab.x86_dis.output, buf[0..len]);
}
pub fn main() !void {
    try testAssembler();
    try testDisassembler();
}
