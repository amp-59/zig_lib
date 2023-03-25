const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const file = gen.file;
const preset = gen.preset;
const builtin = gen.builtin;

const config = @import("./config.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticString(0);

const mkdir_spec: file.MakeDirSpec = .{
    .errors = .{},
};
const create_spec: file.CreateSpec = .{
    .errors = .{},
    .options = .{ .write = .truncate, .exclusive = false },
};
const close_spec: file.CloseSpec = .{
    .errors = .{},
};

pub fn main() void {
    file.makeDir(mkdir_spec, config.zig_out_dir);
    file.makeDir(mkdir_spec, config.zig_out_src_dir);
    file.close(close_spec, file.create(create_spec, config.container_path));
    file.close(close_spec, file.create(create_spec, config.reference_path));
    file.close(close_spec, file.create(create_spec, config.container_kinds_path));
    file.close(close_spec, file.create(create_spec, config.reference_kinds_path));
}
