const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const start = @import("../../start.zig");
const debug = @import("../../debug.zig");
const decls = @import("../decls.zig");
const config = @import("./config.zig");

pub const Array = mem.StaticString(64 * 1024 * 1024);

pub usingnamespace start;

pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    var flags_array: *Array = allocator.create(Array);
    var decls_array: *Array = allocator.create(Array);
    var extra_array: *Array = allocator.create(Array);
    flags_array.define(try gen.readFile(.{ .return_type = usize }, config.flags_template_path, flags_array.referAllUndefined()));
    decls_array.define(try gen.readFile(.{ .return_type = usize }, config.decls_template_path, decls_array.referAllUndefined()));
    extra_array.define(try gen.readFile(.{ .return_type = usize }, config.extra_template_path, extra_array.referAllUndefined()));
    inline for (@typeInfo(decls).Struct.decls) |decl| {
        const value = @field(decls, decl.name);
        const size = if (@hasDecl(value, "backing_integer")) value.backing_integer else usize;
        const Format = gen.ContainerDeclsToBitFieldFormat(size);
        const format: Format = Format.init(value, decl.name);
        format.formatWrite(flags_array);
        format.formatWriteExtra(extra_array);
        format.formatWriteDecls(decls_array);
    }
    if (config.commit) {
        try gen.truncateFile(.{ .return_type = void }, config.flags_path, flags_array.readAll());
        try gen.truncateFile(.{ .return_type = void }, config.extra_path, extra_array.readAll());
        try gen.truncateFile(.{ .return_type = void }, config.decls_path, decls_array.readAll());
    } else {
        debug.write(flags_array.readAll());
        debug.write(extra_array.readAll());
    }
}
