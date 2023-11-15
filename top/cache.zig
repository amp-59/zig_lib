const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const bits = @import("./bits.zig");
const proc = @import("./proc.zig");
const start = @import("./start.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
const INodes = mem.array.StaticArray(usize, 512);
pub const MirrorCacheSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    AddressSpace: type,
    pub const Options = struct {
        max_file_number: usize = 512,
        cache_prefix: []const u8 = "m",
    };
    pub const Logging = packed struct {
        /// Report `open` Acquire and Error.
        open: debug.Logging.AttemptAcquireError = .{},
        /// Report `close` Release and Error.
        close: debug.Logging.ReleaseError = .{},
        /// Report `create` Acquire and Error.
        create: debug.Logging.AcquireError = .{},
        /// Report `map` Success and Error.
        map: debug.Logging.AcquireError = .{},
        /// Report `mkdir` Success and Error.
        mkdir: debug.Logging.SuccessError = .{},
        /// Report `path` Success and Error.
        path: debug.Logging.AcquireError = .{},
        /// Report `read` Success and Error.
        read: debug.Logging.SuccessError = .{},
        /// Report `unmap` Release and Error.
        unmap: debug.Logging.ReleaseError = .{},
        /// Report `write` Success and Error.
        write: debug.Logging.SuccessError = .{},
        /// Report `stat` Success and Error.
        stat: debug.Logging.SuccessErrorFault = .{},
        /// Report `getcwd` Success and Error.
        getcwd: debug.Logging.SuccessError = .{},
        /// Report `futex` Attempt and Success and Error.
        futex: debug.Logging.AttemptSuccessAcquireReleaseError = .{},
    };
    pub const Errors = struct {
        /// Error values for `open` system function.
        open: sys.ErrorPolicy = .{},
        /// Error values for `close` system function.
        close: sys.ErrorPolicy = .{},
        /// Error values for `create` system function.
        create: sys.ErrorPolicy = .{},
        /// Error values for `map` system function.
        map: sys.ErrorPolicy = .{},
        /// Error values for `mkdir` system function.
        mkdir: sys.ErrorPolicy = .{},
        /// Error values for `open` system function.
        path: sys.ErrorPolicy = .{},
        /// Error values for `read` system function.
        read: sys.ErrorPolicy = .{},
        /// Error values for `unmap` system function.
        unmap: sys.ErrorPolicy = .{},
        /// Error values for `write` system function.
        write: sys.ErrorPolicy = .{},
        /// Error values for `stat` system function.
        stat: sys.ErrorPolicy = .{},
        /// Error values for `fork` system function.
        futex: sys.ErrorPolicy = .{},
    };
};
pub fn GenericMirrorCache(comptime cache_spec: MirrorCacheSpec) type {
    const open_flags = .{
        .path = true,
        .directory = true,
    };
    const creat_flags = .{
        .truncate = true,
        .read_write = true,
    };
    const mmap_flags = .{
        .fixed = true,
        .fixed_noreplace = false,
    };
    _ = mmap_flags;
    const statx_fields = .{
        .ino = true,
        .mtime = true,
        .atime = true,
        .ctime = true,
    };
    const stat_at_flags = .{
        .empty_path = true,
    };
    const map = .{ .errors = cache_spec.errors.map, .logging = cache_spec.logging.map };
    const stat = .{ .errors = cache_spec.errors.stat, .logging = cache_spec.logging.stat };
    const open = .{ .errors = cache_spec.errors.open, .logging = cache_spec.logging.open };
    const read = .{ .errors = cache_spec.errors.read, .logging = cache_spec.logging.read, .return_type = usize };
    const futex = .{ .errors = cache_spec.errors.futex, .logging = cache_spec.logging.futex };
    const mkdir = .{ .errors = cache_spec.errors.mkdir, .logging = cache_spec.logging.mkdir };
    const write = .{ .errors = cache_spec.errors.write, .logging = cache_spec.logging.write };
    const close = .{ .errors = cache_spec.errors.close, .logging = cache_spec.logging.close };
    const unmap = .{ .errors = cache_spec.errors.unmap, .logging = cache_spec.logging.unmap };
    const create = .{ .errors = cache_spec.errors.create, .logging = cache_spec.logging.create };
    _ = map;
    _ = stat;
    _ = open;
    _ = read;
    _ = mkdir;
    _ = write;
    _ = close;
    _ = unmap;
    _ = create;
    const T = struct {
        path: mem.SimpleAllocator = .{
            .start = lb_path_addr,
            .next = lb_path_addr,
            .finish = lb_path_addr,
        },
        file: mem.SimpleAllocator = .{
            .start = lb_file_addr,
            .next = lb_file_addr,
            .finish = lb_file_addr,
        },
        futex: u32 = 0,
        const MirrorCache = @This();
        pub const lb_path_addr: comptime_int = cache_spec.AddressSpace.arena(0).lb_addr;
        pub const up_path_addr: comptime_int = cache_spec.AddressSpace.arena(0).up_addr;
        pub const lb_file_addr: comptime_int = cache_spec.AddressSpace.arena(1).lb_addr;
        pub const up_file_addr: comptime_int = cache_spec.AddressSpace.arena(1).up_addr;
        fn allocatePath(
            cache: *MirrorCache,
            dirname: []const u8,
            basename: []const u8,
        ) [:0]const u8 {
            @setRuntimeSafety(builtin.is_safe);
            const len: usize = dirname.len +% basename.len +% 1;
            const buf: [*]u8 = @ptrFromInt(cache.path.allocateAtomic(len +% 1, 1));
            var ptr: [*]u8 = fmt.strcpyEqu(buf, dirname);
            if (basename.len == 1 and basename[0] == '.') {
                ptr[0] = 0;
                return buf[0..dirname.len :0];
            }
            ptr[0] = '/';
            ptr += @intFromBool(dirname.len != 0);
            ptr = fmt.strcpyEqu(ptr, basename);
            ptr[0] = 0;
            return buf[0..len :0];
        }
        fn allocateFileBuf(
            cache: *MirrorCache,
            root_fd: usize,
            file_st: *const file.StatusExtended,
            name: [:0]const u8,
        ) ![*:0]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var buf: [*]u8 = @ptrFromInt(cache.file.allocateAtomic(file_st.size +% 1, 8));
            var cache_file_fd: usize = file.openAt(.{ .errors = .{} }, .{}, root_fd, name);
            try file.read(.{ .return_type = void }, cache_file_fd, buf[0..file_st.size]);
            try file.close(.{}, cache_file_fd);
            buf[file_st.size] = 0;
            return buf[0..file_st.size :0];
        }
        fn scanInternal(
            mirror: *MirrorCache,
            build_inodes: *INodes,
            build_root: [:0]const u8,
            build_root_fd: usize,
            cache_inodes: *INodes,
            cache_root: [:0]const u8,
            cache_root_fd: usize,
            name: [:0]const u8,
        ) !usize {
            @setRuntimeSafety(builtin.is_safe);
            var misses: usize = 0;
            var cache_file_st: file.StatusExtended = .{};
            var build_file_st: file.StatusExtended = .{};
            file.statusExtended(.{ .errors = .{} }, .{}, statx_fields, cache_root_fd, name, &cache_file_st);
            for (cache_inodes.readAll()) |ino| {
                if (ino == cache_file_st.ino) return misses;
            }
            try file.statusExtended(.{}, .{}, statx_fields, build_root_fd, name, &build_file_st);
            if (cache_file_st.mode.kind == .regular) blk: {
                const path_save: usize = mirror.path.next;
                const file_save: usize = mirror.file.next;
                if (cache_file_st.mtime.sec < build_file_st.mtime.sec or
                    cache_file_st.mtime.sec == build_file_st.mtime.sec and
                    cache_file_st.mtime.nsec < build_file_st.mtime.nsec)
                {
                    misses +%= 1;
                    break :blk;
                }
                cache_inodes.writeOne(cache_file_st.ino);
                const buf: [*:0]u8 = try mirror.allocateFileBuf(cache_root_fd, &cache_file_st, name);
                var ptr: [*]u8 = buf;
                while (buf + cache_file_st.size != ptr) : (mirror.path.next = path_save) {
                    const import: []const u8 = mem.terminate(ptr, 0);
                    misses +%= try mirror.scanInternal(build_inodes, build_root, build_root_fd, cache_inodes, cache_root, cache_root_fd, mirror.allocatePath(file.dirname(name), import));
                    ptr += import.len +% 1;
                }
                mirror.file.next = file_save;
                return misses;
            }
            for (build_inodes.readAll()) |ino| {
                if (ino == build_file_st.ino) return misses;
            }
            const save: usize = mirror.file.next;
            const dirname: []const u8 = file.dirname(name);
            if (dirname.len != 0) {
                try file.makePathAt(.{}, cache_root_fd, dirname, file.mode.directory);
            }
            try file.statusExtended(.{}, stat_at_flags, statx_fields, cache_root_fd, &.{}, &cache_file_st);
            const buf: [*:0]u8 = try mirror.allocateFileBuf(build_root_fd, &build_file_st, name);
            const tmp: [*]u8 = @ptrFromInt(mirror.file.allocateRaw(build_file_st.size, 1));
            tmp[build_file_st.size] = 0;
            var itr: builtin.parse.TokenIterator = .{ .buf = buf[0..build_file_st.size :0] };
            var tok: builtin.parse.Token = .{ .tag = .invalid, .loc = .{} };
            var ptr: [*]u8 = tmp;
            while (tok.tag != .eof) : (tok = itr.nextToken()) {
                if (tok.tag == .builtin and mem.testEqualString("@import", itr.buf[tok.loc.start..tok.loc.finish])) {
                    tok = itr.nextToken();
                    tok = itr.nextToken();
                    if (mem.testEqualString(".zig", itr.buf[tok.loc.finish -% 5 .. tok.loc.finish -% 1])) {
                        itr.buf[tok.loc.finish -% 1] = 0;
                        ptr = fmt.strcpyEqu(ptr, itr.buf[tok.loc.start +% 1 .. tok.loc.finish]);
                    }
                }
            }
            const cache_file_fd: usize = try file.createAt(.{}, creat_flags, cache_root_fd, name, file.mode.regular);
            try file.write(.{}, cache_file_fd, fmt.slice(ptr, tmp));
            try file.close(.{}, cache_file_fd);
            mirror.file.next = save;
            return misses +% try mirror.scanInternal(build_inodes, build_root, build_root_fd, cache_inodes, cache_root, cache_root_fd, name);
        }
        pub fn scan(
            mirror: *MirrorCache,
            build_root: [:0]const u8,
            build_root_fd: usize,
            cache_root: [:0]const u8,
            root_pathname: [:0]const u8,
        ) !bool {
            testing.printBufN(4096, .{
                .build_root = build_root,
                .build_root_fd = build_root_fd,
                .cache_root = cache_root,
                .root_pathname = root_pathname,
            });
            while (@cmpxchgWeak(u32, &mirror.futex, 0, 1, .SeqCst, .SeqCst)) |val| {
                proc.futexWait(futex, &mirror.futex, val, &.{ .sec = 10 });
            }
            const cache_m_root: [:0]const u8 = mirror.allocatePath(cache_root, "m");
            var build_inodes: INodes = undefined;
            var cache_inodes: INodes = undefined;
            build_inodes.undefineAll();
            cache_inodes.undefineAll();
            file.makeDirAt(.{ .errors = .{} }, build_root_fd, "zig-cache", file.mode.directory);
            file.makeDirAt(.{ .errors = .{} }, build_root_fd, "zig-cache/m", file.mode.directory);
            const cache_m_root_fd: usize = try file.openAt(.{}, open_flags, file.cwd, cache_m_root);
            const misses: usize = try mirror.scanInternal(&build_inodes, build_root, build_root_fd, &cache_inodes, cache_m_root, cache_m_root_fd, root_pathname);
            try file.close(.{}, cache_m_root_fd);
            mirror.futex = 0;
            proc.futexWake(futex, &mirror.futex, ~@as(u32, 0));
            return misses == 0;
        }
    };
    return T;
}
