fn commandString(build: Builder) anyerror!StaticString {
    var array: StaticString = .{};
    array.writeMany("zig\x00");
    switch (build.cmd) {
        .lib, .exe, .obj => {
            array.writeMany("build-");
            array.writeMany(@tagName(build.cmd));
            array.writeOne('\x00');
        },
        .fmt, .ast_check, .run => {
            array.writeMany(@tagName(build.cmd));
            array.writeOne('\x00');
        },
    }
    _;
    array.writeAny(mem.ptr_wr_spec, .{ build.root, "\x00" });
    return array;
}
