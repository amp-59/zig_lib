const gen = @import("./gen.zig");
const proc = gen.proc;
const meta = gen.meta;
const testing = gen.testing;

const attr = @import("./attr.zig");

const containers = @import("./containers.zig");
const references = @import("./references.zig");

const details: []const attr.More = meta.bytesToSlice(attr.More, @embedFile("./zig-out/src/detail_raw"));

pub usingnamespace proc.start;

const NoSerial = struct {
    kind: attr.Kinds.Tag,
    layout: attr.Layouts.Tag,
    modes: attr.Modes,
    fields: attr.Fields,
    techs: attr.Techniques,
    specs: attr.Specifiers,
};

pub fn main() void {
    var no_serial: [details.len]NoSerial = undefined;

    for (details, 0..) |detail, index| {
        no_serial[index] = .{
            .kind = detail.kind,
            .layout = detail.layout,
            .modes = detail.modes,
            .fields = detail.fields,
            .techs = detail.techs,
            .specs = detail.specs,
        };
    }
    testing.uniqueSet(NoSerial, &no_serial);
}
