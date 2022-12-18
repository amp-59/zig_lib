fn buildAllocatedCommandString(build: BuildCmd, allocator: *Allocator) anyerror!String {
    var array: String = String.init(allocator);
    try array.appendMany(allocator, "zig\x00");
    switch (build.cmd) {
        .lib, .exe, .obj => {
            try array.appendMany(allocator, "build-");
            try array.appendMany(allocator, @tagName(build.cmd));
            try array.appendOne(allocator, '\x00');
        },
        .fmt, .ast_check, .run => {
            try array.appendMany(allocator, @tagName(build.cmd));
            try array.appendOne(allocator, '\x00');
        },
    }
    _;
    try array.appendAny(mem.ptr_wr_spec, allocator, .{ build.root, "\x00" });
    return array.fix(allocator);
}
