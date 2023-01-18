fn buildLength(build: Builder) u64 {
    var len: u64 = "zig\x00".len;
    switch (build.cmd) {
        .lib, .exe, .obj => {
            len += "build-".len + @tagName(build.cmd).len + 1;
        },
        .fmt, .ast_check, .run => {
            len += @tagName(build.cmd).len + 1;
        },
    }
    _;
    len +%= build.root.len + 1;
    return len;
}
