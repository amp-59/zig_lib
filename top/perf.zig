const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub const Measurement = struct {
    name: []const u8,
    config: Config,
};
pub const CPU = enum(u64) {
    any = ~@as(u32, 0),
    self = 0,
    _,
    pub fn no(val: u32) CPU {
        return @intToEnum(CPU, val);
    }
};
pub const Process = enum(usize) {
    all = ~@as(u32, 0),
    self = 0,
    _,
    pub fn id(val: u32) Process {
        return @intToEnum(Process, val);
    }
};
pub const Event = extern struct {
    /// Major type: hardware/software/tracepoint/etc.
    type: Type,
    /// Size of the attr structure, for fwd/bwd compat.
    size: u32 = @sizeOf(Event),
    /// Type specific configuration information.
    config: Config,
    sample_period_or_freq: u64 = 0,
    sample_type: u64 = 0,
    read_format: Format = .{},
    flags: Event.Flags = .{},
    /// wakeup every n events, or
    /// bytes before wakeup
    wakeup_events_or_watermark: u32 = 0,
    bp_type: u32 = 0,
    /// This field is also used for:
    /// bp_addr
    /// kprobe_func for perf_kprobe
    /// uprobe_path for perf_uprobe
    config1: u64 = 0,
    /// This field is also used for:
    /// bp_len
    /// kprobe_addr when kprobe_func == null
    /// probe_offset for perf_[k,u]probe
    config2: u64 = 0,
    /// enum perf_branch_sample_type
    branch_sample_type: u64 = 0,
    /// Defines set of user regs to dump on samples.
    /// See asm/perf_regs.h for details.
    sample_regs_user: u64 = 0,
    /// Defines size of the user stack to dump on samples.
    sample_stack_user: u32 = 0,
    clockid: i32 = 0,
    /// Defines set of regs to dump for each sample
    /// state captured on:
    ///  - precise = 0: PMU interrupt
    ///  - precise > 0: sampled instruction
    ///
    /// See asm/perf_regs.h for details.
    sample_regs_intr: u64 = 0,

    /// Wakeup watermark for AUX area
    aux_watermark: u32 = 0,
    sample_max_stack: u16 = 0,
    /// Align to u64
    zb: u16 = 0,
    pub const Flags = packed struct {
        /// off by default
        disabled: bool = false,
        /// children inherit it
        inherit: bool = false,
        /// must always be on PMU
        pinned: bool = false,
        /// only group on PMU
        exclusive: bool = false,
        /// don't count user
        exclude_user: bool = false,
        /// ditto kernel
        exclude_kernel: bool = false,
        /// ditto hypervisor
        exclude_hv: bool = false,
        /// don't count when idle
        exclude_idle: bool = false,
        /// include mmap data
        mmap: bool = false,
        /// include comm data
        comm: bool = false,
        /// use freq, not period
        freq: bool = false,
        /// per task counts
        inherit_stat: bool = false,
        /// next exec enables
        enable_on_exec: bool = false,
        /// trace fork/exit
        task: bool = false,
        /// wakeup_watermark
        watermark: bool = false,
        /// precise_ip:
        ///
        ///  0 - SAMPLE_IP can have arbitrary skid
        ///  1 - SAMPLE_IP must have constant skid
        ///  2 - SAMPLE_IP requested to have 0 skid
        ///  3 - SAMPLE_IP must have 0 skid
        ///
        ///  See also PERF_RECORD_MISC_EXACT_IP
        /// skid constraint
        precise_ip: u2 = 0,
        /// non-exec mmap data
        mmap_data: bool = false,
        /// sample_type all events
        sample_id_all: bool = false,
        /// don't count in host
        exclude_host: bool = false,
        /// don't count in guest
        exclude_guest: bool = false,
        /// exclude kernel callchains
        exclude_callchain_kernel: bool = false,
        /// exclude user callchains
        exclude_callchain_user: bool = false,
        /// include mmap with inode data
        mmap2: bool = false,
        /// flag comm events that are due to an exec
        comm_exec: bool = false,
        /// use @clockid for time fields
        use_clockid: bool = false,
        /// context switch data
        context_switch: bool = false,
        /// Write ring buffer from end to beginning
        write_backward: bool = false,
        /// include namespaces data
        namespaces: bool = false,
        zb: u35 = 0,
    };
    const Format = packed struct(usize) {
        total_time_enabled: bool = false,
        total_time_running: bool = false,
        id: bool = false,
        group: bool = false,
        lost: bool = false,
        max: bool = false,
        zb6: u58 = 0,
    };
    pub const IOC = enum(u32) {
        enable = 9216,
        disable = 9217,
        refresh = 9218,
        reset = 9219,
        set_output = 9221,
        set_bpf = 1074013192,
        pause_output = 1074013193,
        period = 1074275332,
        set_filter = 1074275334,
        modify_attributes = 1074275339,
        query_bpf = 3221758986,
    };
};
pub const Count = struct {
    pub const Software = enum(u64) {
        cpu_clock = 0,
        task_clock = 1,
        page_faults = 2,
        context_switches = 3,
        cpu_migrations = 4,
        page_faults_min = 5,
        page_faults_maj = 6,
        alignment_faults = 7,
        emulation_faults = 8,
        dummy = 9,
        bpf_output = 10,
        cgroup_switches = 11,
        max = 12,
    };
    pub const Hardware = enum(u64) {
        cpu_cycles = 0,
        instructions = 1,
        cache_references = 2,
        cache_misses = 3,
        branch_instructions = 4,
        branch_misses = 5,
        bus_cycles = 6,
        stalled_cycles_frontend = 7,
        stalled_cycles_backend = 8,
        ref_cpu_cycles = 9,
        max = 10,
    };
    const HWCache = enum(u3) {
        l1d = 0,
        l1i = 1,
        ll = 2,
        dtlb = 3,
        itlb = 4,
        bpu = 5,
        node = 6,
        max = 7,
        pub const Operation = enum(u2) {
            read = 0,
            write = 1,
            prefetch = 2,
            max = 3,
        };
        pub const Result = enum(u2) {
            access = 0,
            miss = 1,
            max = 2,
        };
    };
};
const Type = enum(u32) {
    hardware = 0,
    software = 1,
    tracepoint = 2,
    hw_cache = 3,
    raw = 4,
    breakpoint = 5,
    max = 6,
};
const Config = extern union {
    hardware: Count.Hardware,
    software: Count.Software,
    tracepoint: void,
    hw_cache: void,
    raw: void,
    breakpoint: void,
    max: void,
};
const Sample = enum(u32) {
    ip = 1,
    tid = 2,
    time = 4,
    addr = 8,
    read = 16,
    callchain = 32,
    id = 64,
    cpu = 128,
    period = 256,
    stream_id = 512,
    raw = 1024,
    branch_stack = 2048,
    regs_user = 4096,
    stack_user = 8192,
    weight = 16384,
    data_src = 32768,
    identifier = 65536,
    transaction = 131072,
    regs_intr = 262144,
    phys_addr = 524288,
    aux = 1048576,
    cgroup = 2097152,
    data_page_size = 4194304,
    code_page_size = 8388608,
    weight_struct = 16777216,
    max = 33554432,
    const Branch = enum(u32) {
        user = 1,
        kernel = 2,
        hv = 4,
        any = 8,
        any_call = 16,
        any_return = 32,
        ind_call = 64,
        abort_tx = 128,
        in_tx = 256,
        no_tx = 512,
        cond = 1024,
        call_stack = 2048,
        ind_jump = 4096,
        call = 8192,
        no_flags = 16384,
        no_cycles = 32768,
        type_save = 65536,
        hw_index = 131072,
        priv_save = 262144,
        max = 524288,
    };
    const Registers = enum(u2) {
        abi_none = 0,
        abi_32 = 1,
        abi_64 = 2,
    };
};
pub const Branch = enum(u5) {
    cond = 1,
    uncond = 2,
    ind = 3,
    call = 4,
    ind_call = 5,
    ret = 6,
    syscall = 7,
    sysret = 8,
    cond_call = 9,
    cond_ret = 10,
    eret = 11,
    irq = 12,
    serror = 13,
    no_tx = 14,
    extend_abi = 15,
    max = 16,
    pub const Spec = enum(u3) {
        wrong_path = 1,
        non_spec_correct_path = 2,
        correct_path = 3,
        max = 4,
    };
    pub const New = enum(u4) {
        fault_data = 1,
        fault_inst = 2,
        arch_1 = 3,
        arch_2 = 4,
        arch_3 = 5,
        arch_4 = 6,
        arch_5 = 7,
        max = 8,
    };
    pub const Private = enum(u2) {
        user = 1,
        kernel = 2,
        hv = 3,
    };
};
pub const Flags = packed struct(u8) {
    fd_no_group: bool = false,
    fd_output: bool = false,
    pid_cgroup: bool = false,
    fd_close_on_exec: bool = false,
    zb4: u4 = 0,
};
pub const PerfEventSpec = struct {
    logging: builtin.Logging.SuccessError = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.perf_event_open_errors },
};
pub fn eventOpen(comptime perf_spec: PerfEventSpec, event: *const Event, pid: Process, cpu: CPU, fd: u64, flags: Flags) sys.ErrorUnion(perf_spec.errors, u64) {
    if (meta.wrap(sys.call(.perf_event_open, perf_spec.errors, u64, .{
        @ptrToInt(event), @enumToInt(pid), @enumToInt(cpu), fd, @bitCast(u8, flags),
    }))) |ret| {
        return ret;
    } else |perf_event_open_error| {
        return perf_event_open_error;
    }
}
pub const PerfEventControlSpec = struct {
    logging: builtin.Logging.SuccessError = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.ioctl_errors },
};
pub fn eventControl(comptime perf_spec: PerfEventControlSpec, fd: u64, ctl: Event.IOC, apply_group: bool) sys.ErrorUnion(perf_spec.errors, void) {
    if (meta.wrap(sys.call(.ioctl, perf_spec.errors, void, .{
        fd, @enumToInt(ctl), @boolToInt(apply_group),
    }))) |ret| {
        return ret;
    } else |ioctl_error| {
        return ioctl_error;
    }
}
