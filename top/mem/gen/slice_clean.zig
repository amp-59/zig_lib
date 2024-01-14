const zl = @import("../../../zig_lib.zig");

const config = @import("config.zig");

pub usingnamespace zl.start;

const Allocator = zl.mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = zl.mem.spec.address_space.exact_8,
    .arena_index = 1,
    .options = .{ .require_filo_free = false },
});

pub fn main() !void {
    if (zl.builtin.zig_backend != .stage2_x86_64) {
        const DirStream = zl.file.GenericDirStream(.{ .Allocator = Allocator });
        var address_space: Allocator.AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        if (try zl.file.pathIs(.{}, config.test_safety_dir, .unknown)) {
            try zl.file.makeDir(.{}, config.test_safety_dir, zl.file.mode.directory);
        } else {
            try zl.file.pathAssert(.{}, config.test_safety_dir, .directory);
        }
        if (try zl.file.pathIs(.{}, config.test_safety_slice_dir, .unknown)) {
            try zl.file.makeDir(.{}, config.test_safety_slice_dir, zl.file.mode.directory);
        } else {
            try zl.file.pathAssert(.{}, config.test_safety_slice_dir, .directory);
        }
        var dir: DirStream = try DirStream.init(&allocator, config.test_safety_slice_dir);
        defer dir.deinit(&allocator);
        var entry_list: DirStream.ListView = dir.list();
        while (entry_list.next()) |next| {
            const basename: [:0]const u8 = entry_list.this().name();
            if (zl.mem.testEqualManyBack(u8, ".zig", basename)) {
                if (try zl.file.isAt(.{}, .{}, dir.fd, basename, .regular)) {
                    try zl.file.unlinkAt(.{}, dir.fd, basename);
                }
            }
            entry_list = next;
        }
    }
}
