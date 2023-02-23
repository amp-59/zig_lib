const srg = @import("zig_lib");
const mem = srg.mem;
const file = srg.file;
const proc = srg.proc;
const meta = srg.meta;
const preset = srg.preset;

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.exact_8;

pub const runtime_assertions: bool = false;
pub const is_verbose: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = .{ .require_filo_free = false },
    .logging = preset.allocator.logging.silent,
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
