pub const Packages = []const Pkg;
pub const Macros = []const Macro;

pub const Pkg = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(pkg: Pkg, array: anytype) void {
        array.writeMany("--pkg-begin");
        array.writeOne(0);
        array.writeMany(pkg.name);
        array.writeOne(0);
        array.writeMany(pkg.path);
        array.writeOne(0);
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                array.writeOne(0);
                dep.formatWrite(array);
            }
        }
        array.writeMany("--pkg-end");
        array.writeOne(0);
    }
    pub fn formatLength(pkg: Pkg) u64 {
        var len: u64 = 0;
        len += 11;
        len += 1;
        len += pkg.name.len;
        len += 1;
        len += pkg.path.len;
        len += 1;
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                len += 1;
                len += dep.formatLength();
            }
        }
        len += 9;
        len += 1;
        return len;
    }
};
/// Zig says value does not need to be defined, in which case default to 1
pub const Macro = struct {
    name: []const u8,
    value: ?[]const u8 = null,
    pub fn formatWrite(macro: Macro, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(macro.name);
        if (macro.value) |value| {
            array.writeMany("=");
            array.writeMany(value);
        }
        array.writeOne(0);
    }
    pub fn formatLength(macro: Macro) u64 {
        var len: u64 = 0;
        len += 2;
        len += macro.name.len;
        if (macro.value) |value| {
            len += 1;
            len += value.len;
        }
        len += 1;
        return len;
    }
};
