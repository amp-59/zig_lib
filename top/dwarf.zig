const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const exe = @import("./exe.zig");
const fmt = @import("./fmt.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const parse = @import("./parse.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

// TODO Relocate to namespace `config`.
const DebugSpec = struct {
    logging: Logging = .{},
    const Logging = struct {
        summary: bool = true,
        abbrev_entry: bool = true,
        info_entry: bool = false,
    };
};
// TODO Relocate to namespace `config`.
const debug_spec: DebugSpec = .{};

const WordSize = enum(u1) { dword, qword };

const Range = struct {
    start: u64,
    end: u64,
};
pub const Func = struct {
    range: ?Range,
    name: ?[]const u8,
};
const Unit = struct {
    version: u16,
    word_size: WordSize,
    range: ?Range = null,
    abbrev_tab: *AbbrevTable,
    abbrev_tab_len: u64,
    info_entry: *InfoEntry,
    info_entry_len: u64,
    str_offsets_base: usize = 0,
    addr_base: usize = 0,
    rnglists_base: usize = 0,
    loclists_base: usize = 0,
};
const AbbrevTable = struct {
    abbrev_tab_off: usize,
    ents: [*]AbbrevEntry = undefined,
    ents_max_len: u64 = 0,
    ents_len: u64 = 0,
    fn addEntry(table: *AbbrevTable, allocator: *mem.SimpleAllocator) *AbbrevEntry {
        @setRuntimeSafety(false);
        const size_of: comptime_int = @sizeOf(AbbrevEntry);
        const addr_buf: *u64 = @ptrCast(*u64, &table.ents);
        const ret: *AbbrevEntry = @intToPtr(
            *AbbrevEntry,
            allocator.addGeneric(size_of, 1, addr_buf, &table.ents_max_len, table.ents_len),
        );
        table.ents_len +%= 1;
        return ret;
    }
};
const AbbrevEntry = struct {
    code: u64,
    tag: Tag,
    children: Children,
    kvs: [*]KeyVal = undefined,
    kvs_max_len: u64 = 0,
    kvs_len: u64 = 0,
    const KeyVal = struct {
        attr: Attr,
        form: Form,
        payload: i64 = undefined,
    };
    fn addKeyVal(entry: *AbbrevEntry, allocator: *mem.SimpleAllocator) *KeyVal {
        @setRuntimeSafety(false);
        const size_of: comptime_int = @sizeOf(KeyVal);
        const addr_buf: *u64 = @ptrCast(*u64, &entry.kvs);
        const ret: *KeyVal = @intToPtr(
            *KeyVal,
            allocator.addGeneric(size_of, 1, addr_buf, &entry.kvs_max_len, entry.kvs_len),
        );
        entry.kvs_len +%= 1;
        return ret;
    }
};
const FormValue = union(enum) {
    Address: u64,
    AddrOffset: usize,
    Block: []u8,
    Const: Constant,
    ExprLoc: []u8,
    Flag: bool,
    SecOffset: u64,
    Ref: u64,
    RefAddr: u64,
    String: []const u8,
    StrPtr: u64,
    StrOffset: usize,
    LineStrPtr: u64,
    LocListOffset: u64,
    RangeListOffset: u64,
    data16: [16]u8,
    fn getString(val: FormValue, dwarf: DwarfInfo) ![]const u8 {
        switch (val) {
            .String => |s| return s,
            .StrPtr => |off| return dwarf.getString(off),
            .LineStrPtr => |off| return dwarf.getLineString(off),
            else => builtin.proc.exitError(error.InvalidEncoding, 2),
        }
    }
    fn getUInt(val: FormValue, comptime U: type) !U {
        switch (val) {
            .Const => {
                return @intCast(U, try val.Const.asUnsignedLe());
            },
            .SecOffset => |sec_offset| {
                return @intCast(U, sec_offset);
            },
            else => builtin.proc.exitError(error.InvalidEncoding, 2),
        }
    }
    fn getData16(val: FormValue) ![16]u8 {
        switch (val) {
            .data16 => |d| return d,
            else => builtin.proc.exitError(error.InvalidEncoding, 2),
        }
    }
};
const Constant = struct {
    payload: u64,
    signed: bool,
    fn asUnsignedLe(val: Constant) !u64 {
        if (val.signed) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        return val.payload;
    }
    fn asSignedLe(val: Constant) !i64 {
        if (val.signed) {
            return @bitCast(i64, val.payload);
        }
        builtin.proc.exitError(error.InvalidEncoding, 2);
    }
};
const InfoEntry = struct {
    tag: Tag,
    children: Children,
    kvs: [*]KeyVal = undefined,
    kvs_max_len: u64 = 0,
    kvs_len: u64 = 0,
    const KeyVal = struct {
        key: Attr,
        val: FormValue,
    };
    fn addKeyVal(info_entry: *InfoEntry, allocator: *mem.SimpleAllocator) *KeyVal {
        @setRuntimeSafety(false);
        const size_of: comptime_int = @sizeOf(KeyVal);
        const addr_buf: *u64 = @ptrCast(*u64, &info_entry.kvs);
        const ret: *KeyVal = @intToPtr(
            *KeyVal,
            allocator.addGeneric(size_of, 1, addr_buf, &info_entry.kvs_max_len, info_entry.kvs_len),
        );
        info_entry.kvs_len +%= 1;
        return ret;
    }
    fn getAttr(info_entry: *const InfoEntry, key: Attr) ?*const FormValue {
        for (info_entry.kvs[0..info_entry.kvs_len]) |*kv| {
            if (kv.key == key) return &kv.val;
        }
        return null;
    }
    fn getAttrAddr(info_entry: *const InfoEntry, dwarf: *DwarfInfo, attr_id: Attr, unit: Unit) !u64 {
        const form_value = info_entry.getAttr(attr_id) orelse return error.MissingDebugInfo;
        return switch (form_value.*) {
            FormValue.Address => |value| value,
            FormValue.AddrOffset => |index| try dwarf.readDebugAddr(unit.addr_base, index),
            else => error.InvalidDebugInfo,
        };
    }
    fn getAttrSecOffset(info_entry: *const InfoEntry, attr_id: Attr) !u64 {
        const form_value = info_entry.getAttr(attr_id) orelse return error.MissingDebugInfo;
        return form_value.getUInt(u64);
    }
    fn getAttrUnsignedLe(info_entry: *const InfoEntry, attr_id: Attr) !u64 {
        const form_value = info_entry.getAttr(attr_id) orelse return error.MissingDebugInfo;
        return switch (form_value.*) {
            FormValue.Const => |value| value.asUnsignedLe(),
            else => error.InvalidDebugInfo,
        };
    }
    fn getAttrRef(info_entry: *const InfoEntry, attr_id: Attr) !u64 {
        const form_value = info_entry.getAttr(attr_id) orelse return error.MissingDebugInfo;
        return switch (form_value.*) {
            FormValue.Ref => |value| value,
            else => error.InvalidDebugInfo,
        };
    }
};
pub const DwarfInfo = extern struct {
    info: [*]u8,
    info_len: u64,
    abbrev: [*]u8,
    abbrev_len: u64,
    str: [*]u8,
    str_len: u64,
    str_offsets: [*]u8,
    str_offsets_len: u64,
    line: [*]u8,
    line_len: u64,
    line_str: [*]u8,
    line_str_len: u64,
    ranges: [*]u8,
    ranges_len: u64,
    loclists: [*]u8,
    loclists_len: u64,
    rnglists: [*]u8,
    rnglists_len: u64,
    addr: [*]u8,
    addr_len: u64,
    names: [*]u8,
    names_len: u64,
    frame: [*]u8,
    frame_len: u64,
    abbrev_tabs: [*]AbbrevTable,
    abbrev_tabs_max_len: u64,
    abbrev_tabs_len: u64,
    units: [*]Unit,
    units_max_len: u64,
    units_len: u64,
    funcs: [*]Func,
    funcs_max_len: u64,
    funcs_len: u64,

    const names: [12][]const u8 = .{
        ".debug_info",
        ".debug_abbrev",
        ".debug_str",
        ".debug_str_offsets",
        ".debug_line",
        ".debug_line_str",
        ".debug_ranges",
        ".debug_loclists",
        ".debug_rnglists",
        ".debug_addr",
        ".debug_names",
        ".debug_frame",
    };
    pub fn init(ehdr_addr: u64) DwarfInfo {
        @setRuntimeSafety(false);
        const ehdr: *exe.Elf64_Ehdr = @intToPtr(*exe.Elf64_Ehdr, ehdr_addr);
        const qwords: comptime_int = @divExact(@sizeOf(DwarfInfo), 8);
        var ret: [qwords]u64 = [_]u64{0} ** qwords;
        var shdr: *exe.Elf64_Shdr = @intToPtr(*exe.Elf64_Shdr, ehdr_addr +% ehdr.e_shoff +% ehdr.e_shstrndx *% ehdr.e_shentsize);
        var strtab_addr: u64 = ehdr_addr +% shdr.sh_offset;
        var addr: u64 = ehdr_addr +% ehdr.e_shoff;
        var shdr_idx: u64 = 0;
        while (shdr_idx != ehdr.e_shnum) : (shdr_idx +%= 1) {
            shdr = @intToPtr(*exe.Elf64_Shdr, addr);
            for (DwarfInfo.names, 0..) |field_name, field_idx| {
                const str: [*:0]u8 = @intToPtr([*:0]u8, strtab_addr +% shdr.sh_name);
                var idx: u64 = 0;
                while (str[idx] != 0) : (idx +%= 1) {
                    if (field_name[idx] != str[idx]) break;
                } else {
                    const pair_idx: u64 = field_idx *% 2;
                    ret[pair_idx +% 0] = ehdr_addr +% shdr.sh_offset;
                    ret[pair_idx +% 1] = shdr.sh_size;
                }
            }
            addr +%= ehdr.e_shentsize;
        }
        return @bitCast(DwarfInfo, ret);
    }
    fn addAbbrevTable(dwarf: *DwarfInfo, allocator: *mem.SimpleAllocator) *AbbrevTable {
        @setRuntimeSafety(false);
        const addr_buf: *u64 = @ptrCast(*u64, &dwarf.abbrev_tabs);
        const ret: *AbbrevTable = @intToPtr(*AbbrevTable, allocator.addGeneric(@sizeOf(AbbrevTable), 1, addr_buf, &dwarf.abbrev_tabs_max_len, dwarf.abbrev_tabs_len));
        dwarf.abbrev_tabs_len +%= 1;
        return ret;
    }
    fn addUnit(dwarf: *DwarfInfo, allocator: *mem.SimpleAllocator) *Unit {
        @setRuntimeSafety(false);
        const addr_buf: *u64 = @ptrCast(*u64, &dwarf.units);
        const ret: *Unit = @intToPtr(*Unit, allocator.addGeneric(@sizeOf(Unit), 1, addr_buf, &dwarf.units_max_len, dwarf.units_len));
        dwarf.units_len +%= 1;
        return ret;
    }
    fn addFunc(dwarf: *DwarfInfo, allocator: *mem.SimpleAllocator) *Func {
        @setRuntimeSafety(false);
        const addr_buf: *u64 = @ptrCast(*u64, &dwarf.funcs);
        const ret: *Func = @intToPtr(*Func, allocator.addGeneric(@sizeOf(Func), 1, addr_buf, &dwarf.funcs_max_len, dwarf.funcs_len));
        dwarf.funcs_len +%= 1;
        return ret;
    }
    fn scanAllCompileUnitsInternal(dwarf: *DwarfInfo, allocator: *mem.SimpleAllocator, unit_off: u64) !u64 {
        const buf: [*]u8 = dwarf.info + unit_off;
        var unit_len: u64 = @ptrCast(*align(1) u32, buf).*;
        const word_size: WordSize = @intToEnum(WordSize, @boolToInt(unit_len == 0xffffffff));
        var pos: u64 = 0;
        pos +%= 4;
        if (word_size == .qword) {
            unit_len = @ptrCast(*align(1) u64, buf + pos).*;
            pos +%= 8;
        }
        if (unit_len == 0) {
            return pos;
        }
        if (word_size == .dword and unit_len >= 0xffffffff0) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        const next_off: u64 = pos +% unit_len;
        const version: u16 = @ptrCast(*align(1) u16, buf + pos).*;
        pos +%= 2;
        if (version < 2 or
            version > 5)
        {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        var addr_size: u8 = undefined;
        var abbrev_tab_off: u64 = undefined;
        if (version >= 5) {
            if (@intToEnum(UT, buf[pos]) != .compile) {
                builtin.proc.exitError(error.InvalidEncoding, 2);
            }
            pos +%= 1;
            addr_size = buf[pos];
            pos +%= 1;
            switch (word_size) {
                .qword => {
                    abbrev_tab_off = @ptrCast(*align(1) u64, buf + pos).*;
                    pos +%= 8;
                },
                .dword => {
                    abbrev_tab_off = @ptrCast(*align(1) u32, buf + pos).*;
                    pos +%= 4;
                },
            }
        } else {
            switch (word_size) {
                .qword => {
                    abbrev_tab_off = @ptrCast(*align(1) u64, buf + pos).*;
                    pos +%= 8;
                },
                .dword => {
                    abbrev_tab_off = @ptrCast(*align(1) u32, buf + pos).*;
                    pos +%= 4;
                },
            }
            addr_size = buf[pos];
            pos +%= 1;
        }
        if (addr_size != @sizeOf(usize)) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        if (debug_spec.logging.summary) {
            debug.unitAbstractNotice(version, unit_len, word_size, addr_size);
        }
        const unit: *Unit = try dwarf.createUnit(allocator, word_size, version, abbrev_tab_off, unit_off +% pos);
        pos +%= unit.info_entry_len;
        const info_entry: *InfoEntry = allocator.create(InfoEntry);
        while (pos < next_off) {
            const info_entry_off: u64 = unit_off +% pos;
            const info_entry_len: u64 = try parseInfoEntry(allocator, dwarf, word_size, unit.abbrev_tab, info_entry_off, info_entry);
            pos +%= info_entry_len;
            switch (info_entry.tag) {
                else => {},
                .subprogram,
                .inlined_subroutine,
                .subroutine,
                .entry_point,
                => dwarf.addFunc(allocator).* = .{
                    .name = try parseFuncName(allocator, dwarf, unit, info_entry, unit_off, next_off),
                    .range = try parseRange(dwarf, unit, info_entry),
                },
            }
        }
        return next_off;
    }
    pub fn scanAllCompileUnits(dwarf: *DwarfInfo, allocator: *mem.SimpleAllocator) !void {
        var unit_off: u64 = 0;
        while (unit_off < dwarf.info_len) {
            unit_off += try dwarf.scanAllCompileUnitsInternal(allocator, unit_off);
        }
    }
    fn createUnit(
        dwarf: *DwarfInfo,
        allocator: *mem.SimpleAllocator,
        word_size: WordSize,
        version: u16,
        abbrev_tab_off: u64,
        info_entry_off: u64,
    ) !*Unit {
        const ret: *Unit = dwarf.addUnit(allocator);
        const abbrev_tab: *AbbrevTable = dwarf.addAbbrevTable(allocator);
        const abbrev_tab_len: u64 = try parseAbbrevTable(allocator, dwarf, abbrev_tab_off, abbrev_tab);
        const info_entry: *InfoEntry = allocator.create(InfoEntry);
        const info_entry_len: u64 = try parseInfoEntry(allocator, dwarf, word_size, abbrev_tab, info_entry_off, info_entry);
        ret.* = .{
            .version = version,
            .word_size = word_size,
            .info_entry = info_entry,
            .info_entry_len = info_entry_len,
            .abbrev_tab = abbrev_tab,
            .abbrev_tab_len = abbrev_tab_len,
        };
        if (ret.info_entry.getAttr(.str_offsets_base)) |fv| {
            ret.str_offsets_base = try fv.getUInt(usize);
        }
        if (ret.info_entry.getAttr(.addr_base)) |fv| {
            ret.addr_base = try fv.getUInt(usize);
        }
        if (ret.info_entry.getAttr(.rnglists_base)) |fv| {
            ret.rnglists_base = try fv.getUInt(usize);
        }
        if (ret.info_entry.getAttr(.loclists_base)) |fv| {
            ret.loclists_base = try fv.getUInt(usize);
        }
        return ret;
    }
    fn parseFuncName(
        allocator: *mem.SimpleAllocator,
        dwarf: *DwarfInfo,
        unit: *const Unit,
        info_entry: *InfoEntry,
        unit_off: u64,
        next_off: u64,
    ) !?[]const u8 {
        var depth: i32 = 3;
        var cur_info_entry: InfoEntry = info_entry.*;
        while (depth > 0) : (depth -%= 1) {
            if (cur_info_entry.getAttr(.name)) |form_val| {
                return try getAttrString(dwarf, unit, form_val, dwarf.str[0..dwarf.str_len]);
            }
            if (cur_info_entry.getAttr(.abstract_origin)) |form_val| {
                if (form_val.* != .Ref) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                const ref_off: u64 = form_val.Ref;
                if (ref_off > next_off) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                _ = try parseInfoEntry(allocator, dwarf, unit.word_size, unit.abbrev_tab, unit_off +% ref_off, &cur_info_entry);
                continue;
            }
            if (cur_info_entry.getAttr(.specification)) |form_val| {
                if (form_val.* != .Ref) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                const ref_off: u64 = form_val.Ref;
                if (ref_off > next_off) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                _ = try parseInfoEntry(allocator, dwarf, unit.word_size, unit.abbrev_tab, unit_off +% ref_off, &cur_info_entry);
                continue;
            }
        }
        return null;
    }
    fn parseRange(dwarf: *DwarfInfo, unit: *const Unit, info_entry: *InfoEntry) !?Range {
        if (info_entry.getAttr(.low_pc)) |low_form_val| {
            const low_pc: u64 = switch (low_form_val.*) {
                .Address => |addr| addr,
                .AddrOffset => |off| try dwarf.readDebugAddr(unit.addr_base, off),
                else => builtin.proc.exitError(error.InvalidEncoding, 2),
            };
            if (info_entry.getAttr(.high_pc)) |high_form_val| {
                switch (high_form_val.*) {
                    .Address => |addr| return .{
                        .start = low_pc,
                        .end = addr,
                    },
                    .Const => |val| return .{
                        .start = low_pc,
                        .end = low_pc + try val.asUnsignedLe(),
                    },
                    else => builtin.proc.exitError(error.InvalidEncoding, 2),
                }
            }
        }
        return null;
    }
    fn parseAbbrevTable(
        allocator: *mem.SimpleAllocator,
        dwarf: *DwarfInfo,
        abbrev_tab_off: u64,
        abbrev_tab: *AbbrevTable,
    ) !u64 {
        const abbrev_bytes: []const u8 = dwarf.abbrev[abbrev_tab_off..dwarf.abbrev_len];
        var pos: u64 = 0;
        abbrev_tab.* = .{ .abbrev_tab_off = abbrev_tab_off };
        while (true) {
            const code = parse.noexcept.readLEB128(u64, abbrev_bytes[pos..]);
            pos +%= code[1];
            if (code[0] == 0) {
                break;
            }
            const tag = parse.noexcept.readLEB128(Tag, abbrev_bytes[pos..]);
            pos +%= tag[1];
            const ent: *AbbrevEntry = abbrev_tab.addEntry(allocator);
            ent.* = .{
                .code = code[0],
                .tag = tag[0],
                .children = @intToEnum(Children, abbrev_bytes[pos]),
            };
            pos +%= 1;
            while (true) {
                const attr = parse.noexcept.readLEB128(Attr, abbrev_bytes[pos..]);
                pos +%= attr[1];
                const form = parse.noexcept.readLEB128(Form, abbrev_bytes[pos..]);
                pos +%= form[1];
                if (attr[0] == .null and form[0] == .null) {
                    break;
                }
                const kv: *AbbrevEntry.KeyVal = ent.addKeyVal(allocator);
                if (form[0] == .implicit_const) {
                    const payload = parse.noexcept.readLEB128(i64, abbrev_bytes[pos..]);
                    pos +%= payload[1];
                    kv.* = .{ .attr = attr[0], .form = form[0], .payload = payload[0] };
                } else {
                    kv.* = .{ .attr = attr[0], .form = form[0] };
                }
            }
        }
        if (debug_spec.logging.abbrev_entry) {
            debug.abbrevTableNotice(abbrev_tab);
        }
        return pos;
    }
    fn parseInfoEntry(
        allocator: *mem.SimpleAllocator,
        dwarf: *DwarfInfo,
        word_size: WordSize,
        abbrev_tab: *const AbbrevTable,
        info_entry_off: u64,
        info_entry: *InfoEntry,
    ) !u64 {
        const info_entry_bytes: []u8 = dwarf.info[info_entry_off..dwarf.info_len];
        const code = parse.noexcept.readLEB128(u64, info_entry_bytes);
        var pos: u64 = code[1];
        if (code[0] == 0) {
            return pos;
        }
        const ent: AbbrevEntry = for (abbrev_tab.ents[0..abbrev_tab.ents_len]) |ent| {
            if (ent.code == code[0]) {
                break ent;
            }
        } else {
            testing.printN(32, .{code});
            builtin.proc.exitError(error.InvalidEncoding, 2);
        };
        info_entry.* = .{
            .tag = ent.tag,
            .children = ent.children,
        };
        for (ent.kvs[0..ent.kvs_len], 0..) |kv, kv_idx| {
            const res = try parseFormValue(allocator, word_size, info_entry_bytes[pos..], kv.form);
            info_entry.addKeyVal(allocator).* = .{ .key = kv.attr, .val = res[0] };
            pos +%= res[1];
            if (kv.form == .implicit_const) {
                info_entry.kvs[kv_idx].val.Const.payload = @bitCast(u64, kv.payload);
            }
        }
        if (debug_spec.logging.info_entry) {
            try debug.debugInfoEntryNotice(info_entry);
        }
        return pos;
    }
    fn getLineString(dwarf: DwarfInfo, offset: u64) ![]const u8 {
        return getStringGeneric(dwarf.line_str[0..dwarf.line_str_len], offset);
    }
    fn getString(dwarf: DwarfInfo, offset: u64) ![]const u8 {
        return getStringGeneric(dwarf.str[0..dwarf.str_len], offset);
    }
    fn readDebugAddr(dwarf: DwarfInfo, addr_base: u64, index: u64) !u64 {
        if (dwarf.addr_len == 0) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        if (addr_base < 8) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        const ver: u16 = @ptrCast(*align(1) u16, dwarf.addr + addr_base - 4).*;
        if (ver != 5) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        const addr_size: u8 = dwarf.addr[addr_base -% 2];
        const seg_size: u8 = dwarf.addr[addr_base -% 1];
        const off: u64 = @intCast(usize, addr_base +% (addr_size +% seg_size) *% index);
        if (off +% addr_size > dwarf.addr_len) {
            builtin.proc.exitError(error.InvalidEncoding, 2);
        }
        switch (addr_size) {
            1 => return dwarf.addr[off],
            2 => return @ptrCast(*align(1) u16, dwarf.addr + off).*,
            4 => return @ptrCast(*align(1) u32, dwarf.addr + off).*,
            8 => return @ptrCast(*align(1) u64, dwarf.addr + off).*,
            else => builtin.proc.exitError(error.InvalidEncoding, 2),
        }
    }
    pub fn getAttrString(dwarf: *DwarfInfo, unit: *const Unit, form_val: *const FormValue, opt_str: ?[]const u8) ![]const u8 {
        switch (form_val.*) {
            .String => |value| {
                return value;
            },
            .StrPtr => |offset| {
                return dwarf.getString(offset);
            },
            .StrOffset => |index| {
                if (dwarf.str_offsets_len == 0) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                const str_offsets: []u8 = dwarf.str_offsets[0..dwarf.str_offsets_len];
                if (unit.str_offsets_base == 0) {
                    builtin.proc.exitError(error.InvalidEncoding, 2);
                }
                if (unit.word_size == .qword) {
                    const off: usize = unit.str_offsets_base + (8 *% index);
                    if (off +% 8 > str_offsets.len) {
                        builtin.proc.exitError(error.InvalidEncoding, 2);
                    }
                    return getStringGeneric(opt_str, @ptrCast(*align(1) u64, dwarf.str_offsets + off).*);
                } else {
                    const off: usize = unit.str_offsets_base + (4 *% index);
                    if (off +% 4 > str_offsets.len) {
                        builtin.proc.exitError(error.InvalidEncoding, 2);
                    }
                    return getStringGeneric(opt_str, @ptrCast(*align(1) u32, dwarf.str_offsets + off).*);
                }
            },
            .LineStrPtr => |offset| {
                return dwarf.getLineString(offset);
            },
            else => builtin.proc.exitError(error.InvalidEncoding, 2),
        }
    }
    pub fn findCompileUnit(dwarf: *DwarfInfo, target_address: u64) !*const Unit {
        for (dwarf.units[0..dwarf.units_len]) |*unit| {
            if (unit.range) |range| {
                if (target_address >= range.start and
                    target_address < range.end)
                {
                    return unit;
                }
            }
            const gev5: bool = unit.version >= 5;
            const ranges_len: u64 = mach.cmov64(gev5, dwarf.rnglists_len, dwarf.ranges_len);
            const ranges: [*]u8 = mach.cmovx(gev5, dwarf.rnglists, dwarf.ranges);

            const ranges_val = unit.info_entry.getAttr(.ranges) orelse continue;

            const ranges_offset = switch (ranges_val.*) {
                .SecOffset => |off| off,
                .RangeListOffset => |idx| off: {
                    if (unit.word_size == .qword) {
                        const off: usize = unit.rnglists_base + (8 *% idx);
                        if (off +% 8 > ranges_len) {
                            builtin.proc.exitError(error.InvalidEncoding, 2);
                        }
                        break :off @ptrCast(*align(1) u64, ranges + off).*;
                    } else {
                        const off: usize = unit.rnglists_base + (4 *% idx);
                        if (off +% 4 > ranges_len) {
                            builtin.proc.exitError(error.InvalidEncoding, 2);
                        }
                        break :off @ptrCast(*align(1) u32, ranges + off).*;
                    }
                },
                else => return error.InvalidEncoding,
            };

            // All the addresses in the list are relative to the value
            // specified by DW_AT.low_pc or to some other value encoded
            // in the list itself.
            // If no starting value is specified use zero.
            var base_address = unit.info_entry.getAttrAddr(dwarf, .low_pc, unit.*) catch |err| switch (err) {
                error.MissingDebugInfo => @as(u64, 0), // TODO https://github.com/ziglang/zig/issues/11135
                else => return err,
            };
            const buf: [*]u8 = dwarf.ranges;
            var pos: u64 = ranges_offset;
            if (unit.version < 5) {
                while (true) {
                    const begin_addr: u64 = @ptrCast(*align(1) usize, buf + pos).*;
                    pos +%= @sizeOf(usize);
                    const end_addr: u64 = @ptrCast(*align(1) usize, buf + pos).*;
                    pos +%= @sizeOf(usize);
                    if (begin_addr == 0 and end_addr == 0) {
                        break;
                    }
                    // This entry selects a new value for the base address
                    if (begin_addr == ~@as(usize, 0)) {
                        base_address = end_addr;
                        continue;
                    }
                    if (target_address >= base_address + begin_addr and target_address < base_address + end_addr) {
                        return unit;
                    }
                }
            } else {
                while (true) {
                    const kind: RLE = @intToEnum(RLE, buf[pos]);
                    pos +%= 1;
                    switch (kind) {
                        RLE.end_of_list => break,
                        RLE.base_addressx => {
                            const idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            pos +%= idx[1];
                            base_address = try dwarf.readDebugAddr(unit.addr_base, idx[0]);
                        },
                        RLE.startx_endx => {
                            const start_idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            pos +%= start_idx[1];
                            const start_addr: usize = try dwarf.readDebugAddr(unit.addr_base, start_idx[0]);

                            const end_idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            pos +%= end_idx[1];
                            const end_addr: usize = try dwarf.readDebugAddr(unit.addr_base, end_idx[0]);

                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        RLE.startx_length => {
                            const start_index = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            const start_addr = try dwarf.readDebugAddr(unit.addr_base, start_index[0]);
                            const len = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            const end_addr: u64 = start_addr + len[0];

                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        RLE.offset_pair => {
                            const start_addr = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            pos +%= start_addr[1];
                            const end_addr = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            pos +%= end_addr[1];
                            // This is the only kind that uses the base address
                            if (target_address >= base_address + start_addr[0] and
                                target_address < base_address + end_addr[0])
                            {
                                return unit;
                            }
                        },
                        RLE.base_address => {
                            base_address = @ptrCast(*align(1) usize, buf + pos).*;
                            pos +%= @sizeOf(usize);
                        },
                        RLE.start_end => {
                            const start_addr = @ptrCast(*align(1) usize, buf + pos).*;
                            pos +%= @sizeOf(usize);
                            const end_addr = @ptrCast(*align(1) usize, buf + pos).*;
                            pos +%= @sizeOf(usize);
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        RLE.start_length => {
                            const start_addr = @ptrCast(*align(1) usize, buf + pos).*;
                            pos +%= @sizeOf(usize);
                            const len = parse.noexcept.readLEB128(usize, buf[pos..dwarf.ranges_len]);
                            const end_addr = start_addr + len[0];
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                    }
                }
            }
        }
        return error.MissingDebugInfo;
    }
};
fn getStringGeneric(opt_str: ?[]const u8, offset: u64) ![:0]const u8 {
    const str = opt_str orelse {
        builtin.proc.exitError(error.InvalidEncoding, 2);
    };
    if (offset > str.len) {
        builtin.proc.exitError(error.InvalidEncoding, 2);
    }
    const last = mem.indexOfFirstEqualOne(u8, 0, str[offset..]) orelse {
        builtin.proc.exitError(error.InvalidEncoding, 2);
    };
    return str[offset .. offset +% last :0];
}
fn parseFormValue(allocator: *mem.SimpleAllocator, size: WordSize, bytes: []u8, form: Form) !struct { FormValue, u64 } {
    switch (form) {
        .addr => return .{ .{ .Address = @ptrCast(*align(1) usize, bytes).* }, @sizeOf(u64) },
        .block2 => {
            const blk_len: u16 = @ptrCast(*align(1) u16, bytes).*;
            return .{ FormValue{ .Block = bytes[2 .. 2 +% blk_len] }, 2 +% blk_len };
        },
        .block4 => {
            const blk_len: u32 = @ptrCast(*align(1) u32, bytes).*;
            return .{ FormValue{ .Block = bytes[4 .. 4 +% blk_len] }, 4 +% blk_len };
        },
        .data2 => return .{ .{ .Const = .{ .signed = false, .payload = @ptrCast(*align(1) u16, bytes).* } }, 2 },
        .data4 => return .{ .{ .Const = .{ .signed = false, .payload = @ptrCast(*align(1) u32, bytes).* } }, 4 },
        .data8 => return .{ .{ .Const = .{ .signed = false, .payload = @ptrCast(*align(1) u64, bytes).* } }, 8 },
        .string => {
            const str: [:0]u8 = mach.manyToSlice80(bytes.ptr);
            return .{ .{ .String = str }, str.len };
        },
        .block => {
            const len = parse.noexcept.readLEB128(usize, bytes);
            const blk_len: usize = mem.readIntVar(usize, bytes, len[0]);
            return .{ FormValue{ .Block = bytes[len[0] .. len[0] +% blk_len] }, len[0] +% blk_len };
        },
        .block1 => {
            const blk_len: u8 = @ptrCast(*align(1) u8, bytes).*;
            return .{ FormValue{ .Block = bytes[1 .. 1 +% blk_len] }, 1 +% blk_len };
        },
        .data1 => return .{ .{ .Const = .{ .signed = false, .payload = @ptrCast(*align(1) u8, bytes).* } }, 1 },
        .flag => return .{ .{ .Flag = bytes[0] != 0 }, 1 },
        .udata => {
            const res = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .Const = .{ .signed = false, .payload = res[0] } }, res[1] };
        },
        .sdata => {
            const res = parse.noexcept.readLEB128(i64, bytes);
            return .{ .{ .Const = .{ .signed = true, .payload = @bitCast(u64, res[0]) } }, res[1] };
        },
        .strp => switch (size) {
            .dword => return .{ .{ .StrPtr = @ptrCast(*align(1) u32, bytes).* }, @sizeOf(u32) },
            .qword => return .{ .{ .StrPtr = @ptrCast(*align(1) u64, bytes).* }, @sizeOf(u64) },
        },
        .ref_addr => switch (size) {
            .dword => return .{ .{ .RefAddr = @ptrCast(*align(1) u32, bytes).* }, @sizeOf(u32) },
            .qword => return .{ .{ .RefAddr = @ptrCast(*align(1) u64, bytes).* }, @sizeOf(u64) },
        },
        .ref1 => return .{ .{ .Ref = @ptrCast(*align(1) u8, bytes).* }, 1 },
        .ref2 => return .{ .{ .Ref = @ptrCast(*align(1) u16, bytes).* }, 2 },
        .ref4 => return .{ .{ .Ref = @ptrCast(*align(1) u32, bytes).* }, 4 },
        .ref8 => return .{ .{ .Ref = @ptrCast(*align(1) u64, bytes).* }, 8 },
        .ref_udata => {
            const res = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .Ref = res[0] }, res[1] };
        },
        .indirect => {
            const child = parse.noexcept.readLEB128(Form, bytes);
            const res = try parseFormValue(allocator, size, bytes[child[1]..], child[0]);
            return .{ res[0], child[1] +% res[1] };
        },
        .sec_offset => switch (size) {
            .dword => return .{ .{ .SecOffset = @ptrCast(*align(1) u32, bytes).* }, @sizeOf(u32) },
            .qword => return .{ .{ .SecOffset = @ptrCast(*align(1) u64, bytes).* }, @sizeOf(u64) },
        },
        .exprloc => {
            const loc = parse.noexcept.readLEB128(usize, bytes);
            const expr: []u8 = allocator.allocate(u8, loc[0]);
            mach.memcpy(expr.ptr, bytes[loc[1]..].ptr, expr.len);
            return .{ .{ .ExprLoc = expr }, loc[1] +% expr.len };
        },
        .flag_present => return .{ .{ .Flag = true }, 0 },
        .strx => {
            const off = parse.noexcept.readLEB128(usize, bytes);
            return .{ .{ .StrOffset = off[0] }, off[1] };
        },
        .addrx => {
            const off = parse.noexcept.readLEB128(usize, bytes);
            return .{ .{ .AddrOffset = off[0] }, off[1] };
        },
        .data16 => {
            var data: [16]u8 = undefined;
            mach.memcpy(&data, bytes.ptr, 16);
            return .{ .{ .data16 = data }, 16 };
        },
        .line_strp => switch (size) {
            .dword => return .{ .{ .LineStrPtr = @ptrCast(*align(1) u32, bytes).* }, @sizeOf(u32) },
            .qword => return .{ .{ .LineStrPtr = @ptrCast(*align(1) u64, bytes).* }, @sizeOf(u64) },
        },
        .ref_sig8 => return .{ .{ .RefAddr = @ptrCast(*align(1) u64, bytes).* }, @sizeOf(u64) },
        .implicit_const => return .{ .{ .Const = .{ .signed = true, .payload = undefined } }, 0 },
        .loclistx => {
            const off = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .LocListOffset = off[0] }, off[1] };
        },
        .rnglistx => {
            const off = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .RangeListOffset = off[0] }, off[1] };
        },
        .strx1 => return .{ .{ .StrOffset = @ptrCast(*align(1) u8, bytes).* }, 1 },
        .strx2 => return .{ .{ .StrOffset = @ptrCast(*align(1) u16, bytes).* }, 2 },
        .strx3 => return .{ .{ .StrOffset = @ptrCast(*align(1) u24, bytes).* }, 3 },
        .strx4 => return .{ .{ .StrOffset = @ptrCast(*align(1) u32, bytes).* }, 4 },
        .addrx1 => return .{ .{ .AddrOffset = @ptrCast(*align(1) u8, bytes).* }, 1 },
        .addrx2 => return .{ .{ .AddrOffset = @ptrCast(*align(1) u16, bytes).* }, 2 },
        .addrx3 => return .{ .{ .AddrOffset = @ptrCast(*align(1) u32, bytes).* }, 3 },
        .addrx4 => return .{ .{ .AddrOffset = @ptrCast(*align(1) u64, bytes).* }, 4 },
        else => {
            builtin.proc.exitErrorFault(error.UnhandledFormValueType, @tagName(form), 2);
        },
    }
}
pub const Tag = enum(u64) {
    padding = 0x00,
    array_type = 0x01,
    class_type = 0x02,
    entry_point = 0x03,
    enumeration_type = 0x04,
    formal_parameter = 0x05,
    imported_declaration = 0x08,
    label = 0x0a,
    lexical_block = 0x0b,
    member = 0x0d,
    pointer_type = 0x0f,
    reference_type = 0x10,
    compile_unit = 0x11,
    string_type = 0x12,
    structure_type = 0x13,
    subroutine = 0x14,
    subroutine_type = 0x15,
    typedef = 0x16,
    union_type = 0x17,
    unspecified_parameters = 0x18,
    variant = 0x19,
    common_block = 0x1a,
    common_inclusion = 0x1b,
    inheritance = 0x1c,
    inlined_subroutine = 0x1d,
    module = 0x1e,
    ptr_to_member_type = 0x1f,
    set_type = 0x20,
    subrange_type = 0x21,
    with_stmt = 0x22,
    access_declaration = 0x23,
    base_type = 0x24,
    catch_block = 0x25,
    const_type = 0x26,
    constant = 0x27,
    enumerator = 0x28,
    file_type = 0x29,
    friend = 0x2a,
    namelist = 0x2b,
    namelist_item = 0x2c,
    packed_type = 0x2d,
    subprogram = 0x2e,
    template_type_param = 0x2f,
    template_value_param = 0x30,
    thrown_type = 0x31,
    try_block = 0x32,
    variant_part = 0x33,
    variable = 0x34,
    volatile_type = 0x35,
    // DWARF 3
    dwarf_procedure = 0x36,
    restrict_type = 0x37,
    interface_type = 0x38,
    namespace = 0x39,
    imported_module = 0x3a,
    unspecified_type = 0x3b,
    partial_unit = 0x3c,
    imported_unit = 0x3d,
    condition = 0x3f,
    shared_type = 0x40,
    // DWARF 4
    type_unit = 0x41,
    rvalue_reference_type = 0x42,
    template_alias = 0x43,
    // DWARF 5
    coarray_type = 0x44,
    generic_subrange = 0x45,
    dynamic_type = 0x46,
    atomic_type = 0x47,
    call_site = 0x48,
    call_site_parameter = 0x49,
    skeleton_unit = 0x4a,
    immutable_type = 0x4b,
    lo_user = 0x4080,
    hi_user = 0xffff,
    MIPS_loop = 0x4081,
    HP_array_descriptor = 0x4090,
    HP_Bliss_field = 0x4091,
    HP_Bliss_field_set = 0x4092,
    format_label = 0x4101,
    function_template = 0x4102,
    class_template = 0x4103,
    GNU_BINCL = 0x4104,
    GNU_EINCL = 0x4105,
    GNU_template_template_param = 0x4106,
    GNU_template_parameter_pack = 0x4107,
    GNU_formal_parameter_pack = 0x4108,
    GNU_call_site = 0x4109,
    GNU_call_site_parameter = 0x410a,
    upc_shared_type = 0x8765,
    upc_strict_type = 0x8766,
    upc_relaxed_type = 0x8767,
    PGI_kanji_type = 0xA000,
    PGI_interface_block = 0xA020,
};
pub const Attr = enum(u64) {
    null = 0x00,
    sibling = 0x01,
    location = 0x02,
    name = 0x03,
    ordering = 0x09,
    subscr_data = 0x0a,
    byte_size = 0x0b,
    bit_offset = 0x0c,
    bit_size = 0x0d,
    element_list = 0x0f,
    stmt_list = 0x10,
    low_pc = 0x11,
    high_pc = 0x12,
    language = 0x13,
    member = 0x14,
    discr = 0x15,
    discr_value = 0x16,
    visibility = 0x17,
    import = 0x18,
    string_length = 0x19,
    common_reference = 0x1a,
    comp_dir = 0x1b,
    const_value = 0x1c,
    containing_type = 0x1d,
    default_value = 0x1e,
    @"inline" = 0x20,
    is_optional = 0x21,
    lower_bound = 0x22,
    producer = 0x25,
    prototyped = 0x27,
    return_addr = 0x2a,
    start_scope = 0x2c,
    bit_stride = 0x2e,
    upper_bound = 0x2f,
    abstract_origin = 0x31,
    accessibility = 0x32,
    address_class = 0x33,
    artificial = 0x34,
    base_types = 0x35,
    calling_convention = 0x36,
    count = 0x37,
    data_member_location = 0x38,
    decl_column = 0x39,
    decl_file = 0x3a,
    decl_line = 0x3b,
    declaration = 0x3c,
    discr_list = 0x3d,
    encoding = 0x3e,
    external = 0x3f,
    frame_base = 0x40,
    friend = 0x41,
    identifier_case = 0x42,
    macro_info = 0x43,
    namelist_items = 0x44,
    priority = 0x45,
    segment = 0x46,
    specification = 0x47,
    static_link = 0x48,
    type = 0x49,
    use_location = 0x4a,
    variable_parameter = 0x4b,
    virtuality = 0x4c,
    vtable_elem_location = 0x4d,
    // DWARF 3 values.
    allocated = 0x4e,
    associated = 0x4f,
    data_location = 0x50,
    byte_stride = 0x51,
    entry_pc = 0x52,
    use_UTF8 = 0x53,
    extension = 0x54,
    ranges = 0x55,
    trampoline = 0x56,
    call_column = 0x57,
    call_file = 0x58,
    call_line = 0x59,
    description = 0x5a,
    binary_scale = 0x5b,
    decimal_scale = 0x5c,
    small = 0x5d,
    decimal_sign = 0x5e,
    digit_count = 0x5f,
    picture_string = 0x60,
    mutable = 0x61,
    threads_scaled = 0x62,
    explicit = 0x63,
    object_pointer = 0x64,
    endianity = 0x65,
    elemental = 0x66,
    pure = 0x67,
    recursive = 0x68,
    // DWARF 4.
    signature = 0x69,
    main_subprogram = 0x6a,
    data_bit_offset = 0x6b,
    const_expr = 0x6c,
    enum_class = 0x6d,
    linkage_name = 0x6e,
    // DWARF 5
    string_length_bit_size = 0x6f,
    string_length_byte_size = 0x70,
    rank = 0x71,
    str_offsets_base = 0x72,
    addr_base = 0x73,
    rnglists_base = 0x74,
    dwo_name = 0x76,
    reference = 0x77,
    rvalue_reference = 0x78,
    macros = 0x79,
    call_all_calls = 0x7a,
    call_all_source_calls = 0x7b,
    call_all_tail_calls = 0x7c,
    call_return_pc = 0x7d,
    call_value = 0x7e,
    call_origin = 0x7f,
    call_parameter = 0x80,
    call_pc = 0x81,
    call_tail_call = 0x82,
    call_target = 0x83,
    call_target_clobbered = 0x84,
    call_data_location = 0x85,
    call_data_value = 0x86,
    noreturn = 0x87,
    alignment = 0x88,
    export_symbols = 0x89,
    deleted = 0x8a,
    defaulted = 0x8b,
    loclists_base = 0x8c,
    lo_user = 0x2000, // Implementation-defined range start.
    hi_user = 0x3fff, // Implementation-defined range end.
    // GNU extensions.
    sf_names = 0x2101,
    src_info = 0x2102,
    mac_info = 0x2103,
    src_coords = 0x2104,
    body_begin = 0x2105,
    body_end = 0x2106,
    GNU_vector = 0x2107,
    GNU_guarded_by = 0x2108,
    GNU_pt_guarded_by = 0x2109,
    GNU_guarded = 0x210a,
    GNU_pt_guarded = 0x210b,
    GNU_locks_excluded = 0x210c,
    GNU_exclusive_locks_required = 0x210d,
    GNU_shared_locks_required = 0x210e,
    GNU_odr_signature = 0x210f,
    GNU_template_name = 0x2110,
    GNU_call_site_value = 0x2111,
    GNU_call_site_data_value = 0x2112,
    GNU_call_site_target = 0x2113,
    GNU_call_site_target_clobbered = 0x2114,
    GNU_tail_call = 0x2115,
    GNU_all_tail_call_sites = 0x2116,
    GNU_all_call_sites = 0x2117,
    GNU_all_source_call_sites = 0x2118,
    GNU_macros = 0x2119,
    GNU_dwo_name = 0x2130,
    GNU_dwo_id = 0x2131,
    GNU_ranges_base = 0x2132,
    GNU_addr_base = 0x2133,
    GNU_pubnames = 0x2134,
    GNU_pubtypes = 0x2135,
    VMS_rtnbeg_pd_address = 0x2201,
    use_GNAT_descriptive_type = 0x2301,
    GNAT_descriptive_type = 0x2302,
    upc_threads_scaled = 0x3210,
    other,
    _,
    // PGI (STMicroelectronics) extensions.
    const PGI = enum(u64) {
        PGI_lbase = 0x3a00,
        PGI_soffset = 0x3a01,
        PGI_lstride = 0x3a02,
    };
    // SGI/MIPS extensions.
    const MIPS = enum(u64) {
        MIPS_fde = 0x2001,
        MIPS_loop_begin = 0x2002,
        MIPS_tail_loop_begin = 0x2003,
        MIPS_epilog_begin = 0x2004,
        MIPS_loop_unroll_factor = 0x2005,
        MIPS_software_pipeline_depth = 0x2006,
        MIPS_linkage_name = 0x2007,
        MIPS_stride = 0x2008,
        MIPS_abstract_name = 0x2009,
        MIPS_clone_origin = 0x200a,
        MIPS_has_inlines = 0x200b,
    };
    // HP extensions.
    const HP = enum(u64) {
        HP_block_index = 0x2000,
        HP_unmodifiable = 0x2001, // Same as AT.MIPS_fde.
        HP_prologue = 0x2005, // Same as AT.MIPS_loop_unroll.
        HP_epilogue = 0x2008, // Same as AT.MIPS_stride.
        HP_actuals_stmt_list = 0x2010,
        HP_proc_per_section = 0x2011,
        HP_raw_data_ptr = 0x2012,
        HP_pass_by_reference = 0x2013,
        HP_opt_level = 0x2014,
        HP_prof_version_id = 0x2015,
        HP_opt_flags = 0x2016,
        HP_cold_region_low_pc = 0x2017,
        HP_cold_region_high_pc = 0x2018,
        HP_all_variables_modifiable = 0x2019,
        HP_linkage_name = 0x201a,
        HP_prof_flags = 0x201b, // In comp unit of procs_info for -g.
        HP_unit_name = 0x201f,
        HP_unit_size = 0x2020,
        HP_widened_byte_size = 0x2021,
        HP_definition_points = 0x2022,
        HP_default_location = 0x2023,
        HP_is_result_param = 0x2029,
    };
};
pub const Form = enum(u64) {
    null = 0x00,
    addr = 0x01,
    block2 = 0x03,
    block4 = 0x04,
    data2 = 0x05,
    data4 = 0x06,
    data8 = 0x07,
    string = 0x08,
    block = 0x09,
    block1 = 0x0a,
    data1 = 0x0b,
    flag = 0x0c,
    sdata = 0x0d,
    strp = 0x0e,
    udata = 0x0f,
    ref_addr = 0x10,
    ref1 = 0x11,
    ref2 = 0x12,
    ref4 = 0x13,
    ref8 = 0x14,
    ref_udata = 0x15,
    indirect = 0x16,
    sec_offset = 0x17,
    exprloc = 0x18,
    flag_present = 0x19,
    strx = 0x1a,
    addrx = 0x1b,
    ref_sup4 = 0x1c,
    strp_sup = 0x1d,
    data16 = 0x1e,
    line_strp = 0x1f,
    ref_sig8 = 0x20,
    implicit_const = 0x21,
    loclistx = 0x22,
    rnglistx = 0x23,
    ref_sup8 = 0x24,
    strx1 = 0x25,
    strx2 = 0x26,
    strx3 = 0x27,
    strx4 = 0x28,
    addrx1 = 0x29,
    addrx2 = 0x2a,
    addrx3 = 0x2b,
    addrx4 = 0x2c,
    GNU_addr_index = 0x1f01,
    GNU_str_index = 0x1f02,
    GNU_ref_alt = 0x1f20,
    GNU_strp_alt = 0x1f21,
    other,
    _,
};
const LLE = enum(u8) {
    end_of_list = 0x00,
    base_addressx = 0x01,
    startx_endx = 0x02,
    startx_length = 0x03,
    offset_pair = 0x04,
    default_location = 0x05,
    base_address = 0x06,
    start_end = 0x07,
    start_length = 0x08,
};
const CFA = enum(u8) {
    advance_loc = 0x40,
    offset = 0x80,
    restore = 0xc0,
    nop = 0x00,
    set_loc = 0x01,
    advance_loc1 = 0x02,
    advance_loc2 = 0x03,
    advance_loc4 = 0x04,
    offset_extended = 0x05,
    restore_extended = 0x06,
    undefined = 0x07,
    same_value = 0x08,
    register = 0x09,
    remember_state = 0x0a,
    restore_state = 0x0b,
    def_cfa = 0x0c,
    def_cfa_register = 0x0d,
    def_cfa_offset = 0x0e,
    // DWARF 3.
    def_cfa_expression = 0x0f,
    expression = 0x10,
    offset_extended_sf = 0x11,
    def_cfa_sf = 0x12,
    def_cfa_offset_sf = 0x13,
    val_offset = 0x14,
    val_offset_sf = 0x15,
    val_expression = 0x16,
    lo_user = 0x1c,
    hi_user = 0x3f,
    // SGI/MIPS specific.
    MIPS_advance_loc8 = 0x1d,
    // GNU extensions.
    GNU_window_save = 0x2d,
    GNU_args_size = 0x2e,
    GNU_negative_offset_extended = 0x2f,
};
const Children = enum(u8) {
    no = 0x00,
    yes = 0x01,
};
const LNS = enum(u8) {
    extended_op = 0x00,
    copy = 0x01,
    advance_pc = 0x02,
    advance_line = 0x03,
    set_file = 0x04,
    set_column = 0x05,
    negate_stmt = 0x06,
    set_basic_block = 0x07,
    const_add_pc = 0x08,
    fixed_advance_pc = 0x09,
    set_prologue_end = 0x0a,
    set_epilogue_begin = 0x0b,
    set_isa = 0x0c,
};
const LNE = enum(u8) {
    end_sequence = 0x01,
    set_address = 0x02,
    define_file = 0x03,
    set_discriminator = 0x04,
    lo_user = 0x80,
    hi_user = 0xff,
};
const UT = enum(u8) {
    compile = 0x01,
    type = 0x02,
    partial = 0x03,
    skeleton = 0x04,
    split_compile = 0x05,
    split_type = 0x06,
    lo_user = 0x80,
    hi_user = 0xff,
};
const LNCT = enum(u8) {
    path = 0x1,
    directory_index = 0x2,
    timestamp = 0x3,
    size = 0x4,
    MD5 = 0x5,
    lo_user = 0x2000,
    hi_user = 0x3fff,
};
const RLE = enum(u8) {
    end_of_list = 0x00,
    base_addressx = 0x01,
    startx_endx = 0x02,
    startx_length = 0x03,
    offset_pair = 0x04,
    base_address = 0x05,
    start_end = 0x06,
    start_length = 0x07,
};
const CC = enum(u8) {
    normal = 0x1,
    program = 0x2,
    nocall = 0x3,
    pass_by_reference = 0x4,
    pass_by_value = 0x5,
    lo_user = 0x40,
    hi_user = 0xff,
    GNU_renesas_sh = 0x40,
    GNU_borland_fastcall_i386 = 0x41,
};

const debug = struct {
    const LineInfo = struct {
        line: u64,
        column: u64,
        file: []const u8,
    };
    const about_dwarf: [:0]const u8 = builtin.fmt.about("dwarf");
    const about_abbrev_tab: [:0]const u8 = builtin.fmt.about("abbrev");
    const about_abbrev_code: [:0]const u8 = builtin.fmt.about("code");
    const about_debug_entry: [:0]const u8 = builtin.fmt.about("full");
    const about_dwarf_version: [:0]const u8 = builtin.fmt.about("dwarf-version");
    const about_dwarf_addrsize: [:0]const u8 = builtin.fmt.about("dwarf-addrsize");
    fn printIntAt(src: builtin.SourceLocation, msg: []const u8, int: u64) void {
        var buf: [512]u8 = undefined;
        var len: u64 = 0;
        mach.memcpy(&buf, src.fn_name.ptr, src.fn_name.len);
        len +%= src.fn_name.len;
        @ptrCast(*[2]u8, buf[len..].ptr).* = ": ".*;
        len +%= 2;
        mach.memcpy(buf[len..].ptr, msg.ptr, msg.len);
        len +%= msg.len;
        const int_s: []const u8 = builtin.fmt.ud64(int).readAll();
        mach.memcpy(buf[len..].ptr, int_s.ptr, int_s.len);
        len +%= int_s.len;
        buf[len] = '\n';
        len +%= 1;
        builtin.debug.write(buf[0..len]);
    }
    fn unitAbstractNotice(ver: u16, unit_len: u64, word_size: WordSize, addr_size: u8) void {
        const ver_s: []const u8 = builtin.fmt.ud64(ver).readAll();
        const unit_len_s: []const u8 = builtin.fmt.ud64(unit_len).readAll();
        const word_size_s: []const u8 = @tagName(word_size);
        const addr_size_s: []const u8 = builtin.fmt.ud64(addr_size).readAll();
        var buf: [512]u8 = undefined;
        var len: u64 = 0;
        mach.memcpy(&buf, about_dwarf.ptr, about_dwarf.len);
        len +%= about_dwarf.len;
        @ptrCast(*[4]u8, buf[len..].ptr).* = "ver=".*;
        len +%= 4;
        mach.memcpy(buf[len..].ptr, ver_s.ptr, ver_s.len);
        len +%= ver_s.len;
        @ptrCast(*[11]u8, buf[len..].ptr).* = ", unit_len=".*;
        len +%= 11;
        mach.memcpy(buf[len..].ptr, unit_len_s.ptr, unit_len_s.len);
        len +%= unit_len_s.len;
        @ptrCast(*[12]u8, buf[len..].ptr).* = ", word_size=".*;
        len +%= 12;
        mach.memcpy(buf[len..].ptr, word_size_s.ptr, word_size_s.len);
        len +%= word_size_s.len;
        @ptrCast(*[12]u8, buf[len..].ptr).* = ", addr_size=".*;
        len +%= 12;
        mach.memcpy(buf[len..].ptr, addr_size_s.ptr, addr_size_s.len);
        len +%= addr_size_s.len;
        buf[len] = '\n';
        builtin.debug.write(buf[0 .. len +% 1]);
    }
    fn abbrevTableNotice(abbrev_tab: *AbbrevTable) void {
        @setRuntimeSafety(false);
        var buf: [512]u8 = undefined;
        builtin.debug.write(about_abbrev_tab ++ "\n");
        for (abbrev_tab.ents[0..abbrev_tab.ents_len]) |*ent| {
            const tag_id_s: []const u8 = @tagName(ent.tag);
            const code_s: []const u8 = builtin.fmt.ud64(ent.code).readAll();
            builtin.debug.logAlwaysAIO(&buf, &.{ about_abbrev_code, code_s, ", ", tag_id_s, "\n" });
            for (ent.kvs[0..ent.kvs_len], 0..) |*kv, kv_idx| {
                var len: u64 = 0;
                const kv_idx_s: []const u8 = builtin.fmt.ud64(kv_idx).readAll();
                mach.memset(buf[len..].ptr, ' ', 4 -% kv_idx_s.len);
                len +%= 4 -% kv_idx_s.len;
                mach.memcpy(buf[len..].ptr, kv_idx_s.ptr, kv_idx_s.len);
                len +%= kv_idx_s.len;
                buf[len] = ':';
                len +%= 1;
                mach.memset(buf[len..].ptr, ' ', 11);
                len +%= 11;
                const attr_s: []const u8 = @tagName(kv.attr);
                mach.memcpy(buf[len..].ptr, attr_s.ptr, attr_s.len);
                len +%= attr_s.len;
                @ptrCast(*[2]u8, buf[len..].ptr).* = ": ".*;
                len +%= 2;
                const form_s: []const u8 = @tagName(kv.form);
                mach.memcpy(buf[len..].ptr, form_s.ptr, form_s.len);
                len +%= form_s.len;
                if (kv.payload != 0) {
                    @ptrCast(*[3]u8, buf[len..].ptr).* = " = ".*;
                    len +%= 3;
                    const payload_s: []const u8 = builtin.fmt.id64(kv.payload).readAll();
                    mach.memcpy(buf[len..].ptr, payload_s.ptr, payload_s.len);
                    len +%= payload_s.len;
                }
                buf[len] = '\n';
                len +%= 1;
                builtin.debug.write(buf[0..len]);
            }
        }
    }
    fn debugInfoEntryNotice(info_entry: *InfoEntry) !void {
        @setRuntimeSafety(false);
        var buf: [512]u8 = undefined;
        const tag_id_s: []const u8 = @tagName(info_entry.tag);
        builtin.debug.logAlwaysAIO(&buf, &.{ about_debug_entry, tag_id_s, "\n" });
        for (info_entry.kvs[0..info_entry.kvs_len], 0..) |*kv, kv_idx| {
            var len: u64 = 0;
            const attr_idx_s: []const u8 = builtin.fmt.ud64(kv_idx).readAll();
            mach.memset(buf[len..].ptr, ' ', 4 -% attr_idx_s.len);
            len +%= 4 -% attr_idx_s.len;
            mach.memcpy(buf[len..].ptr, attr_idx_s.ptr, attr_idx_s.len);
            len +%= attr_idx_s.len;
            buf[len] = ':';
            len +%= 1;
            mach.memset(buf[len..].ptr, ' ', 11);
            len +%= 11;
            const attr_id_s: []const u8 = @tagName(kv.key);
            mach.memcpy(buf[len..].ptr, attr_id_s.ptr, attr_id_s.len);
            len +%= attr_id_s.len;
            @ptrCast(*[2]u8, buf[len..].ptr).* = ": ".*;
            len +%= 2;
            const attr_type_s: []const u8 = @tagName(kv.val);
            mach.memcpy(buf[len..].ptr, attr_type_s.ptr, attr_type_s.len);
            len +%= attr_type_s.len;
            @ptrCast(*[3]u8, buf[len..].ptr).* = " = ".*;
            len +%= 3;
            switch (kv.val) {
                .Address => |addr| {
                    const addr_s: []const u8 = builtin.fmt.ux64(addr).readAll();
                    mach.memcpy(buf[len..].ptr, addr_s.ptr, addr_s.len);
                },
                .AddrOffset => |addrx| {
                    const addrx_s: []const u8 = builtin.fmt.ud64(addrx).readAll();
                    mach.memcpy(buf[len..].ptr, addrx_s.ptr, addrx_s.len);
                },
                .Block => |block| {
                    builtin.debug.write(block);
                },
                .Const => |val| {
                    if (val.signed) {
                        const signed: i64 = val.asSignedLe() catch continue;
                        const signed_s: []const u8 = builtin.fmt.id64(signed).readAll();
                        mach.memcpy(buf[len..].ptr, signed_s.ptr, signed_s.len);
                        len +%= signed_s.len;
                    } else {
                        const unsigned: u64 = val.asUnsignedLe() catch continue;
                        const unsigned_s: []const u8 = builtin.fmt.ud64(unsigned).readAll();
                        mach.memcpy(buf[len..].ptr, unsigned_s.ptr, unsigned_s.len);
                        len +%= unsigned_s.len;
                    }
                },
                .ExprLoc => |exprloc| {
                    _ = exprloc;
                },
                .Flag => |flag| {
                    _ = flag;
                },
                .SecOffset => |sec_offset| {
                    const sec_offset_s: []const u8 = builtin.fmt.ud64(sec_offset).readAll();
                    _ = sec_offset_s;
                },
                .Ref => |ref| {
                    _ = ref;
                },
                .RefAddr => |ref_addr| {
                    const addr_s: []const u8 = builtin.fmt.ux64(ref_addr).readAll();
                    _ = addr_s;
                },
                .String => |str| {
                    _ = str;
                },
                .StrPtr => |strp| {
                    _ = strp;
                },
                .StrOffset => |strx| {
                    _ = strx;
                },
                .LineStrPtr => |line_strp| {
                    _ = line_strp;
                },
                .LocListOffset => |loclistx| {
                    _ = loclistx;
                },
                .RangeListOffset => |rnglistx| {
                    _ = rnglistx;
                },
                else => {},
            }
            buf[len] = '\n';
            len +%= 1;
            builtin.debug.write(buf[0..len]);
        }
    }
};
pub fn self(allocator: *mem.SimpleAllocator) DwarfInfo {
    var st: file.Status = undefined;
    const fd: u64 = sys.call_noexcept(.open, u64, .{ @ptrToInt("/proc/self/exe"), sys.O.RDONLY, 0 });
    mach.assert(fd < 1024, "could not open executable");
    var rc: u64 = sys.call_noexcept(.fstat, u64, .{ fd, @ptrToInt(&st) });
    mach.assert(rc == 0, "could not stat executable");
    const buf: []u8 = allocator.allocateAligned(u8, st.size, 4096);
    rc = sys.call_noexcept(.read, u64, .{ fd, @ptrToInt(buf.ptr), buf.len });
    mach.assert(rc == buf.len, "could not read executable");
    return DwarfInfo.init(@ptrToInt(buf.ptr));
}
pub export fn printCompileUnits() void {
    var allocator: mem.SimpleAllocator = .{};
    var dwarf: DwarfInfo = self(&allocator);
    dwarf.scanAllCompileUnits(&allocator) catch {
        return; // could not parse DWARF
    };
    for (dwarf.funcs[0..dwarf.funcs_len]) |func| {
        if (func.name) |fn_name| {
            builtin.debug.write(fn_name);
            builtin.debug.write("\n");
        }
    }
    allocator.unmap();
}
