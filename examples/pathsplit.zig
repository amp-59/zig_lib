const srg = @import("zig_lib");
const mem = srg.mem;
const fmt = srg.fmt;
const proc = srg.proc;
const file = srg.file;
const meta = srg.meta;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const AddressSpace = spec.address_space.regular_128;
pub const logging_default: builtin.Logging.Default = .{
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};

pub const PathSplitSpec = struct {
    Allocator: type,
};
pub fn GenericPathSplit(comptime path_split_spec: PathSplitSpec) type {
    return struct {
        path: [:0]const u8,
        index: u16 = 0,
        max: u16 = 0,
        info: InfoArray,
        const PathSplit = @This();
        const Allocator = path_split_spec.Allocator;
        const InfoArray = Allocator.StructuredVector(struct { pos: u16 = 0, len: u16 = 0 });
        pub fn init(allocator: *Allocator, path: [:0]const u8) !PathSplit {
            var info: InfoArray = try InfoArray.init(allocator, 2048);
            var index: u16 = 0;
            var prev: u16 = 0;
            while (prev < path.len) {
                if (path[prev] == '/') {
                    var next: u16 = prev;
                    while (path[next] == '/') {
                        next += 1;
                    }
                    if (path[prev] == 0) {
                        break;
                    }
                    info.writeOne(info.readOneAt(index));
                    info.overwriteOneBack(.{
                        .pos = prev,
                        .len = next - prev,
                    });
                    index += 1;
                    prev = next + 1;
                } else {
                    prev += 1;
                }
            }
            info.shrink(allocator, info.len());
            return .{
                .path = path,
                .index = 0,
                .max = index,
                .info = info,
            };
        }
        pub fn deinit(path_split: *PathSplit, allocator: *Allocator) void {
            path_split.info.deinit(allocator);
        }
    };
}

pub fn main(args: [][*:0]u8) !void {
    const Allocator = mem.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    const PathSplit = GenericPathSplit(.{ .Allocator = Allocator });
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    for (args) |arg| {
        var path_split: PathSplit = try PathSplit.init(&allocator, meta.manyToSlice(arg));
        defer path_split.deinit(&allocator);
        var array: mem.StaticString(1024 * 512) = .{};
        array.writeAny(spec.reinterpret.fmt, fmt.any(path_split));
        builtin.debug.write(array.readAll());
    }
}
