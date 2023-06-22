const zig_lib = @import("../zig_lib.zig");
const sys = zig_lib.sys;
const gen = zig_lib.gen;
pub fn main() void {
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
    gen.containerDeclsToBitField(sys.AT, usize, "At");
    gen.containerDeclsToBitField(sys.O, usize, "Open");
    gen.containerDeclsToBitField(sys.RWF, usize, "ReadWrite");
    gen.containerDeclsToBitField(sys.S, usize, "Status");
    gen.containerDeclsToBitField(sys.STATX.ATTR, usize, "StatusExtendedAttributes");
    gen.containerDeclsToBitField(sys.STATX, usize, "StatusExtendedFields");
}
