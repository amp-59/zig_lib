fn buildAllocWrite(build: Builder, allocator: anytype, array: anytype) !void {
    try meta.wrap(array.appendMany(allocator, build.name ++ "\x00"));
    switch (build.cmd) {
        .lib, .exe, .obj => {
            try meta.wrap(array.appendMany(allocator, "build-"));
            try meta.wrap(array.appendMany(allocator, @tagName(build.cmd)));
            try meta.wrap(array.appendOne(allocator, '\x00'));
        },
        .fmt, .ast_check, .run => {
            try meta.wrap(array.appendMany(allocator, @tagName(build.cmd)));
            try meta.wrap(array.appendOne(allocator, '\x00'));
        },
    }
    _;
    try meta.wrap(array.appendMany(allocator, build.root));
    try meta.wrap(array.appendOne(allocator, '\x00'));
}
