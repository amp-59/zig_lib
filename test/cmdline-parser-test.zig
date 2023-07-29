const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const elf = zl.elf;
const file = zl.file;
const proc = zl.proc;
const mach = zl.mach;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

var s: struct { x: ?usize = null, y: usize = 50 } = .{};

fn loadAll(comptime Pointers: type, pathname: [:0]const u8) Pointers {
    @setRuntimeSafety(builtin.is_safe);
    const prot: file.Map.Protection = .{ .exec = true };
    const flags: file.Map.Flags = .{};
    var addr: usize = 0x80000000;
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @intFromPtr(pathname.ptr), 0, 0 });
    if (fd > 1024) {
        proc.exitErrorFault(error.NoSuchFileOrDirectory, pathname, 2);
    }
    sys.call_noexcept(.fstat, void, .{ fd, @intFromPtr(&st) });
    const len: usize = mach.alignA64(st.size, 4096);
    const rc_addr1: usize = sys.call_noexcept(.mmap, usize, [6]usize{ addr, len, @bitCast(prot), @bitCast(flags), fd, 0 });
    if (rc_addr1 != addr) {
        proc.exitErrorFault(error.OutOfMemory, pathname, 2);
    }
    const elf_info: elf.ElfInfo = elf.ElfInfo.init(addr);
    addr +%= elf_info.executableOffset();
    const rc_addr2: usize = sys.call_noexcept(.mmap, usize, [6]usize{ addr, len, @bitCast(prot), @bitCast(flags), fd, 0 });
    if (rc_addr2 != addr) {
        proc.exitErrorFault(error.OutOfMemory, pathname, 2);
    }
    return elf_info.loadAll(Pointers);
}
fn writeField(array: *mem.StaticArray(u8, 4096), field_name: []const u8, field_value: anytype) void {
    array.writeOne('.');
    array.writeMany(field_name);
    array.writeMany(" = ");
    array.writeFormat(fmt.render(.{}, field_value));
    array.writeMany(", ");
}
pub fn main(args: anytype) !void {
    var allocator: mem.SimpleAllocator = .{};
    const ptrs: build.ParseCommand = loadAll(build.ParseCommand, "zig-out/lib/libparse.so");
    var cmd: build.BuildCommand = .{ .kind = .exe };
    ptrs.build(&cmd, &allocator, args.ptr, args.len);
    var array: mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeMany("node.addBuild(allocator, .{ ");
    inline for (@typeInfo(build.BuildCommand).Struct.fields) |field| {
        if (@typeInfo(field.type) == .Optional) {
            if (@field(cmd, field.name)) |field_value| {
                writeField(&array, field.name, field_value);
            }
        } else {
            if (field.default_value) |ptr| {
                if (@field(cmd, field.name) != mem.pointerOpaque(field.type, ptr).*) {
                    writeField(&array, field.name, @field(cmd, field.name));
                }
            } else {
                writeField(&array, field.name, @field(cmd, field.name));
            }
        }
    }
    array.writeMany("}, \"");
    if (cmd.name) |name| {
        array.writeMany(name);
    } else {
        array.writeMany("anonymous");
    }
    array.writeMany("\", \"<path>\");\n");
    debug.write(array.readAll());
}
