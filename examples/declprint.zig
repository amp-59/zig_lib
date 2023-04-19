const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const fmt = srg.fmt;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace proc.start;

fn recursivePrint(comptime T: type) void {
    inline for (comptime meta.resolve(@typeInfo(T)).decls) |decl| {
        if (decl.is_pub) {
            const field = @field(T, decl.name);
            const Field = @TypeOf(field);
            var array: mem.StaticString(4096) = .{};
            switch (@typeInfo(Field)) {
                .Int => |int_info| {
                    const I = @Type(.{ .Int = .{
                        .bits = int_info.bits,
                        .signedness = .unsigned,
                    } });
                    array.writeAny(spec.reinterpret.fmt, comptime .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(I) ++ " = ",
                        fmt.ux(@bitCast(I, field)),
                        ";\n",
                    });
                    file.write(.{ .errors = .{} }, 1, array.readAll());
                },
                .ComptimeInt => {
                    const int_fmt = blk_0: {
                        const tmp_0 = fmt.ux(@as(comptime_int, field));
                        const IntFmt = fmt.PolynomialFormat(blk_1: {
                            var tmp_1 = @TypeOf(tmp_0).fmt_spec;
                            tmp_1.width = .min;
                            break :blk_1 tmp_1;
                        });
                        break :blk_0 IntFmt{ .value = tmp_0.value };
                    };
                    array.writeAny(spec.reinterpret.fmt, comptime .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(@TypeOf(int_fmt.value)) ++ " = ",
                        int_fmt,
                        ";\n",
                    });
                    file.write(.{ .errors = .{} }, 1, array.readAll());
                },
                .Struct, .Array, .Pointer => {
                    array.writeAny(spec.reinterpret.fmt, comptime .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(Field) ++ " = ",
                        fmt.render(.{ .omit_default_fields = false, .infer_type_names = true }, field),
                        ";\n",
                    });
                    file.write(.{ .errors = .{} }, 1, array.readAll());
                },
                .Type => {
                    if (comptime meta.isContainer(field)) {
                        array.writeAny(spec.reinterpret.fmt, .{
                            "pub const ",
                            fmt.IdentifierFormat{ .value = decl.name },
                            " = " ++ comptime builtin.fmt.typeDeclSpecifier(@typeInfo(field)) ++ " {\n",
                        });
                        builtin.debug.write(array.readAll());
                        array.undefineAll();
                        recursivePrint(field);
                        array.writeMany("};\n");
                        file.write(.{ .errors = .{} }, 1, array.readAll());
                    }
                },
                else => {},
            }
        }
    }
}
pub fn main() void {
    recursivePrint(srg.spec.builder);
    recursivePrint(srg.spec.address_space.errors);
    recursivePrint(srg.spec.address_space.logging);
    recursivePrint(srg.spec.allocator);
    recursivePrint(srg.spec.dir);
    recursivePrint(srg.spec.sys);
    recursivePrint(srg.sys);
}
