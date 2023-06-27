const zig_lib = @import("../zig_lib.zig");
const sys = zig_lib.sys;
const gen = zig_lib.gen;

const perf = @import("../top/perf.zig");

pub const Access = enum(u32) {
    pub const file = 0x0;
    pub const exec = 0x1;
    pub const write = 0x2;
    pub const read = 0x4;
};

pub fn main() void {
    if (false) {
        gen.containerDeclsToBitField(sys.CLONE, u32, "Clone");
        gen.containerDeclsToBitField(sys.FPE, usize, "FloatingPointError");
        gen.containerDeclsToBitField(sys.SS, usize, "SignalStack");
        gen.containerDeclsToBitField(sys.SA, usize, "SignalAction");
        gen.containerDeclsToBitField(sys.MAP, usize, "Map");
        gen.containerDeclsToBitField(sys.PROT, usize, "Protect");
        gen.containerDeclsToBitField(sys.MADV, usize, "MAdvise");
        gen.containerDeclsToBitField(sys.REMAP, usize, "Remap");
        gen.containerDeclsToBitField(sys.MS, usize, "Sync");
        gen.containerDeclsToBitField(sys.PROT, usize, "Prot");
        gen.containerDeclsToBitField(sys.O, usize, "Open");
        gen.containerDeclsToBitField(sys.RWF, usize, "ReadWrite");
        gen.containerDeclsToBitField(sys.S, usize, "Status");
        gen.containerDeclsToBitField(sys.STATX.ATTR, usize, "StatusExtendedAttributes");
        gen.containerDeclsToBitField(sys.STATX, usize, "StatusExtendedFields");
        gen.containerDeclsToBitField(Access, usize, "Access");
    }
    gen.containerDeclsToBitField(sys.AT, usize, "At");
    if (false) {
        gen.containerDeclsToBitField(perf.Mem.Blk, usize, "Blk");
        gen.containerDeclsToBitField(perf.Mem.Hops, usize, "Hops");
        gen.containerDeclsToBitField(perf.Mem.Lock, usize, "Lock");
        gen.containerDeclsToBitField(perf.Mem.Lvl, usize, "Lvl");
        gen.containerDeclsToBitField(perf.Mem.LvlNum, usize, "LvlNum");
        gen.containerDeclsToBitField(perf.Mem.Op, usize, "Op");
        gen.containerDeclsToBitField(perf.Mem.Remote, usize, "Remote");
        gen.containerDeclsToBitField(perf.Mem.Snoop, usize, "Snoop");
        gen.containerDeclsToBitField(perf.Mem.TLB, usize, "TLB");
        gen.containerDeclsToBitField(perf.Branch.Spec, usize, "Spec");
        gen.containerDeclsToBitField(perf.Branch.New, usize, "New");
        gen.containerDeclsToBitField(perf.Branch.Private, usize, "Private");
    }
}
