const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

const llc = @import("../top/build/llc_tasks.zig");

pub fn main() void {
    var llc_cmd: llc.LLCCommand = .{
        .unroll_max_count = 16,
        .remarks_section = true,
        .pass_remarks_output = "opt_remarks",
    };
    var buf: [4096]u8 = undefined;
    var len: usize = llc_cmd.formatWriteBuf(&buf);
    var pos: usize = 0;
    var idx: usize = 0;
    while (idx != len) : (idx +%= 1) {
        if (buf[idx] == 0) {
            buf[idx] = 10;
            zl.debug.write(buf[pos .. idx + 1]);
            pos = idx;
        }
    }
}
