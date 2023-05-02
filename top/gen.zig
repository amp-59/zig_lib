const mem = @import("./mem.zig");
const file = @import("./file.zig");
const spec = @import("./spec.zig");

pub const ListKind = enum {
    Parameter,
    Argument,
};
pub const ArgList = struct {
    args: [16][:0]const u8,
    len: u8,
    kind: ListKind,
    ret: [:0]const u8,
    pub fn writeOne(arg_list: *ArgList, symbol: [:0]const u8) void {
        arg_list.args[arg_list.len] = symbol;
        arg_list.len +%= 1;
    }
    pub fn readAll(arg_list: *const ArgList) []const [:0]const u8 {
        return arg_list.args[0..arg_list.len];
    }
};
pub const DeclList = struct {
    decls: [24][:0]const u8,
    len: u8,
    pub fn writeOne(decl_list: *DeclList, symbol: [:0]const u8) void {
        decl_list.decls[decl_list.len] = symbol;
        decl_list.len +%= 1;
    }
    pub fn readAll(decl_list: *const DeclList) []const [:0]const u8 {
        return decl_list.decls[0..decl_list.len];
    }
    pub fn have(decl_list: *const DeclList, symbol: [:0]const u8) bool {
        for (decl_list.readAll()) |decl| {
            if (decl.ptr == symbol.ptr) {
                return true;
            }
        }
        return false;
    }
};
pub fn truncateFile(comptime write_spec: file.WriteSpec, pathname: [:0]const u8, buf: []const write_spec.child) void {
    const fd: u64 = file.create(spec.create.truncate_noexcept, pathname, file.file_mode);
    defer file.close(spec.generic.noexcept, fd);
    file.writeSlice(write_spec, fd, buf);
}
pub fn appendFile(comptime write_spec: file.WriteSpec, pathname: [:0]const u8, buf: []const write_spec.child) void {
    const fd: u64 = file.open(spec.open.append_noexcept, pathname);
    defer file.close(spec.generic.noexcept, fd);
    file.writeSlice(write_spec, fd, buf);
}
pub fn readFile(comptime read_spec: file.ReadSpec, pathname: [:0]const u8, buf: []read_spec.child) u64 {
    const fd: u64 = file.open(spec.open.append_noexcept, pathname);
    defer file.close(spec.generic.noexcept, fd);
    return file.readSlice(read_spec, fd, buf);
}
