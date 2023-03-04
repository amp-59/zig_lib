const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;
const tok = @import("./tok.zig");
const attr = @import("./attr.zig");
const ctn_fn = @import("./ctn_fn.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};

pub usingnamespace proc.start;

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

const Array = Allocator.StructuredVector(u8);
const ArgListArray = Allocator.StructuredVector(gen.ArgList);

fn writeOneUnique(arg_lists: *ArgListArray, arg_list: gen.ArgList) u64 {
    for (arg_lists.readAll(), 0..) |unique_arg_list, match_index| {
        if (mem.testEqualMany([:0]const u8, unique_arg_list.readAll(), arg_list.readAll())) {
            return match_index;
        }
    }
    const ret: u64 = arg_lists.len();
    arg_lists.writeOne(arg_list);
    return ret;
}
fn writeThing(array: *Array, array_lists: *ArgListArray, lists: *Array, kind: gen.ListKind) void {
    const name: [:0]const u8 = switch (kind) {
        .Parameter => "params",
        .Argument => "args",
    };
    const type_name: [:0]const u8 = switch (kind) {
        .Parameter => "PIndex",
        .Argument => "AIndex",
    };
    var ctn_index: u64 = 0;
    array.writeMany("const container_");
    array.writeMany(name);
    array.writeMany(": []const ");
    array.writeMany(type_name);
    array.writeMany("=&[_]");
    array.writeMany(type_name);
    array.writeMany("{");
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        array.writeMany(".{");
        const ctn_group: []const out.Index = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
        var ctn_fn_index: u64 = 0;
        while (ctn_fn_index != ctn_fn.key.len) : (ctn_fn_index +%= 1) {
            array.writeFormat(fmt.ud64(writeOneUnique(
                array_lists,
                ctn_fn.key[ctn_fn_index].argList(out.impl_variants[ctn_group[0]].less(), kind),
            )));
            array.writeOne(',');
        } else {
            array.writeOne('\n');
        }
        array.writeMany("},");
    }
    array.writeMany("};\n");
    lists.writeMany("pub const ");
    lists.writeMany(type_name);
    lists.writeMany("=");
    switch (array_lists.len()) {
        0...255 => lists.writeMany("u8;"),
        256...65535 => lists.writeMany("u16;"),
        else => lists.writeMany("u32;"),
    }
}
fn writeSecondThing(array_lists: *ArgListArray, lists: *Array, kind: gen.ListKind) void {
    const name: [:0]const u8 = switch (kind) {
        .Parameter => "params",
        .Argument => "args",
    };
    lists.writeMany("\nconst ");
    lists.writeMany(name);
    lists.writeMany("_lists:[]const gen.Arglist=&[_]gen.ArgList{");
    for (array_lists.readAll()) |arg_list| {
        lists.writeMany(".{.args=.{");
        for (arg_list.args, 0..) |symbol, symbol_index| {
            if (arg_list.len > symbol_index) {
                if (tok.symbolName(symbol)) |symbol_name| {
                    lists.writeMany("tok.");
                    lists.writeMany(symbol_name);
                    lists.writeMany(",");
                }
            } else {
                lists.undefine(@boolToInt(arg_list.len != 0));
                lists.writeMany("}++.{undefined}**");
                lists.writeFormat(fmt.ud64(arg_list.args.len - symbol_index));
                lists.writeMany(",.len=");
                lists.writeFormat(fmt.ud64(arg_list.len));
                lists.writeMany(",.kind=.Parameter");
                break;
            }
        }
        lists.writeMany("},\n");
    }
    lists.writeMany("};\n");
}

pub fn main() void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var args: Array = Array.init(&allocator, 1024 * 1024);
    var params: Array = Array.init(&allocator, 1024 * 1024);
    var lists: Array = Array.init(&allocator, 1024 * 1024);
    var arg_lists: ArgListArray = ArgListArray.init(&allocator, out.impl_variants.len * ctn_fn.key.len);
    var param_lists: ArgListArray = ArgListArray.init(&allocator, out.impl_variants.len * ctn_fn.key.len);
    var ctn_index: u64 = 0;
    params.writeMany("const container_params:[]const PIndex=&[_]PIndex{");
    args.writeMany("const container_args:[]const AIndex=&[_]AIndex{");
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        params.writeMany(".{");
        args.writeMany(".{");
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);
        const ctn_group: []const out.Index = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
        var ctn_fn_index: u64 = 0;
        while (ctn_fn_index != ctn_fn.key.len) : (ctn_fn_index +%= 1) {
            params.writeFormat(fmt.ud64(writeOneUnique(&param_lists, ctn_fn.key[ctn_fn_index].argList(out.impl_variants[ctn_group[0]].less(), .Parameter))));
            args.writeFormat(fmt.ud64(writeOneUnique(&arg_lists, ctn_fn.key[ctn_fn_index].argList(out.impl_variants[ctn_group[0]].less(), .Argument))));
            params.writeOne(',');
            args.writeOne(',');
        } else {
            params.writeOne('\n');
            args.writeOne('\n');
        }
        params.writeMany("},");
        args.writeMany("},");
    }
    params.writeMany("};\n");
    args.writeMany("};\n");
    lists.writeMany("pub const AIndex=");
    switch (arg_lists.len()) {
        0...255 => lists.writeMany("u8;"),
        256...65535 => lists.writeMany("u16;"),
        else => lists.writeMany("u32;"),
    }
    lists.writeMany("\npub const PIndex=");
    switch (param_lists.len()) {
        0...255 => lists.writeMany("u8;"),
        256...65535 => lists.writeMany("u16;"),
        else => lists.writeMany("u32;"),
    }
    lists.writeMany("\nconst param_lists:[]const gen.Arglist=&[_]gen.ArgList{");
    for (arg_lists.readAll()) |arg_list| {
        lists.writeMany(".{.args=.{");
        for (arg_list.args, 0..) |symbol, symbol_index| {
            if (arg_list.len > symbol_index) {
                if (tok.symbolName(symbol)) |symbol_name| {
                    lists.writeMany("tok.");
                    lists.writeMany(symbol_name);
                    lists.writeMany(",");
                }
            } else {
                lists.undefine(@boolToInt(arg_list.len != 0));
                lists.writeMany("}++.{undefined}**");
                lists.writeFormat(fmt.ud64(arg_list.args.len - symbol_index));
                lists.writeMany(",.len=");
                lists.writeFormat(fmt.ud64(arg_list.len));
                lists.writeMany(",.kind=.Parameter");
                break;
            }
        }
        lists.writeMany("},\n");
    }
    lists.writeMany("};\n");
    lists.writeMany("const arg_lists:[]const gen.Arglist=&[_]gen.ArgList{");
    for (arg_lists.readAll()) |arg_list| {
        lists.writeMany(".{.args=.{");
        for (arg_list.args, 0..) |symbol, symbol_index| {
            if (arg_list.len > symbol_index) {
                if (tok.symbolName(symbol)) |symbol_name| {
                    lists.writeMany("tok.");
                    lists.writeMany(symbol_name);
                    lists.writeMany(",");
                }
            } else {
                lists.undefine(@boolToInt(arg_list.len != 0));
                lists.writeMany("}++.{undefined}**");
                lists.writeFormat(fmt.ud64(arg_list.args.len - symbol_index));
                lists.writeMany(",.len=");
                lists.writeFormat(fmt.ud64(arg_list.len));
                lists.writeMany(",.kind=.Argument");
                break;
            }
        }
        lists.writeMany("},\n");
    }
    lists.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&lists, "container_args.zig");
    gen.appendAuxiliarySourceFile(&args, "container_args.zig");
    gen.appendAuxiliarySourceFile(&params, "container_args.zig");
}
