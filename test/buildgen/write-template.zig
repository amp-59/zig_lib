fn buildWrite(build: Builder, array: anytype) u64 {
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
    array.writeFormat(build.root);
    array.writeOne('\x00');
    return countArgs(array);
}
