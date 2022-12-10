const sys = @import("./sys.zig");
const meta = @import("./meta.zig");

pub const Open = meta.EnumBitField(enum(u64) {
    no_cache = OPEN.DIRECT,
    no_atime = OPEN.NOATIME,
    no_follow = OPEN.NOFOLLOW,
    no_block = OPEN.NONBLOCK,
    no_ctty = OPEN.NOCTTY,
    close_on_exec = OPEN.CLOEXEC,
    temporary = OPEN.TMPFILE,
    directory = OPEN.DIRECTORY,
    path = OPEN.PATH,
    append = OPEN.APPEND,
    truncate = OPEN.TRUNC,
    create = OPEN.CREAT,
    read_only = OPEN.RDONLY,
    write_only = OPEN.WRONLY,
    read_write = OPEN.RDWR,
    exclusive = OPEN.EXCL,
    const OPEN = sys.O;
});
const Mode = meta.EnumBitField(enum(u16) {
    owner_read = MODE.IRUSR,
    owner_write = MODE.IWUSR,
    owner_execute = MODE.IXUSR,
    group_read = MODE.IRGRP,
    group_write = MODE.IWGRP,
    group_execute = MODE.IXGRP,
    other_read = MODE.IROTH,
    other_write = MODE.IWOTH,
    other_execute = MODE.IXOTH,
    regular = MODE.IFREG,
    directory = MODE.IFDIR,
    character_special = MODE.IFCHR,
    block_special = MODE.IFBLK,
    named_pipe = MODE.IFIFO,
    socket = MODE.IFSOCK,
    symbolic_link = MODE.IFLNK,

    const MODE = sys.S;
});
