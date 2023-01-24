const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;

export fn remapStack() void {
    const Static = struct {
        var start: u64 = 0;
        export fn foundUpper(_: u32, info: *const proc.SignalInfo, _: ?*const anyopaque) void {
            const up_addr = info.fields.fault.addr;
            const lb_addr = info.fields.fault.addr - 8 * 0x1000000;
            mem.unmap(.{ .errors = null }, lb_addr, up_addr - lb_addr);
            mem.map(.{ .errors = null, .options = .{} }, lb_addr, up_addr - lb_addr);
            asm volatile ("jmp _start");
        }
    };
    if (Static.start != 0) {
        return;
    }
    Static.start = asm volatile (""
        : [_] "={rbp}" (-> u64),
    );
    proc.exception.updateSignalHandler(sys.SIG.SEGV, Static.foundUpper);
    var scan_addr: u64 = srg.mach.alignA64(Static.start, 4096);
    while (true) : (scan_addr += 4096) {
        Static.start = @intToPtr(*u64, scan_addr).*;
    }
}
pub export fn _start() void {
    remapStack();
    sys.exit(0);
}
