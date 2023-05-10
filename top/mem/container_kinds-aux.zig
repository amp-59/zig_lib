const mem = @import("../mem.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const algo = @import("../algo.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");
const ctn_fn = @import("./ctn_fn.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = spec.allocator.errors.noexcept,
    .logging = spec.allocator.logging.silent,
    .options = spec.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .logging = spec.address_space.logging.silent,
    .errors = spec.address_space.errors.noexcept,
    .options = .{},
});
const Array = mem.StaticString(1024 * 1024);
fn concat(comptime Tags: type, allocator: *Allocator, sets: []const Tags) Tags {
    var len: u64 = 0;
    for (sets) |tags| {
        len +%= tags.len();
    }
    var ret: Tags = Tags.init(allocator, len);
    for (sets) |tags| {
        ret.writeMany(tags.readAll());
    }
    return ret;
}
pub fn main() void {
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("const ctn_fn = @import(\"../../ctn_fn.zig\");\n");
    const writeKind = attr.Fn.static.writeKindSwitch;
    const Pair = attr.Fn.static.Pair(ctn_fn.Fn);
    const read: Pair = attr.Fn.static.prefixSubTagNew(ctn_fn.Fn, .read);
    const refer: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, read[0], .refer);
    const write: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, refer[0], .write);
    const append: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, write[0], .append);
    const overwrite: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, append[0], .overwrite);
    const helper: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, overwrite[0], .__);
    const define: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, helper[0], .define);
    const undefine: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, define[0], .undefine);
    const stream: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, undefine[0], .stream);
    const unstream: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, stream[0], .unstream);
    const one: Pair = attr.Fn.static.subTagNew(ctn_fn.Fn, .One);
    const read_one: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, one[1], .read);
    const refer_one: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_one[0], .refer);
    const count: Pair = attr.Fn.static.subTag(ctn_fn.Fn, one[0], .Count);
    const read_count: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, count[1], .read);
    const refer_count: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_count[0], .refer);
    const many: Pair = attr.Fn.static.subTag(ctn_fn.Fn, count[0], .Many);
    const read_many: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, many[1], .read);
    const refer_many: Pair = attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_many[0], .refer);
    const format: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, write[1], .Format);
    const args: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, format[0], .Args);
    const fields: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, args[0], .Fields);
    const any: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, fields[0], .Any);
    const sentinel: Pair = attr.Fn.static.subTag(ctn_fn.Fn, many[1] ++ count[1], .WithSentinel);
    const at: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, read[1] ++ refer[1] ++ overwrite[1], .At);
    const all_defined: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, at[0], .AllDefined);
    const all_undefined: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, all_defined[0], .AllUndefined);
    const defined: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, all_undefined[0], .Defined);
    const @"undefined": Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, defined[0], .Undefined);
    const streamed: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, @"undefined"[0], .Streamed);
    const unstreamed: Pair = attr.Fn.static.suffixSubTag(ctn_fn.Fn, streamed[0], .Unstreamed);
    const offset_defined: Pair = attr.Fn.static.subTag(ctn_fn.Fn, defined[1], .Offset);
    const offset_undefined: Pair = attr.Fn.static.subTag(ctn_fn.Fn, @"undefined"[1], .Offset);
    const offset_streamed: Pair = attr.Fn.static.subTag(ctn_fn.Fn, streamed[1], .Offset);
    const offset_unstreamed: Pair = attr.Fn.static.subTag(ctn_fn.Fn, unstreamed[1], .Offset);

    writeKind(ctn_fn.Fn, &array, .read, read[1]);
    writeKind(ctn_fn.Fn, &array, .refer, refer[1]);
    writeKind(ctn_fn.Fn, &array, .overwrite, overwrite[1]);
    writeKind(ctn_fn.Fn, &array, .write, write[1]);
    writeKind(ctn_fn.Fn, &array, .append, append[1]);
    writeKind(ctn_fn.Fn, &array, .helper, helper[1]);
    writeKind(ctn_fn.Fn, &array, .define, define[1]);
    writeKind(ctn_fn.Fn, &array, .undefine, undefine[1]);
    writeKind(ctn_fn.Fn, &array, .stream, stream[1]);
    writeKind(ctn_fn.Fn, &array, .unstream, unstream[1]);
    writeKind(ctn_fn.Fn, &array, .one, one[1]);
    writeKind(ctn_fn.Fn, &array, .read_one, read_one[1]);
    writeKind(ctn_fn.Fn, &array, .refer_one, refer_one[1]);
    writeKind(ctn_fn.Fn, &array, .count, count[1]);
    writeKind(ctn_fn.Fn, &array, .read_count, read_count[1]);
    writeKind(ctn_fn.Fn, &array, .refer_count, refer_count[1]);
    writeKind(ctn_fn.Fn, &array, .many, many[1]);
    writeKind(ctn_fn.Fn, &array, .read_many, read_many[1]);
    writeKind(ctn_fn.Fn, &array, .refer_many, refer_many[1]);
    writeKind(ctn_fn.Fn, &array, .format, format[1]);
    writeKind(ctn_fn.Fn, &array, .args, args[1]);
    writeKind(ctn_fn.Fn, &array, .fields, fields[1]);
    writeKind(ctn_fn.Fn, &array, .any, any[1]);
    writeKind(ctn_fn.Fn, &array, .sentinel, sentinel[1]);
    writeKind(ctn_fn.Fn, &array, .at, at[1]);
    writeKind(ctn_fn.Fn, &array, .defined, defined[1]);
    writeKind(ctn_fn.Fn, &array, .@"@\"undefined\"", @"undefined"[1]);
    writeKind(ctn_fn.Fn, &array, .streamed, streamed[1]);
    writeKind(ctn_fn.Fn, &array, .unstreamed, unstreamed[1]);
    writeKind(ctn_fn.Fn, &array, .relative_forward, @"undefined"[1] ++ unstreamed[1]);
    writeKind(ctn_fn.Fn, &array, .relative_reverse, defined[1] ++ streamed[1]);
    writeKind(ctn_fn.Fn, &array, .offset, offset_defined[1] ++ offset_undefined[1] ++ offset_streamed[1] ++ offset_unstreamed[1]);
    writeKind(ctn_fn.Fn, &array, .special, helper[0]);

    const fd: u64 = file.create(spec.create.truncate_noexcept, config.container_kinds_path, file.file_mode);
    file.write(spec.generic.noexcept, fd, array.readAll());
    file.close(spec.generic.noexcept, fd);
}
