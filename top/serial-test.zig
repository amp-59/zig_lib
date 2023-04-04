const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const spec = @import("./spec.zig");
const build = @import("./build2.zig");
const serial = @import("./serial.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

const attr = @import("./mem/attr.zig");
const mem_types = @import("./mem/types.zig");

const build_types = @import("./build/types2.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
pub const signal_handlers: builtin.SignalHandlers = .{
    .segmentation_fault = true,
    .bus_error = false,
    .illegal_instruction = false,
    .floating_point_error = false,
};
pub const runtime_assertions: bool = true;
pub const comptime_assertions: bool = true;

const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_offset = 0x40000000,
    .logging = spec.address_space.logging.silent,
    .errors = spec.address_space.errors.noexcept,
    .options = .{},
});
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = spec.allocator.options.small,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
});
const spec_sets_a: []const mem_types.AbstractSpecification = &attr.abstract_specs;
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
pub fn testVarietyStructure() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    const v: []const []const []const []const Variety = &.{&.{&.{&.{
        .{ .x = &.{ "one,", "two,", "three," }, .y = "one,two,three\n" },
        .{ .x = &.{ "four,", "five,", "six," }, .y = "four,five,six\n\n" },
    }}}};
    const Return = @TypeOf(@constCast(v));
    try meta.wrap(serial.serialWrite(serial_spec, @TypeOf(v), &allocator, builtin.absolutePath("zig-out/bin/variety_0"), v));
    const u: Return = try meta.wrap(serial.serialRead(serial_spec, Return, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, @TypeOf(u), &allocator, builtin.absolutePath("zig-out/bin/variety_1"), u));
    const t: Return = try meta.wrap(serial.serialRead(serial_spec, Return, &allocator, builtin.absolutePath("zig-out/bin/variety_1")));
    testing.print(v);
    testing.print(u);
    testing.print(t);
    builtin.assertEqualMemory(Return, u, t);
}
const serial_spec: serial.SerialSpec = .{
    .Allocator = Allocator,
    .logging = spec.serializer.logging.silent,
    .errors = spec.serializer.errors.noexcept,
};
pub fn testLargeStructure() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    try meta.wrap(serial.serialWrite(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_a));
    const spec_sets_b: []const types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_b));
    const spec_sets_c: []const types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    testing.print(fmt.any(spec_sets_a));
    testing.print(fmt.any(spec_sets_b));
    testing.print(fmt.any(spec_sets_c));
    builtin.assertEqualMemory([]const types.AbstractSpecification, spec_sets_b, spec_sets_c);
}
pub fn testLargeFlatStructure() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    try meta.wrap(serial.serialWrite(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_a));
    const spec_sets_b: []const types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    try meta.wrap(serial.serialWrite(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0"), spec_sets_b));
    const spec_sets_c: []const types.AbstractSpecification =
        try meta.wrap(serial.serialRead(serial_spec, []const types.AbstractSpecification, &allocator, builtin.absolutePath("zig-out/bin/variety_0")));
    testing.print(fmt.any(spec_sets_a));
    testing.print(fmt.any(spec_sets_b));
    testing.print(fmt.any(spec_sets_c));
    builtin.assertEqualMemory([]const types.AbstractSpecification, spec_sets_b, spec_sets_c);
}
pub fn testLongComplexCase() !void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);

    try meta.wrap(serial.serialWrite(serial_spec, []const []const []const types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0));
    const spec_sets_1: [][][]types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []const []const []const types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const []const []const types.Specifier, spec_sets_0, spec_sets_1);

    try meta.wrap(serial.serialWrite(serial_spec, []const []const types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0]));
    const spec_set_1: [][]types.Specifier = try meta.wrap(serial.serialRead(serial_spec, [][]types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const []const types.Specifier, spec_set_1, spec_sets_0[0]);

    try meta.wrap(serial.serialWrite(serial_spec, []const types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0][0]));
    const specs_1: []types.Specifier = try meta.wrap(serial.serialRead(serial_spec, []types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory([]const types.Specifier, specs_1, spec_sets_0[0][0]);

    try meta.wrap(serial.serialWrite(serial_spec, types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec"), spec_sets_0[0][0][0]));
    const spec_1: types.Specifier = try meta.wrap(serial.serialRead(serial_spec, types.Specifier, &allocator, builtin.absolutePath("zig-out/bin/spec")));
    builtin.assertEqualMemory(types.Specifier, spec_1, spec_sets_0[0][0][0]);

    allocator.deinit(&address_space);
}
pub fn main() !void {
    try meta.wrap(testLongComplexCase());
    try meta.wrap(testLargeStructure());
    try meta.wrap(testLargeFlatStructure());
    try meta.wrap(testVarietyStructure());
}
