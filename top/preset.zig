const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const file = @import("./file.zig");
const builtin = @import("./builtin.zig");

pub const allocator = opaque {
    pub const options = opaque {
        pub const small: mem.AllocatorOptions = .{
            .count_branches = false,
            .count_allocations = false,
            .count_useful_bytes = false,
            .check_parametric_binding = false,
        };
    };
    pub const logging = opaque {
        pub const verbose: mem.AllocatorLogging = .{
            .arena = builtin.Logging.verbose,
            .head = true,
            .sentinel = true,
            .metadata = true,
            .branches = true,
            .map = builtin.Logging.verbose,
            .unmap = builtin.Logging.verbose,
            .remap = builtin.Logging.verbose,
            .advise = builtin.Logging.verbose,
            .allocate = true,
            .reallocate = true,
            .reinterpret = true,
            .deallocate = true,
        };
        pub const silent: mem.AllocatorLogging = .{
            .arena = builtin.Logging.silent,
            .head = false,
            .sentinel = false,
            .metadata = false,
            .branches = false,
            .map = builtin.Logging.silent,
            .unmap = builtin.Logging.silent,
            .remap = builtin.Logging.silent,
            .advise = builtin.Logging.silent,
            .allocate = false,
            .reallocate = false,
            .reinterpret = false,
            .deallocate = false,
        };
    };
    pub const errors = opaque {
        pub const noexcept: mem.AllocatorErrors = .{
            // This should not be allowed, but no consistency within library to
            // enforce yet.
            .acquire = null,
            .release = null,
            .map = null,
            .remap = null,
            .unmap = null,
        };
        pub const uniform: mem.AllocatorErrors = .{
            .acquire = error{OpaqueSystemError},
            .release = null,
            .map = &.{},
            .remap = &.{},
            .unmap = null,
        };
        pub const critical: mem.AllocatorErrors = .{
            .map = sys.mmap_errors,
            .remap = sys.mremap_errors,
            .release = error{OverSupply},
            .acquire = error{UnderSupply},
            .unmap = sys.munmap_errors,
        };
    };
};
pub const map = opaque {
    pub const options = opaque {
        pub const object: file.MapSpec.Options = .{
            .visibility = .private,
            .anonymous = false,
            .read = true,
            .write = false,
            .exec = true,
            .populate = true,
            .grows_down = false,
            .sync = false,
        };
    };
};
