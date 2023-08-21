const zl = @import("../zig_lib.zig");
const mg = @import("../top/mem/gen.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const file = zl.file;
const mach = zl.mach;
const meta = zl.meta;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const serial = zl.serial;
const builtin = zl.builtin;
const testing = zl.testing;
const tab = @import("./tab.zig");

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;
pub const signal_handlers: debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
pub const runtime_assertions: bool = true;
pub const comptime_assertions: bool = false;
const test_real_examples: bool = true;
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = spec.address_space.exact_8,
    .arena_index = 0,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
    .options = spec.allocator.options.small,
});
const AddressSpace = Allocator.AddressSpace;
const Variety = struct {
    x: []const []const u8,
    y: [*:0]const u8,
};
pub fn testVarietyStructure(address_space: *Allocator.AddressSpace) !void {
    var allocator: Allocator = try Allocator.init(address_space);
    defer allocator.deinit(address_space);
    const v: []const []const []const []const Variety = &.{&.{&.{&.{
        .{ .x = &.{ "one,", "two,", "three," }, .y = "one,two,three\n" },
        .{ .x = &.{ "four,", "five,", "six," }, .y = "four,five,six\n\n" },
    }}}};
    const Return = @TypeOf(@constCast(v));
    try meta.wrap(serial.serialWrite(serial_spec, @TypeOf(v), &allocator, builtin.absolutePath("zig-out/bin/variety_0"), v));
    const u: Return = try meta.wrap(serial.serialRead(serial_spec, Return, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, @TypeOf(u), &allocator, builtin.absolutePath("zig-out/bin/variety_1"), u));
    const t: Return = try meta.wrap(serial.serialRead(serial_spec, Return, &allocator, builtin.absolutePath("zig-out/bin/variety_1")));
    debug.assertEqualMemory(Return, u, t);
}
const serial_spec: serial.SerialSpec = .{
    .Allocator = Allocator,
    .logging = spec.serializer.logging.silent,
    .errors = spec.serializer.errors.noexcept,
};
pub fn testLargeStructure(address_space: *Allocator.AddressSpace) !void {
    var allocator: Allocator = try Allocator.init(address_space);
    defer allocator.deinit(address_space);
    try meta.wrap(serial.serialWrite(serial_spec, []const mg.types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), mg.attr.abstract_specs));
    const spec_sets_b: []const mg.types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const mg.types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, []const mg.types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_b));
    const spec_sets_c: []const mg.types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const mg.types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    debug.assertEqualMemory([]const mg.types.AbstractSpecification, spec_sets_b, spec_sets_c);
}
const Node = build.GenericNode(.{});

var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .dependencies = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "context" },
    },
    .image_base = 0x10000,
    .strip = true,
    .static = true,
    .compiler_rt = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .omit_frame_pointer = false,
    .modules = &.{ .{
        .name = "zig_lib",
        .path = "zig_lib.zig",
    }, .{
        .name = "@build",
        .path = "build.zig",
    }, .{
        .name = "context",
        .path = "zig-cache/context.zig",
    } },
};
pub fn testLongComplexCase(address_space: *AddressSpace) !void {
    var allocator: Allocator = try Allocator.init(address_space);
    defer allocator.deinit(address_space);
    try meta.wrap(serial.serialWrite(serial_spec, []const []const []const mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), tab.spec_sets_0));
    const spec_sets_1: [][][]mg.types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []const []const []const mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    try debug.expectEqualMemory([]const []const []const mg.types.Specifier, tab.spec_sets_0, spec_sets_1);
    try meta.wrap(serial.serialWrite(serial_spec, []const []const mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), tab.spec_sets_0[0]));
    const spec_set_1: [][]mg.types.Specifier = try meta.wrap(serial.serialRead(serial_spec, [][]mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    try debug.expectEqualMemory([]const []const mg.types.Specifier, spec_set_1, tab.spec_sets_0[0]);
    try meta.wrap(serial.serialWrite(serial_spec, []const mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), tab.spec_sets_0[0][0]));
    const specs_1: []mg.types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    try debug.expectEqualMemory([]const mg.types.Specifier, specs_1, tab.spec_sets_0[0][0]);
    try meta.wrap(serial.serialWrite(serial_spec, mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), tab.spec_sets_0[0][0][0]));
    const spec_1: mg.types.Specifier = try meta.wrap(serial.serialRead(serial_spec, mg.types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    try debug.expectEqualMemory(mg.types.Specifier, spec_1, tab.spec_sets_0[0][0][0]);
}
pub fn testWriteSerialFeatures(address_space: *AddressSpace) !void {
    const test_optionals_and_slices: bool = true;
    if (test_optionals_and_slices) {
        const S = struct {
            string: []const u8,
            slice_of_strings: []const []const u8,
            slices_of_strings: []const []const []const u8,
            optional_string: ?[]const u8,
            optional_slice_of_strings: ?[]const []const u8,
            optional_slices_of_strings: ?[]const []const []const u8,
        };
        var s: S = .{
            .string = "one",
            .slice_of_strings = &.{ "one", "two", "three" },
            .slices_of_strings = &.{
                &.{ "one", "two", "three" },
                &.{ "four", "five", "six" },
                &.{ "seven", "eight", "nine" },
            },
            .optional_string = "one",
            .optional_slice_of_strings = &.{ "one", "two", "three" },
            .optional_slices_of_strings = &.{
                &.{ "one", "two", "three" },
                &.{ "four", "five", "six" },
                &.{ "seven", "eight", "nine" },
            },
        };
        {
            var allocator: Allocator = try Allocator.init(address_space);
            defer allocator.deinit(address_space);
            try meta.wrap(serial.serialWrite(serial_spec, S, &allocator, "zig-out/bin/serial_feature_test", s));
        }
        {
            var allocator: Allocator = try Allocator.init(address_space);
            defer allocator.deinit(address_space);
            const t: S = try meta.wrap(serial.serialRead(serial_spec, S, &allocator, "zig-out/bin/serial_feature_test"));
            try debug.expectEqualMemory(S, s, t);
        }
    }
}
pub fn main() !void {
    var address_space: AddressSpace = .{};
    try meta.wrap(testWriteSerialFeatures(&address_space));
    try meta.wrap(testLongComplexCase(&address_space));
    try meta.wrap(testLargeStructure(&address_space));
    try meta.wrap(testVarietyStructure(&address_space));
}
