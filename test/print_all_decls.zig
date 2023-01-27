const srg = @import("zig_lib");
const mem = srg.mem;
const fmt = srg.fmt;
const proc = srg.proc;
const meta = srg.meta;
const file = srg.file;
const preset = srg.preset;
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
                    array.writeAny(preset.reinterpret.fmt, .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(I) ++ " = ",
                        fmt.ux(@bitCast(I, field)),
                        ";\n",
                    });
                    file.noexcept.write(1, array.readAll());
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
                    array.writeAny(preset.reinterpret.fmt, .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(@TypeOf(int_fmt.value)) ++ " = ",
                        int_fmt,
                        ";\n",
                    });
                    file.noexcept.write(1, array.readAll());
                },
                .Struct, .Array, .Pointer => {
                    array.writeAny(preset.reinterpret.fmt, .{
                        "pub const ",
                        fmt.IdentifierFormat{ .value = decl.name },
                        ": " ++ @typeName(Field) ++ " = ",
                        comptime fmt.any(field),
                        ";\n",
                    });
                    file.noexcept.write(1, array.readAll());
                },
                .Type => {
                    if (comptime meta.isContainer(field)) {
                        array.writeAny(preset.reinterpret.fmt, .{
                            "pub const ",
                            fmt.IdentifierFormat{ .value = decl.name },
                            " = " ++ comptime builtin.fmt.typeDeclSpecifier(@typeInfo(field)) ++ " {\n",
                        });
                        file.noexcept.write(2, array.readAll());
                        array.undefineAll();
                        recursivePrint(field);
                        array.writeMany("};\n");
                        file.noexcept.write(2, array.readAll());
                    }
                },
                else => {},
            }
        }
    }
}
pub fn main() void {
    recursivePrint(srg.sys);
}
