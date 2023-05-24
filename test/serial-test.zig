const top = @import("../zig_lib.zig");
const mem = top.mem;
const fmt = top.fmt;
const proc = top.proc;
const file = top.file;
const mach = top.mach;
const meta = top.meta;
const spec = top.spec;
const build = top.build;
const serial = top.serial;
const builtin = top.builtin;
const testing = top.testing;

const attr = @import("../top/mem/gen/attr.zig");
const mem_types = @import("../top/mem/gen/types.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
pub const signal_handlers: builtin.SignalHandlers = .{
    .segmentation_fault = true,
    .bus_error = true,
    .illegal_instruction = true,
    .floating_point_error = true,
};
pub const runtime_assertions: bool = true;
pub const comptime_assertions: bool = false;

const test_real_examples: bool = true;

const AddressSpace = Builder.AddressSpace;

const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
    .options = spec.allocator.options.small_composed,
});
const spec_sets_a: []const mem_types.AbstractSpecification = attr.abstract_specs;
const spec_sets_0: []const []const []const mem_types.Specifier = &.{ &.{ &.{ .{ .default = .{
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
const tech_sets_0: []const []const []const mem_types.Technique = &.{ &.{&.{}}, &.{&.{}}, &.{&.{}}, &.{&.{}}, &.{ &.{.{ .mutually_exclusive = .{
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

const Variety = struct {
    x: []const []const u8,
    y: [*:0]const u8,
};
pub fn testVarietyStructure(address_space: *AddressSpace) !void {
    var allocator: Allocator = Allocator.init(address_space);
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
    builtin.assertEqualMemory(Return, u, t);
}
const serial_spec: serial.SerialSpec = .{
    .Allocator = Allocator,
    .logging = spec.serializer.logging.silent,
    .errors = spec.serializer.errors.noexcept,
};
pub fn testLargeStructure(address_space: *AddressSpace) !void {
    var allocator: Allocator = Allocator.init(address_space);
    defer allocator.deinit(address_space);
    try meta.wrap(serial.serialWrite(serial_spec, []const mem_types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_a));
    const spec_sets_b: []const mem_types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const mem_types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, []const mem_types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_b));
    const spec_sets_c: []const mem_types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const mem_types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    builtin.assertEqualMemory([]const mem_types.AbstractSpecification, spec_sets_b, spec_sets_c);
}
const builder_spec: build.BuilderSpec = .{
    .errors = spec.builder.errors.noexcept,
    .logging = spec.builder.logging.silent,
};
const Builder = build.GenericBuilder(builder_spec);

var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .dependencies = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "env" },
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
        .name = "env",
        .path = "zig-cache/env.zig",
    } },
};
pub fn testBuildProgram(allocator: *Builder.Allocator, builder: *Builder) !void {
    const g3 = try builder.addGroup(allocator, "g3");
    build_cmd.kind = .obj;
    const t2: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj0.zig" });
    const t3: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj1.zig" });
    const t4: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj2.zig" });
    const t5: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj3.zig" });
    const t6: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj4.zig" });
    const t7: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/obj5.zig" });
    const t1: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/lib0.zig" });
    const t0: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .root = "test/src/lib1.zig" });
    build_cmd.kind = .exe;
    const t: *Builder.Target = try g3.addBuild(allocator, build_cmd, .{ .name = "bin", .root = "test/src/main.zig" });
    t1.dependOnObject(allocator, t2);
    t1.dependOnObject(allocator, t3);
    t1.dependOnObject(allocator, t4);
    t0.dependOnObject(allocator, t1);
    t0.dependOnObject(allocator, t2);
    t0.dependOnObject(allocator, t3);
    t.dependOnObject(allocator, t0);
    t.dependOnObject(allocator, t5);
    t.dependOnObject(allocator, t6);
    t.dependOnObject(allocator, t7);
}
pub fn testLargeFlatStructureBuilder(args: anytype, vars: anytype, address_space: *AddressSpace) !void {
    var allocator_a: Allocator = Allocator.init(address_space);
    var allocator_b: Builder.Allocator = if (Builder.Allocator == mem.SimpleAllocator)
        Builder.Allocator.init_arena(Builder.AddressSpace.arena(Builder.max_thread_count))
    else
        Builder.Allocator.init(address_space, Builder.max_thread_count);
    defer if (Builder.Allocator != mem.SimpleAllocator) {
        allocator_b.deinit(address_space, Builder.max_thread_count);
    };
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try testBuildProgram(&allocator_b, &builder);
    var buf: [4096]u8 = undefined;
    for (builder.grps[0..builder.grps_len], 0..) |grp, grp_idx| {
        const pathname: []const u8 = "zig-out/bin/groups";
        for (grp.trgs[0..grp.trgs_len], 0..) |trg, trg_idx| {
            const s = allocator_a.save();
            defer allocator_a.restore(s);
            const len: u64 = builtin.debug.writeMulti(&buf, &.{ pathname, builtin.fmt.ud64(grp_idx).readAll(), "_", builtin.fmt.ud64(trg_idx).readAll() });
            buf[len] = 0;
            try serial.serialWrite(.{ .Allocator = Allocator }, build.BuildCommand, &allocator_a, buf[0..len :0], trg.task_cmd.build.*);
        }
    }
    for (builder.grps[0..builder.grps_len], 0..) |grp, grp_idx| {
        const pathname: []const u8 = "zig-out/bin/groups";
        for (grp.trgs[0..grp.trgs_len], 0..) |trg, trg_idx| {
            const s = allocator_a.save();
            defer allocator_a.restore(s);
            const len: u64 = builtin.debug.writeMulti(&buf, &.{ pathname, builtin.fmt.ud64(grp_idx).readAll(), "_", builtin.fmt.ud64(trg_idx).readAll() });
            buf[len] = 0;
            const s_build_cmd: build.BuildCommand = try serial.serialRead(.{ .Allocator = Allocator }, build.BuildCommand, &allocator_a, buf[0..len :0]);
            try builtin.expectEqualMemory(build.BuildCommand, s_build_cmd, trg.task_cmd.build.*);
        }
    }
}
pub fn testLongComplexCase(address_space: *AddressSpace) !void {
    var allocator: Allocator = Allocator.init(address_space);
    defer allocator.deinit(address_space);

    try meta.wrap(serial.serialWrite(serial_spec, []const []const []const mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0));
    const spec_sets_1: [][][]mem_types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []const []const []const mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const []const []const mem_types.Specifier, spec_sets_0, spec_sets_1);

    try meta.wrap(serial.serialWrite(serial_spec, []const []const mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0]));
    const spec_set_1: [][]mem_types.Specifier = try meta.wrap(serial.serialRead(serial_spec, [][]mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const []const mem_types.Specifier, spec_set_1, spec_sets_0[0]);

    try meta.wrap(serial.serialWrite(serial_spec, []const mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0][0]));
    const specs_1: []mem_types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const mem_types.Specifier, specs_1, spec_sets_0[0][0]);

    try meta.wrap(serial.serialWrite(serial_spec, mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0][0][0]));
    const spec_1: mem_types.Specifier = try meta.wrap(serial.serialRead(serial_spec, mem_types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory(mem_types.Specifier, spec_1, spec_sets_0[0][0][0]);
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
            var allocator: Allocator = Allocator.init(address_space);
            defer allocator.deinit(address_space);
            try meta.wrap(serial.serialWrite(serial_spec, S, &allocator, "zig-out/bin/serial_feature_test", s));
        }
        {
            var allocator: Allocator = Allocator.init(address_space);
            defer allocator.deinit(address_space);
            const t: S = try meta.wrap(serial.serialRead(serial_spec, S, &allocator, "zig-out/bin/serial_feature_test"));
            try builtin.expectEqualMemory(S, s, t);
        }
    }
}

//pub fn main() !void {
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    try meta.wrap(testWriteSerialFeatures(&address_space));
    if (test_real_examples) {
        try meta.wrap(testLongComplexCase(&address_space));
        try meta.wrap(testLargeStructure(&address_space));
        try meta.wrap(testLargeFlatStructureBuilder(args, vars, &address_space));
        try meta.wrap(testVarietyStructure(&address_space));
    }
}
