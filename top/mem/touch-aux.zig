const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const file = gen.file;
const preset = gen.preset;
const builtin = gen.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticString(0);

const build_root: [:0]const u8 = @cImport({}).build_root;

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
    const zig_out_dir: [:0]const u8 = build_root ++ "/top/mem/zig-out";
    const zig_out_src_dir: [:0]const u8 = zig_out_dir ++ "/src";

    file.makeDir(mkdir_spec, zig_out_dir);
    file.makeDir(mkdir_spec, zig_out_src_dir);

    file.close(close_spec, file.create(create_spec, gen.primaryFile("containers.zig")));
    file.close(close_spec, file.create(create_spec, gen.primaryFile("references.zig")));
    file.close(close_spec, file.create(create_spec, gen.auxiliaryFile("container_kinds.zig")));
    file.close(close_spec, file.create(create_spec, gen.auxiliaryFile("reference_kinds.zig")));
}
