const sys = @import("./sys.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;
pub const is_verbose: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const exec_zig: bool = false;
const errors: ?[]const sys.ErrorCode = &.{};

const make_dir_spec: file.MakeDirSpec = .{
    .errors = errors,
};
const create_spec: file.CreateSpec = .{
    .options = .{},
    .errors = errors,
};
const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null },
    .errors = errors,
};
const open_dir_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = null, .directory = true },
    .errors = errors,
};
const exec_spec: proc.ExecuteSpec = .{
    .options = .{},
    .errors = errors,
};
const remove_dir_spec: file.RemoveDirSpec = .{
    .errors = errors,
};
const unlink_spec: file.UnlinkSpec = .{
    .errors = errors,
};
const close_spec: file.CloseSpec = .{
    .errors = errors,
};
const stat_spec: file.StatSpec = .{
    .errors = errors,
};
pub fn main() !void {
    {
        try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
        const fd: u64 = try file.create(create_spec, "/run/user/1000/file_test");
        try file.close(close_spec, fd);
        try file.unlink(unlink_spec, "/run/user/1000/file_test");
    }
    {
        try file.makeDir(make_dir_spec, "/run/user/1000/file_test");
        var st: file.Stat = try file.stat(stat_spec, "/run/user/1000/file_test");
        builtin.assert(st.isDirectory());
        const dir_fd: u64 = try file.open(open_dir_spec, "/run/user/1000/file_test");
        try file.makeDirAt(make_dir_spec, dir_fd, "file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test/file_test");
        try file.removeDir(remove_dir_spec, "/run/user/1000/file_test");
        try file.close(close_spec, dir_fd);
    }
}
