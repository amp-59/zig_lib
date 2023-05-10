const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const file = gen.file;
const spec = gen.spec;
const builtin = gen.builtin;
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const Array = mem.StaticString(0);
const mkdir_spec: file.MakeDirSpec = .{ .errors = .{} };
const create_spec: file.CreateSpec = .{ .errors = .{}, .options = .{ .exclusive = false } };
const close_spec: file.CloseSpec = .{ .errors = .{} };
pub fn main() void {
    file.makeDir(mkdir_spec, config.zig_out_dir, file.mode.directory);
    file.makeDir(mkdir_spec, config.zig_out_src_dir, file.mode.directory);
    file.makeDir(mkdir_spec, config.container_dir_path, file.mode.directory);
    file.makeDir(mkdir_spec, config.reference_dir_path, file.mode.directory);
    file.close(close_spec, file.create(create_spec, config.container_file_path, file.mode.regular));
    file.close(close_spec, file.create(create_spec, config.reference_file_path, file.mode.regular));
    file.close(close_spec, file.create(create_spec, config.container_kinds_path, file.mode.regular));
    file.close(close_spec, file.create(create_spec, config.reference_kinds_path, file.mode.regular));
}
