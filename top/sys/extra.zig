pub const Clone = struct {
    pub const clear_signal_handlers = 0;
    pub const new_time = 128;
    pub const vm = 256;
    pub const fs = 512;
    pub const files = 1024;
    pub const signal_handlers = 2048;
    pub const pid_fd = 4096;
    pub const traced = 8192;
    pub const vfork = 16384;
    pub const thread = 65536;
    pub const new_namespace = 131072;
    pub const sysvsem = 262144;
    pub const set_thread_local_storage = 524288;
    pub const set_parent_thread_id = 1048576;
    pub const clear_child_thread_id = 2097152;
    pub const detached = 4194304;
    pub const untraced = 8388608;
    pub const set_child_thread_id = 16777216;
    pub const new_cgroup = 33554432;
    pub const new_uts = 67108864;
    pub const new_ipc = 134217728;
    pub const new_user = 268435456;
    pub const new_pid = 536870912;
    pub const new_net = 1073741824;
    pub const io = 2147483648;
    pub const default_value = struct {
        pub const clear_signal_handlers = 0;
        pub const new_time = 0;
        pub const vm = 0;
        pub const fs = 0;
        pub const files = 0;
        pub const signal_handlers = 0;
        pub const pid_fd = 0;
        pub const traced = 0;
        pub const vfork = 0;
        pub const thread = 0;
        pub const new_namespace = 0;
        pub const sysvsem = 0;
        pub const set_thread_local_storage = 0;
        pub const set_parent_thread_id = 0;
        pub const clear_child_thread_id = 0;
        pub const detached = 0;
        pub const untraced = 0;
        pub const set_child_thread_id = 0;
        pub const new_cgroup = 0;
        pub const new_uts = 0;
        pub const new_ipc = 0;
        pub const new_user = 0;
        pub const new_pid = 0;
        pub const new_net = 0;
        pub const io = 0;
    };
    pub const extra_names: []const []const u8 = &.{};
};
pub const SignalAction = struct {
    pub const no_child_stop = 1;
    pub const no_child_wait = 2;
    pub const siginfo = 4;
    pub const unsupported = 1024;
    pub const expose_tagbits = 2048;
    pub const restorer = 67108864;
    pub const on_stack = 134217728;
    pub const restart = 268435456;
    pub const no_defer = 1073741824;
    pub const reset_handler = 2147483648;
    pub const default_value = struct {
        pub const no_child_stop = 0;
        pub const no_child_wait = 0;
        pub const siginfo = 0;
        pub const unsupported = 0;
        pub const expose_tagbits = 0;
        pub const restorer = 0;
        pub const on_stack = 0;
        pub const restart = 0;
        pub const no_defer = 0;
        pub const reset_handler = 0;
    };
    pub const extra_names: []const []const u8 = &.{};
};