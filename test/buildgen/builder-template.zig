const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");

pub const BuildCmd = struct {
    cmd: enum { exe, lib, obj, fmt, ast_check, run },
    root: [:0]const u8,
    _: void,
    pub const Allocator = mem.GenericArenaAllocator(.{
        .arena_index = mem.arena_indices.builder,
        .options = .{ .require_filo_free = false, .trace_state = true },
    });
    const fmt_spec: mem.ReinterpretSpec = blk: {
        var tmp: mem.ReinterpretSpec = mem.fmt_wr_spec;
        tmp.integral = .{ .format = .dec };
        break :blk tmp;
    };
    const DirStream = file.DirStreamBlock(.{ .Allocator = Allocator, .options = .{} });
    const Path = Allocator.StructuredVectorWithSentinel(u8, 0);
    const Paths = Allocator.StructuredVectorLowAligned(Path, 8);
    const StringV = Allocator.StructuredHolderHolderLowAligned(u8, 8);
    const String = Allocator.StructuredVectorLowAligned(u8, 8);
    const PointersV = Allocator.StructuredHolder([*:0]u8);
    const Pointers = Allocator.StructuredVector([*:0]u8);
    const StaticString = mem.StaticString(8192);
    const PointersS = mem.StaticArray([*:0]u8, 1024);
    const ArgData = struct { data: String, ptrs: Pointers };
    const ArgDataS = struct { data: StaticString, ptrs: PointersS };

    fn buildAllocatedCommandString(build: BuildCmd, allocator: *Allocator) anyerror!String {
        var array: StringV = StringV.init(allocator);
        try array.appendMany(allocator, "zig\x00");
        switch (build.cmd) {
            .lib, .exe, .obj => {
                try array.appendMany(allocator, "build-");
                try array.appendMany(allocator, @tagName(build.cmd));
                try array.appendOne(allocator, '\x00');
            },
            .fmt, .ast_check, .run => {
                try array.appendMany(allocator, @tagName(build.cmd));
                try array.appendOne(allocator, '\x00');
            },
        }
        build.__dynamic;
        try array.appendAny(mem.ptr_wr_spec, allocator, .{ build.root, "\x00" });
        return array.fix(allocator);
    }
    fn buildStaticCommandString(build: BuildCmd) anyerror!StaticString {
        var array: StaticString = .{};
        array.writeMany("zig\x00");
        switch (build.cmd) {
            .lib, .exe, .obj => {
                array.writeMany("build-");
                array.writeMany(@tagName(build.cmd));
                array.writeOne('\x00');
            },
            .fmt, .ast_check, .run => {
                array.writeMany(@tagName(build.cmd));
                array.writeOne('\x00');
            },
        }
        build.__static;
        array.writeAny(mem.ptr_wr_spec, .{ build.root, "\x00" });
        return array;
    }
    fn parcelDataV(build: BuildCmd, allocator: *Allocator) anyerror!ArgData {
        const data: String = try build.buildAllocatedCommandString(allocator);
        var ptrsv: PointersV = PointersV.init(allocator);
        var idx: u64 = 0;
        for (data.readAll()) |c, i| {
            if (c == 0) {
                try ptrsv.appendOne(allocator, data.referAll()[idx..i :0].ptr);
                idx = i + 1;
            }
        }
        if (ptrsv.impl.low(allocator.*) != ptrsv.impl.next()) {
            mem.set(ptrsv.impl.next(), @as(u64, 0), 1);
        }
        const ptrs: Pointers = try ptrsv.fix(allocator);
        return ArgData{ .data = data, .ptrs = ptrs };
    }
    pub fn show(build: BuildCmd, address_space: *mem.AddressSpace) !void {
        var allocator: Allocator = try Allocator.init(address_space);
        var ad: BuildCmd.ArgData = try build.parcelDataV(&allocator);
        for (ad.ptrs.readAll()) |argp| {
            try file.write(2, mem.manyToSlice(argp));
            try file.write(2, "\n");
        }
        allocator.discard();
        allocator.deinit(address_space);
    }
    pub fn execute(build: BuildCmd, address_space: *mem.AddressSpace, vars: [][*:0]u8) !u64 {
        var allocator: Allocator = try Allocator.init(address_space);
        var ad: BuildCmd.ArgData = try build.parcelDataV(&allocator);
        const dir_fd: u64 = try file.find(vars, "zig");
        const args: [][*:0]u8 = ad.ptrs.referAll();
        var wstatus: u64 = 0;
        if (args.len != 0) {
            try proc.commandAt(.{}, dir_fd, "zig", args, vars);
        }
        allocator.discard();
        allocator.deinit(address_space);
        return wstatus;
    }
    pub fn executeS(build: BuildCmd, vars: [][*:0]u8) !u64 {
        const dir_fd: u64 = try file.find(vars, "zig");
        defer file.close(.{ .errors = null }, dir_fd);
        const data: StaticString = try build.buildStaticCommandString();
        var args: PointersS = .{};
        var idx: u64 = 0;
        for (data.readAll()) |c, i| {
            if (c == 0) {
                args.writeOne(data.referAll()[idx..i :0].ptr);
                idx = i + 1;
            }
        }
        if (args.impl.start() != args.impl.next()) {
            mem.set(args.impl.next(), @as(u64, 0), 1);
        }
        if (args.count() != 0) {
            return proc.commandAt(.{}, dir_fd, "zig", args.referAll(), vars);
        }
        return 0;
    }
};
