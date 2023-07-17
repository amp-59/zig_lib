const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const file = @import("../../file.zig");
const proc = @import("../../proc.zig");
const builtin = @import("../../builtin.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
fn writeCpuInternal(array: *types.Array, decl_name: []const u8, cpu_model: anytype) void {
    array.writeMany("pub const ");
    array.writeFormat(fmt.IdentifierFormat{ .value = decl_name });
    array.writeMany(":Target.Cpu.Model=");
    array.writeFormat(fmt.render(.{ .infer_type_names = true, .omit_trailing_comma = true }, cpu_model));
    array.writeMany(";\n");
}
pub fn main() !void {
    const std = @import("std");
    const Target = std.Target;
    @setEvalBranchQuota(~@as(u32, 0));
    var allocator: mem.SimpleAllocator = .{};
    var array: *types.Array = allocator.create(types.Array);
    array.undefineAll();
    inline for (config.arch_names) |pair| {
        const fd: u64 = try file.create(.{ .options = .{ .exclusive = false } }, pair[1], file.mode.regular);
        const arch = @field(Target, pair[0]);
        array.writeMany("pub const Target=@import(\"../target.zig\").Target;\n");
        array.writeMany("pub const Feature=");
        array.writeFormat(comptime types.TypeDescr.declare("Feature", arch.Feature));
        array.writeMany(";\n");
        array.writeMany("pub const all_features:[]const Target.Feature=&.{");
        for (arch.all_features) |feature| {
            array.writeFormat(fmt.render(.{ .infer_type_names = true, .omit_trailing_comma = true }, feature));
            array.writeMany(",\n");
        }
        array.writeMany("};\n");
        array.writeMany("pub const cpu=struct{\n");
        inline for (@typeInfo(arch.cpu).Struct.decls) |decl| {
            writeCpuInternal(array, decl.name, @field(arch.cpu, decl.name));
        }
        array.writeMany("};\n");
        try file.write(.{}, fd, array.readAll());
        try file.close(.{}, fd);
        array.undefineAll();
    }
}
