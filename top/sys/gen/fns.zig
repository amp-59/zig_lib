const zl = @import("../../../zig_lib.zig");
const fmt = zl.fmt;
const debug = zl.debug;

pub usingnamespace zl.start;

const Variant = struct {
    arch: enum { x86, aarch64 },
};

const Fn = struct {
    name: []const u8,
    tag: zl.sys.Fn,
    args: []const *const Argument,
    regs: []const Register,
};
const Argument = struct {
    name: []const u8,
    type: type,
};
const Register = union(enum) {
    arg: *const Argument,
    imm: comptime_int,
};

const addr_arg: Argument = .{ .name = "addr", .type = usize };
const len_arg: Argument = .{ .name = "len", .type = usize };
const old_addr_arg: Argument = .{ .name = "old_addr", .type = usize };
const old_len_arg: Argument = .{ .name = "old_len", .type = usize };
const new_addr_arg: Argument = .{ .name = "new_addr", .type = usize };
const new_len_arg: Argument = .{ .name = "new_len", .type = usize };

const mmap_prot_arg: Argument = .{ .name = "prot", .type = zl.sys.flags.MemProt };
const mmap_flags_arg: Argument = .{ .name = "flags", .type = zl.sys.flags.MemMap };
const mremap_flags_arg: Argument = .{ .name = "flags", .type = zl.sys.flags.Remap };

const mem = [_]Fn{
    .{
        .name = "map",
        .tag = .mmap,
        .args = &.{ &mmap_prot_arg, &mmap_flags_arg, &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &mmap_prot_arg },
            .{ .arg = &mmap_flags_arg },
            .{ .imm = -1 }, // fd
            .{ .imm = 0 }, // offset
        },
    },
    .{
        .name = "unmap",
        .tag = .munmap,
        .args = &.{ &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
        },
    },
    .{
        .name = "remap",
        .tag = .mremap,
        .args = &.{ &mremap_flags_arg, &old_addr_arg, &old_len_arg, &new_addr_arg, &new_len_arg },
        .regs = &.{
            .{ .arg = &old_addr_arg },
            .{ .arg = &old_len_arg },
            .{ .arg = &new_len_arg },
            .{ .arg = &mremap_flags_arg },
            .{ .arg = &new_addr_arg },
        },
    },
    .{
        .name = "protect",
        .tag = .mprotect,
        .args = &.{ &addr_arg, &len_arg, &mmap_prot_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &mmap_prot_arg },
        },
    },
};
pub const Type = fmt.GenericTypeDescrFormat(.{
    .default_field_values = .fast,
    .option_5 = true,
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
pub fn main() void {
    var buf: [4096]u8 = undefined;
    inline for (mem) |sys_fn| {
        var ptr: [*]u8 = &buf;
        ptr[0..3].* = "fn ".*;
        ptr += 3;
        ptr = zl.fmt.strcpyEqu(ptr, sys_fn.name);
        ptr[0] = '(';
        ptr += 1;
        inline for (sys_fn.args) |arg| {
            ptr = fmt.strcpyEqu(ptr, arg.name);
            ptr[0] = ':';
            ptr += 1;
            ptr = fmt.strcpyEqu(ptr, @typeName(arg.type));
            ptr[0] = ',';
            ptr += 1;
        }
        ptr[0..7].* = ")void{\n".*;
        ptr += 7;
        zl.fmt.print(ptr, &buf);
    }
}
