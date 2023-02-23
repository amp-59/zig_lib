const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

pub const DirStreamSpec = struct {
    Allocator: type,
    initial_size: u64 = 1024,
    errors: DirStreamErrors = .{},
    options: DirStreamOptions = .{},
    logging: DirStreamLogging = .{},
    const Specification = @This();
};
pub const DirStreamErrors = struct {
    getdents: sys.ErrorPolicy = .{ .throw = sys.getdents_errors },
    open: sys.ErrorPolicy = .{ .throw = sys.open_errors },
    close: sys.ErrorPolicy = .{ .abort = sys.close_errors },
};
pub const DirStreamOptions = struct {
    init_read_all: bool = true,
    shrink_after_read: bool = true,
    make_list: bool = true,
    close_when_done: bool = true,
};
pub const DirStreamLogging = struct {
    open: builtin.Logging.AcquireErrorFault = .{},
    close: builtin.Logging.ReleaseErrorFault = .{},
    getdents: builtin.Logging.SuccessErrorFault = .{},
};
pub const Kind = enum(u8) {
    regular = sys.S.IFREG >> 12,
    directory = sys.S.IFDIR >> 12,
    character_special = sys.S.IFCHR >> 12,
    block_special = sys.S.IFBLK >> 12,
    named_pipe = sys.S.IFIFO >> 12,
    socket = sys.S.IFSOCK >> 12,
    symbolic_link = sys.S.IFLNK >> 12,
};
pub fn GenericDirStream(comptime spec: DirStreamSpec) type {
    return (struct {
        path: [:0]const u8,
        fd: u64,
        blk: Block,
        count: u64,
        const DirStream = @This();
        const Block = mem.ReadWriteResizeUnstructuredDisjunctAlignment(.{
            .low_alignment = 8,
            .high_alignment = 8,
        });
        pub const Allocator = dir_spec.Allocator;
        pub const ListView = mem.GenericLinkedListView(.{ .child = Entry, .low_alignment = 8 });

        pub const Entry = opaque {
            pub fn possess(dirent: *const Entry, dir: *DirStream) void {
                @intToPtr(*const Block, @ptrToInt(dirent) + 0).* = dir.blk;
                file.close(dir_close_spec, dir.fd);
            }
            pub fn entries(dirent: *const Entry) Block {
                return @intToPtr(*const Block, @ptrToInt(dirent) + 0).*;
            }
            pub fn len(dirent: *const Entry) u16 {
                return @intToPtr(*const u16, @ptrToInt(dirent) + 8).*;
            }
            pub fn kind(dirent: *const Entry) Kind {
                return @intToPtr(*const Kind, @ptrToInt(dirent) + 10).*;
            }
            pub fn name(dirent: *const Entry) [:0]const u8 {
                return @intToPtr([*:0]u8, @ptrToInt(dirent) + 11)[0..dirent.len() :0];
            }
            pub fn isDirectory(dirent: *const Entry) bool {
                return dirent.kind == .directory;
            }
            pub fn isCharacterSpecial(dirent: *const Entry) bool {
                return dirent.kind == .character_special;
            }
            pub fn isBlockSpecial(dirent: *const Entry) bool {
                return dirent.kind == .block_special;
            }
            pub fn isRegular(dirent: Entry) bool {
                return dirent.kind == .regular;
            }
            pub fn isNamedPipe(dirent: *const Entry) bool {
                return dirent.kind == .named_pipe;
            }
            pub fn isSymbolicLink(dirent: *const Entry) bool {
                return dirent.kind == .symbolic_link;
            }
            pub fn isSocket(dirent: *const Entry) bool {
                return dirent.kind == .socket;
            }
        };
        const List = opaque {
            const name_offset: u8 = @offsetOf(file.DirectoryEntry, "array");
            const reclen_offset: u8 = @offsetOf(file.DirectoryEntry, "reclen");
            const offset_offset: u8 = @offsetOf(file.DirectoryEntry, "offset");
            // Often the dot and dot-dot directory entries will not be the first
            // and second entries, and the addresses of the head and sentinel
            // nodes of our mangled list must be known--otherwise we would have
            // to store more metadata in the DirStream object.
            fn shiftBothBlocks(s_lb_addr: u64, major_src_addr: u64, minor_src_addr: u64) void {
                disordered += 1;
                const major_save: [24]u8 = @intToPtr(*const [24]u8, major_src_addr).*;
                const major_dst_addr: u64 = s_lb_addr;
                const minor_save: [24]u8 = @intToPtr(*const [24]u8, minor_src_addr).*;
                const minor_dst_addr: u64 = s_lb_addr + 24;
                const upper_src_addr: u64 = @max(major_src_addr, minor_src_addr);
                const lower_src_addr: u64 = @min(major_src_addr, minor_src_addr);
                var t_lb_addr: u64 = upper_src_addr;
                while (t_lb_addr != lower_src_addr + 24) {
                    t_lb_addr -= 8;
                    @intToPtr(*u64, t_lb_addr + 24).* = @intToPtr(*u64, t_lb_addr).*;
                }
                t_lb_addr = lower_src_addr;
                while (t_lb_addr != major_dst_addr) {
                    t_lb_addr -= 8;
                    @intToPtr(*u64, t_lb_addr + 48).* = @intToPtr(*u64, t_lb_addr).*;
                }
                @intToPtr(*[24]u8, major_dst_addr).* = major_save;
                @intToPtr(*[24]u8, minor_dst_addr).* = minor_save;
            }
            // 11780 = [2]u8{ 4, 46 }, i.e. "d."
            // 46    = [2]u8{ 46, 0 }, i.e. ".\x00"
            // 1070  = [2]u8{ 46, 4 }
            // 11776 = [2]u8{ 0, 46 }
            // This method is about 25% faster than testing if starts with ".\0"
            // and "..\0", and cmoving the relevant index. I suppose this
            // respects endian, but have never tested it.
            fn classifyNameExperimental(addrs: *[3]u64, s_lb_addr: u64) void {
                const w0: u16 = @intToPtr(*const u16, s_lb_addr + 18).*;
                const w1: u16 = @intToPtr(*const u16, s_lb_addr + 20).*;
                const j0: u8 = @boolToInt(w0 == if (builtin.is_little) 11780 else 1070);
                const j1: u8 = j0 << @boolToInt(w1 == if (builtin.is_little) 46 else 11776);
                const j2: u8 = j1 & (@as(u8, 1) << @boolToInt(w1 != 0));
                addrs[j2] = s_lb_addr;
            }
            fn mangle(s_lb_addr: u64) void {
                const len: u16 = @intToPtr(*u16, s_lb_addr + 16).*;
                const a_0: u64 = (s_lb_addr + len) -% 8;
                const a_1: u16 = 64 -% @clz(@intToPtr(*const u64, a_0).*);
                const a_2: u16 = (len + (1 + (a_1 / 8))) - (name_offset + 8);
                const a_3: *u8 = @intToPtr(*u8, s_lb_addr + name_offset + (a_2 - 1));
                const name_len: u16 = a_2 -% @boolToInt(a_3.* == 0);
                @intToPtr(*u8, s_lb_addr + name_offset + name_len).* = 0;
                @intToPtr(*u16, s_lb_addr + reclen_offset).* = name_len;
                @intToPtr(*u64, s_lb_addr + offset_offset).* = 0;
            }
            fn rectifyEntryOrder(s_lb_addr: u64) u64 {
                var addrs: [3]u64 = .{0} ** 3;
                var t_lb_addr: u64 = s_lb_addr;
                classifyNameExperimental(&addrs, t_lb_addr);
                t_lb_addr = nextAddress(t_lb_addr);
                classifyNameExperimental(&addrs, t_lb_addr);
                while (addrs[1] *% addrs[2] == 0) : (t_lb_addr = nextAddress(t_lb_addr)) {
                    classifyNameExperimental(&addrs, t_lb_addr);
                }
                if (!(builtin.int2a(bool, addrs[1] == s_lb_addr, addrs[2] == s_lb_addr + 24))) {
                    shiftBothBlocks(s_lb_addr, addrs[1], addrs[2]);
                }
                return s_lb_addr;
            }
            /// Converts linux directory stream to a linked list without moving
            /// or copying. '..' directory sacrificed to make room for the list
            /// sentinel node. Do not touch.
            pub fn interleaveXorListNodes(dir: DirStream) u64 {
                const s_lb_addr: u64 = rectifyEntryOrder(dir.blk.aligned_byte_address());
                const s_up_addr: u64 = dir.blk.undefined_byte_address();
                const t_node_addr: u64 = nextAddress(s_lb_addr);
                var s_node_addr: u64 = s_lb_addr;
                var p_node_addr: u64 = 0;
                var i_node_addr: u64 = nextAddress(t_node_addr);
                mangle(s_node_addr);
                ListView.Node.Link.mutate(s_node_addr, 0, t_node_addr);
                ListView.Node.Link.mutate(t_node_addr, s_node_addr, 0);
                mangle(t_node_addr);
                var count: u64 = 1;
                while (i_node_addr < s_up_addr) : (count += 1) {
                    ListView.Node.Link.mutate(s_node_addr, p_node_addr, i_node_addr);
                    ListView.Node.Link.mutate(i_node_addr, s_node_addr, t_node_addr);
                    ListView.Node.Link.mutate(t_node_addr, i_node_addr, 0);
                    p_node_addr = s_node_addr;
                    s_node_addr = i_node_addr;
                    i_node_addr = nextAddress(i_node_addr);
                    mangle(s_node_addr);
                }
                return count;
            }
            pub fn nextAddress(s_lb_addr: u64) u64 {
                return s_lb_addr + @intToPtr(*u16, s_lb_addr + reclen_offset).*;
            }
        };
        pub const dir_spec: DirStreamSpec = spec;
        const dir_open_spec: file.OpenSpec = .{
            .options = .{
                .write = null,
                .directory = true,
                .read = true,
            },
            .logging = dir_spec.logging.open,
        };
        const dir_close_spec: file.CloseSpec = .{
            .errors = .{},
            .logging = dir_spec.logging.close,
        };
        pub var disordered: u64 = 0;

        pub fn list(dir: *DirStream) ListView {
            return .{
                .links = .{
                    .major = dir.blk.aligned_byte_address(),
                    .minor = dir.blk.aligned_byte_address() + 48,
                },
                .count = dir.count,
                .index = 0,
            };
        }
        fn clear(s_lb_addr: u64, s_bytes: u64) void {
            mem.set(s_lb_addr, @as(u8, 0), s_bytes);
        }
        fn getDirectoryEntries(dir: *const DirStream) sys.Call(spec.errors.getdents.throw, u64) {
            return sys.call(.getdents64, spec.errors.getdents, u64, .{
                dir.fd,
                dir.blk.undefined_byte_address(),
                dir.blk.undefined_byte_count(),
            });
        }
        fn grow(dir: *DirStream, allocator: *Allocator) !void {
            const s_bytes: u64 = dir.blk.writable_byte_count();
            const t_bytes: u64 = s_bytes * 2;
            const s_impl: Block = dir.blk;
            try meta.wrap(allocator.resizeManyAbove(Block, &dir.blk, .{ .bytes = t_bytes }));
            clear(s_impl.unwritable_byte_address(), dir.blk.unwritable_byte_address() - s_impl.unwritable_byte_address());
        }
        fn shrink(dir: *DirStream, allocator: *Allocator) !void {
            const t_bytes: u64 = mach.alignA(dir.blk.defined_byte_count() + 48, 8);
            allocator.resizeManyBelow(Block, &dir.blk, .{ .bytes = t_bytes });
        }
        fn readAll(dir: *DirStream, allocator: *Allocator) !void {
            dir.blk.define(try dir.getDirectoryEntries());
            while (dir.blk.undefined_byte_count() < 528) {
                try dir.grow(allocator);
                dir.blk.define(try dir.getDirectoryEntries());
            }
            if (dir_spec.options.shrink_after_read) {
                try dir.shrink(allocator);
            }
        }
        pub fn initAt(allocator: *Allocator, dirfd: ?u64, name: [:0]const u8) !DirStream {
            const fd: u64 = try file.openAt(dir_open_spec, dirfd orelse sys.S.AT_FDCWD, name);
            const blk: Block = try meta.wrap(allocator.allocateMany(Block, .{ .bytes = dir_spec.initial_size }));
            clear(blk.aligned_byte_address(), dir_spec.initial_size);
            var ret: DirStream = .{ .path = name, .fd = fd, .blk = blk, .count = 1 };
            if (dir_spec.options.init_read_all) {
                try ret.readAll(allocator);
            }
            if (dir_spec.options.make_list) {
                ret.count = List.interleaveXorListNodes(ret);
            }
            return ret;
        }
        pub fn init(allocator: *Allocator, pathname: [:0]const u8) !DirStream {
            const fd: u64 = try file.open(dir_open_spec, pathname);
            const blk: Block = try meta.wrap(allocator.allocateMany(Block, .{ .bytes = dir_spec.initial_size }));
            clear(blk.aligned_byte_address(), dir_spec.initial_size);
            var ret: DirStream = .{ .path = pathname, .fd = fd, .blk = blk, .count = 1 };
            if (dir_spec.options.init_read_all) {
                try ret.readAll(allocator);
            }
            if (dir_spec.options.make_list) {
                ret.count = List.interleaveXorListNodes(ret);
            }
            return ret;
        }
        /// Close directory file and free all allocated memory.
        pub fn deinit(dir: *DirStream, allocator: *Allocator) void {
            allocator.deallocateMany(Block, dir.blk);
            if (dir.fd != 0) {
                file.close(dir_close_spec, dir.fd);
                dir.fd = 0;
            }
        }
    });
}
