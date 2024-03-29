const sys = @import("sys.zig");
const mem = @import("mem.zig");
const elf = @import("elf.zig");
const fmt = @import("fmt.zig");
const proc = @import("proc.zig");
const file = @import("file.zig");
const meta = @import("meta.zig");
const trace = @import("trace.zig");
const parse = @import("parse.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
const testing = @import("testing.zig");
const Allocator = mem.SimpleAllocator;
pub const logging_summary: bool = false;
pub const logging_abbrev_entry: bool = false;
pub const logging_info_entry: bool = false;
const is_safe: bool = false;
const WordSize = enum(u8) {
    dword = 4,
    qword = 8,
};
const Range = packed struct {
    start: u64 = 0,
    end: u64 = 0,
};
const Func = struct {
    range: Range,
    name: ?[]const u8,
    unit: *Unit,
};
const Tag = enum(u64) {
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
    type_unit = 0x41,
    rvalue_reference_type = 0x42,
    template_alias = 0x43,
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
const Attr = enum(u64) {
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
    signature = 0x69,
    main_subprogram = 0x6a,
    data_bit_offset = 0x6b,
    const_expr = 0x6c,
    enum_class = 0x6d,
    linkage_name = 0x6e,
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
    lo_user = 0x2000,
    hi_user = 0x3fff,
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
        HP_unmodifiable = 0x2001,
        HP_prologue = 0x2005,
        HP_epilogue = 0x2008,
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
        HP_prof_flags = 0x201b,
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
    MIPS_advance_loc8 = 0x1d,
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
pub const Unit = extern struct {
    off: u64,
    len: u64,
    version: u16,
    word_size: WordSize,
    addr_size: u8,
    range: Range,
    str_offsets_base: usize,
    addr_base: usize,
    rnglists_base: usize,
    loclists_base: usize,
    abbrev_tab: *AbbrevTable,
    info_entry: *Die,
    dirs: [*]FileEntry,
    dirs_max_len: usize,
    dirs_len: usize,
    files: [*]FileEntry,
    files_max_len: usize,
    files_len: usize,
    fn addDir(unit: *Unit, allocator: *Allocator) *FileEntry {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&unit.dirs);
        const ret: *FileEntry = @ptrFromInt(allocator.addGeneric(@sizeOf(FileEntry), @alignOf(FileEntry), 1, addr_buf, &unit.dirs_max_len, unit.dirs_len));
        unit.dirs_len +%= 1;
        mem.zero(FileEntry, ret);
        return ret;
    }
    fn addFile(unit: *Unit, allocator: *Allocator) *FileEntry {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&unit.files);
        const ret: *FileEntry = @ptrFromInt(allocator.addGeneric(@sizeOf(FileEntry), @alignOf(FileEntry), 1, addr_buf, &unit.files_max_len, unit.files_len));
        unit.files_len +%= 1;
        mem.zero(FileEntry, ret);
        return ret;
    }
    fn init(allocator: *Allocator, dwarf_info: *DwarfInfo, bytes: [*]u8, unit_off: u64) *Unit {
        @setRuntimeSafety(is_safe);
        const buf: [*]u8 = bytes + unit_off;
        const ret: *Unit = dwarf_info.addUnit(allocator);
        ret.off = unit_off;
        ret.word_size = @enumFromInt(@as(u8, 4) << @intFromBool(@as(*align(1) u32, @ptrCast(buf)).* == ~@as(u32, 0)));
        switch (ret.word_size) {
            .qword => ret.len = @as(*align(1) u64, @ptrCast(buf + 4)).*,
            .dword => ret.len = @as(*align(1) u32, @ptrCast(buf)).*,
        }
        if (ret.word_size == .dword and
            ret.len >= ~@as(u32, 0))
        {
            proc.exitError(error.InvalidUnitLength, 2);
        }
        var pos: u64 = switch (ret.word_size) {
            .qword => 12,
            .dword => 4,
        };
        ret.version = @as(*align(1) u16, @ptrCast(buf + pos)).*;
        if (ret.version < 2 or
            ret.version > 5)
        {
            proc.exitError(error.InvalidDWARFVersion, 2);
        }
        ret.abbrev_tab = @ptrFromInt(allocator.allocateRaw(
            @sizeOf(AbbrevTable),
            @alignOf(AbbrevTable),
        ));
        pos +%= 2;
        if (ret.version >= 5) {
            if (@as(UT, @enumFromInt(buf[pos])) != .compile) {
                proc.exitError(error.InvalidEncoding, 2);
            }
            pos +%= 1;
            ret.addr_size = buf[pos];
            pos +%= 1;
            switch (ret.word_size) {
                .qword => ret.abbrev_tab.off = @as(*align(1) u64, @ptrCast(buf + pos)).*,
                .dword => ret.abbrev_tab.off = @as(*align(1) u32, @ptrCast(buf + pos)).*,
            }
            pos +%= @intFromEnum(ret.word_size);
        } else {
            switch (ret.word_size) {
                .qword => ret.abbrev_tab.off = @as(*align(1) u64, @ptrCast(buf + pos)).*,
                .dword => ret.abbrev_tab.off = @as(*align(1) u32, @ptrCast(buf + pos)).*,
            }
            pos +%= @intFromEnum(ret.word_size);
            ret.addr_size = buf[pos];
            pos +%= 1;
        }
        ret.info_entry = @ptrFromInt(allocator.allocateRaw(
            @sizeOf(Die),
            @alignOf(Die),
        ));
        ret.info_entry.off = unit_off +% pos;
        return ret;
    }
};
const AbbrevTable = struct {
    off: usize,
    len: usize,
    ents: [*]AbbrevTable.Entry,
    ents_max_len: u64,
    ents_len: u64,
    const Entry = struct {
        head: extern struct {
            code: u64,
            tag: Tag,
            children: bool,
        },
        kvs: [*]KeyVal,
        kvs_max_len: u64,
        kvs_len: u64,
        const KeyVal = struct {
            attr: Attr,
            form: Form,
            payload: i64 = 0,
        };
        fn addKeyVal(entry: *Entry, allocator: *Allocator) *KeyVal {
            @setRuntimeSafety(is_safe);
            const addr_buf: *usize = @ptrCast(&entry.kvs);
            const ret: *KeyVal = @ptrFromInt(allocator.addGeneric(@sizeOf(KeyVal), @alignOf(KeyVal), 1, addr_buf, &entry.kvs_max_len, entry.kvs_len));
            entry.kvs_len +%= 1;
            mem.zero(KeyVal, ret);
            return ret;
        }
    };
    fn addEntry(table: *AbbrevTable, allocator: *Allocator) *AbbrevTable.Entry {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&table.ents);
        const ret: *AbbrevTable.Entry = @ptrFromInt(allocator.addGeneric(@sizeOf(AbbrevTable.Entry), @alignOf(AbbrevTable.Entry), 1, addr_buf, &table.ents_max_len, table.ents_len));
        table.ents_len +%= 1;
        mem.zero(AbbrevTable.Entry, ret);
        return ret;
    }
};
pub const Die = extern struct {
    head: extern struct {
        tag: Tag,
        children: bool,
    },
    off: usize,
    len: usize,
    kvs: [*]KeyVal,
    kvs_max_len: usize = 0,
    kvs_len: usize = 0,
    const KeyVal = struct {
        key: Attr,
        val: FormValue,
    };
    fn addKeyVal(info_entry: *Die, allocator: *Allocator) *KeyVal {
        @setRuntimeSafety(is_safe);
        const addr_buf: *u64 = @as(*u64, @ptrCast(&info_entry.kvs));
        const ret: *KeyVal = @as(
            *KeyVal,
            @ptrFromInt(allocator.addGeneric(@sizeOf(KeyVal), @alignOf(KeyVal), 1, addr_buf, &info_entry.kvs_max_len, info_entry.kvs_len)),
        );
        info_entry.kvs_len +%= 1;
        return ret;
    }
    pub fn get(info_entry: *const Die, key: Attr) ?*const FormValue {
        @setRuntimeSafety(is_safe);
        for (info_entry.kvs[0..info_entry.kvs_len]) |*kv| {
            if (kv.key == key) {
                return &kv.val;
            }
        }
        return null;
    }
    fn address(info_entry: *const Die, dwarf_info: *DwarfInfo, attr_id: Attr, unit: *Unit) ?u64 {
        @setRuntimeSafety(is_safe);
        if (info_entry.get(attr_id)) |form_val| {
            switch (form_val.*) {
                FormValue.Address => |value| {
                    return value;
                },
                FormValue.AddrOffset => |index| {
                    return dwarf_info.readDebugAddr(unit.addr_base, index);
                },
                else => proc.exitError(error.InvalidEncoding, 2),
            }
        }
        return null;
    }
    fn offset(info_entry: *const Die, attr_id: Attr) ?u64 {
        @setRuntimeSafety(is_safe);
        if (info_entry.get(attr_id)) |form_val| {
            return form_val.getUInt(u64);
        }
        return null;
    }
};
pub const FormValue = union(enum) {
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
    pub fn getString(val: FormValue, dwarf_info: *DwarfInfo) []const u8 {
        @setRuntimeSafety(is_safe);
        switch (val) {
            .String => |s| return s,
            .StrPtr => |off| return dwarf_info.getString(off),
            .LineStrPtr => |off| return dwarf_info.getLineString(off),
            else => proc.exitError(error.InvalidEncoding, 2),
        }
    }
    fn getUInt(val: FormValue, comptime U: type) U {
        @setRuntimeSafety(is_safe);
        switch (val) {
            .Const => {
                return @as(U, @intCast(val.Const.asUnsignedLe()));
            },
            .SecOffset => |sec_offset| {
                return @as(U, @intCast(sec_offset));
            },
            else => proc.exitError(error.InvalidEncoding, 2),
        }
    }
    fn getData16(val: FormValue) ![16]u8 {
        @setRuntimeSafety(is_safe);
        switch (val) {
            .data16 => |d| return d,
            else => proc.exitError(error.InvalidEncoding, 2),
        }
    }
};
const Constant = struct {
    payload: u64,
    signed: bool,
    fn asUnsignedLe(val: Constant) u64 {
        @setRuntimeSafety(is_safe);
        if (val.signed) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        return val.payload;
    }
    fn asSignedLe(val: Constant) i64 {
        @setRuntimeSafety(is_safe);
        if (val.signed) {
            return @as(i64, @bitCast(val.payload));
        }
        proc.exitError(error.InvalidEncoding, 2);
    }
};
pub const DwarfInfo = extern struct {
    /// All `AbbrevTable`s listed by this DwarfInfo.
    abbrev_tabs: [*]AbbrevTable,
    abbrev_tabs_max_len: usize,
    abbrev_tabs_len: usize,
    /// All compile `Unit`s listed by this DwarfInfo.
    units: [*]Unit,
    units_max_len: usize,
    units_len: usize,
    /// All functions encountered while scanning for `Unit`s.
    funcs: [*]Func,
    funcs_max_len: usize,
    funcs_len: usize,
    /// All addresses requested from this `DwarfInfo`.
    addr_info: [*]AddressInfo,
    addr_info_max_len: usize,
    addr_info_len: usize,
    /// All unique source locations.
    src_locs: [*]trace.SourceLocation,
    src_locs_max_len: usize,
    src_locs_len: usize,
    impl: extern struct {
        info: [*]u8,
        info_len: usize,
        abbrev: [*]u8,
        abbrev_len: usize,
        str: [*]u8,
        str_len: usize,
        str_offsets: [*]u8,
        str_offsets_len: usize,
        line: [*]u8,
        line_len: usize,
        line_str: [*]u8,
        line_str_len: usize,
        ranges: [*]u8,
        ranges_len: usize,
        loclists: [*]u8,
        loclists_len: usize,
        rnglists: [*]u8,
        rnglists_len: usize,
        addr: [*]u8,
        addr_len: usize,
        names: [*]u8,
        names_len: usize,
        frame: [*]u8,
        frame_len: usize,
    },
    pub var active: ?*DwarfInfo = null;
    pub const AddressInfo = struct {
        /// Lookup address.
        addr: usize,
        /// Number of requests for this address.
        count: u32 = 0,

        /// Offset of message in output buffer.
        start: [*]u8,
        /// End of message in output buffer.
        finish: [*]u8,
    };
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
        @setRuntimeSafety(is_safe);
        const ehdr: *elf.Elf64_Ehdr = @ptrFromInt(ehdr_addr);
        const qwords: comptime_int = @divExact(@sizeOf(DwarfInfo), 8);
        const offset: comptime_int = @divExact(@offsetOf(DwarfInfo, "impl"), 8);
        var ret: [qwords]u64 = .{0} ** qwords;
        var shdr: *elf.Elf64_Shdr = @ptrFromInt(ehdr_addr +% ehdr.shoff +% (ehdr.shstrndx *% ehdr.shentsize));
        const strtab_addr: u64 = ehdr_addr +% shdr.offset;
        var addr: u64 = ehdr_addr +% ehdr.shoff;
        var shdr_idx: u64 = 0;
        while (shdr_idx != ehdr.shnum) : (shdr_idx +%= 1) {
            shdr = @ptrFromInt(addr);
            for (DwarfInfo.names, 0..) |field_name, field_idx| {
                const str: [*:0]u8 = @ptrFromInt(strtab_addr +% shdr.name);
                var idx: usize = 0;
                while (str[idx] != 0) : (idx +%= 1) {
                    if (field_name[idx] != str[idx]) break;
                } else {
                    const pair_idx: usize = (field_idx *% 2) +% offset;
                    ret[pair_idx +% 0] = ehdr_addr +% shdr.offset;
                    ret[pair_idx +% 1] = shdr.size;
                }
            }
            addr +%= ehdr.shentsize;
        }
        if (logging_abbrev_entry or
            logging_summary or
            logging_info_entry)
        {
            DwarfInfo.active = @ptrCast(&ret);
        }
        return @bitCast(ret);
    }
    fn addAbbrevTable(dwarf_info: *DwarfInfo, allocator: *Allocator) *AbbrevTable {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&dwarf_info.abbrev_tabs);
        const ret: *AbbrevTable = @ptrFromInt(allocator.addGeneric(@sizeOf(AbbrevTable), @alignOf(AbbrevTable), 1, addr_buf, &dwarf_info.abbrev_tabs_max_len, dwarf_info.abbrev_tabs_len));
        dwarf_info.abbrev_tabs_len +%= 1;
        mem.zero(AbbrevTable, ret);
        return ret;
    }
    fn addUnit(dwarf_info: *DwarfInfo, allocator: *Allocator) *Unit {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&dwarf_info.units);
        const ret: *Unit = @ptrFromInt(allocator.addGeneric(@sizeOf(Unit), @alignOf(Unit), 1, addr_buf, &dwarf_info.units_max_len, dwarf_info.units_len));
        dwarf_info.units_len +%= 1;
        mem.zero(Unit, ret);
        return ret;
    }
    fn addFunc(dwarf_info: *DwarfInfo, allocator: *Allocator) *Func {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&dwarf_info.funcs);
        const ret: *Func = @ptrFromInt(allocator.addGeneric(@sizeOf(Func), @alignOf(Func), 1, addr_buf, &dwarf_info.funcs_max_len, dwarf_info.funcs_len));
        dwarf_info.funcs_len +%= 1;
        mem.zero(Func, ret);
        return ret;
    }
    pub fn addAddressInfo(dwarf_info: *DwarfInfo, allocator: *Allocator) *AddressInfo {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&dwarf_info.addr_info);
        const ret: *AddressInfo = @ptrFromInt(allocator.addGeneric(@sizeOf(AddressInfo), @alignOf(AddressInfo), 1, addr_buf, &dwarf_info.addr_info_max_len, dwarf_info.addr_info_len));
        dwarf_info.addr_info_len +%= 1;
        mem.zero(AddressInfo, ret);
        return ret;
    }
    pub fn addSourceLocation(dwarf_info: *DwarfInfo, allocator: *Allocator) *trace.SourceLocation {
        @setRuntimeSafety(is_safe);
        const addr_buf: *usize = @ptrCast(&dwarf_info.src_locs);
        const ret: *trace.SourceLocation = @ptrFromInt(allocator.addGeneric(@sizeOf(trace.SourceLocation), @alignOf(trace.SourceLocation), 1, addr_buf, &dwarf_info.src_locs_max_len, dwarf_info.src_locs_len));
        dwarf_info.src_locs_len +%= 1;
        mem.zero(trace.SourceLocation, ret);
        return ret;
    }
    fn populateUnit(allocator: *Allocator, dwarf_info: *DwarfInfo, unit: *Unit) void {
        @setRuntimeSafety(is_safe);
        parseAbbrevTable(allocator, dwarf_info, unit.abbrev_tab);
        parseDie(allocator, dwarf_info, unit, unit.info_entry);
        if (logging_summary) {
            about.unitAbstractNotice(unit);
        }
        if (unit.info_entry.get(.str_offsets_base)) |form_val| {
            unit.str_offsets_base = form_val.getUInt(usize);
        }
        if (unit.info_entry.get(.addr_base)) |form_val| {
            unit.addr_base = form_val.getUInt(usize);
        }
        if (unit.info_entry.get(.rnglists_base)) |form_val| {
            unit.rnglists_base = form_val.getUInt(usize);
        }
        if (unit.info_entry.get(.loclists_base)) |form_val| {
            unit.loclists_base = form_val.getUInt(usize);
        }
    }
    pub fn scanAllCompileUnits(dwarf_info: *DwarfInfo, allocator: *Allocator) void {
        @setRuntimeSafety(is_safe);
        var unit_off: u64 = 0;
        while (unit_off < dwarf_info.impl.info_len) {
            const unit: *Unit = Unit.init(allocator, dwarf_info, dwarf_info.impl.info, unit_off);
            populateUnit(allocator, dwarf_info, unit);
            const next_off: u64 = switch (unit.word_size) {
                .qword => 12 +% unit.len,
                .dword => 4 +% unit.len,
            };
            var info_entry: Die = undefined;
            var pos: u64 = unit.info_entry.off +% unit.info_entry.len;
            while (pos < next_off) {
                mem.zero(Die, &info_entry);
                info_entry.off = unit_off +% pos;
                parseDie(allocator, dwarf_info, unit, &info_entry);
                pos +%= info_entry.len;
                if (info_entry.head.tag == .subprogram or
                    info_entry.head.tag == .inlined_subroutine or
                    info_entry.head.tag == .subroutine or
                    info_entry.head.tag == .entry_point)
                {
                    dwarf_info.addFunc(allocator).* = .{
                        .name = parseFuncName(allocator, dwarf_info, unit, &info_entry, unit_off, next_off),
                        .range = parseRange(dwarf_info, unit, &info_entry),
                        .unit = unit,
                    };
                }
            }
            unit_off +%= next_off;
        }
    }
    fn parseFuncName(
        allocator: *Allocator,
        dwarf_info: *DwarfInfo,
        unit: *Unit,
        info_entry: *Die,
        unit_off: u64,
        next_off: u64,
    ) ?[]const u8 {
        @setRuntimeSafety(is_safe);
        var depth: i32 = 3;
        var cur_info_entry: Die = info_entry.*;
        while (depth > 0) : (depth -%= 1) {
            if (cur_info_entry.get(.name)) |form_val| {
                return getAttrString(dwarf_info, unit, form_val, dwarf_info.impl.str[0..dwarf_info.impl.str_len]);
            }
            if (cur_info_entry.get(.abstract_origin)) |form_val| {
                if (form_val.* != .Ref) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                const ref_off: u64 = form_val.Ref;
                if (ref_off > next_off) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                cur_info_entry.off = unit_off +% ref_off;
                parseDie(allocator, dwarf_info, unit, &cur_info_entry);
                continue;
            }
            if (cur_info_entry.get(.specification)) |form_val| {
                if (form_val.* != .Ref) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                const ref_off: u64 = form_val.Ref;
                if (ref_off > next_off) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                cur_info_entry.off = unit_off +% ref_off;
                parseDie(allocator, dwarf_info, unit, &cur_info_entry);
                continue;
            }
        }
        return null;
    }
    fn parseRange(dwarf_info: *DwarfInfo, unit: *const Unit, info_entry: *Die) Range {
        @setRuntimeSafety(is_safe);
        if (info_entry.get(.low_pc)) |low_form_val| {
            const low_pc: u64 = switch (low_form_val.*) {
                .Address => |addr| addr,
                .AddrOffset => |off| dwarf_info.readDebugAddr(unit.addr_base, off),
                else => proc.exitError(error.InvalidEncoding, 2),
            };
            if (info_entry.get(.high_pc)) |high_form_val| {
                switch (high_form_val.*) {
                    .Address => |addr| return .{
                        .start = low_pc,
                        .end = addr,
                    },
                    .Const => |val| return .{
                        .start = low_pc,
                        .end = low_pc +% val.asUnsignedLe(),
                    },
                    else => proc.exitError(error.InvalidEncoding, 2),
                }
            }
        }
        return .{};
    }
    fn parseAbbrevTable(
        allocator: *Allocator,
        dwarf_info: *DwarfInfo,
        abbrev_tab: *AbbrevTable,
    ) void {
        @setRuntimeSafety(is_safe);
        const abbrev_bytes: [*]u8 = dwarf_info.impl.abbrev + abbrev_tab.off;
        while (true) {
            const code = parse.noexcept.unsignedLEB128(abbrev_bytes + abbrev_tab.len);
            abbrev_tab.len +%= code[1];
            if (code[0] == 0) {
                break;
            }
            const tag = parse.noexcept.unsignedLEB128(abbrev_bytes + abbrev_tab.len);
            abbrev_tab.len +%= tag[1];
            const ent: *AbbrevTable.Entry = abbrev_tab.addEntry(allocator);
            ent.head = .{
                .tag = @enumFromInt(tag[0]),
                .children = abbrev_bytes[abbrev_tab.len] == 1,
                .code = code[0],
            };
            abbrev_tab.len +%= 1;
            while (true) {
                const attr = parse.noexcept.unsignedLEB128(abbrev_bytes + abbrev_tab.len);
                abbrev_tab.len +%= attr[1];
                const form = parse.noexcept.unsignedLEB128(abbrev_bytes + abbrev_tab.len);
                abbrev_tab.len +%= form[1];
                if (attr[0] == 0 and form[0] == 0) {
                    break;
                }
                const kv: *AbbrevTable.Entry.KeyVal = ent.addKeyVal(allocator);
                if (form[0] == @intFromEnum(Form.implicit_const)) {
                    const payload = parse.noexcept.signedLEB128(abbrev_bytes + abbrev_tab.len);
                    abbrev_tab.len +%= payload[1];
                    kv.* = .{
                        .attr = @enumFromInt(attr[0]),
                        .form = @enumFromInt(form[0]),
                        .payload = payload[0],
                    };
                } else {
                    kv.* = .{
                        .attr = @enumFromInt(attr[0]),
                        .form = @enumFromInt(form[0]),
                    };
                }
            }
        }
        if (logging_abbrev_entry) {
            about.abbrevTableNotice(abbrev_tab);
        }
    }
    fn parseDie(
        allocator: *Allocator,
        dwarf_info: *DwarfInfo,
        unit: *Unit,
        info_entry: *Die,
    ) void {
        @setRuntimeSafety(is_safe);
        const info_entry_bytes: []u8 = dwarf_info.impl.info[info_entry.off..dwarf_info.impl.info_len];
        const code = parse.noexcept.readLEB128(u64, info_entry_bytes);
        info_entry.len = code[1];
        info_entry.kvs_len = 0;
        if (code[0] == 0) {
            return;
        }
        var ents_idx: usize = 0;
        while (ents_idx != unit.abbrev_tab.ents_len) : (ents_idx +%= 1) {
            if (unit.abbrev_tab.ents[ents_idx].head.code == code[0]) {
                break;
            }
        } else {
            return;
        }
        const entry: AbbrevTable.Entry = unit.abbrev_tab.ents[ents_idx];
        info_entry.head = .{
            .tag = entry.head.tag,
            .children = entry.head.children,
        };
        for (entry.kvs[0..entry.kvs_len], 0..) |kv, kv_idx| {
            const res = parseFormValue(allocator, unit, info_entry_bytes[info_entry.len..], kv.form);
            info_entry.addKeyVal(allocator).* = .{ .key = kv.attr, .val = res[0] };
            info_entry.len +%= res[1];
            if (kv.form == .implicit_const) {
                info_entry.kvs[kv_idx].val.Const.payload = @bitCast(kv.payload);
            }
        }
        if (logging_info_entry) {
            about.debugDieNotice(info_entry);
        }
    }
    fn parseFileEntry(bytes: []u8) ?struct { FileEntry, u64 } {
        @setRuntimeSafety(is_safe);
        var pos: usize = 0;
        const name: [:0]const u8 = mem.terminate(bytes.ptr, 0);
        if (name.len == 0) {
            return null;
        }
        pos +%= name.len +% 1;
        const dir_idx = parse.noexcept.readLEB128(u32, bytes[pos..]);
        pos +%= dir_idx[1];
        const mtime = parse.noexcept.readLEB128(u64, bytes[pos..]);
        pos +%= mtime[1];
        const size = parse.noexcept.readLEB128(u64, bytes[pos..]);
        pos +%= size[1];
        return .{ .{ .name = name, .dir_idx = dir_idx[0], .mtime = mtime[0], .size = size[0] }, pos };
    }
    fn parseDirectoryEntry(bytes: []u8) ?struct { FileEntry, u64 } {
        @setRuntimeSafety(is_safe);
        const dir: [:0]const u8 = mem.terminate(bytes.ptr, 0);
        if (dir.len == 0) {
            return null;
        }
        return .{ .{ .name = dir }, dir.len +% 1 };
    }
    fn getLineString(dwarf_info: DwarfInfo, offset: u64) [:0]const u8 {
        @setRuntimeSafety(is_safe);
        return getStringGeneric(dwarf_info.impl.line_str[0..dwarf_info.impl.line_str_len], offset);
    }
    fn getString(dwarf_info: DwarfInfo, offset: u64) [:0]const u8 {
        @setRuntimeSafety(is_safe);
        return getStringGeneric(dwarf_info.impl.str[0..dwarf_info.impl.str_len], offset);
    }
    pub fn getSymbolName(dwarf_info: *DwarfInfo, instr_addr: u64) ?[]const u8 {
        @setRuntimeSafety(is_safe);
        for (dwarf_info.funcs[0..dwarf_info.funcs_len]) |*func| {
            if (instr_addr >= func.range.start and
                instr_addr < func.range.end)
            {
                return func.name;
            }
        }
        return null;
    }
    fn readDebugAddr(dwarf_info: DwarfInfo, addr_base: u64, index: u64) u64 {
        @setRuntimeSafety(is_safe);
        if (dwarf_info.impl.addr_len == 0) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        if (addr_base < 8) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        const ver: u16 = @as(*align(1) u16, @ptrCast(dwarf_info.impl.addr + addr_base - 4)).*;
        if (ver != 5) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        const addr_size: u8 = dwarf_info.impl.addr[addr_base -% 2];
        const seg_size: u8 = dwarf_info.impl.addr[addr_base -% 1];
        const off: u64 = @as(usize, @intCast(addr_base +% (addr_size +% seg_size) *% index));
        if (off +% addr_size > dwarf_info.impl.addr_len) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        switch (addr_size) {
            1 => return dwarf_info.impl.addr[off],
            2 => return @as(*align(1) u16, @ptrCast(dwarf_info.impl.addr + off)).*,
            4 => return @as(*align(1) u32, @ptrCast(dwarf_info.impl.addr + off)).*,
            8 => return @as(*align(1) u64, @ptrCast(dwarf_info.impl.addr + off)).*,
            else => proc.exitError(error.InvalidEncoding, 2),
        }
    }
    pub fn getAttrString(dwarf_info: *DwarfInfo, unit: *const Unit, form_val: *const FormValue, str: []const u8) []const u8 {
        @setRuntimeSafety(is_safe);
        switch (form_val.*) {
            .String => |value| {
                return value;
            },
            .StrPtr => |offset| {
                return dwarf_info.getString(offset);
            },
            .StrOffset => |index| {
                if (dwarf_info.impl.str_offsets_len == 0) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                if (unit.str_offsets_base == 0) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                if (unit.word_size == .qword) {
                    const off: usize = unit.str_offsets_base +% (8 *% index);
                    if (off +% 8 > dwarf_info.impl.str_offsets_len) {
                        proc.exitError(error.InvalidEncoding, 2);
                    }
                    return getStringGeneric(str, @as(*align(1) u64, @ptrCast(dwarf_info.impl.str_offsets + off)).*);
                } else {
                    const off: usize = unit.str_offsets_base +% (4 *% index);
                    if (off +% 4 > dwarf_info.impl.str_offsets_len) {
                        proc.exitError(error.InvalidEncoding, 2);
                    }
                    return getStringGeneric(str, @as(*align(1) u32, @ptrCast(dwarf_info.impl.str_offsets + off)).*);
                }
            },
            .LineStrPtr => |offset| {
                return dwarf_info.getLineString(offset);
            },
            else => proc.exitError(error.InvalidEncoding, 2),
        }
    }
    pub fn findCompileUnit(dwarf_info: *DwarfInfo, target_address: u64) ?*Unit {
        @setRuntimeSafety(is_safe);
        for (dwarf_info.units[0..dwarf_info.units_len]) |*unit| {
            if (target_address >= unit.range.start and
                target_address < unit.range.end)
            {
                return unit;
            }
            const gev5: bool = unit.version >= 5;
            const ranges_len: u64 = if (gev5) dwarf_info.impl.rnglists_len else dwarf_info.impl.ranges_len;
            const ranges: [*]u8 = if (gev5) dwarf_info.impl.rnglists else dwarf_info.impl.ranges;
            const ranges_val = unit.info_entry.get(.ranges) orelse {
                continue;
            };
            const ranges_offset = switch (ranges_val.*) {
                .SecOffset => |off| off,
                .RangeListOffset => |idx| off: {
                    if (unit.word_size == .qword) {
                        const off: usize = unit.rnglists_base + (8 *% idx);
                        if (off +% 8 > ranges_len) {
                            proc.exitError(error.InvalidEncoding, 2);
                        }
                        break :off @as(*align(1) u64, @ptrCast(ranges + off)).*;
                    } else {
                        const off: usize = unit.rnglists_base + (4 *% idx);
                        if (off +% 4 > ranges_len) {
                            proc.exitError(error.InvalidEncoding, 2);
                        }
                        break :off @as(*align(1) u32, @ptrCast(ranges + off)).*;
                    }
                },
                else => proc.exitError(error.InvalidEncoding, 2),
            };
            var base_address: usize = unit.info_entry.address(dwarf_info, .low_pc, unit) orelse 0;
            const buf: [*]u8 = dwarf_info.impl.ranges;
            var pos: u64 = ranges_offset;
            if (unit.version < 5) {
                while (true) {
                    const begin_addr: u64 = @as(*align(1) u64, @ptrCast(buf + pos)).*;
                    pos +%= @sizeOf(u64);
                    const end_addr: u64 = @as(*align(1) u64, @ptrCast(buf + pos)).*;
                    pos +%= @sizeOf(u64);
                    if (begin_addr == 0 and end_addr == 0) {
                        break;
                    }
                    if (begin_addr == ~@as(usize, 0)) {
                        base_address = end_addr;
                        continue;
                    }
                    if (target_address >= base_address + begin_addr and
                        target_address <= base_address + end_addr)
                    {
                        return unit;
                    }
                }
            } else {
                while (true) {
                    const kind: RLE = @enumFromInt(buf[pos]);
                    pos +%= 1;
                    switch (kind) {
                        .end_of_list => break,
                        .base_addressx => {
                            const idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            pos +%= idx[1];
                            base_address = dwarf_info.readDebugAddr(unit.addr_base, idx[0]);
                        },
                        .startx_endx => {
                            const start_idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            pos +%= start_idx[1];
                            const start_addr: usize = dwarf_info.readDebugAddr(unit.addr_base, start_idx[0]);
                            const end_idx = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            pos +%= end_idx[1];
                            const end_addr: usize = dwarf_info.readDebugAddr(unit.addr_base, end_idx[0]);
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        .startx_length => {
                            const start_index = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            const start_addr: usize = dwarf_info.readDebugAddr(unit.addr_base, start_index[0]);
                            const len = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            const end_addr: u64 = start_addr + len[0];
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        .offset_pair => {
                            const start_addr = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            pos +%= start_addr[1];
                            const end_addr = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            pos +%= end_addr[1];
                            if (target_address >= base_address + start_addr[0] and
                                target_address < base_address + end_addr[0])
                            {
                                return unit;
                            }
                        },
                        .base_address => {
                            base_address = @as(*align(1) usize, @ptrCast(buf + pos)).*;
                            pos +%= @sizeOf(usize);
                        },
                        .start_end => {
                            const start_addr = @as(*align(1) usize, @ptrCast(buf + pos)).*;
                            pos +%= @sizeOf(usize);
                            const end_addr = @as(*align(1) usize, @ptrCast(buf + pos)).*;
                            pos +%= @sizeOf(usize);
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                        .start_length => {
                            const start_addr = @as(*align(1) usize, @ptrCast(buf + pos)).*;
                            pos +%= @sizeOf(usize);
                            const len = parse.noexcept.readLEB128(usize, buf[pos..dwarf_info.impl.ranges_len]);
                            const end_addr = start_addr + len[0];
                            if (target_address >= start_addr and target_address < end_addr) {
                                return unit;
                            }
                        },
                    }
                }
            }
        }
        return null;
    }
    pub fn getSourceLocation(
        dwarf_info: *DwarfInfo,
        allocator: *Allocator,
        unit: *Unit,
        instr_addr: u64,
    ) ?trace.SourceLocation {
        @setRuntimeSafety(is_safe);
        const unit_cwd: []const u8 = blk: {
            const form_val: *const FormValue = unit.info_entry.get(.comp_dir) orelse {
                proc.exitError(error.InvalidEncoding, 2);
            };
            break :blk getAttrString(dwarf_info, unit, form_val, dwarf_info.impl.line_str[0..dwarf_info.impl.line_str_len]);
        };
        const line_off: u64 = unit.info_entry.offset(.stmt_list) orelse {
            proc.exitError(error.InvalidEncoding, 2);
        };
        const line_unit: *Unit = Unit.init(allocator, dwarf_info, dwarf_info.impl.line, line_off);
        const obv_files_len: u64 = unit.files_len;
        defer {
            if (obv_files_len != 0) unit.files_len = @truncate(obv_files_len);
        }
        const next_unit_off = line_off +% switch (line_unit.word_size) {
            .qword => line_unit.len +% 12,
            .dword => line_unit.len +% 8,
        };
        const buf: [*]u8 = dwarf_info.impl.line;
        const bytes: []u8 = buf[0..dwarf_info.impl.line_len];
        var pos: u64 = line_unit.info_entry.off;
        const next_off: u64 = (pos +% line_unit.abbrev_tab.off) -% 1;
        const min_instr_len: u8 = dwarf_info.impl.line[pos -% 1];
        if (min_instr_len == 0) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        if (line_unit.version >= 4) {
            pos +%= 1;
        }
        const is_stmt: bool = buf[pos] != 0;
        const line_base: i8 = @bitCast(buf[pos +% 1]);
        const line_range: u8 = buf[pos +% 2];
        const opcode_base: u8 = buf[pos +% 3];
        pos +%= 4;
        var opcode_lens: [*]u8 = @ptrFromInt(allocator.allocateRaw(opcode_base -% 1, 1));
        var idx: usize = 0;
        while (idx != opcode_base -% 1) : (idx +%= 1) {
            opcode_lens[idx] = buf[pos];
            pos +%= 1;
        }
        if (line_range == 0) {
            proc.exitError(error.InvalidEncoding, 2);
        }
        if (unit.files_len == 0) {
            unit.addDir(allocator).* = .{ .name = unit_cwd };
            while (parseDirectoryEntry(bytes[pos..])) |dent| {
                unit.addDir(allocator).* = dent[0];
                pos +%= dent[1];
            }
        }
        pos +%= 1;
        if (unit.files_len == 0) {
            while (parseFileEntry(bytes[pos..])) |fent| {
                unit.addFile(allocator).* = fent[0];
                pos +%= fent[1];
            }
        }
        pos +%= 1;
        var prog: LineNumberProgram = LineNumberProgram.init(is_stmt);
        pos = next_off;
        while (pos < next_unit_off) {
            const opcode: u8 = buf[pos];
            pos +%= 1;
            if (opcode == @intFromEnum(LNS.extended_op)) {
                const op_size = parse.noexcept.unsignedLEB128(buf + pos);
                pos +%= op_size[1];
                if (op_size[0] < 1) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                const sub_op: u8 = buf[pos];
                pos +%= 1;
                switch (@as(LNE, @enumFromInt(sub_op))) {
                    LNE.end_sequence => {
                        prog.state.is_end_sequence = true;
                        if (prog.checkLineMatch(allocator, unit, instr_addr)) |info| {
                            return info;
                        }
                        prog.reset();
                    },
                    LNE.set_address => {
                        const addr: usize = @as(*align(1) usize, @ptrCast(buf + pos)).*;
                        pos +%= @sizeOf(usize);
                        prog.state.addr = addr;
                    },
                    LNE.define_file => {
                        if (parseFileEntry(bytes[pos..])) |fent| {
                            unit.addFile(allocator).* = fent[0];
                            pos +%= fent[1];
                        }
                    },
                    else => {
                        const fwd_amt: isize = @bitCast(op_size[0] -% 1);
                        if (fwd_amt < 0) {
                            pos -%= @intCast(-fwd_amt);
                        } else {
                            pos +%= @intCast(fwd_amt);
                        }
                    },
                }
            } else if (opcode >= opcode_base) {
                const adjusted_opcode: u8 = opcode -% opcode_base;
                const inc_addr: u8 = min_instr_len *% (adjusted_opcode / line_range);
                const inc_line: i32 = @as(i32, line_base) +% @as(i32, adjusted_opcode % line_range);
                prog.state.line +%= inc_line;
                prog.state.addr +%= inc_addr;
                if (prog.checkLineMatch(allocator, unit, instr_addr)) |info| {
                    return info;
                }
                prog.state.is_basic_block = false;
            } else {
                switch (@as(LNS, @enumFromInt(opcode))) {
                    LNS.copy => {
                        if (prog.checkLineMatch(allocator, unit, instr_addr)) |info| {
                            return info;
                        }
                        prog.state.is_basic_block = false;
                    },
                    LNS.advance_pc => {
                        const arg = parse.noexcept.unsignedLEB128(buf + pos);
                        pos +%= arg[1];
                        prog.state.addr +%= arg[0] *% min_instr_len;
                    },
                    LNS.advance_line => {
                        const arg = parse.noexcept.readLEB128(i64, bytes[pos..]);
                        pos +%= arg[1];
                        prog.state.line +%= arg[0];
                    },
                    LNS.set_file => {
                        const arg = parse.noexcept.unsignedLEB128(buf + pos);
                        pos +%= arg[1];
                        prog.state.file = arg[0];
                    },
                    LNS.set_column => {
                        const arg = parse.noexcept.unsignedLEB128(buf + pos);
                        pos +%= arg[1];
                        prog.state.column = arg[0];
                    },
                    LNS.negate_stmt => {
                        prog.state.is_stmt = !prog.state.is_stmt;
                    },
                    LNS.set_basic_block => {
                        prog.state.is_basic_block = true;
                    },
                    LNS.const_add_pc => {
                        const inc_addr: u8 = min_instr_len *% ((255 -% opcode_base) / line_range);
                        prog.state.addr +%= inc_addr;
                    },
                    LNS.fixed_advance_pc => {
                        const arg: u16 = @as(*align(1) u16, @ptrCast(buf + pos)).*;
                        pos +%= 2;
                        prog.state.addr +%= arg;
                    },
                    else => {
                        if (opcode -% 1 >= opcode_base) {
                            proc.exitError(error.InvalidEncoding, 2);
                        }
                        pos +%= opcode_lens[opcode -% 1];
                    },
                }
            }
        }
        proc.exitError(error.InvalidEncoding, 2);
    }
};
fn getStringGeneric(str: []const u8, offset: u64) [:0]const u8 {
    @setRuntimeSafety(is_safe);
    if (offset > str.len) {
        proc.exitError(error.InvalidEncoding, 2);
    }
    return mem.terminate(str[offset..].ptr, 0);
}
fn parseFormValue(allocator: *Allocator, unit: *Unit, bytes: []u8, form: Form) struct { FormValue, u64 } {
    @setRuntimeSafety(is_safe);
    switch (form) {
        .addr => return .{ .{ .Address = @as(*align(1) usize, @ptrCast(bytes)).* }, @sizeOf(u64) },
        .block2 => {
            const blk_len: u16 = @as(*align(1) u16, @ptrCast(bytes)).*;
            return .{ FormValue{ .Block = bytes[2 .. 2 +% blk_len] }, 2 +% blk_len };
        },
        .block4 => {
            const blk_len: u32 = @as(*align(1) u32, @ptrCast(bytes)).*;
            return .{ FormValue{ .Block = bytes[4 .. 4 +% blk_len] }, 4 +% blk_len };
        },
        .data2 => return .{ .{ .Const = .{ .signed = false, .payload = @as(*align(1) u16, @ptrCast(bytes)).* } }, 2 },
        .data4 => return .{ .{ .Const = .{ .signed = false, .payload = @as(*align(1) u32, @ptrCast(bytes)).* } }, 4 },
        .data8 => return .{ .{ .Const = .{ .signed = false, .payload = @as(*align(1) u64, @ptrCast(bytes)).* } }, 8 },
        .string => {
            const str: [:0]u8 = mem.terminate(bytes.ptr, 0);
            return .{ .{ .String = str }, str.len };
        },
        .block => {
            const len = parse.noexcept.readLEB128(usize, bytes);
            const blk_len: usize = mem.readIntVar(usize, bytes, len[0]);
            return .{ FormValue{ .Block = bytes[len[0] .. len[0] +% blk_len] }, len[0] +% blk_len };
        },
        .block1 => {
            const blk_len: u8 = @as(*align(1) u8, @ptrCast(bytes)).*;
            return .{ FormValue{ .Block = bytes[1 .. 1 +% blk_len] }, 1 +% blk_len };
        },
        .data1 => return .{ .{ .Const = .{ .signed = false, .payload = @as(*align(1) u8, @ptrCast(bytes)).* } }, 1 },
        .flag => return .{ .{ .Flag = bytes[0] != 0 }, 1 },
        .udata => {
            const res = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .Const = .{ .signed = false, .payload = res[0] } }, res[1] };
        },
        .sdata => {
            const res = parse.noexcept.readLEB128(i64, bytes);
            return .{ .{ .Const = .{ .signed = true, .payload = @as(u64, @bitCast(res[0])) } }, res[1] };
        },
        .strp => switch (unit.word_size) {
            .dword => return .{ .{ .StrPtr = @as(*align(1) u32, @ptrCast(bytes)).* }, @sizeOf(u32) },
            .qword => return .{ .{ .StrPtr = @as(*align(1) u64, @ptrCast(bytes)).* }, @sizeOf(u64) },
        },
        .ref_addr => switch (unit.word_size) {
            .dword => return .{ .{ .RefAddr = @as(*align(1) u32, @ptrCast(bytes)).* }, @sizeOf(u32) },
            .qword => return .{ .{ .RefAddr = @as(*align(1) u64, @ptrCast(bytes)).* }, @sizeOf(u64) },
        },
        .ref1 => return .{ .{ .Ref = @as(*align(1) u8, @ptrCast(bytes)).* }, 1 },
        .ref2 => return .{ .{ .Ref = @as(*align(1) u16, @ptrCast(bytes)).* }, 2 },
        .ref4 => return .{ .{ .Ref = @as(*align(1) u32, @ptrCast(bytes)).* }, 4 },
        .ref8 => return .{ .{ .Ref = @as(*align(1) u64, @ptrCast(bytes)).* }, 8 },
        .ref_udata => {
            const res = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .Ref = res[0] }, res[1] };
        },
        .indirect => {
            const child = parse.noexcept.readLEB128(Form, bytes);
            const res = parseFormValue(allocator, unit, bytes[child[1]..], child[0]);
            return .{ res[0], child[1] +% res[1] };
        },
        .sec_offset => switch (unit.word_size) {
            .dword => return .{ .{ .SecOffset = @as(*align(1) u32, @ptrCast(bytes)).* }, @sizeOf(u32) },
            .qword => return .{ .{ .SecOffset = @as(*align(1) u64, @ptrCast(bytes)).* }, @sizeOf(u64) },
        },
        .exprloc => {
            const loc = parse.noexcept.readLEB128(usize, bytes);
            const expr: []u8 = allocator.allocate(u8, loc[0]);
            @memcpy(expr, bytes[loc[1]..].ptr);
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
            @memcpy(&data, bytes.ptr);
            return .{ .{ .data16 = data }, 16 };
        },
        .line_strp => switch (unit.word_size) {
            .dword => return .{ .{ .LineStrPtr = @as(*align(1) u32, @ptrCast(bytes)).* }, @sizeOf(u32) },
            .qword => return .{ .{ .LineStrPtr = @as(*align(1) u64, @ptrCast(bytes)).* }, @sizeOf(u64) },
        },
        .ref_sig8 => return .{ .{ .RefAddr = @as(*align(1) u64, @ptrCast(bytes)).* }, @sizeOf(u64) },
        .implicit_const => return .{ .{ .Const = .{ .signed = true, .payload = undefined } }, 0 },
        .loclistx => {
            const off = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .LocListOffset = off[0] }, off[1] };
        },
        .rnglistx => {
            const off = parse.noexcept.readLEB128(u64, bytes);
            return .{ .{ .RangeListOffset = off[0] }, off[1] };
        },
        .strx1 => return .{ .{ .StrOffset = @as(*align(1) u8, @ptrCast(bytes)).* }, 1 },
        .strx2 => return .{ .{ .StrOffset = @as(*align(1) u16, @ptrCast(bytes)).* }, 2 },
        .strx3 => return .{ .{ .StrOffset = @as(*align(1) u24, @ptrCast(bytes)).* }, 3 },
        .strx4 => return .{ .{ .StrOffset = @as(*align(1) u32, @ptrCast(bytes)).* }, 4 },
        .addrx1 => return .{ .{ .AddrOffset = @as(*align(1) u8, @ptrCast(bytes)).* }, 1 },
        .addrx2 => return .{ .{ .AddrOffset = @as(*align(1) u16, @ptrCast(bytes)).* }, 2 },
        .addrx3 => return .{ .{ .AddrOffset = @as(*align(1) u32, @ptrCast(bytes)).* }, 3 },
        .addrx4 => return .{ .{ .AddrOffset = @as(*align(1) u64, @ptrCast(bytes)).* }, 4 },
        else => {
            proc.exitErrorFault(error.UnhandledFormValueType, @tagName(form), 2);
        },
    }
}
const FileEntry = struct {
    dir_idx: u32 = 0,
    name: []const u8,
    mtime: u64 = 0,
    size: u64 = 0,
    md5: [16]u8 = [1]u8{0} ** 16,
    buf: [*]u8 = undefined,
    buf_len: u64 = 0,
    fn pathname(entry: *const FileEntry, allocator: *Allocator, dirs: [*]FileEntry) [:0]const u8 {
        @setRuntimeSafety(is_safe);
        const dirname: []const u8 = dirs[entry.dir_idx].name;
        const ret: [*]u8 = @ptrFromInt(allocator.allocateRaw(dirname.len +% entry.name.len +% 2, 1));
        var len: usize = 0;
        len +%= fmt.strcpy(ret + len, dirname);
        ret[len] = '/';
        len +%= 1;
        len +%= fmt.strcpy(ret + len, entry.name);
        ret[len] = 0;
        return ret[0..len :0];
    }
};
// TODO: Inline this abstraction.
const LineNumberProgram = struct {
    /// Previous valid line state (if any)
    prev: ?State,
    /// Current line state
    state: State,
    /// Default flags
    is_stmt: bool,
    const State = struct {
        /// Current address
        addr: u64 = 0,
        /// Current file index
        file: usize = 1,
        /// Current line in file
        line: i64 = 1,
        /// Current column in line
        column: u64 = 0,
        /// Flags
        is_stmt: bool,
        is_basic_block: bool = false,
        is_end_sequence: bool = false,
    };
    fn reset(lnp: *LineNumberProgram) void {
        @setRuntimeSafety(is_safe);
        lnp.prev = null;
        lnp.state = .{ .is_stmt = lnp.is_stmt };
    }
    fn init(is_stmt: bool) LineNumberProgram {
        @setRuntimeSafety(is_safe);
        return .{
            .is_stmt = is_stmt,
            .prev = null,
            .state = .{ .is_stmt = is_stmt },
        };
    }
    fn checkLineMatch(lnp: *LineNumberProgram, allocator: *Allocator, unit: *const Unit, addr: usize) ?trace.SourceLocation {
        @setRuntimeSafety(is_safe);
        if (lnp.prev) |prev| {
            if (addr >= prev.addr and
                addr <= lnp.state.addr)
            {
                if (prev.file == 0) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                const idx: usize = prev.file -% 1;
                if (idx >= unit.files_len) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                const entry: FileEntry = unit.files[idx];
                if (entry.dir_idx >= unit.dirs_len) {
                    proc.exitError(error.InvalidEncoding, 2);
                }
                return .{
                    .line = if (prev.line != 0)
                        @intCast(prev.line)
                    else
                        @intCast(lnp.state.line),
                    .column = prev.column,
                    .file = entry.pathname(allocator, unit.dirs),
                };
            }
        }
        lnp.prev = lnp.state;
        return null;
    }
};
const about = struct {
    const dwarf_s: fmt.AboutSrc = fmt.about("dwarf");
    const abbrev_tab_s: fmt.AboutSrc = fmt.about("abbrev");
    const abbrev_code_s: fmt.AboutSrc = fmt.about("code");
    const debug_entry_s: fmt.AboutSrc = fmt.about("full");
    const dwarf_version_s: fmt.AboutSrc = fmt.about("dwarf-version");
    const dwarf_addrsize_s: fmt.AboutSrc = fmt.about("dwarf-addrsize");
    fn printIntAt(src: builtin.SourceLocation, msg: []const u8, int: u64) void {
        @setRuntimeSafety(is_safe);
        var buf: [512]u8 = undefined;
        var len: u64 = 0;
        var ud64: fmt.Ud64 = .{ .value = int };
        @memcpy(&buf, src.fn_name);
        len +%= src.fn_name.len;
        @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ": ".*;
        len +%= 2;
        @memcpy(buf[len..].ptr, msg);
        len +%= msg.len;
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        len +%= 1;
        debug.write(buf[0..len]);
    }
    fn unitAbstractNotice(unit: *Unit) void {
        @setRuntimeSafety(is_safe);
        var buf: [512]u8 = undefined;
        var len: u64 = 0;
        var ud64: fmt.Ud64 = .{ .value = unit.version };
        @as(fmt.AboutDest, @ptrCast(&buf)).* = dwarf_s.*;
        len +%= dwarf_s.len;
        @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = "ver=".*;
        len +%= 4;
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        @as(*[11]u8, @ptrCast(buf[len..].ptr)).* = ", unit_len=".*;
        len +%= 11;
        ud64.value = unit.len;
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        @as(*[12]u8, @ptrCast(buf[len..].ptr)).* = ", word_size=".*;
        len +%= 12;
        ud64.value = @intFromEnum(unit.word_size);
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        @as(*[12]u8, @ptrCast(buf[len..].ptr)).* = ", addr_size=".*;
        len +%= 12;
        ud64.value = unit.addr_size;
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        debug.write(buf[0 .. len +% 1]);
    }
    fn abbrevTableNotice(abbrev_tab: *AbbrevTable) void {
        @setRuntimeSafety(is_safe);
        var buf: [32768]u8 = undefined;
        var tmp: [24]u8 = undefined;
        var len: usize = 0;
        var id64: fmt.Id64 = undefined;
        @as(fmt.AboutDest, @ptrCast(&buf)).* = abbrev_tab_s.*;
        len +%= abbrev_tab_s.len;
        for (abbrev_tab.ents[0..abbrev_tab.ents_len]) |*ent| {
            len = 0;
            @as(fmt.AboutDest, @ptrCast(buf[len..].ptr)).* = abbrev_code_s.*;
            len +%= abbrev_code_s.len;
            id64.value = @bitCast(ent.head.code);
            len +%= id64.formatWriteBuf(buf[len..].ptr);
            @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
            len +%= 2;
            @memcpy(buf[len..].ptr, @tagName(ent.head.tag));
            len +%= @tagName(ent.head.tag).len;
            buf[len] = '\n';
            len +%= 1;
            for (ent.kvs[0..ent.kvs_len], 0..) |*kv, kv_idx| {
                id64.value = @bitCast(kv_idx);
                const tmp_len: usize = id64.formatWriteBuf(&tmp);
                @as(*[4]u8, @ptrCast(buf[len..].ptr)).* = "    ".*;
                len +%= 4 -% tmp_len;
                @memcpy(buf[len..].ptr, tmp[0..tmp_len]);
                len +%= tmp_len;
                buf[len] = ':';
                len +%= 1;
                @memset(buf[len .. len +% 11], ' ');
                len +%= 11;
                @memcpy(buf[len..].ptr, @tagName(kv.attr));
                len +%= @tagName(kv.attr).len;
                @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ": ".*;
                len +%= 2;
                @memcpy(buf[len..].ptr, @tagName(kv.form));
                len +%= @tagName(kv.form).len;
                if (kv.payload != 0) {
                    @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = " = ".*;
                    len +%= 3;
                    id64.value = @bitCast(kv.payload);
                    len +%= id64.formatWriteBuf(buf[len..].ptr);
                }
                buf[len] = '\n';
                debug.write(buf[0 .. len +% 1]);
                len = 0;
            }
        }
    }
    fn debugDieNotice(info_entry: *Die) void {
        @setRuntimeSafety(is_safe);
        var buf: [32768]u8 = undefined;
        buf[0..debug_entry_s.len].* = debug_entry_s.*;
        var ptr: [*]u8 = buf[debug_entry_s.len..];
        ptr = fmt.strcpyEqu(ptr, @tagName(info_entry.head.tag));
        ptr[0] = '\n';
        ptr += 1;
        for (info_entry.kvs[0..info_entry.kvs_len], 0..) |*kv, kv_idx| {
            ptr = fmt.SideBarIndexFormat.write(ptr, 4, kv_idx);
            ptr = fmt.strcpyEqu(ptr, @tagName(kv.key));
            ptr[0..2].* = ": ".*;
            ptr += 2;
            ptr = fmt.strcpyEqu(ptr, @tagName(kv.val));
            ptr[0..3].* = " = ".*;
            ptr += 3;
            switch (kv.val) {
                .Address => |addr| {
                    ptr = fmt.Ixsize.write(ptr, @bitCast(addr));
                },
                .AddrOffset => |addrx| {
                    ptr = fmt.Idsize.write(ptr, @bitCast(addrx));
                },
                .Block => |block| {
                    debug.write(fmt.slice(ptr, &buf));
                    ptr = &buf;
                    debug.write(block);
                },
                .Const => |val| {
                    ptr = fmt.Idsize.write(ptr, @bitCast(val.payload));
                },
                .Ref => |ref| {
                    ptr[0] = '@';
                    ptr += 1;
                    ptr = fmt.Idsize.write(ptr, @bitCast(ref));
                },
                .String => |name| {
                    ptr = fmt.strcpyEqu(ptr, name);
                },
                else => {},
            }
            ptr[0] = '\n';
            ptr += 1;
            debug.write(fmt.slice(ptr, &buf));
            ptr = buf[0..];
        }
    }
};
