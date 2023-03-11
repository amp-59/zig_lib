//! This stage summarises the abstract specification.
const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const meta = gen.meta;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const abstract_spec = @import("./abstract_spec.zig");
const attr = @import("./attr2.0.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

pub fn newTypeSpecs() void {
    var array: Array = undefined;
    array.undefineAll();
    inline for (attr.specs) |x| {
        comptime var p_struct_info: builtin.Type = meta.structInfo(.Auto, &.{});
        comptime var s_struct_info: builtin.Type = meta.structInfo(.Auto, &.{});
        comptime var v_fields: []const builtin.Type.StructField = &.{};
        inline for (x.specifiers) |spec| {
            switch (spec) {
                .default => |default| {
                    s_struct_info.Struct.fields = s_struct_info.Struct.fields ++
                        .{meta.structField(default.type, @tagName(default.tag), null)};
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(default.type, @tagName(default.tag), null)};
                },
                .derived => |derived| {
                    s_struct_info.Struct.fields = s_struct_info.Struct.fields ++
                        .{meta.structField(derived.type, @tagName(derived.tag), null)};
                },
                .stripped => |stripped| {
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(stripped.type, @tagName(stripped.tag), null)};
                },
                .optional_derived => |derived| {
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(?derived.type, @tagName(derived.tag), null)};
                    s_struct_info.Struct.fields = s_struct_info.Struct.fields ++
                        .{meta.structField(derived.type, @tagName(derived.tag), null)};
                },
                .optional_variant => |variant| {
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(?variant.type, @tagName(variant.tag), null)};
                    v_fields = v_fields ++
                        .{meta.structField(variant.type, @tagName(variant.tag), null)};
                },
                .decl_optional_derived => |decl_derived| {
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(?decl_derived.type, @tagName(decl_derived.tag), null)};
                    s_struct_info.Struct.fields = s_struct_info.Struct.fields ++
                        .{meta.structField(decl_derived.type, @tagName(decl_derived.tag), null)};
                },
                .decl_optional_variant => |decl_variant| {
                    p_struct_info.Struct.fields = p_struct_info.Struct.fields ++
                        .{meta.structField(decl_variant.ctn_type, @tagName(decl_variant.ctn_tag), null)};
                    v_fields = v_fields ++
                        .{meta.structField(decl_variant.decl_type, @tagName(decl_variant.decl_tag), null)};
                },
            }
        }
        comptime var s_v_struct_infos: []const builtin.Type = &.{s_struct_info};
        inline for (v_fields) |v_field| {
            inline for (s_v_struct_infos) |s_v_struct_info| {
                s_v_struct_infos = s_v_struct_infos ++
                    .{meta.structInfo(.Auto, s_v_struct_info.Struct.fields ++ .{v_field})};
            }
        }
        array.writeFormat(comptime gen.ProtoTypeDescrFormat.init(@Type(p_struct_info)));
        inline for (s_v_struct_infos) |s_v_struct_info| {
            array.writeFormat(comptime gen.ProtoTypeDescrFormat.init(@Type(s_v_struct_info)));
            array.writeOne('\n');
        }
    }

    builtin.debug.write(array.readAll());
}
pub const main = newTypeSpecs;
