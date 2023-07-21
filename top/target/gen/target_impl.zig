const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const meta = @import("../../meta.zig");
const file = @import("../../file.zig");
const proc = @import("../../proc.zig");
const builtin = @import("../../builtin.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace @import("../../start.zig");
const create_spec: file.CreateSpec = .{ .options = .{ .exclusive = false } };
inline fn writeDeclaration(array: *types.Array, comptime name: []const u8, comptime T: type) void {
    array.writeMany("pub const " ++ name ++ "=");
    array.writeFormat(comptime types.TypeDescr.declare(name, T));
    array.writeMany(";\n");
}
pub fn main() !void {
    const Target = @import("std").Target;
    const fd: u64 = try file.create(create_spec, config.toplevel_source_path, file.mode.regular);
    var allocator: mem.SimpleAllocator = .{};
    var array: *types.Array = allocator.create(types.Array);
    array.undefineAll();
    array.writeMany(
        \\pub const Target=struct{
        \\cpu:Cpu,
        \\os:Os,
        \\abi:Abi,
        \\ofmt:ObjectFormat,
        \\
    );
    writeDeclaration(array, "Set", Target.Cpu.Feature.Set);
    writeDeclaration(array, "Feature", Target.Cpu.Feature);
    array.writeMany(
        \\pub const Cpu=struct{
        \\arch:Arch,
        \\model:*const Model,
        \\features:Set,
        \\
    );
    writeDeclaration(array, "Model", Target.Cpu.Model);
    writeDeclaration(array, "Arch", Target.Cpu.Arch);
    array.writeMany("};\n");
    array.writeMany(
        \\pub const Os=struct{
        \\tag:Tag,
        \\version_range:VersionRange,
        \\
    );
    writeDeclaration(array, "Tag", Target.Os.Tag);
    writeDeclaration(array, "Version", @import("std").SemanticVersion);
    writeDeclaration(array, "Range", @import("std").SemanticVersion.Range);
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
