const zig_lib = @import("zig_lib");
const mem = zig_lib.mem;
const file = zig_lib.file;
const proc = zig_lib.proc;
const meta = zig_lib.meta;
const spec = zig_lib.spec;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

pub const AddressSpace = spec.address_space.exact_8;

pub const runtime_assertions: bool = false;

pub const logging_override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};

const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = .{ .require_filo_free = false },
    .logging = spec.allocator.logging.silent,
});
const DirStream = file.GenericDirStream(.{ .Allocator = Allocator });

pub fn main(args: [][*:0]u8) !void {
    // Acquire dynamic memory boilerplate
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    for (args[1..]) |arg| {
        // Open directory a path
        var dir: DirStream = try DirStream.init(&allocator, meta.manyToSlice(arg));
        defer dir.deinit(&allocator);

        // Convert stream to linked list
        var list: DirStream.ListView = dir.list();

        var index: u64 = 1;
        while (list.at(index)) |entry| : (index +%= 1) {
            // Write directory entry name to stderr
            builtin.debug.write(entry.name());
            builtin.debug.write("\n");
        }
    }
}
