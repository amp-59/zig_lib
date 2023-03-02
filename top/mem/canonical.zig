const gen = @import("./gen.zig");
const attr = @import("./attr.zig");
const detail = @import("./detail.zig");

const Specifiers = @import("./zig-out/src/specifiers.zig").Specifiers;

pub const CanonicalSpec = struct {
    type_name: []const u8 = "Canonical",
    fields: []const CanonicalFieldSpec,
};
pub const CanonicalFieldSpec = struct {
    src_name: []const u8,
    src_type: type,
    dst_name: []const u8,
    dst_type_name: []const u8,
    detail: type,
};
pub const kinds: CanonicalFieldSpec = .{
    .src_name = "kinds",
    .src_type = attr.Kinds,
    .dst_name = "kind",
    .dst_type_name = "Kind",
    .detail = detail.Base,
};
pub const layouts: CanonicalFieldSpec = .{
    .src_name = "layouts",
    .src_type = attr.Layouts,
    .dst_name = "layout",
    .dst_type_name = "Layout",
    .detail = detail.Base,
};
pub const modes: CanonicalFieldSpec = .{
    .src_name = "modes",
    .src_type = attr.Modes,
    .dst_name = "mode",
    .dst_type_name = "Mode",
    .detail = detail.Base,
};
pub const managers: CanonicalFieldSpec = .{
    .src_name = "managers",
    .src_type = attr.Managers,
    .dst_name = "manager",
    .dst_type_name = "Manager",
    .detail = detail.Base,
};
pub const fields: CanonicalFieldSpec = .{
    .src_type = attr.Fields,
    .src_name = "fields",
    .dst_name = "field",
    .dst_type_name = "Field",
    .detail = detail.Base,
};
pub const techs: CanonicalFieldSpec = .{
    .src_name = "techs",
    .src_type = attr.Techniques,
    .dst_name = "tech",
    .dst_type_name = "Technique",
    .detail = detail.Base,
};
pub const specs: CanonicalFieldSpec = .{
    .src_name = "specs",
    .src_type = Specifiers,
    .dst_name = "spec",
    .dst_type_name = "Specifier",
    .detail = detail.More,
};
