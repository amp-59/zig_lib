const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const file = @import("../../file.zig");
const proc = @import("../../proc.zig");
const builtin = @import("../../builtin.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
const Target = @import("std").Target;
const Version = @import("std").SemanticVersion;
const VersionRange = @import("std").SemanticVersion.Range;
pub usingnamespace @import("../../start.zig");
const create_spec: file.CreateSpec = .{
    .options = .{ .exclusive = false },
};
fn writeDeclaration(array: *types.Array, comptime name: []const u8, comptime T: type) void {
    array.writeMany("pub const " ++ name ++ "=");
    array.writeFormat(comptime types.TypeDescr.declare(name, T));
    array.writeMany(";\n");
}
pub fn main() !void {
    const fd: u64 = try file.create(create_spec, config.toplevel_source_path, file.mode.regular);
    var allocator: mem.SimpleAllocator = .{};
    var array: *types.Array = allocator.create(types.Array);
    array.undefineAll();
    array.writeMany("pub const Target=struct{\n");
    array.writeMany("cpu:Cpu,\n");
    array.writeMany("os:Os,\n");
    array.writeMany("abi:Abi,\n");
    array.writeMany("ofmt:ObjectFormat,\n");
    array.writeFormat(comptime types.TypeDescr.declare("Set", Target.Cpu.Feature.Set));
    array.writeFormat(comptime types.TypeDescr.declare("Feature", Target.Cpu.Feature));
    array.writeMany("pub const Cpu=struct{\n");
    array.writeMany("arch:Arch,\n");
    array.writeMany("model:*const Model,\n");
    array.writeMany("features:Set,\n");
    array.writeFormat(comptime types.TypeDescr.declare("Model", Target.Cpu.Model));
    array.writeFormat(comptime types.TypeDescr.declare("Arch", Target.Cpu.Arch));
    array.writeMany("};\n");
    array.writeMany("pub const Os=struct{\n");
    array.writeMany("tag:Tag,\n");
    array.writeMany("version_range:VersionRange,\n");
    array.writeFormat(comptime types.TypeDescr.declare("Tag", Target.Os.Tag));
    array.writeFormat(comptime types.TypeDescr.declare("Version", Version));
    array.writeFormat(comptime types.TypeDescr.declare("Range", VersionRange));
    array.writeFormat(comptime types.TypeDescr.declare("LinuxVersionRange", Target.Os.LinuxVersionRange));
    array.writeFormat(comptime types.TypeDescr.declare("WindowsVersion", Target.Os.WindowsVersion));
    array.writeFormat(comptime types.TypeDescr.declare("VersionRange", Target.Os.VersionRange));
    array.writeMany("};\n");
    array.writeFormat(comptime types.TypeDescr.declare("Abi", Target.Abi));
    array.writeFormat(comptime types.TypeDescr.declare("ObjectFormat", Target.ObjectFormat));
    inline for (config.arch_names) |pair| {
        array.writeMany("pub const ");
        array.writeFormat(fmt.IdentifierFormat{ .value = pair[0] });
        array.writeMany("=@import(\"./target/" ++ pair[1][config.primary_dir.len +% 1 ..] ++ "\");\n");
    }
    array.writeMany("};\n");
    try file.write(.{}, fd, array.readAll());
    try file.close(.{}, fd);
    array.undefineAll();
}
