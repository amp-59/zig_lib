const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const serial = @import("./serial.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

const attr = @import("./mem/attr.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = .{
    .Success = true,
    .Acquire = false,
    .Release = false,
    .Error = true,
    .Fault = true,
};
pub const signal_handlers: builtin.SignalHandlers = .{
    .segmentation_fault = true,
    .bus_error = false,
    .illegal_instruction = false,
    .floating_point_error = false,
};
pub const runtime_assertions: bool = false;

const AddressSpace = preset.address_space.regular_128;
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = .{ .prefer_remap = false },
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});

const Variety = struct {
    x: []const []const u8,
    y: [*:0]const u8,
};
pub fn testVarietyStructure() !void {
    const std = @import("std");
    _ = std;

    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    const v: []const []const []const []const Variety = &.{&.{&.{&.{
        .{ .x = &.{ "one,", "two,", "three," }, .y = "one,two,three\n" },
        .{ .x = &.{ "four,", "five,", "six," }, .y = "four,five,six\n\n" },
    }}}};
    const Return = @TypeOf(@constCast(v));

    try serial.serialize(&allocator, "zig-out/bin/variety_0", v);
    const u: Return = try serial.deserialize(Return, &allocator, "zig-out/bin/variety_0");

    try serial.serialize(&allocator, "zig-out/bin/variety_1", u);
    const t: Return = try serial.deserialize(Return, &allocator, "zig-out/bin/variety_1");

    testing.print(v);
    testing.print(u);
    testing.print(t);
}
pub fn testSingleComplexCase() !void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    var address_space: AddressSpace = .{};

    var allocator: Allocator = try Allocator.init(&address_space);
    allocator.ub_addr +%= 1;
    try serial.serialize(&allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0);
    allocator.deinit(&address_space);

    allocator = try Allocator.init(&address_space);
    allocator.ub_addr +%= 1;
    const spec_sets_1: [][][]attr.Specifier = try serial.deserialize([][][]attr.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"));
    try serial.serialize(&allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_1[0]);
    allocator.deinit(&address_space);

    allocator = try Allocator.init(&address_space);
    allocator.ub_addr +%= 1;
    const spec_set_1: [][]attr.Specifier = try serial.deserialize([][]attr.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"));
    try serial.serialize(&allocator, builtin.absolutePath("zig-out/bin/spec"), spec_set_1[0]);
    allocator.deinit(&address_space);

    allocator = try Allocator.init(&address_space);
    allocator.ub_addr +%= 1;
    const spec_1: []attr.Specifier = try serial.deserialize([]attr.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"));
    try serial.serialize(&allocator, builtin.absolutePath("zig-out/bin/spec"), spec_1[0]);
    allocator.deinit(&address_space);

    allocator = try Allocator.init(&address_space);
    const spec: attr.Specifier = try serial.deserialize(attr.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"));
    _ = spec;

    allocator.deinit(&address_space);
}
pub fn main() !void {
    try meta.wrap(testVarietyStructure());
    try meta.wrap(testSingleComplexCase());
}
const spec_sets_0: []const []const []const attr.Specifier = &.{ &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .default = .{
    .tag = .count,
    .type = .{ .type_name = "u64" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .default = .{
    .tag = .Allocator,
    .type = .{ .type_name = "type" },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .default = .{
    .tag = .Allocator,
    .type = .{ .type_name = "type" },
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .default = .{
    .tag = .Allocator,
    .type = .{ .type_name = "type" },
} } }, &.{ .{ .default = .{
    .tag = .child,
    .type = .{ .type_name = "type" },
} }, .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .default = .{
    .tag = .Allocator,
    .type = .{ .type_name = "type" },
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{
            .{
                .name = "lb_addr",
                .type = .{ .type_name = "u64" },
                .default_value = null,
            },
            .{
                .name = "up_addr",
                .type = .{ .type_name = "u64" },
                .default_value = null,
            },
        },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } }, &.{ &.{.{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }}, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } }, &.{ .{ .optional_derived = .{
    .tag = .low_alignment,
    .type = .{ .type_name = "u64" },
    .fn_name = "lowAlignment",
} }, .{ .optional_variant = .{
    .tag = .sentinel,
    .type = .{ .type_refer = .{
        .spec = "*const ",
        .type = &.{ .type_name = "anyopaque" },
    } },
} }, .{ .decl_optional_variant = .{
    .ctn_tag = .Allocator,
    .decl_tag = .arena,
    .ctn_type = .{ .type_name = "type" },
    .decl_type = .{ .type_decl = .{ .Composition = .{
        .spec = "struct",
        .fields = &.{ .{
            .name = "lb_addr",
            .type = .{ .type_name = "u64" },
            .default_value = null,
        }, .{ .name = "up_addr", .type = .{ .type_name = "u64" }, .default_value = null } },
    } } },
} } } } };
const tech_sets_0: []const []const []const attr.Technique = &.{ &.{&.{}}, &.{&.{}}, &.{&.{}}, &.{&.{}}, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } }, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } }, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } }, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } }, &.{ .{ .standalone = .single_packed_approximate_capacity }, .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .single_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } }, &.{ .{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }, .{ .mutually_exclusive = .{
    .kind = .optional,
    .opt_tag = .capacity,
    .tech_tag = .double_packed_approximate_capacity,
    .tech_tags = &.{ .single_packed_approximate_capacity, .double_packed_approximate_capacity },
} } } }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .disjunct_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment, .disjunct_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }} }, &.{ &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .lazy_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }}, &.{.{ .mutually_exclusive = .{
    .kind = .mandatory,
    .opt_tag = .alignment,
    .tech_tag = .unit_alignment,
    .tech_tags = &.{ .lazy_alignment, .unit_alignment },
} }} } };
