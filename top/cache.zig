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
    _ = stat;
    _ = read;
    _ = mkdir;
    _ = write;
    _ = create;
    const T = extern struct {
        path: mem.Bounds = .{ .lb_addr = lb_path_addr, .up_addr = lb_path_addr },
        file: mem.Bounds = .{ .lb_addr = lb_file_addr, .up_addr = lb_file_addr },
        const MirrorCache = @This();
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
        const statx_fields = .{
            .ino = true,
            .mtime = true,
            .atime = true,
            .ctime = true,
        };
        const stat_at_flags = .{
            .empty_path = true,
        };
        const INodes = mem.array.StaticArray(usize, cache_spec.options.max_file_number);
        pub const lb_path_addr: comptime_int = cache_spec.AddressSpace.arena(0).lb_addr;
        pub const up_path_addr: comptime_int = cache_spec.AddressSpace.arena(0).up_addr;
        pub const lb_file_addr: comptime_int = cache_spec.AddressSpace.arena(1).lb_addr;
        pub const up_file_addr: comptime_int = cache_spec.AddressSpace.arena(1).up_addr;
        pub fn scan(
            mirror: *MirrorCache,
            build_root: [:0]const u8,
            build_root_fd: usize,
            cache_root: [:0]const u8,
            root_pathname: [:0]const u8,
        ) !bool {
            @setRuntimeSafety(builtin.is_safe);
            while (@cmpxchgWeak(usize, &mirror.path.up_addr, lb_path_addr, up_path_addr, .SeqCst, .SeqCst)) |val| {
                proc.futexWait(futex, @ptrCast(&mirror.path.up_addr), @intCast(val), &.{ .sec = 10 });
            }
            mem.map(map, .{}, .{}, lb_path_addr, 1024 * 1024);
            const cache_m_root: [:0]const u8 = mirror.allocatePath(cache_root, "m");
            var build_inodes: INodes = undefined;
            var cache_inodes: INodes = undefined;
            mem.zero(INodes, &build_inodes);
            mem.zero(INodes, &cache_inodes);
            build_inodes.undefineAll();
            cache_inodes.undefineAll();
            file.makeDirAt(.{ .errors = .{} }, build_root_fd, cache_root, file.mode.directory);
            file.makeDirAt(.{ .errors = .{} }, build_root_fd, cache_m_root, file.mode.directory);
            const cache_m_root_fd: usize = file.openAt(open, open_flags, file.cwd, cache_m_root);
            const misses: usize = mirror.createMirrorFileSystemCache(
                &build_inodes,
                build_root,
                build_root_fd,
                &cache_inodes,
                cache_m_root,
                cache_m_root_fd,
                root_pathname[build_root.len +% 1 ..],
            ) catch 1;
            file.close(close, cache_m_root_fd);
            mem.unmap(unmap, lb_path_addr, 1024 * 1024);
            proc.futexWake(futex, @ptrCast(&mirror.path.up_addr), ~@as(u32, 0));
            mirror.path.up_addr = lb_path_addr;
            return misses == 0;
        }
        fn allocatePath(
            mirror: *MirrorCache,
            dirname: []const u8,
            basename: []const u8,
        ) [:0]const u8 {
            @setRuntimeSafety(builtin.is_safe);
            const buf: [*]u8 = @ptrFromInt(@atomicRmw(usize, &mirror.path.up_addr, .Add, dirname.len +% basename.len +% 2, .SeqCst));
            var ptr: [*]u8 = fmt.strcpyEqu(buf, dirname);
            if (basename.len == 1 and basename[0] == '.') {
                ptr[0] = 0;
                return buf[0..dirname.len :0];
            }
            ptr[0] = '/';
            ptr += @intFromBool(dirname.len != 0 and basename.len != 0);
            ptr = fmt.strcpyEqu(ptr, basename);
            ptr[0] = 0;
            return buf[0 .. dirname.len +% 1 +% basename.len :0];
        }
        fn createMirrorFileSystemCache(
            mirror: *MirrorCache,
            build_inodes: *INodes,
            build_root: [:0]const u8,
            build_root_fd: usize,
            cache_inodes: *INodes,
            cache_m_root: [:0]const u8,
            cache_m_root_fd: usize,
            name: [:0]const u8,
        ) !usize {
            @setRuntimeSafety(builtin.is_safe);
            var misses: usize = 0;
            var cache_file_st: file.StatusExtended = .{};
            var build_file_st: file.StatusExtended = .{};
            file.statusExtended(.{ .errors = .{} }, .{}, statx_fields, cache_m_root_fd, name, &cache_file_st);
            for (cache_inodes.readAll()) |ino| {
                if (ino == cache_file_st.ino) return misses;
            }
            file.statusExtended(.{ .errors = .{} }, .{}, statx_fields, build_root_fd, name, &build_file_st);
            if (build_file_st.mode.kind != .regular) {
                return 0;
            }
            if (cache_file_st.mode.kind == .regular) blk: {
                if (cache_file_st.size == 0) {
                    return 0;
                }
                const path_save: usize = mirror.path.up_addr;
                const file_save: usize = mirror.file.up_addr;
                if (cache_file_st.mtime.sec < build_file_st.mtime.sec or
                    cache_file_st.mtime.sec == build_file_st.mtime.sec and
                    cache_file_st.mtime.nsec < build_file_st.mtime.nsec)
                {
                    misses +%= 1;
                    break :blk;
                }
                cache_inodes.writeOne(cache_file_st.ino);
                const len: usize = bits.alignA4096(cache_file_st.size);
                const addr: usize = @atomicRmw(usize, &mirror.file.up_addr, .Add, len, .SeqCst);
                const fd: usize = try file.openAt(.{}, .{}, cache_m_root_fd, name);
                try file.map(.{}, .{}, mmap_flags, fd, addr, len, 0);
                file.close(close, fd);
                const buf: [*]u8 = @ptrFromInt(addr);
                var ptr: [*]u8 = buf;
                while (fmt.strlen(ptr, buf) != cache_file_st.size) : (mirror.path.up_addr = path_save) {
                    const import: []const u8 = mem.terminate(ptr, 0);
                    const root_pathname: [:0]const u8 = mirror.allocatePath(file.dirname(name), import);
                    misses +%= try mirror.createMirrorFileSystemCache(build_inodes, build_root, build_root_fd, cache_inodes, cache_m_root, cache_m_root_fd, root_pathname);
                    ptr += import.len +% 1;
                }
                mirror.file.up_addr = file_save;
                return misses;
            }
            for (build_inodes.readAll()) |ino| {
                if (ino == build_file_st.ino) return misses;
            }
            const save: usize = mirror.file.up_addr;
            const dirname: []const u8 = file.dirname(name);
            if (dirname.len != 0) {
                try file.makePathAt(.{}, cache_m_root_fd, dirname, file.mode.directory);
            }
            const len: usize = bits.alignA4096(build_file_st.size);
            const addr: usize = @atomicRmw(usize, &mirror.file.up_addr, .Add, len *% 2, .SeqCst);
            const build_file_fd: usize = try file.openAt(.{}, .{}, build_root_fd, name);
            try file.map(.{}, .{}, mmap_flags, build_file_fd, addr, len, 0);
            file.close(close, build_file_fd);
            try mem.map(.{}, .{}, mmap_flags, addr +% len, len);
            const buf: [*]u8 = @ptrFromInt(addr);
            const tmp: [*]u8 = @ptrFromInt(addr +% len);
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
            const cache_file_fd: usize = try file.createAt(.{}, creat_flags, cache_m_root_fd, name, file.mode.regular);
            try file.write(.{}, cache_file_fd, fmt.slice(ptr, tmp));
            try file.close(.{}, cache_file_fd);
            mirror.file.up_addr = save;
            return misses +% try mirror.createMirrorFileSystemCache(build_inodes, build_root, build_root_fd, cache_inodes, cache_m_root, cache_m_root_fd, name);
        }
    };
    return T;
}
