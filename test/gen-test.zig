const zl = @import("../zig_lib.zig");
const exe = zl.exe;
const sys = zl.sys;
const gen = zl.gen;
const mem = zl.mem;
const debug = zl.debug;
const builtin = zl.builtin;

const perf = @import("../top/perf.zig");

pub usingnamespace zl.start;

comptime {
    _ = zl.mach;
}

pub const Access = enum(u32) {
    pub const file = 0x0;
    pub const exec = 0x1;
    pub const write = 0x2;
    pub const read = 0x4;
};
fn testMemoryContainerDecls() void {
    gen.containerDeclsToBitField(sys.MAP, usize, "Map");
    gen.containerDeclsToBitField(sys.PROT, usize, "Protect");
    gen.containerDeclsToBitField(sys.MADV, usize, "Advise");
    gen.containerDeclsToBitField(sys.AT, usize, "At");
}
fn testFileContainerDecls() void {
    gen.containerDeclsToBitField(sys.CLONE, u32, "Clone");
    gen.containerDeclsToBitField(sys.FPE, usize, "FloatingPointError");
    gen.containerDeclsToBitField(sys.SS, usize, "SignalStack");
    gen.containerDeclsToBitField(sys.SA, usize, "SignalAction");
    gen.containerDeclsToBitField(sys.REMAP, usize, "Remap");
    gen.containerDeclsToBitField(sys.MS, usize, "Sync");
    gen.containerDeclsToBitField(sys.O, usize, "Open");
    gen.containerDeclsToBitField(sys.RWF, usize, "ReadWrite");
    gen.containerDeclsToBitField(sys.S, usize, "Status");
    gen.containerDeclsToBitField(sys.STATX.ATTR, usize, "StatusExtendedAttributes");
    gen.containerDeclsToBitField(sys.STATX, usize, "StatusExtendedFields");
    gen.containerDeclsToBitField(Access, usize, "Access");
}
fn testIOCTLContainerDecls() void {
    gen.containerDeclsToBitField(sys.TC.C, usize, "Control");
    gen.containerDeclsToBitField(sys.TC.I, usize, "Input");
    gen.containerDeclsToBitField(sys.TC.L, usize, "Local");
    gen.containerDeclsToBitField(sys.TC.O, usize, "Output");
    gen.containerDeclsToBitField(sys.TC.V, usize, "Special");
}
fn testOtherContainerDecls() void {
    gen.containerDeclsToBitField(perf.Branch.Spec, usize, "Spec");
    gen.containerDeclsToBitField(perf.Branch.New, usize, "New");
    gen.containerDeclsToBitField(perf.Branch.Private, usize, "Private");
}
pub fn main() void {
    var b: bool = mem.unstable(bool, true);
    if (b) gen.allPanicDeclarations();
    if (b) testMemoryContainerDecls();
    if (b) testFileContainerDecls();
    if (b) testIOCTLContainerDecls();
    if (b) testOtherContainerDecls();
}
