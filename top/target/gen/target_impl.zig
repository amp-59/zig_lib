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
    writeDeclaration(array, "Set", Target.Cpu.Feature.Set);
    writeDeclaration(array, "Feature", Target.Cpu.Feature);
    array.writeMany("pub const Cpu=struct{\n");
    array.writeMany("arch:Arch,\n");
    array.writeMany("model:*const Model,\n");
    array.writeMany("features:Set,\n");
    writeDeclaration(array, "Model", Target.Cpu.Model);
    writeDeclaration(array, "Arch", Target.Cpu.Arch);
    array.writeMany("};\n");
    array.writeMany("pub const Os=struct{\n");
    array.writeMany("tag:Tag,\n");
    array.writeMany("version_range:VersionRange,\n");
    writeDeclaration(array, "Tag", Target.Os.Tag);
    writeDeclaration(array, "Version", Version);
    writeDeclaration(array, "Range", VersionRange);
    writeDeclaration(array, "LinuxVersionRange", Target.Os.LinuxVersionRange);
    writeDeclaration(array, "WindowsVersion", Target.Os.WindowsVersion);
    writeDeclaration(array, "VersionRange", Target.Os.VersionRange);
    array.writeMany("};\n");
    writeDeclaration(array, "Abi", Target.Abi);
    writeDeclaration(array, "ObjectFormat", Target.ObjectFormat);
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
