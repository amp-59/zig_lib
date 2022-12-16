export fn relativeJumpA(x: u64, z: u64) u64 {
    return @call(.never_inline, condOp, .{ x, z });
}
export fn relativeJumpB(x: u64, y: u64) u64 {
    return @call(.never_inline, relativeJumpA, .{ x, y });
}
fn condOp(x: u64, y: u64) callconv(.C) u64 {
    return @call(.never_inline, &if (x > y) sub else add, .{ x, y });
}

comptime {
    // Purposely ridiculous name:
    @export(condOp, .{ .name = "subtract if first arg lower", .linkage = .Strong });
}

export fn add(x: u64, y: u64) u64 {
    return (x +% y);
}
export fn sub(x: u64, y: u64) u64 {
    return (x -% y);
}
export fn orThis(x: u64, y: u64) u64 {
    return x * y;
}
