const zl = @import("../zig_lib.zig");
const mg = @import("../top/mem/gen.zig");

const virtual = zl.virtual;

pub const spec_sets_0: []const []const []const mg.types.Specifier = &.{
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .default = .{
        .tag = .count,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{.{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }}, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } }, .{ .decl_optional_variant = .{
        .ctn_tag = .Allocator,
        .decl_tag = .arena,
        .ctn_type = .{ .type_decl = .{
            .name = "type",
        } },
        .decl_type = .{ .type_decl = .{
            .defn = .{
                .spec = "struct",
                .fields = &.{ .{
                    .name = "lb_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                }, .{
                    .name = "up_addr",
                    .type = .{ .type_decl = .{
                        .name = "u64",
                    } },
                } },
            },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } } }, &.{ .{ .default = .{
        .tag = .child,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
    &.{ &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } } }, &.{ .{ .optional_derived = .{
        .tag = .low_alignment,
        .type = .{ .type_decl = .{
            .name = "u64",
        } },
        .fn_name = "lowAlignment",
    } }, .{ .default = .{
        .tag = .Allocator,
        .type = .{ .type_decl = .{
            .name = "type",
        } },
    } }, .{ .optional_variant = .{
        .tag = .sentinel,
        .type = .{ .type_ref = .{
            .spec = "*const ",
            .type = &.{ .type_decl = .{
                .name = "anyopaque",
            } },
        } },
    } } } },
};
pub const tech_sets_0: []const []const []const mg.types.Technique = &.{
    &.{&.{}}, &.{&.{}}, &.{&.{}}, &.{&.{}},
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
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
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .lazy_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }}, &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .unit_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .lazy_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }}, &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .unit_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .lazy_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }}, &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .unit_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }} },
    &.{ &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .lazy_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }}, &.{.{ .mutually_exclusive = .{
        .kind = .mandatory,
        .opt_tag = .alignment,
        .tech_tag = .unit_alignment,
        .tech_tags = &.{ .lazy_alignment, .unit_alignment },
    } }} },
};

pub const trivial_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000004000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x010000000000, .up_addr = 0x110000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
};
pub const simple_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
};
pub const rare_sub_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
};
// zig fmt: off
pub const complex_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x0f0000000000, .up_addr = 0x100000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x130000000000, .up_addr = 0x140000000000 }, // [X]
    .{ .lb_addr = 0x140000000000, .up_addr = 0x150000000000 }, // [X]
    .{ .lb_addr = 0x150000000000, .up_addr = 0x160000000000 },
    .{ .lb_addr = 0x2a0000000000, .up_addr = 0x2b0000000000 },
    .{ .lb_addr = 0x2d0000000000, .up_addr = 0x2e0000000000 }, // [X]
    .{ .lb_addr = 0x2e0000000000, .up_addr = 0x2f0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x2f0000000000, .up_addr = 0x300000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x300000000000, .up_addr = 0x310000000000 },
    .{ .lb_addr = 0x310000000000, .up_addr = 0x320000000000 }, // [X]
    .{ .lb_addr = 0x320000000000, .up_addr = 0x330000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x330000000000, .up_addr = 0x340000000000 },
    .{ .lb_addr = 0x340000000000, .up_addr = 0x350000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x350000000000, .up_addr = 0x360000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x360000000000, .up_addr = 0x370000000000 }, // [X]
    .{ .lb_addr = 0x370000000000, .up_addr = 0x380000000000 }, // [X]
    .{ .lb_addr = 0x380000000000, .up_addr = 0x390000000000 }, // [X]
    .{ .lb_addr = 0x390000000000, .up_addr = 0x3a0000000000 }, // [X]
    .{ .lb_addr = 0x430000000000, .up_addr = 0x440000000000 },
    .{ .lb_addr = 0x440000000000, .up_addr = 0x450000000000 },
    .{ .lb_addr = 0x450000000000, .up_addr = 0x460000000000 },
    .{ .lb_addr = 0x460000000000, .up_addr = 0x470000000000 },
    .{ .lb_addr = 0x470000000000, .up_addr = 0x480000000000 },
    .{ .lb_addr = 0x480000000000, .up_addr = 0x490000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x490000000000, .up_addr = 0x4a0000000000 }, // [X]
    .{ .lb_addr = 0x4a0000000000, .up_addr = 0x4b0000000000 },
    .{ .lb_addr = 0x4b0000000000, .up_addr = 0x4c0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x4c0000000000, .up_addr = 0x4d0000000000 }, // [X]
    .{ .lb_addr = 0x4d0000000000, .up_addr = 0x4e0000000000 },
    .{ .lb_addr = 0x4e0000000000, .up_addr = 0x4f0000000000 },
    .{ .lb_addr = 0x4f0000000000, .up_addr = 0x500000000000 }, // [X]
    .{ .lb_addr = 0x500000000000, .up_addr = 0x510000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x510000000000, .up_addr = 0x520000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x520000000000, .up_addr = 0x530000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x530000000000, .up_addr = 0x540000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x540000000000, .up_addr = 0x550000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x550000000000, .up_addr = 0x560000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x560000000000, .up_addr = 0x570000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x570000000000, .up_addr = 0x580000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x580000000000, .up_addr = 0x590000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x590000000000, .up_addr = 0x5a0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x5a0000000000, .up_addr = 0x5b0000000000 }, // [X]
    .{ .lb_addr = 0x5b0000000000, .up_addr = 0x5c0000000000 },
    .{ .lb_addr = 0x5c0000000000, .up_addr = 0x5d0000000000 },
};
// zig fmt: on

pub const x86_asm = .{
    .input =
    \\int3
    \\mov rax, rbx
    \\mov qword ptr [rbp], rax
    \\mov qword ptr [rbp - 16], rax
    \\mov qword ptr [16 + rbp], rax
    \\mov rax, 0x10
    \\mov byte ptr [rbp - 0x10], 0x10
    \\mov word ptr [rbp + r12], r11w
    \\mov word ptr [rbp + r12 * 2], r11w
    \\mov word ptr [rbp + r12 * 2 - 16], r11w
    \\mov dword ptr [rip - 16], r12d
    \\mov rax, fs:0x0
    \\mov rax, gs:0x1000000000000000
    \\movzx r12, al
    \\imul r12, qword ptr [rbp - 16], 6
    \\jmp 0x0
    \\jc 0x0
    \\jb 0x0
    \\sal rax, 1
    \\sal rax, 63
    \\shl rax, 63
    \\sar rax, 63
    \\shr rax, 63
    \\test byte ptr [rbp - 16], r12b
    \\sal r12, cl
    \\mul qword ptr [rip - 16]
    \\div r12
    \\idiv byte ptr [rbp - 16]
    \\cwde
    \\cbw
    \\cdqe
    \\test byte ptr [rbp], ah
    \\test byte ptr [r12], spl
    \\cdq
    \\cwd
    \\cqo
    \\test bl, 0x1
    \\mov rbx,0x8000000000000000
    \\movss xmm0, dword ptr [rbp]
    \\movss xmm0, xmm1
    \\movss dword ptr [rbp - 16 + rax * 2], xmm7
    \\movss dword ptr [rbp - 16 + rax * 2], xmm8
    \\movss xmm15, xmm9
    \\movsd xmm8, qword ptr [rbp - 16]
    \\movsd qword ptr [rbp - 8], xmm0
    \\ucomisd xmm0, qword ptr [rbp - 16]
    \\fisttp qword ptr [rbp - 16]
    \\fisttp word ptr [rip + 32]
    \\fisttp dword ptr [rax]
    \\fld tbyte ptr [rbp]
    \\fld dword ptr [rbp]
    \\xor bl, 0xff
    \\ud2
    \\add rsp, -1
    \\add rsp, 0xff
    \\mov sil, byte ptr [rax + rcx * 1]
    \\leave
    \\endbr64
    \\
    ,
    .output = &[_]u8{
        0xCC, 0x48, 0x89, 0xD8, 0x48, 0x89, 0x45, 0x00,
        0x48, 0x89, 0x45, 0xF0, 0x48, 0x89, 0x45, 0x10,
        0x48, 0xC7, 0xC0, 0x10, 0x00, 0x00, 0x00, 0xC6,
        0x45, 0xF0, 0x10, 0x66, 0x46, 0x89, 0x5C, 0x25,
        0x00, 0x66, 0x46, 0x89, 0x5C, 0x65, 0x00, 0x66,
        0x46, 0x89, 0x5C, 0x65, 0xF0, 0x44, 0x89, 0x25,
        0xF0, 0xFF, 0xFF, 0xFF, 0x64, 0x48, 0x8B, 0x04,
        0x25, 0x00, 0x00, 0x00, 0x00, 0x65, 0x48, 0xA1,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10,
        0x4C, 0x0F, 0xB6, 0xE0, 0x4C, 0x6B, 0x65, 0xF0,
        0x06, 0xE9, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x82,
        0x00, 0x00, 0x00, 0x00, 0x0F, 0x82, 0x00, 0x00,
        0x00, 0x00, 0x48, 0xD1, 0xE0, 0x48, 0xC1, 0xE0,
        0x3F, 0x48, 0xC1, 0xE0, 0x3F, 0x48, 0xC1, 0xF8,
        0x3F, 0x48, 0xC1, 0xE8, 0x3F, 0x44, 0x84, 0x65,
        0xF0, 0x49, 0xD3, 0xE4, 0x48, 0xF7, 0x25, 0xF0,
        0xFF, 0xFF, 0xFF, 0x49, 0xF7, 0xF4, 0xF6, 0x7D,
        0xF0, 0x98, 0x66, 0x98, 0x48, 0x98, 0x84, 0x65,
        0x00, 0x41, 0x84, 0x24, 0x24, 0x99, 0x66, 0x99,
        0x48, 0x99, 0xF6, 0xC3, 0x01, 0x48, 0xBB, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xF3,
        0x0F, 0x10, 0x45, 0x00, 0xF3, 0x0F, 0x10, 0xC1,
        0xF3, 0x0F, 0x11, 0x7C, 0x45, 0xF0, 0xF3, 0x44,
        0x0F, 0x11, 0x44, 0x45, 0xF0, 0xF3, 0x45, 0x0F,
        0x10, 0xF9, 0xF2, 0x44, 0x0F, 0x10, 0x45, 0xF0,
        0xF2, 0x0F, 0x11, 0x45, 0xF8, 0x66, 0x0F, 0x2E,
        0x45, 0xF0, 0xDD, 0x4D, 0xF0, 0xDF, 0x0D, 0x20,
        0x00, 0x00, 0x00, 0xDB, 0x08, 0xDB, 0x6D, 0x00,
        0xD9, 0x45, 0x00, 0x80, 0xF3, 0xFF, 0x0F, 0x0B,
        0x48, 0x83, 0xC4, 0xFF, 0x48, 0x81, 0xC4, 0xFF,
        0x00, 0x00, 0x00, 0x40, 0x8A, 0x34, 0x08, 0xC9,
        0xF3, 0x0F, 0x1E, 0xFA,
    },
};

pub const x86_asm_2 = .{
    .input =
    \\push            rbp
    \\mov             rbp, rsp
    \\push            rbx
    \\sub             rsp, 104
    \\mov             rbx, qword ptr [rbp + 24]
    \\vmovaps         xmm1, xmmword ptr [rip + SPEC_1]
    \\mov             r10, qword ptr [rbp + 16]
    \\lea             rax, [rip + executeCommandThreaded]
    \\vmovq           xmm0, rbx
    \\lea             r11, [rbx + 8]
    \\vmovaps         xmmword ptr [rbp - 96], xmm1
    \\vpbroadcastq    xmm0, xmm0
    \\vpaddq          xmm0, xmm0, xmmword ptr [rip + SPEC_0]
    \\vmovdqa         xmmword ptr [rbp - 80], xmm0
    \\vpxor           xmm0, xmm0, xmm0
    \\mov             qword ptr [rbp - 64], 0
    \\mov             qword ptr [rbp - 56], rbx
    \\mov             qword ptr [rbp - 48], 4096
    \\mov             qword ptr [rbp - 40], r11
    \\mov             qword ptr [rbp - 16], 0
    \\vmovdqa         xmmword ptr [rbp - 32], xmm0
    \\mov             qword ptr [rbx + 8], rax
    \\mov             qword ptr [rbx + 16], rdi
    \\mov             qword ptr [rbx + 24], rsi
    \\mov             qword ptr [rbx + 32], rdx
    \\mov             qword ptr [rbx + 40], rcx
    \\mov             qword ptr [rbx + 48], r10
    \\mov             byte ptr [rbx + 56], r8b
    \\mov             byte ptr [rbx + 57], r9b
    \\lea             rdi, [rbp - 96]
    \\mov             eax, 435
    \\mov             esi, 88
    \\syscall         # clone3
    \\test            rax, rax
    \\je              1f
    \\add             rsp, 104
    \\pop             rbx
    \\pop             rbp
    \\ret
    \\xor             rbp, rbp
    \\sub             rsp, 4096
    \\mov             rax, rsp
    \\mov             rdi, qword ptr [rax + 16]
    \\mov             rsi, qword ptr [rax + 24]
    \\mov             rdx, qword ptr [rax + 32]
    \\mov             rcx, qword ptr [rax + 40]
    \\movzx           r8d, byte ptr [rax + 56]
    \\movzx           r9d, byte ptr [rax + 57]
    \\mov             rbx, qword ptr [rax + 48]
    \\mov             qword ptr [rsp], rbx
    \\call            qword ptr [rax + 8]
    \\mov             rax, 60
    \\mov             rdi, 0
    \\syscall         # exit
    \\
    ,
    .output = &[_]u8{},
};

pub const x86_dis = .{
    .input = &[_]u8{
        0x48, 0xb8, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x41, 0xbc, 0xf0, 0xff, 0xff, 0xff, 0x49, 0x89, 0xC4, 0x4C,
        0x89, 0x25, 0xF0, 0xFF, 0xFF, 0xFF, 0x4C, 0x89, 0x1d, 0xf0,
        0xff, 0xff, 0xff, 0x49, 0x89, 0x43, 0xf0, 0x46, 0x88, 0x5C,
        0xE5, 0xF0, 0x4c, 0x8b, 0x65, 0xf0, 0x48, 0x8b, 0x85, 0x00,
        0xf0, 0xff, 0xff, 0x48, 0x8b, 0x18, 0xc6, 0x45, 0xf0, 0x10,
        0x49, 0xc7, 0x43, 0xf0, 0x10, 0x00, 0x00, 0x00, 0x48, 0x8d,
        0x45, 0xf0, 0x41, 0x8d, 0x43, 0x10, 0x4c, 0x8d, 0x25, 0x00,
        0x00, 0x00, 0x00, 0x48, 0x03, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x48, 0x83, 0xc0, 0x10, 0x48, 0x83, 0x45, 0xf0, 0xf0, 0x80,
        0x55, 0xf0, 0x10, 0x48, 0x83, 0x60, 0x10, 0x08, 0x48, 0x83,
        0x4d, 0x10, 0x0f, 0x49, 0x83, 0xdb, 0x08, 0x49, 0x83, 0xec,
        0x00, 0x41, 0x80, 0x73, 0xf0, 0x20, 0x34, 0x10, 0x1d, 0x00,
        0x00, 0x00, 0x00, 0x48, 0x2d, 0x0f, 0x00, 0x00, 0x00, 0x66,
        0x1d, 0x00, 0x10, 0x66, 0x25, 0xf0, 0xff, 0x66, 0x48, 0x25,
        0xf0, 0xff, 0xff, 0xff, 0x65, 0x66, 0xa1, 0x10, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0xa2, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x26, 0xa3, 0x08, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x48, 0xa1, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x65, 0x44, 0x01, 0x24, 0x25,
        0x00, 0x00, 0x00, 0x10, 0x0f, 0x05, 0x42, 0xff, 0x14, 0x5d,
        0x00, 0x00, 0x00, 0x00, 0x42, 0xff, 0x14, 0x65, 0x00, 0x00,
        0x00, 0x00, 0x0f, 0xbf, 0xc3, 0x0f, 0xbe, 0xc3, 0x66, 0x0f,
        0xbe, 0xc3, 0x48, 0x63, 0xc3, 0xe8, 0x00, 0x00, 0x00, 0x00,
        0xe9, 0x00, 0x00, 0x00, 0x00, 0x41, 0x53, 0x0f, 0x82, 0x00,
        0x00, 0x00, 0x00, 0x48, 0xD1, 0xE0, 0x48, 0xC1, 0xE0, 0x3F,
        0x48, 0xC1, 0xE0, 0x3F, 0x48, 0xC1, 0xF8, 0x3F, 0x48, 0xC1,
        0xE8, 0x3F, 0x44, 0x84, 0x65, 0xF0, 0x46, 0x6B, 0x64, 0x5D,
        0xF0, 0x08, 0x41, 0xD3, 0xEC, 0x4A, 0x0F, 0x4A, 0x44, 0xE5,
        0x00, 0x48, 0x98, 0x41, 0x84, 0x24, 0x24, 0x84, 0x65, 0x00,
        0x66, 0x99, 0x99, 0x48, 0x99, 0xF6, 0xC3, 0x01, 0x48, 0xBB,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x40, 0x8A,
        0x34, 0x08,
    },
    .output =
    \\mov rax, 0x10
    \\mov r12d, 0xfffffff0
    \\mov r12, rax
    \\mov qword ptr [rip - 0x10], r12
    \\mov qword ptr [rip - 0x10], r11
    \\mov qword ptr [r11 - 0x10], rax
    \\mov byte ptr [rbp + r12 * 8 - 0x10], r11b
    \\mov r12, qword ptr [rbp - 0x10]
    \\mov rax, qword ptr [rbp - 0x1000]
    \\mov rbx, qword ptr [rax]
    \\mov byte ptr [rbp - 0x10], 0x10
    \\mov qword ptr [r11 - 0x10], 0x10
    \\lea rax, qword ptr [rbp - 0x10]
    \\lea eax, dword ptr [r11 + 0x10]
    \\lea r12, qword ptr [rip]
    \\add rax, qword ptr [rip]
    \\add rax, 0x10
    \\add qword ptr [rbp - 0x10], 0xf0
    \\adc byte ptr [rbp - 0x10], 0x10
    \\and qword ptr [rax + 0x10], 0x8
    \\or qword ptr [rbp + 0x10], 0xf
    \\sbb r11, 0x8
    \\sub r12, 0x0
    \\xor byte ptr [r11 - 0x10], 0x20
    \\xor al, 0x10
    \\sbb eax, 0x0
    \\sub rax, 0xf
    \\sbb ax, 0x1000
    \\and ax, 0xfff0
    \\and rax, 0xfffffff0
    \\mov ax, gs:0x10
    \\mov ss:0x0, al
    \\mov es:0x8, eax
    \\mov rax, ds:0x0
    \\add dword ptr gs:0x10000000, r12d
    \\syscall
    \\call qword ptr [r11 * 2]
    \\call qword ptr [r12 * 2]
    \\movsx eax, bx
    \\movsx eax, bl
    \\movsx ax, bl
    \\movsxd rax, ebx
    \\call 0x0
    \\jmp 0x0
    \\push r11
    \\jb 0x0
    \\sal rax, 0x1
    \\sal rax, 0x3f
    \\sal rax, 0x3f
    \\sar rax, 0x3f
    \\shr rax, 0x3f
    \\test byte ptr [rbp - 0x10], r12b
    \\imul r12d, dword ptr [rbp + r11 * 2 - 0x10], 0x8
    \\shr r12d, cl
    \\cmovp rax, qword ptr [rbp + r12 * 8]
    \\cdqe
    \\test byte ptr [r12], spl
    \\test byte ptr [rbp], ah
    \\cwd
    \\cdq
    \\cqo
    \\test bl, 0x1
    \\mov rbx, 0x8000000000000000
    \\mov sil, byte ptr [rax + rcx * 1]
    \\
    ,
};
