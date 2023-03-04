const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;
const attr = @import("./attr.zig");
const ctn_fn = @import("./ctn_fn.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .logging = preset.address_space.logging.silent,
    .errors = preset.address_space.errors.noexcept,
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

fn mainStatic() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "ctn_fn", "../../ctn_fn.zig");
    const writeKind = attr.Fn.static.writeKindSwitch;
    const Tags = []const ctn_fn.Fn;
    const Pair = attr.Fn.static.Pair(ctn_fn.Fn);
    const read: Pair = comptime attr.Fn.static.prefixSubTagNew(ctn_fn.Fn, .read);
    const refer: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, read[0], .refer);
    const write: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, refer[0], .write);
    const append: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, write[0], .append);
    const overwrite: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, append[0], .overwrite);
    const helper: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, overwrite[0], .__);
    const is_value: Tags = comptime read[1] ++ write[1] ++ refer[1] ++ append[1] ++ overwrite[1];
    const one: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, is_value, .One);
    const read_one: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, one[1], .read);
    const refer_one: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_one[0], .refer);
    const count: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, one[0], .Count);
    const read_count: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, count[1], .read);
    const refer_count: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_count[0], .refer);
    const many: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, count[0], .Many);
    const read_many: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, many[1], .read);
    const refer_many: Pair = comptime attr.Fn.static.prefixSubTag(ctn_fn.Fn, read_many[0], .refer);
    const sentinel: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, many[1] ++ count[1], .WithSentinel);
    const at: Pair = comptime attr.Fn.static.suffixSubTag(ctn_fn.Fn, read[1] ++ refer[1] ++ overwrite[1], .At);
    const defined: Pair = comptime attr.Fn.static.suffixSubTag(ctn_fn.Fn, at[0], .Defined);
    const @"undefined": Pair = comptime attr.Fn.static.suffixSubTag(ctn_fn.Fn, defined[0], .Undefined);
    const streamed: Pair = comptime attr.Fn.static.suffixSubTag(ctn_fn.Fn, @"undefined"[0], .Streamed);
    const unstreamed: Pair = comptime attr.Fn.static.suffixSubTag(ctn_fn.Fn, streamed[0], .Unstreamed);
    const offset_defined: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, defined[1], .Offset);
    const offset_undefined: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, @"undefined"[1], .Offset);
    const offset_streamed: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, streamed[1], .Offset);
    const offset_unstreamed: Pair = comptime attr.Fn.static.subTag(ctn_fn.Fn, unstreamed[1], .Offset);
    writeKind(ctn_fn.Fn, &array, "read", read[1]);
    writeKind(ctn_fn.Fn, &array, "refer", refer[1]);
    writeKind(ctn_fn.Fn, &array, "write", write[1]);
    writeKind(ctn_fn.Fn, &array, "append", append[1]);
    writeKind(ctn_fn.Fn, &array, "overwrite", overwrite[1]);
    writeKind(ctn_fn.Fn, &array, "helper", helper[1]);
    writeKind(ctn_fn.Fn, &array, "special", helper[0]);
    writeKind(ctn_fn.Fn, &array, "value", is_value);
    writeKind(ctn_fn.Fn, &array, "one", one[1]);
    writeKind(ctn_fn.Fn, &array, "read_one", read_one[1]);
    writeKind(ctn_fn.Fn, &array, "refer_one", refer_one[1]);
    writeKind(ctn_fn.Fn, &array, "count", count[1]);
    writeKind(ctn_fn.Fn, &array, "read_count", read_count[1]);
    writeKind(ctn_fn.Fn, &array, "refer_count", refer_count[1]);
    writeKind(ctn_fn.Fn, &array, "many", many[1]);
    writeKind(ctn_fn.Fn, &array, "read_many", read_many[1]);
    writeKind(ctn_fn.Fn, &array, "refer_many", refer_many[1]);
    writeKind(ctn_fn.Fn, &array, "sentinel", sentinel[1]);
    writeKind(ctn_fn.Fn, &array, "at", at[1]);
    writeKind(ctn_fn.Fn, &array, "defined", defined[1]);
    writeKind(ctn_fn.Fn, &array, "@\"undefined\"", @"undefined"[1]);
    writeKind(ctn_fn.Fn, &array, "streamed", streamed[1]);
    writeKind(ctn_fn.Fn, &array, "unstreamed", unstreamed[1]);
    writeKind(ctn_fn.Fn, &array, "relative", offset_defined[0] ++ offset_undefined[0] ++ offset_streamed[0] ++ offset_unstreamed[0]);
    writeKind(ctn_fn.Fn, &array, "offset", offset_defined[1] ++ offset_undefined[1] ++ offset_streamed[1] ++ offset_unstreamed[1]);
    gen.writeAuxiliarySourceFile(&array, "container_kinds.zig");
}
fn mainAllocated() void {
    var array: Array = undefined;
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    array.undefineAll();
    gen.writeImport(&array, "ctn_fn", "../../ctn_fn.zig");
    const Tags = Allocator.StructuredVector(ctn_fn.Fn);
    const Pair = attr.Fn.Pair(Allocator, ctn_fn.Fn);
    const read: Pair = attr.Fn.prefixSubTagNew(ctn_fn.Fn, &allocator, .read);
    const refer: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, read[0], .refer);
    const write: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, refer[0], .write);
    const append: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, write[0], .append);
    const overwrite: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, append[0], .overwrite);
    const helper: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, overwrite[0], .__);
    const is_value: Tags = concat(Tags, &allocator, &.{ read[1], write[1], refer[1], append[1], overwrite[1] });
    const one: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, is_value, .One);
    const read_one: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, one[1], .read);
    const refer_one: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, read_one[0], .refer);
    const count: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, one[0], .Count);
    const read_count: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, count[1], .read);
    const refer_count: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, read_count[0], .refer);
    const many: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, count[0], .Many);
    const read_many: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, many[1], .read);
    const refer_many: Pair = attr.Fn.prefixSubTag(ctn_fn.Fn, &allocator, read_many[0], .refer);
    const sentinel: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, concat(Tags, &allocator, &.{ many[1], count[1] }), .WithSentinel);
    const at: Pair = attr.Fn.suffixSubTag(ctn_fn.Fn, &allocator, concat(Tags, &allocator, &.{ read[1], refer[1], overwrite[1] }), .At);
    const defined: Pair = attr.Fn.suffixSubTag(ctn_fn.Fn, &allocator, at[0], .Defined);
    const @"undefined": Pair = attr.Fn.suffixSubTag(ctn_fn.Fn, &allocator, defined[0], .Undefined);
    const streamed: Pair = attr.Fn.suffixSubTag(ctn_fn.Fn, &allocator, @"undefined"[0], .Streamed);
    const unstreamed: Pair = attr.Fn.suffixSubTag(ctn_fn.Fn, &allocator, streamed[0], .Unstreamed);
    const offset_defined: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, defined[1], .Offset);
    const offset_undefined: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, @"undefined"[1], .Offset);
    const offset_streamed: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, streamed[1], .Offset);
    const offset_unstreamed: Pair = attr.Fn.subTag(ctn_fn.Fn, &allocator, unstreamed[1], .Offset);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "read", read[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "refer", refer[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "write", write[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "append", append[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "overwrite", overwrite[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "helper", helper[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "special", helper[0]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "value", is_value);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "one", one[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "read_one", read_one[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "refer_one", refer_one[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "count", count[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "read_count", read_count[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "refer_count", refer_count[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "many", many[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "read_many", read_many[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "refer_many", refer_many[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "sentinel", sentinel[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "at", at[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "defined", defined[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "@\"undefined\"", @"undefined"[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "streamed", streamed[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "unstreamed", unstreamed[1]);
    attr.Fn.writeKind(ctn_fn.Fn, &array, "relative", concat(Tags, &allocator, &.{
        offset_defined[0],  offset_undefined[0],
        offset_streamed[0], offset_unstreamed[0],
    }));
    attr.Fn.writeKind(ctn_fn.Fn, &array, "offset", concat(Tags, &allocator, &.{
        offset_defined[1],  offset_undefined[1],
        offset_streamed[1], offset_unstreamed[1],
    }));
    gen.writeAuxiliarySourceFile(&array, "container_kinds.zig");
}
pub const main = mainStatic;
