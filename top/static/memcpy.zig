pub export fn memcpy(noalias dest: [*]u8, noalias source: [*]const u8, count: usize) callconv(.C) void {
    var index: usize = 0;
    while (index != count) : (index += 1) {
        dest[index] = source[index];
    }
}
