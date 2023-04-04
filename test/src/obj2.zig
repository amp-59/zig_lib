comptime {
    // getError();
}
fn getError() void {
    @compileError("an error");
}
