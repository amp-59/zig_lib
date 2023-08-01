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
