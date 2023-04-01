const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");
const types = @import("./build/types2.zig");
const tasks = @import("./build/tasks.zig");
const command_line = @import("./build/command_line.zig");
pub const State = enum(u8) {
    unavailable = 0,
    failed = 1,
    ready = 2,
    blocking = 3,
    finished = 255,
};
pub const Task = enum(u8) {
    format = 0,
    build = 1,
    run = 2,
};

pub const BuilderSpec = struct {
    options: Options = .{},
    logging: Logging = .{},
    errors: Errors = .{},
    pub const Options = struct {
        max_command_line: u64 = 65536,
        max_command_args: u64 = 1024,
        max_relevant_depth: u64 = 1,
    };
    pub const Logging = packed struct {
        command: proc.CommandSpec.Logging = .{},
        path: builtin.Logging.AcquireErrorFault = .{},
        create: builtin.Logging.AcquireErrorFault = .{},
        close: builtin.Logging.ReleaseErrorFault = .{},
        mkdir: builtin.Logging.SuccessErrorFault = .{},
        write: builtin.Logging.SuccessErrorFault = .{},
        map: builtin.Logging.AcquireErrorFault = .{},
        unmap: builtin.Logging.AcquireErrorFault = .{},
        stat: builtin.Logging.SuccessErrorFault = .{},
    };
    pub const Errors = struct {
        command: proc.CommandSpec.Errors = .{},
        path: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        clock: sys.ErrorPolicy = .{ .throw = sys.clock_get_errors },
        sleep: sys.ErrorPolicy = .{ .throw = sys.nanosleep_errors },
        create: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        mkdir: sys.ErrorPolicy = .{ .throw = sys.mkdir_noexcl_errors },
        close: sys.ErrorPolicy = .{ .abort = sys.close_errors },
        write: sys.ErrorPolicy = .{ .abort = sys.write_errors },
        map: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
        unmap: sys.ErrorPolicy = .{ .abort = sys.munmap_errors },
        stat: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
        clone: sys.ErrorPolicy = .{},
    };
    const map_options: mem.MapSpec.Options = .{
        .grows_down = true,
    };
    const create_options: file.CreateSpec.Options = .{
        .exclusive = false,
        .write = .truncate,
    };
    pub fn path(comptime spec: BuilderSpec) file.PathSpec {
        return .{ .errors = spec.errors.path, .logging = spec.logging.path };
    }
    pub fn command(comptime spec: BuilderSpec) proc.CommandSpec {
        return .{ .errors = spec.errors.command, .logging = spec.logging.command };
    }
    pub fn clock(comptime spec: BuilderSpec) time.ClockSpec {
        return .{ .errors = spec.errors.clock };
    }
    pub fn sleep(comptime spec: BuilderSpec) time.SleepSpec {
        return .{ .errors = spec.errors.sleep };
    }
    pub fn mkdir(comptime spec: BuilderSpec) file.MakeDirSpec {
        return .{ .errors = spec.errors.mkdir, .logging = spec.logging.mkdir };
    }
    pub fn write(comptime spec: BuilderSpec) file.WriteSpec {
        return .{ .errors = spec.errors.write, .logging = spec.logging.write };
    }
    pub fn close(comptime spec: BuilderSpec) file.CloseSpec {
        return .{ .errors = spec.errors.close, .logging = spec.logging.close };
    }
    pub fn clone(comptime spec: BuilderSpec) proc.CloneSpec {
        return .{ .return_type = void, .errors = spec.errors.clone };
    }
    pub fn unmap(comptime spec: BuilderSpec) mem.UnmapSpec {
        return .{ .errors = spec.errors.unmap, .logging = spec.logging.unmap };
    }
    pub fn stat(comptime spec: BuilderSpec) file.StatSpec {
        return .{ .errors = spec.errors.stat, .logging = spec.logging.stat };
    }
    pub fn map(comptime spec: BuilderSpec) mem.MapSpec {
        return .{
            .errors = spec.errors.map,
            .logging = spec.logging.map,
            .options = map_options,
        };
    }
    pub fn create(comptime spec: BuilderSpec) file.CreateSpec {
        return .{
            .errors = spec.errors.create,
            .logging = spec.logging.create,
            .options = create_options,
        };
    }
};
pub fn GenericBuilder(comptime spec: BuilderSpec) type {
    return (struct {
        zig_exe: [:0]const u8,
        build_root: [:0]const u8,
        cache_root: [:0]const u8,
        global_cache_root: [:0]const u8,
        dir_fd: u64,
        args: [][*:0]u8,
        vars: [][*:0]u8,
        run_args: [][*:0]u8 = &.{},
        grps: []Group = &.{},
        grps_len: u64 = 0,
        const Builder = @This();

        pub const Types = struct {
            const target_payload: type = types.Allocator.allocate_payload(*Target);
            const group_payload: type = types.Allocator.allocate_payload(*Group);
            const dependency_payload: type = types.Allocator.allocate_payload(*Dependency);
        };
        pub const Dependency = struct {
            target: *Target,
            task: Task,
            state: State,
        };
        pub const Target = struct {
            name: [:0]const u8,
            root: [:0]const u8,
            build_cmd: *tasks.BuildCommand,
            run_cmd: *tasks.RunCommand,
            lock: Lock = .{},
            deps: []Dependency = &.{},
            deps_len: u64 = 0,
            pub const Lock = virtual.ThreadSafeSet(5, State, Task);
            fn binaryRelative(target: *Target, allocator: *types.Allocator) [:0]const u8 {
                return switch (target.build_cmd.kind) {
                    .exe => concatenate(allocator, &.{ tok.exe_out_dir, target.name }),
                    .lib => concatenate(allocator, &.{ tok.exe_out_dir, target.name, tok.lib_ext }),
                    .obj => concatenate(allocator, &.{ tok.exe_out_dir, target.name, tok.obj_ext }),
                };
            }
            inline fn binaryPath(target: *Target, allocator: *types.Allocator, builder: *Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = binaryRelative(target, allocator) };
            }
            fn emitBinary(target: *Target, allocator: *types.Allocator, builder: *Builder) void {
                target.build_cmd.emit_bin = .{ .yes = binaryPath(target, allocator, builder) };
            }
            fn assemblyRelative(target: *Target, allocator: *types.Allocator) [:0]const u8 {
                return concatenate(allocator, &.{ tok.aux_out_dir, target.name, tok.asm_ext });
            }
            inline fn assemblyPath(target: *Target, allocator: *types.Allocator, builder: *Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = assemblyRelative(target, allocator, builder) };
            }
            fn emitAssembly(target: *Target, allocator: *types.Allocator, builder: *Builder) void {
                target.build_cmd.emit_asm = .{ .yes = assemblyPath(target, allocator, builder) };
            }
            fn rootSourcePath(target: *Target, builder: *Builder) types.Path {
                return .{ .absolute = builder.build_root, .relative = target.root };
            }
            pub fn dependOnRun(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
                target.addDependency(allocator, dependency, .run, .finished);
            }
            pub fn dependOnBuild(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
                target.addDependency(allocator, dependency, .build, .finished);
            }
            pub fn dependOnFormat(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
                target.addDependency(allocator, dependency, .format, .finished);
            }
            pub fn addDependency(target: *Target, allocator: *types.Allocator, dependency: *Target, task: Task, state: State) void {
                if (target.deps_len == target.deps.len) {
                    target.deps = allocator.reallocateIrreversible(Dependency, target.deps, (target.deps_len +% 1) *% 2);
                }
                target.deps[target.deps_len] = .{ .target = dependency, .task = task, .state = state };
                target.deps_len +%= 1;
            }
        };
        pub const Group = struct {
            name: [:0]const u8,
            builder: *Builder,
            trgs: []Target = &.{},
            trgs_len: u64 = 0,
            pub fn acquireGroupLock(
                group: *Group,
                address_space: *types.AddressSpace,
                thread_space: *types.ThreadSpace,
                allocator: *types.Allocator,
                task: Task,
            ) sys.Call(.{
                .throw = types.Allocator.resize_error_policy.throw ++
                    decls.clock_spec.errors.throw ++ decls.map_spec.errors.throw,
                .abort = types.Allocator.resize_error_policy.abort ++
                    decls.clock_spec.errors.abort ++ decls.map_spec.errors.abort,
            }, void) {
                for (group.trgs[0..group.trgs_len]) |*target| {
                    if (target.lock.atomicTransform(task, .ready, .blocking)) {
                        try meta.wrap(group.builder.acquireTargetLock(address_space, thread_space, allocator, target, task, null, 1));
                    }
                }
                while (groupScan(group, task, .finished)) {
                    try meta.wrap(time.sleep(decls.sleep_spec, .{ .nsec = 5000000 }));
                }
            }
            pub fn addTarget(
                group: *Group,
                allocator: *types.Allocator,
                kind: tasks.OutputMode,
                name: [:0]const u8,
                root: [:0]const u8,
                comptime extra: anytype,
            ) Types.target_payload {
                if (group.trgs_len == group.trgs.len) {
                    group.trgs = allocator.reallocateIrreversible(Target, group.trgs, (group.trgs_len +% 1) *% 2);
                }
                const ret: *Target = &group.trgs[group.trgs_len];
                group.trgs_len +%= 1;
                ret.* = .{
                    .root = root,
                    .name = name,
                    .build_cmd = allocator.createIrreversible(tasks.BuildCommand),
                    .run_cmd = allocator.createIrreversible(tasks.RunCommand),
                };
                builtin.assert(ret.lock.transform(.build, .unavailable, .ready));
                ret.build_cmd.* = .{
                    .kind = kind,
                    .name = name,
                    .cache_root = group.builder.cache_root,
                    .global_cache_root = group.builder.global_cache_root,
                    .main_pkg_path = group.builder.build_root,
                };
                buildExtra(ret.build_cmd, extra);
                ret.emitBinary(allocator, group.builder);
                return ret;
            }
        };
        pub fn addGroup(builder: *Builder, allocator: *types.Allocator, name: [:0]const u8) Types.group_payload {
            if (builder.grps.len == builder.grps_len) {
                builder.grps = try meta.wrap(allocator.reallocateIrreversible(Group, builder.grps, (builder.grps_len +% 1) *% 2));
            }
            const ret: *Group = &builder.grps[builder.grps_len];
            builder.grps_len +%= 1;
            ret.* = .{ .name = name, .builder = builder, .trgs = &.{}, .trgs_len = 0 };
            return ret;
        }
        inline fn system(builder: *const Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(.{
            .throw = spec.errors.command.fork.throw ++ spec.errors.command.execve.throw ++
                spec.errors.command.waitpid.throw ++ spec.errors.clock.throw,
            .abort = spec.errors.command.fork.abort ++ spec.errors.command.execve.abort ++
                spec.errors.command.waitpid.abort ++ spec.errors.clock.throw,
        }, u8) {
            const start: time.TimeSpec = try meta.wrap(time.get(decls.clock_spec, .realtime));
            const ret: u8 = try meta.wrap(proc.command(decls.command_spec, meta.manyToSlice(args[0]), args, builder.vars));
            const finish: time.TimeSpec = try meta.wrap(time.get(decls.clock_spec, .realtime));
            ts.* = time.diff(finish, start);
            return ret;
        }
        pub fn addTarget(
            builder: *Builder,
            allocator: *types.Allocator,
            kind: tasks.OutputMode,
            name: [:0]const u8,
            root: [:0]const u8,
            comptime extra: anytype,
        ) Types.target_payload {
            return builder.grps[0].addTarget(allocator, kind, name, root, extra);
        }

        pub fn init(
            zig_exe: [:0]const u8,
            build_root: [:0]const u8,
            cache_root: [:0]const u8,
            global_cache_root: [:0]const u8,
            args: [][*:0]u8,
            vars: [][*:0]u8,
        ) sys.Call(.{
            .throw = types.Allocator.resize_error_policy.throw ++ spec.errors.mkdir.throw ++ spec.errors.path.throw ++
                spec.errors.close.throw ++ spec.errors.create.throw,
            .abort = types.Allocator.resize_error_policy.abort ++ spec.errors.mkdir.abort ++ spec.errors.path.abort ++
                spec.errors.close.abort ++ spec.errors.create.abort,
        }, Builder) {
            if (types.thread_count != 0) {
                const stack_lb_addr: u64 = types.ThreadSpace.addr_spec.allocated_byte_address();
                const stack_up_addr: u64 = types.ThreadSpace.addr_spec.unallocated_byte_address();
                try meta.wrap(mem.map(decls.map_spec, stack_lb_addr, stack_up_addr -% stack_lb_addr));
            }
            const build_root_fd: u64 = try meta.wrap(file.path(decls.path_spec, build_root));
            try meta.wrap(writeEnvDecls(zig_exe, build_root, cache_root, global_cache_root));
            return .{
                .zig_exe = zig_exe,
                .build_root = build_root,
                .cache_root = cache_root,
                .global_cache_root = global_cache_root,
                .args = args,
                .vars = vars,
                .dir_fd = build_root_fd,
            };
        }
        pub fn acquireTargetThread(
            builder: *Builder,
            address_space: *types.AddressSpace,
            thread_space: *types.ThreadSpace,
            allocator: *types.Allocator,
            target: *Target,
            task: Task,
            depth: u64,
        ) sys.Call(.{
            .throw = types.Allocator.resize_error_policy.throw ++ decls.clock_spec.errors.throw ++ decls.map_spec.errors.throw,
            .abort = types.Allocator.resize_error_policy.abort ++ decls.clock_spec.errors.abort ++ decls.map_spec.errors.abort,
        }, void) {
            if (types.thread_count == 0) {
                doOperation(builder, allocator, target, task, depth);
            } else {
                var arena_index: types.AddressSpace.Index = 0;
                while (arena_index != types.thread_count) : (arena_index +%= 1) {
                    if (thread_space.atomicSet(arena_index)) {
                        const stack_up_addr: u64 = types.ThreadSpace.high(arena_index);
                        const stack_ab_addr: u64 = stack_up_addr -% 4096;
                        return proc.callClone(decls.clone_spec, stack_ab_addr, {}, doOperationThreaded, .{
                            builder, address_space, thread_space, target, task, arena_index, depth,
                        });
                    }
                }
                doOperation(builder, allocator, target, task, depth);
            }
        }
        pub fn acquireTargetLock(
            builder: *Builder,
            address_space: *types.AddressSpace,
            thread_space: *types.ThreadSpace,
            allocator: *types.Allocator,
            target: *Target,
            task: Task,
            arena_index: ?types.AddressSpace.Index,
            depth: u64,
        ) sys.Call(.{
            .throw = types.Allocator.resize_error_policy.throw ++ decls.clock_spec.errors.throw ++ decls.map_spec.errors.throw ++
                decls.clone_spec.errors.throw ++ decls.sleep_spec.errors.throw,
            .abort = types.Allocator.resize_error_policy.abort ++ decls.clock_spec.errors.abort ++ decls.map_spec.errors.abort ++
                decls.clone_spec.errors.abort ++ decls.sleep_spec.errors.abort,
        }, void) {
            for (target.deps[0..target.deps_len]) |dep| {
                if (dep.target.lock.atomicTransform(dep.task, .ready, .blocking)) {
                    try meta.wrap(builder.acquireTargetLock(address_space, thread_space, allocator, dep.target, dep.task, arena_index, depth +% 1));
                }
            }
            while (dependencyScan(address_space, thread_space, target, task, arena_index)) {
                try meta.wrap(time.sleep(decls.sleep_spec, .{ .nsec = 50000 }));
            }
            try meta.wrap(builder.acquireTargetThread(address_space, thread_space, allocator, target, task, depth));
        }
        fn buildWrite(builder: *Builder, target: *Target, allocator: *types.Allocator, root_path: types.Path) [:0]u8 {
            var ret: types.Args = types.Args.init(allocator, 65536);
            ret.writeMany(builder.zig_exe);
            ret.writeOne(0);
            ret.writeMany("build-");
            ret.writeMany(@tagName(target.build_cmd.kind));
            ret.writeOne(0);
            command_line.buildWrite(target.build_cmd, &ret);
            ret.writeFormat(root_path);
            ret.writeOne(0);
            ret.writeOne(0);
            ret.undefine(1);
            return ret.referAllDefinedWithSentinel(0);
        }
        fn buildLength(builder: *Builder, target: *Target, root_path: types.Path) u64 {
            var len: u64 = builder.zig_exe.len +% 1;
            len +%= 6 +% @tagName(target.build_cmd.kind).len +% 1;
            len +%= command_line.buildLength(target.build_cmd);
            len +%= root_path.formatLength();
            len +%= 1;
            return len;
        }
        fn buildOperation(builder: *Builder, allocator: *types.Allocator, target: *Target, task: Task, depth: u64) bool {
            _ = task;
            const save: types.Allocator.Save = allocator.save();
            defer allocator.restore(save);

            const bin_path: [:0]const u8 = target.binaryRelative(allocator);
            const root_path: types.Path = target.rootSourcePath(builder);

            const args: [:0]u8 = buildWrite(builder, target, allocator, root_path);
            const ptrs: [][*:0]u8 = makeArgPtrs(allocator, args);

            const old_size: u64 = builder.getFileSize(bin_path);

            var cmd_time: time.TimeSpec = undefined;
            const rc: u8 = try meta.wrap(builder.system(ptrs, &cmd_time));

            const new_size: u64 = builder.getFileSize(bin_path);
            if (true or depth > spec.options.max_relevant_depth) {
                debug.buildNotice(target.name, cmd_time, old_size, new_size);
            }
            return rc == 0;
        }
        fn doOperationThreaded(
            builder: *Builder,
            address_space: *types.AddressSpace,
            thread_space: *types.ThreadSpace,
            target: *Target,
            task: Task,
            arena_index: types.AddressSpace.Index,
            depth: u64,
        ) void {
            var allocator: types.Allocator = types.Allocator.init(address_space, arena_index);
            defer allocator.deinit(address_space, arena_index);
            if (switch (task) {
                .build => buildOperation(builder, &allocator, target, task, depth),
                .format => unreachable,
                .run => unreachable,
            }) {
                builtin.assert(target.lock.atomicTransform(task, .blocking, .finished));
                builtin.assert(thread_space.atomicUnset(arena_index));
            } else {
                builtin.assert(target.lock.atomicTransform(task, .blocking, .failed));
                builtin.assert(thread_space.atomicUnset(arena_index));
            }
        }
        fn doOperation(
            builder: *Builder,
            allocator: *types.Allocator,
            target: *Target,
            task: Task,
            depth: u64,
        ) void {
            if (switch (task) {
                .build => buildOperation(builder, allocator, target, task, depth),
                .format => unreachable,
                .run => unreachable,
            }) {
                builtin.assert(target.lock.atomicTransform(task, .blocking, .finished));
            } else {
                builtin.assert(target.lock.atomicTransform(task, .blocking, .failed));
            }
        }
        fn getFileStatus(builder: *Builder, name: [:0]const u8) ?file.FileStatus {
            return meta.wrap(file.fstatAt(decls.stat_spec, builder.dir_fd, name)) catch null;
        }
        fn getFileSize(builder: *Builder, name: [:0]const u8) u64 {
            return if (getFileStatus(builder, name)) |st| st.size else 0;
        }
        fn makeZigCacheDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_cache_dir, file.dir_mode));
        }
        fn makeZigOutDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_out_dir, file.dir_mode));
        }
        fn makeBinDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_exe_out_dir, file.dir_mode));
        }
        fn makeAuxDir(builder: *Builder) sys.Call(decls.mkdir_spec.errors, void) {
            try meta.wrap(file.makeDirAt(decls.mkdir_spec, builder.dir_fd, tok.zig_aux_out_dir, file.dir_mode));
        }
        fn writeEnvDecls(
            zig_exe: [:0]const u8,
            build_root: [:0]const u8,
            cache_root: [:0]const u8,
            global_cache_root: [:0]const u8,
        ) sys.Call(.{
            .throw = decls.mkdir_spec.errors.throw ++ decls.create_spec.errors.throw ++
                decls.write_spec.errors.throw ++ decls.close_spec.errors.throw,
            .abort = decls.mkdir_spec.errors.abort ++ decls.create_spec.errors.abort ++
                decls.write_spec.errors.abort ++ decls.close_spec.errors.abort,
        }, void) {
            const cache_root_fd: u64 = try meta.wrap(file.path(decls.path_spec, cache_root));
            const env_fd: u64 = try meta.wrap(file.createAt(decls.create_spec, cache_root_fd, tok.env_name, file.file_mode));
            for ([_][]const u8{
                tok.zig_exe_decl,                           zig_exe,
                tok.end_expr ++ tok.build_root_decl,        build_root,
                tok.end_expr ++ tok.cache_root_decl,        cache_root,
                tok.end_expr ++ tok.global_cache_root_decl, global_cache_root,
                tok.end_expr,
            }) |s| {
                try meta.wrap(file.write(decls.write_spec, env_fd, s));
            }
            try meta.wrap(file.close(decls.close_spec, env_fd));
            try meta.wrap(file.close(decls.close_spec, cache_root_fd));
        }
        fn groupScan(group: *Group, task: Task, state: State) bool {
            for (group.trgs[0..group.trgs_len]) |*target| {
                if (target.lock.get(task) == .failed) {
                    builtin.proc.exitWithError(error.DependencyFailed, 2);
                }
            }
            for (group.trgs[0..group.trgs_len]) |target| {
                if (target.lock.get(task) != state) {
                    return true;
                }
            }
            return false;
        }
        fn dependencyScan(
            address_space: *types.AddressSpace,
            thread_space: *types.ThreadSpace,
            target: *Target,
            task: Task,
            arena_index: ?types.AddressSpace.Index,
        ) bool {
            var idx: u64 = 0;
            while (idx != target.deps_len) : (idx +%= 1) {
                const dep: Dependency = target.deps[idx];
                if (dep.target.lock.get(dep.task) == .failed) {
                    builtin.assert(target.lock.atomicTransform(task, .blocking, .failed));
                    if (arena_index) |index| {
                        builtin.assert(address_space.atomicUnset(index));
                        builtin.assert(thread_space.atomicUnset(index));
                    }
                    builtin.proc.exitWithError(error.DependencyFailed, 2);
                }
            }
            while (idx != target.deps_len) : (idx +%= 1) {
                const dep: Dependency = target.deps[idx];
                if (dep.target.lock.get(dep.task) != dep.state) {
                    return true;
                }
            }
            return false;
        }
        const decls = struct {
            const path_spec: file.PathSpec = spec.path();
            const close_spec: file.CloseSpec = spec.close();
            const map_spec: mem.MapSpec = spec.map();
            const stat_spec: file.StatSpec = spec.stat();
            const unmap_spec: mem.UnmapSpec = spec.unmap();
            const clock_spec: time.ClockSpec = spec.clock();
            const sleep_spec: time.SleepSpec = spec.sleep();
            const clone_spec: proc.CloneSpec = spec.clone();
            const write_spec: file.WriteSpec = spec.write();
            const create_spec: file.CreateSpec = spec.create();
            const mkdir_spec: file.MakeDirSpec = spec.mkdir();
            const command_spec: proc.CommandSpec = spec.command();
        };
        const tok = struct {
            const env_name: [:0]const u8 = "env.zig";
            const build_name: [:0]const u8 = "build.zig";

            const zig_out_dir: [:0]const u8 = "zig-out/";
            const zig_cache_dir: [:0]const u8 = "zig-cache/";
            const exe_out_dir: [:0]const u8 = "zig-out/bin/";
            const aux_out_dir: [:0]const u8 = "zig-out/aux/";

            const lib_ext: [:0]const u8 = ".so";
            const obj_ext: [:0]const u8 = ".o";
            const asm_ext: [:0]const u8 = ".s";
            const llvm_bc_ext: [:0]const u8 = ".bc";
            const llvm_ir_ext: [:0]const u8 = ".ll";
            const header_ext: [:0]const u8 = ".h";
            const analysis_ext: [:0]const u8 = ".json";

            const zig_exe_decl: [:0]const u8 = "pub const zig_exe: [:0]const u8 = \"";
            const build_root_decl: [:0]const u8 = "pub const build_root: [:0]const u8 = \"";
            const cache_root_decl: [:0]const u8 = "pub const cache_dir: [:0]const u8 = \"";
            const global_cache_root_decl: [:0]const u8 = "pub const global_cache_dir: [:0]const u8 = \"";
            const end_expr: [:0]const u8 = "\";\n";
        };
        const debug = struct {
            const ChangedSize = fmt.ChangedBytesFormat(.{
                .dec_style = "\x1b[92m-",
                .inc_style = "\x1b[91m+",
            });
            const new_style: [:0]const u8 = "\x1b[93m";
            const no_style: [:0]const u8 = "*\x1b[0m";
            const about_run_s: [:0]const u8 = builtin.debug.about("run");
            const about_build_s: [:0]const u8 = builtin.debug.about("build");
            const about_format_s: [:0]const u8 = builtin.debug.about("format");
            fn buildNotice(name: [:0]const u8, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
                var array: mem.StaticString(4096) = undefined;
                array.undefineAll();
                array.writeMany(about_build_s);
                array.writeMany(name);
                array.writeMany(", ");
                if (old_size == 0) {
                    array.writeMany(new_style);
                    array.writeFormat(fmt.bytes(new_size));
                    array.writeMany(no_style);
                } else {
                    array.writeFormat(ChangedSize.init(old_size, new_size));
                }
                array.writeMany(", ");
                array.writeFormat(fmt.ud64(durat.sec));
                array.writeMany(".");
                array.writeFormat(fmt.nsec(durat.nsec));
                array.undefine(6);
                array.writeMany("s\n");
                builtin.debug.write(array.readAll());
            }
            fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: ?u8) void {
                var array: mem.StaticString(4096) = undefined;
                array.undefineAll();
                array.writeMany(about);
                array.writeMany(name);
                array.writeMany(", ");
                if (rc) |return_code| {
                    array.writeMany("rc=");
                    array.writeFormat(fmt.ud8(return_code));
                    array.writeMany(", ");
                }
                array.writeFormat(fmt.ud64(durat.sec));
                array.writeMany(".");
                array.writeFormat(fmt.nsec(durat.nsec));
                array.undefine(6);
                array.writeMany("s\n");
                builtin.debug.write(array.readAll());
            }
            inline fn runNotice(name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
                simpleTimedNotice(about_run_s, name, durat, rc);
            }
            inline fn formatNotice(name: [:0]const u8, durat: time.TimeSpec) void {
                simpleTimedNotice(about_format_s, name, durat, null);
            }
        };
    });
}
fn duplicate(allocator: *types.Allocator, values: []const u8) [:0]u8 {
    var buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, values.len, 0);
    mach.memcpy(buf.ptr, values.ptr, values.len);
    return buf;
}
fn duplicate2(allocator: *types.Allocator, values: []const []const u8) [][:0]u8 {
    var buf: [][:0]u8 = allocator.allocateIrreversible([:0]u8, values.len);
    var idx: u64 = 0;
    for (values) |value| {
        buf[idx] = duplicate(allocator, value);
        idx +%= 1;
    }
}
fn concatenate(allocator: *types.Allocator, values: []const []const u8) [:0]u8 {
    var len: u64 = 0;
    for (values) |value| len +%= value.len;
    const buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, len, 0);
    var idx: u64 = 0;
    for (values) |value| {
        mach.memcpy(buf[idx..].ptr, value.ptr, value.len);
        idx +%= value.len;
    }
    return buf;
}
fn makeArgPtrs(allocator: *types.Allocator, args: [:0]u8) [][*:0]u8 {
    const ptrs: [][*:0]u8 = argsPointers(allocator, args);
    var len: u64 = 0;
    var idx: u64 = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0) {
            ptrs[len] = args[pos..idx :0];
            len +%= 1;
            pos = idx +% 1;
        }
    }
    ptrs[len] = builtin.zero([*:0]u8);
    return ptrs[0..len];
}
fn argsPointers(allocator: *types.Allocator, args: [:0]u8) [][*:0]u8 {
    var count: u64 = 0;
    for (args) |value| {
        count +%= @boolToInt(value == 0);
    }
    return allocator.allocateIrreversible([*:0]u8, count +% 1);
}
noinline fn buildExtra(build_cmd: *tasks.BuildCommand, comptime extra: anytype) void {
    inline for (@typeInfo(@TypeOf(extra)).Struct.fields) |field| {
        @field(build_cmd, field.name) = @field(extra, field.name);
    }
}
