pub usingnamespace if (@hasDecl(@import("@build"), "buildMain"))
    @import("./zig_lib/build_runner.zig")
else
    @import("./std_build_runner.zig");
