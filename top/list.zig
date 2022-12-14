const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const builtin = @import("./builtin.zig");
pub const ListSpec = struct {
    child: type,
    low_alignment: u64,
    Allocator: type,
};
pub fn XorLinkedListAdv(comptime spec: ListSpec) type {
    return struct {
        links: Links,
        count: u64,
        index: u64,
        save: ?Block = null,
        const List = @This();
        const Allocator = list_spec.Allocator;
        const Block = Allocator.UnstructuredStaticViewLowAligned(Node.size, Node.alignment).Reference;
        pub const Node = struct {
            blk: Block,
            pub fn read(s_node: Node) child {
                return Data.read(s_node.blk);
            }
            pub fn refer(s_node: Node) *child {
                return Data.refer(s_node.blk);
            }
            pub const Data = opaque {
                const begin: u64 = if (!link_after) link_size else 0;
                const len: u64 = mach.alignA64(unit_size, link_alignment);
                const end: u64 = begin + len;
                fn addr(t_node_blk: Block) u64 {
                    return t_node_blk.start() + Node.Data.begin;
                }
                fn read(s_node_blk: Block) child {
                    const s_data_addr: u64 = Node.Data.addr(s_node_blk);
                    return builtin.intToPtr(*child, s_data_addr).*;
                }
                fn write(s_node_blk: Block, s_data: child) void {
                    const s_data_addr: u64 = Node.Data.addr(s_node_blk);
                    builtin.intToPtr(*child, s_data_addr).* = s_data;
                }
                fn refer(s_node_blk: Block) *child {
                    const s_data_addr: u64 = Node.Data.addr(s_node_blk);
                    return builtin.intToPtr(*child, s_data_addr);
                }
            };
            pub const Link = opaque {
                const begin: u64 = if (link_after) mem.alignAbove(unit_size, link_alignment) else 0;
                const len: u64 = link_size;
                const end: u64 = begin + len;
                fn addr(t_node_blk: Block) u64 {
                    return t_node_blk.start() + Node.Link.begin;
                }
                fn refer(s_node_blk: Block) *u64 {
                    return builtin.intToPtr(*u64, Node.Link.addr(s_node_blk));
                }
                fn read(s_node_blk: Block) u64 {
                    return builtin.intToPtr(*u64, Node.Link.addr(s_node_blk)).*;
                }
                fn write(t_node_blk: Block, b_node_blk: Block, a_node_blk: Block) void {
                    builtin.intToPtr(*u64, Node.Link.addr(t_node_blk)).* = (b_node_blk.lb_word ^ a_node_blk.lb_word);
                }
                fn mutate(t_node_blk: Block, b_node_blk: Block, a_node_blk: Block) void {
                    builtin.intToPtr(*u64, Node.Link.addr(t_node_blk)).* = (b_node_blk.lb_word ^ a_node_blk.lb_word);
                }
                fn prev(s_node_blk: Block, t_node_blk: Block) Block {
                    const x_addr: u64 = builtin.intToPtr(*u64, Node.Link.addr(s_node_blk)).*;
                    return Block{ .lb_word = x_addr ^ t_node_blk.lb_word };
                }
                fn next(s_node_blk: Block, t_node_blk: Block) Block {
                    const x_addr: u64 = builtin.intToPtr(*u64, Node.Link.addr(t_node_blk)).*;
                    return Block{ .lb_word = s_node_blk.lb_word ^ x_addr };
                }
                fn integrateAfter(s_node_blk: Block, t_node_blk: Block, a_node_blk: Block, s_data: child) Links {
                    Node.Link.write(a_node_blk, t_node_blk, zero_block);
                    Node.Link.write(t_node_blk, s_node_blk, a_node_blk);
                    Node.Data.write(t_node_blk, s_data);
                    return .{ .major = t_node_blk, .minor = a_node_blk };
                }
                fn integrateBefore(b_node_blk: Block, s_node_blk: Block, t_node_blk: Block, s_data: child) Links {
                    Node.Link.write(b_node_blk, zero_block, s_node_blk);
                    Node.Link.write(s_node_blk, b_node_blk, t_node_blk);
                    Node.Data.write(b_node_blk, s_data);
                    return .{ .major = b_node_blk, .minor = s_node_blk };
                }
                fn integrateBetween(p_node_blk: Block, i_node_blk: Block, s_node_blk: Block, s_data: child) void {
                    const b_node_blk: Block = Node.Link.prev(p_node_blk, s_node_blk);
                    const a_node_blk: Block = Node.Link.next(p_node_blk, s_node_blk);
                    Node.Link.mutate(p_node_blk, b_node_blk, i_node_blk);
                    Node.Link.mutate(i_node_blk, p_node_blk, s_node_blk);
                    Node.Link.mutate(s_node_blk, i_node_blk, a_node_blk);
                    Node.Data.write(i_node_blk, s_data);
                }
                fn disintegrateAfter(s_node_blk: Block, t_node_blk: Block) Links {
                    const p_node_blk: Block = Node.Link.prev(s_node_blk, t_node_blk);
                    const o_node_blk: Block = Node.Link.prev(p_node_blk, s_node_blk);
                    Node.Link.mutate(p_node_blk, o_node_blk, t_node_blk);
                    Node.Link.write(t_node_blk, p_node_blk, zero_block);
                    Node.Link.refer(s_node_blk).* = 0;
                    return .{ .major = p_node_blk, .minor = t_node_blk };
                }
                fn disintegrateBefore(s_node_blk: Block, t_node_blk: Block) Links {
                    const n_node_blk: Block = Node.Link.next(s_node_blk, t_node_blk);
                    Node.Link.write(t_node_blk, zero_block, n_node_blk);
                    Node.Link.refer(s_node_blk).* = 0;
                    return .{ .major = t_node_blk, .minor = n_node_blk };
                }
                fn disintegrateBetween(m_node_blk: Block, t_node_blk: Block) Links {
                    const p_node_blk: Block = Node.Link.prev(m_node_blk, t_node_blk);
                    const i_node_blk: Block = Node.Link.next(m_node_blk, t_node_blk);
                    const n_node_blk: Block = Node.Link.next(t_node_blk, i_node_blk);
                    Node.Link.mutate(m_node_blk, p_node_blk, i_node_blk);
                    Node.Link.mutate(i_node_blk, m_node_blk, n_node_blk);
                    Node.Link.refer(t_node_blk).* = 0;
                    return .{ .major = i_node_blk, .minor = n_node_blk };
                }
            };
            const link_after: bool = link_alignment < low_alignment;
            const link_size: u64 = @sizeOf(u64);
            const link_alignment: u64 = @alignOf(u64);
            const unit_size: u64 = @sizeOf(child);
            const low_alignment: u64 = @alignOf(child);
            const alignment: u64 = builtin.max(u64, link_alignment, low_alignment);
            const offset: u64 = builtin.max(u64, Link.end, Data.end);
            const size: u64 = mach.alignA64(offset, if (link_after) link_alignment else low_alignment);
        };
        pub const Links = struct {
            major: Block,
            minor: Block,
            pub fn set(major: anytype, minor: anytype) Links {
                return .{ .major = @bitCast(Block, major), .minor = @bitCast(Block, minor) };
            }
            pub fn basicInit(s: anytype, t: anytype) Links {
                const s_node_blk: Block = if (@TypeOf(s) == Block) s else .{ .lb_word = s };
                const t_node_blk: Block = if (@TypeOf(t) == Block) t else .{ .lb_word = t };
                Node.Link.write(s_node_blk, zero_block, t_node_blk);
                Node.Link.write(t_node_blk, s_node_blk, zero_block);
                return .{ .major = s_node_blk, .minor = t_node_blk };
            }
            pub fn next(links: Links) ?Block {
                const t_next_blk: Block = Node.Link.next(links.major, links.minor);
                return mach.cmovxZ(t_next_blk.start() > 0x10000, t_next_blk);
            }
            pub fn prev(links: Links) ?Block {
                const t_prev_blk: Block = Node.Link.prev(links.major, links.minor);
                return mach.cmovxZ(t_prev_blk.start() > 0x10000, t_prev_blk);
            }
            pub fn nextPair(links: Links) ?Links {
                const t_next_blk: Block = Node.Link.next(links.major, links.minor);
                return mach.cmovxZ(t_next_blk.start() > 0x10000, Links{ .major = links.minor, .minor = t_next_blk });
            }
            pub fn prevPair(links: Links) ?Links {
                const t_prev_blk: Block = Node.Link.prev(links.major, links.minor);
                return mach.cmovxZ(t_prev_blk.start() > 0x10000, Links{ .major = t_prev_blk, .minor = links.major });
            }
            pub fn toList(links: *Links) List {
                const index = links.countToHead();
                return .{
                    .links = links.*,
                    .index = index,
                    .count = index + links.countToTail(),
                };
            }
            fn countToHead(links: Links) u64 {
                var temp: Links = links;
                var i: u64 = 0;
                while (temp.prevPair()) |prev_pair| {
                    temp = prev_pair;
                    i += 1;
                }
                return i;
            }
            fn countToTail(links: Links) u64 {
                var temp: Links = links;
                var i: u64 = 0;
                while (temp.nextPair()) |next_pair| {
                    temp = next_pair;
                    i += 1;
                }
                return i;
            }
        };
        pub const list_spec: ListSpec = spec;
        const child = list_spec.child;
        const zero_block: Block = .{ .lb_word = 0 };
        pub fn this(list: *List) *child {
            return Node.Data.refer(list.links.major);
        }
        pub fn at(list: *List, i: u64) !*child {
            try list.goTo(i);
            return list.this();
        }
        pub fn next(list: List) ?List {
            if (list.links.nextPair()) |links| {
                return List{ .links = links, .count = list.count, .index = list.index + 1, .save = list.save };
            }
            return null;
        }
        pub fn prev(list: List) ?List {
            if (list.links.prevPair()) |links| {
                return List{ .links = links, .count = list.count, .index = list.index - 1, .save = list.save };
            }
            return null;
        }
        pub fn goToHead(list: *List) void {
            while (list.links.prevPair()) |links| {
                list.links = links;
                list.index -= 1;
            }
        }
        pub fn goToTail(list: *List) void {
            while (list.links.nextPair()) |links| {
                list.links = links;
                list.index += 1;
            }
        }
        pub fn goToNext(list: *List) error{NoItems}!void {
            if (list.links.nextPair()) |next_pair| {
                list.links = next_pair;
                list.index += 1;
            } else {
                return error.NoItems;
            }
        }
        pub fn goToPrev(list: *List) error{NoItems}!void {
            if (list.links.prevPair()) |prev_pair| {
                list.links = prev_pair;
                list.index -= 1;
            } else {
                return error.NoItems;
            }
        }
        pub fn goTo(list: *List, to: u64) !void {
            if (to != list.index) {
                while (to < list.index) {
                    try list.goToPrev();
                } else while (to > list.index) {
                    try list.goToNext();
                }
            }
        }
        fn unlinkA(list: *List, allocator: *Allocator) void {
            list.goToTail();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateAfter(s_node_blk, t_node_blk);
            list.count -= 1;
            list.index = list.count;
            s_node_blk.destroy(allocator);
        }
        fn unlinkB(list: *List, allocator: *Allocator) void {
            list.goToHead();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateBefore(s_node_blk, t_node_blk);
            list.count -= 1;
            s_node_blk.destroy(allocator);
        }
        fn unlinkC(list: *List, allocator: *Allocator, index: u64) !void {
            try list.goTo(index - 1);
            const m_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateBetween(m_node_blk, t_node_blk);
            list.index = index;
            list.count -= 1;
            t_node_blk.destroy(allocator);
        }
        pub fn unlink(list: *List, allocator: *Allocator, i: ?u64) !void {
            const index: u64 = i orelse list.index;
            if (index == 0) {
                return list.unlinkB(allocator);
            }
            if (index == list.count) {
                return list.unlinkA(allocator);
            }
            return list.unlinkC(allocator, index);
        }
        fn extract0(list: *List) Node {
            const s_node_blk: Block = list.links.major;
            list.count -= 1;
            return .{ .blk = s_node_blk };
        }
        fn extractA(list: *List) Node {
            list.goToTail();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateAfter(s_node_blk, t_node_blk);
            list.count -= 1;
            list.index -= 1;
            return .{ .blk = s_node_blk };
        }
        fn extractB(list: *List) Node {
            list.goToHead();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateBefore(s_node_blk, t_node_blk);
            list.count -= 1;
            return .{ .blk = s_node_blk };
        }
        fn extractC(list: *List, index: u64) !Node {
            try list.goTo(index - 1);
            const m_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.disintegrateBetween(m_node_blk, t_node_blk);
            list.index = index;
            list.count -= 1;
            return .{ .blk = t_node_blk };
        }
        pub fn extract(list: *List, index: u64) !Node {
            if (list.count == 0) {
                return error.NoItems;
            }
            if (list.count == 1) {
                return list.extract0();
            }
            if (index == 0) {
                return list.extractB();
            }
            if (list.count == index + 1) {
                return list.extractA();
            }
            return list.extractC(index);
        }
        /// Effectively increments the list index
        pub fn delete(list: *List, index: ?u64) !void {
            if (list.count == 0) {
                return error.NoItems;
            }
            switch (list.count) {
                1, 2 => {
                    const b: bool = index orelse list.index == 0;
                    const s_node_blk: Block = mach.cmovx(b, list.links.minor, list.links.major);
                    const t_node_blk: Block = mach.cmovx(b, list.links.major, list.links.minor);
                    list.links = Links.basicInit(s_node_blk, t_node_blk);
                    list.count -= 1;
                },
                else => {
                    const data: Node = try list.extract(index orelse list.index);
                    list.retire(data);
                },
            }
        }
        pub fn retire(list: *List, s_node: Node) void {
            list.setNodeBlock(s_node.blk);
        }
        fn insertInitial(list: *List, data: child) void {
            const s_node_blk: Block = list.links.major;
            Node.Data.write(s_node_blk, data);
            list.count += 1;
        }
        fn insertAfter(list: *List, data: child, n_node_blk: Block) !void {
            list.goToTail();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.integrateAfter(s_node_blk, t_node_blk, n_node_blk, data);
            list.index += 1;
            list.count += 1;
        }
        pub fn insertBefore(list: *List, data: child, b_node_blk: Block) !void {
            list.goToHead();
            const s_node_blk: Block = list.links.major;
            const t_node_blk: Block = list.links.minor;
            list.links = Node.Link.integrateBefore(b_node_blk, s_node_blk, t_node_blk, data);
            list.count += 1;
        }
        fn insertBetween(list: *List, index: u64, data: child, i_node_blk: Block) !void {
            try list.goTo(index - 1);
            const p_node_blk: Block = list.links.major;
            const s_node_blk: Block = list.links.minor;
            Node.Link.integrateBetween(p_node_blk, i_node_blk, s_node_blk, data);
            list.links.major = i_node_blk;
            list.index += 1;
            list.count += 1;
        }
        pub fn insert(list: *List, allocator: *Allocator, i: ?u64, data: child) !void {
            const count: u64 = list.count;
            const index: u64 = i orelse list.index;
            const n_node_blk: Block = try list.getNodeBlock(allocator);
            if (index == 0) {
                return list.insertBefore(data, n_node_blk);
            }
            if (index == count) {
                return list.insertAfter(data, n_node_blk);
            }
            if (count == 0) {
                return list.insertInitial(data);
            }
            return list.insertBetween(index, data, n_node_blk);
        }
        pub fn new(list: *List, allocator: *Allocator) !*child {
            try list.append(allocator, zero_block);
            return list.this();
        }
        pub fn append(list: *List, allocator: *Allocator, data: child) !void {
            if (list.count == 0) {
                return list.insertInitial(data);
            }
            const n_node_blk: Block = try list.getNodeBlock(allocator);
            try @call(
                .{ .modifier = .always_inline },
                insertAfter,
                .{ list, data, n_node_blk },
            );
        }
        pub fn prepend(list: *List, allocator: *Allocator, data: child) !void {
            if (list.count == 0) {
                return list.insertInitial(data);
            }
            const n_node_blk: Block = try list.getNodeBlock(allocator);
            try @call(
                .{ .modifier = .always_inline },
                insertBefore,
                .{ list, data, n_node_blk },
            );
        }
        fn getNodeBlock(list: *List, allocator: *Allocator) !Block {
            if (list.save) |s_save_blk| {
                const t_save_addr: u64 = Node.Link.read(s_save_blk);
                list.save = mach.cmovxZ(t_save_addr != 0, Block{ .lb_word = t_save_addr });
                return s_save_blk;
            } else {
                return allocator.allocateStatic(Block, .{ .count = 1 });
            }
        }
        fn setNodeBlock(list: *List, s_node_blk: Block) void {
            if (list.save) |s_save_blk| {
                Node.Link.refer(s_node_blk).* = s_save_blk.lb_word;
            }
            list.save = s_node_blk;
        }
        fn Match(comptime decls: anytype) type {
            if (comptime meta.isNothing(decls)) {
                return child;
            } else {
                return meta.RecursedField(child, decls);
            }
        }
        fn value(list: *List, comptime decls: anytype) Match(decls) {
            if (comptime meta.isNothing(decls)) {
                return list.this().*;
            } else {
                return meta.recursedField(child, decls, list.this().*);
            }
        }
        fn matchG(list: List, comptime decls: anytype, l_value: Match(decls)) ?List {
            var tmp: List = list;
            tmp.goToHead();
            if (tmp.count <= 1) {
                if (mem.eql(l_value, tmp.value(decls))) {
                    return tmp;
                }
            } else {
                if (tmp.links.nextPair()) |links| {
                    if (mem.eql(l_value, tmp.value(decls))) {
                        return tmp;
                    }
                    tmp.links = links;
                    tmp.index += 1;
                }
                while (tmp.links.nextPair()) |links| {
                    if (mem.eql(l_value, tmp.value(decls))) {
                        return tmp;
                    }
                    tmp.links = links;
                    tmp.index += 1;
                }
                if (mem.eql(l_value, tmp.value(decls))) {
                    return tmp;
                }
            }
        }
        fn matchA(list: *List, comptime decls: anytype, l_value: Match(decls)) bool {
            var ret: List = list.*;
            ret.goToHead();
            while (ret.links.nextPair()) |t_links| {
                if (mem.eql(l_value, ret.value(decls))) {
                    list.* = ret;
                    return true;
                }
                ret.index += 1;
                ret.links = t_links;
            } else {
                if (mem.eql(l_value, ret.value(decls))) {
                    list.* = ret;
                    return true;
                }
            }
            return false;
        }
        pub fn iterator(list: List) List {
            var ret: List = list;
            ret.goToHead();
            return ret;
        }
        pub fn init(allocator: *Allocator) !List {
            const s_node_blk: Block = try allocator.allocateStatic(Block, .{ .count = 1 });
            const t_node_blk: Block = try allocator.allocateStatic(Block, .{ .count = 1 });
            Node.Link.write(s_node_blk, zero_block, t_node_blk);
            Node.Link.write(t_node_blk, s_node_blk, zero_block);
            return List{ .links = .{ .major = s_node_blk, .minor = t_node_blk }, .index = 0, .count = 0 };
        }
        pub fn deinit(list: *List, allocator: *Allocator) void {
            while (list.save) |s_save_addr| {
                const t_save_addr: u64 = Node.Link.read(s_save_addr);
                list.save = mach.cmovxZ(t_save_addr != 0, Block{ .lb_word = t_save_addr });
                allocator.deallocateStatic(Block, s_save_addr, .{ .count = 1 });
            }
            switch (list.count) {
                0, 1 => {
                    if (list.links.major.start() + Node.size == list.links.minor.start()) {
                        allocator.deallocateStatic(Block, list.links.major, .{ .count = 2 });
                    } else {
                        allocator.deallocateStatic(Block, list.links.major, .{ .count = 1 });
                        allocator.deallocateStatic(Block, list.links.minor, .{ .count = 1 });
                    }
                },
                else => {
                    if (list.index <= list.count / 2) {
                        list.goToHead();
                        var s_lb_blk: Block = list.links.major;
                        var n_count: u64 = 1;
                        while (list.next()) |next_list| {
                            if (list.links.minor.start() == list.links.major.start() + Node.size) {
                                n_count += 1;
                            } else {
                                allocator.deallocateStatic(Block, s_lb_blk, .{ .count = n_count });
                                s_lb_blk = list.links.minor;
                                n_count = 1;
                            }
                            list.* = next_list;
                        } else {
                            if (list.links.minor.start() == list.links.major.start() + Node.size) {
                                n_count += 1;
                            } else {
                                allocator.deallocateStatic(Block, list.links.minor, .{ .count = 1 });
                            }
                            allocator.deallocateStatic(Block, s_lb_blk, .{ .count = n_count });
                        }
                    } else {
                        list.goToTail();
                        var s_lb_blk: Block = list.links.minor;
                        var n_count: u64 = 1;
                        while (list.prev()) |prev_list| {
                            if (list.links.minor.start() == list.links.major.start() + Node.size) {
                                n_count += 1;
                            } else {
                                allocator.deallocateStatic(Block, s_lb_blk, .{ .count = n_count });
                                s_lb_blk = list.links.major;
                                n_count = 1;
                            }
                            list.* = prev_list;
                        } else {
                            if (list.links.minor.start() == list.links.major.start() + Node.size) {
                                n_count += 1;
                            } else {
                                allocator.deallocateStatic(Block, list.links.minor, .{ .count = 1 });
                            }
                            allocator.deallocateStatic(Block, s_lb_blk, .{ .count = n_count });
                        }
                    }
                },
            }
        }
        pub const Graphics = struct {
            const IOAllocator = mem.GenericArenaAllocator(.{ .arena_index = 32 });
            const IOPrintArray = IOAllocator.StructuredHolder(u8);
            pub fn show(list: List, address_space: *mem.AddressSpace) !void {
                var allocator: IOAllocator = try IOAllocator.init(address_space);
                defer allocator.deinit(address_space);
                var array: IOPrintArray = IOPrintArray.init(&allocator);
                defer array.deinit(&allocator);
                var tmp: List = list;
                tmp.goToHead();
                if (tmp.count <= 1) {
                    try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                        "head-",    fmt.ud64(tmp.index),
                        ": \t(",    fmt.ux64(tmp.links.major.start()),
                        "+",        fmt.ud64(tmp.links.major.alignment()),
                        ',',        fmt.ux64(tmp.links.minor.start()),
                        "+",        fmt.ud64(tmp.links.minor.alignment()),
                        ")\ndata-", fmt.ud64(tmp.index),
                        ": \t",     fmt.any(Node.Data.read(tmp.links.major)),
                        '\n',
                    });
                } else {
                    if (tmp.links.nextPair()) |links| {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "head-",   fmt.ud64(tmp.index),
                            ": \t(",   fmt.ux64(tmp.links.major.start()),
                            "+",       fmt.ud64(tmp.links.major.alignment()),
                            ',',       fmt.ux64(tmp.links.minor.start()),
                            "+",       fmt.ud64(tmp.links.minor.alignment()),
                            ") -> ",   fmt.ux64(links.major.start()),
                            "+",       fmt.ud64(links.major.alignment()),
                            "\ndata-", fmt.ud64(tmp.index),
                            ": \t",    fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                        tmp.links = links;
                        tmp.index += 1;
                    }
                    while (tmp.links.nextPair()) |links| {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "link-",   fmt.ud64(tmp.index),
                            ": \t",    fmt.ux64(tmp.links.prev().?.start()),
                            "+",       fmt.ud64(tmp.links.prev().?.alignment()),
                            " <- (",   fmt.ux64(tmp.links.major.start()),
                            "+",       fmt.ud64(tmp.links.major.alignment()),
                            ',',       fmt.ux64(tmp.links.minor.start()),
                            "+",       fmt.ud64(tmp.links.minor.alignment()),
                            ") -> ",   fmt.ux64(tmp.links.next().?.start()),
                            "+",       fmt.ud64(tmp.links.next().?.alignment()),
                            "\ndata-", fmt.ud64(tmp.index),
                            ": \t",    fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                        tmp.links = links;
                        tmp.index += 1;
                    } else {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "sentinel-", fmt.ud64(tmp.index),
                            ":\t",       fmt.ux64(tmp.links.prev().?.start()),
                            "+",         fmt.ud64(tmp.links.prev().?.alignment()),
                            " <- (",     fmt.ux64(tmp.links.major.start()),
                            "+",         fmt.ud64(tmp.links.major.alignment()),
                            ',',         fmt.ux64(tmp.links.minor.start()),
                            "+",         fmt.ud64(tmp.links.minor.alignment()),
                            ")\ndata-",  fmt.ud64(tmp.index),
                            ": \t",      fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                    }
                }
                file.noexcept.write(2, array.readAll(allocator));
            }
        };
    };
}
pub const ListViewSpec = struct {
    child: type,
    low_alignment: u64,
};
pub fn XorLinkedListViewAdv(comptime spec: ListViewSpec) type {
    return struct {
        links: Links,
        count: u64,
        index: u64,
        save: ?u64 = null,
        const List = @This();
        pub const Node = opaque {
            pub const Data = opaque {
                const begin: u64 = if (link_after) 0 else link_size;
                const end: u64 = begin + mach.alignA64(unit_size, link_alignment);
                fn read(s_node_addr: u64) child {
                    return builtin.intToPtr(*child, s_node_addr + Node.Data.begin).*;
                }
                fn write(s_node_addr: u64, data: child) void {
                    const s_data_addr: u64 = s_node_addr + Node.Data.begin;
                    builtin.intToPtr(*child, s_data_addr).* = data;
                }
                fn refer(s_node_addr: u64) *child {
                    return builtin.intToPtr(*child, s_node_addr + Node.Data.begin);
                }
                fn node(data: *child) u64 {
                    return @ptrToInt(data) - mach.cmov64z(!Node.link_after, link_size);
                }
            };
            pub const Link = opaque {
                const begin: u64 = if (link_after) mem.alignA64(unit_size, link_alignment) else 0;
                const end: u64 = begin + link_size;
                fn refer(s_node_addr: u64) *u64 {
                    const s_link_addr: u64 = s_node_addr + Node.Link.begin;
                    return builtin.intToPtr(*u64, s_link_addr);
                }
                fn read(s_node_addr: u64) u64 {
                    const s_link_addr: u64 = s_node_addr + Node.Link.begin;
                    return builtin.intToPtr(*u64, s_link_addr).*;
                }
                pub fn write(t_node_addr: u64, b_node_addr: u64, a_node_addr: u64) void {
                    const t_link_addr: u64 = t_node_addr + Node.Link.begin;
                    builtin.intToPtr(*u64, t_link_addr).* = (b_node_addr ^ a_node_addr);
                }
                pub fn mutate(t_node_addr: u64, b_node_addr: u64, a_node_addr: u64) void {
                    const t_link_addr: u64 = t_node_addr + Node.Link.begin;
                    builtin.intToPtr(*u64, t_link_addr).* = (b_node_addr ^ a_node_addr);
                }
                fn prev(s_node_addr: u64, t_node_addr: u64) u64 {
                    const s_link_addr: u64 = s_node_addr + Node.Link.begin;
                    const x_addr: u64 = builtin.intToPtr(*u64, s_link_addr).*;
                    return x_addr ^ t_node_addr;
                }
                fn next(s_node_addr: u64, t_node_addr: u64) u64 {
                    const t_link_addr: u64 = t_node_addr + Node.Link.begin;
                    const x_addr: u64 = builtin.intToPtr(*u64, t_link_addr).*;
                    return x_addr ^ s_node_addr;
                }
                fn integrateAfter(s_node_addr: u64, t_node_addr: u64, a_node_addr: u64, data: child) Links {
                    Node.Link.write(a_node_addr, t_node_addr, 0);
                    Node.Link.write(t_node_addr, s_node_addr, a_node_addr);
                    Node.Data.write(t_node_addr, data);
                    return .{ .major = t_node_addr, .minor = a_node_addr };
                }
                fn integrateBefore(b_node_addr: u64, s_node_addr: u64, t_node_addr: u64, data: child) Links {
                    Node.Link.write(b_node_addr, 0, s_node_addr);
                    Node.Link.write(s_node_addr, b_node_addr, t_node_addr);
                    Node.Data.write(b_node_addr, data);
                    return .{ .major = b_node_addr, .minor = s_node_addr };
                }
                fn integrateBetween(p_node_addr: u64, i_node_addr: u64, s_node_addr: u64, data: child) void {
                    const b_node_addr: u64 = Node.Link.prev(p_node_addr, s_node_addr);
                    const a_node_addr: u64 = Node.Link.next(p_node_addr, s_node_addr);
                    Node.Link.mutate(p_node_addr, b_node_addr, i_node_addr);
                    Node.Link.mutate(i_node_addr, p_node_addr, s_node_addr);
                    Node.Link.mutate(s_node_addr, i_node_addr, a_node_addr);
                    Node.Data.write(i_node_addr, data);
                }
                fn disintegrateAfter(s_node_addr: u64, t_node_addr: u64) Links {
                    const p_node_addr: u64 = Node.Link.prev(s_node_addr, t_node_addr);
                    const o_node_addr: u64 = Node.Link.prev(p_node_addr, s_node_addr);
                    Node.Link.mutate(p_node_addr, o_node_addr, t_node_addr);
                    Node.Link.write(t_node_addr, p_node_addr, 0);
                    Node.Link.refer(s_node_addr).* = 0;
                    return .{ .major = p_node_addr, .minor = t_node_addr };
                }
                fn disintegrateBefore(s_node_addr: u64, t_node_addr: u64) Links {
                    const n_node_addr: u64 = Node.Link.next(s_node_addr, t_node_addr);
                    Node.Link.write(t_node_addr, Node.Link.head_mask, 0, n_node_addr);
                    Node.Link.refer(s_node_addr).* = 0;
                    return .{ .major = t_node_addr, .minor = n_node_addr };
                }
                fn disintegrateBetween(m_node_addr: u64, t_node_addr: u64) Links {
                    const p_node_addr: u64 = Node.Link.prev(m_node_addr, t_node_addr);
                    const i_node_addr: u64 = Node.Link.next(m_node_addr, t_node_addr);
                    const n_node_addr: u64 = Node.Link.next(t_node_addr, i_node_addr);
                    Node.Link.mutate(m_node_addr, p_node_addr, i_node_addr);
                    Node.Link.mutate(i_node_addr, m_node_addr, n_node_addr);
                    Node.Link.refer(t_node_addr).* = 0;
                    return .{ .major = i_node_addr, .minor = n_node_addr };
                }
            };
            const link_size: u64 = @sizeOf(u64);
            const link_alignment: u64 = @alignOf(u64);
            const unit_size: u64 = @sizeOf(child);
            const low_alignment: u64 = @alignOf(child);
            const link_after: bool = link_alignment < low_alignment;
            const max_offset: u64 = @max(Link.offset.end, Data.offset.end);
            pub const alignment: u64 = @max(link_alignment, low_alignment);
            pub const size: u64 = mach.alignA64(max_offset, if (link_after)
                link_alignment
            else
                low_alignment);
        };
        pub const Links = struct {
            major: u64,
            minor: u64,
            pub fn basicInit(s_node_addr: u64, t_node_addr: u64) Links {
                Node.Link.write(s_node_addr, Node.Link.head_mask, 0, t_node_addr);
                Node.Link.write(t_node_addr, Node.Link.tail_mask, s_node_addr, 0);
                return .{ .major = s_node_addr, .minor = t_node_addr };
            }
            fn next(links: Links) ?u64 {
                const t_next_addr: u64 = Node.Link.next(links.major, links.minor);
                return mach.cmovxZ(t_next_addr > 0x10000, t_next_addr);
            }
            fn prev(links: Links) ?u64 {
                const t_prev_addr: u64 = Node.Link.prev(links.major, links.minor);
                return mach.cmovxZ(t_prev_addr > 0x10000, t_prev_addr);
            }
            fn nextPair(links: Links) ?Links {
                const t_next_addr: u64 = Node.Link.next(links.major, links.minor);
                return mach.cmovxZ(t_next_addr > 0x10000, Links{ .major = links.minor, .minor = t_next_addr });
            }
            fn prevPair(links: Links) ?Links {
                const t_prev_addr: u64 = Node.Link.prev(links.major, links.minor);
                return mach.cmovxZ(t_prev_addr > 0x10000, Links{ .major = t_prev_addr, .minor = links.major });
            }
            fn toList(links: *Links) List {
                const index = links.countToHead();
                return .{
                    .links = links.*,
                    .index = index,
                    .count = index + links.countToTail(),
                };
            }
            fn countToHead(links: Links) u64 {
                var temp: Links = links;
                var i: u64 = 0;
                while (temp.prevPair()) |prev_pair| {
                    temp = prev_pair;
                    i += 1;
                }
                return i;
            }
            fn countToTail(links: Links) u64 {
                var temp: Links = links;
                var i: u64 = 0;
                while (temp.nextPair()) |next_pair| {
                    temp = next_pair;
                    i += 1;
                }
                return i;
            }
        };
        const child: type = list_spec.child;
        pub const list_spec: ListViewSpec = spec;
        pub fn this(list: List) *child {
            return Node.Data.refer(list.links.major);
        }
        pub fn at(list: *List, i: u64) !*child {
            try list.goTo(i);
            return list.this();
        }
        pub fn next(list: List) ?List {
            if (list.links.nextPair()) |links| {
                return List{ .links = links, .count = list.count, .index = list.index + 1, .save = list.save };
            }
            return null;
        }
        pub fn prev(list: List) ?List {
            if (list.links.prevPair()) |links| {
                return List{ .links = links, .count = list.count, .index = list.index - 1, .save = list.save };
            }
            return null;
        }
        pub fn goToHead(list: *List) void {
            while (list.links.prevPair()) |links| {
                list.links = links;
                list.index -= 1;
            }
        }
        pub fn goToTail(list: *List) void {
            while (list.links.nextPair()) |links| {
                list.links = links;
                list.index += 1;
            }
        }
        pub fn goToNext(list: *List) error{NoItems}!void {
            if (list.links.nextPair()) |next_pair| {
                list.links = next_pair;
                list.index += 1;
            } else {
                return error.NoItems;
            }
        }
        pub fn goToPrev(list: *List) error{NoItems}!void {
            if (list.links.prevPair()) |prev_pair| {
                list.links = prev_pair;
                list.index -= 1;
            } else {
                return error.NoItems;
            }
        }
        pub fn goTo(list: *List, to: u64) !void {
            if (to != list.index) {
                while (to < list.index) {
                    try list.goToPrev();
                } else while (to > list.index) {
                    try list.goToNext();
                }
            }
        }
        fn extract0(list: *List) *child {
            const s_node_addr: u64 = list.links.major;
            const ret: *child = Node.Data.refer(s_node_addr);
            list.count -= 1;
            return ret;
        }
        fn extractA(list: *List) *child {
            list.goToTail();
            const s_node_addr: u64 = list.links.major;
            const t_node_addr: u64 = list.links.minor;
            const ret: *child = Node.Data.refer(s_node_addr);
            list.links = Node.Link.disintegrateAfter(s_node_addr, t_node_addr);
            list.count -= 1;
            list.index -= 1;
            return ret;
        }
        fn extractB(list: *List) *child {
            list.goToHead();
            const s_node_addr: u64 = list.links.major;
            const t_node_addr: u64 = list.links.minor;
            const ret: *child = Node.Data.refer(s_node_addr);
            list.links = Node.Link.disintegrateBefore(s_node_addr, t_node_addr);
            list.count -= 1;
            return ret;
        }
        fn extractC(list: *List, index: u64) !*child {
            try list.goTo(index - 1);
            const m_node_addr: u64 = list.links.major;
            const t_node_addr: u64 = list.links.minor;
            const ret: *child = Node.Data.refer(t_node_addr);
            list.links = Node.Link.disintegrateBetween(m_node_addr, t_node_addr);
            list.index = index;
            list.count -= 1;
            return ret;
        }
        pub fn extract(list: *List, index: u64) !*child {
            if (list.count == 0) {
                return error.NoItems;
            }
            if (list.count == 1) {
                return list.extract0();
            }
            if (index == 0) {
                return list.extractB();
            }
            if (list.count == index + 1) {
                return list.extractA();
            }
            return list.extractC(index);
        }
        /// Effectively increments the list index
        pub fn delete(list: *List, index: ?u64) !void {
            switch (list.count) {
                0 => {
                    return error.NoItems;
                },
                1, 2 => {
                    const b: bool = index orelse list.index == 0;
                    const s_node_addr: u64 = mach.cmov64(b, list.links.minor, list.links.major);
                    const t_node_addr: u64 = mach.cmov64(b, list.links.major, list.links.minor);
                    list.links = Links.basicInit(s_node_addr, t_node_addr);
                    list.count -= 1;
                },
                else => {
                    const data: *child = try list.extract(index orelse list.index);
                    list.retire(data);
                },
            }
        }
        pub fn retire(list: *List, data: *child) void {
            const s_node_addr: u64 = Node.Data.node(data);
            list.setNodeAddr(s_node_addr);
        }
        fn insertInitial(list: *List, data: child) void {
            const s_node_addr: u64 = list.links.major;
            Node.Data.write(s_node_addr, data);
            list.count += 1;
        }
        fn insertAfter(list: *List, data: child, n_node_addr: u64) !void {
            list.goToTail();
            const s_node_addr: u64 = list.links.major;
            const t_node_addr: u64 = list.links.minor;
            list.links = Node.Link.integrateAfter(s_node_addr, t_node_addr, n_node_addr, data);
            list.index += 1;
            list.count += 1;
        }
        pub fn insertBefore(list: *List, data: child, b_node_addr: u64) !void {
            list.goToHead();
            const s_node_addr: u64 = list.links.major;
            const t_node_addr: u64 = list.links.minor;
            list.links = Node.Link.integrateBefore(b_node_addr, s_node_addr, t_node_addr, data);
            list.count += 1;
        }
        fn insertBetween(list: *List, index: u64, data: child, i_node_addr: u64) !void {
            try list.goTo(index - 1);
            const p_node_addr: u64 = list.links.major;
            const s_node_addr: u64 = list.links.minor;
            Node.Link.integrateBetween(p_node_addr, i_node_addr, s_node_addr, data);
            list.links.major = i_node_addr;
            list.index += 1;
            list.count += 1;
        }
        fn setNodeAddr(list: *List, s_node_addr: u64) void {
            if (list.save) |s_save_addr| {
                Node.Link.refer(s_node_addr).* = s_save_addr;
            }
            list.save = s_node_addr;
        }
        fn Match(comptime decls: anytype) type {
            if (comptime meta.isNothing(decls)) {
                return child;
            } else {
                return meta.RecursedField(child, decls);
            }
        }
        fn value(list: *List, comptime decls: anytype) Match(decls) {
            if (comptime meta.isNothing(decls)) {
                return list.this().*;
            } else {
                return meta.recursedField(child, decls, list.this().*);
            }
        }
        fn matchG(list: List, comptime decls: anytype, l_value: Match(decls)) ?List {
            var tmp: List = list;
            tmp.goToHead();
            if (tmp.count <= 1) {
                if (mem.eql(l_value, tmp.value(decls))) {
                    return tmp;
                }
            } else {
                if (tmp.links.nextPair()) |links| {
                    if (mem.eql(l_value, tmp.value(decls))) {
                        return tmp;
                    }
                    tmp.links = links;
                    tmp.index += 1;
                }
                while (tmp.links.nextPair()) |links| {
                    if (l_value == tmp.value(decls)) {
                        return tmp;
                    }
                    tmp.links = links;
                    tmp.index += 1;
                }
                if (l_value == tmp.value(decls)) {
                    return tmp;
                }
            }
        }
        fn matchA(list: *List, comptime decls: anytype, l_value: Match(decls)) bool {
            var ret: List = list.*;
            ret.goToHead();
            while (ret.links.nextPair()) |t_links| {
                if (meta.valcmp(.Equal, l_value, ret.value(decls))) {
                    list.* = ret;
                    return true;
                }
                ret.index += 1;
                ret.links = t_links;
            } else {
                if (meta.valcmp(.Equal, l_value, ret.value(decls))) {
                    list.* = ret;
                    return true;
                }
            }
            return false;
        }
        pub fn iterator(list: List) List {
            var ret: List = list;
            ret.goToHead();
            return ret;
        }
        pub const Graphics = struct {
            const IOAllocator = mem.GenericArenaAllocator(.{ .arena_index = 32 });
            const IOPrintArray = IOAllocator.Holder(u8);
            pub fn show(list: List, address_space: *mem.AddressSpace) !void {
                var allocator: IOAllocator = try IOAllocator.init(address_space);
                defer allocator.deinit(address_space);
                var array: IOPrintArray = IOPrintArray.init(&allocator);
                defer array.deinit(&allocator);
                var tmp: List = list;
                tmp.goToHead();
                if (tmp.count <= 1) {
                    try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                        "head-",    fmt.ud64(tmp.index),
                        ": \t(",    fmt.ux64(tmp.links.major),
                        ',',        fmt.ux64(tmp.links.minor),
                        ")\ndata-", fmt.ud64(tmp.index),
                        ": \t",     fmt.any(Node.Data.read(tmp.links.major)),
                        '\n',
                    });
                } else {
                    if (tmp.links.nextPair()) |links| {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "head-",   fmt.ud64(tmp.index),
                            ": \t(",   fmt.ux64(tmp.links.major),
                            ',',       fmt.ux64(tmp.links.minor),
                            ") -> ",   fmt.ux64(links.major),
                            "\ndata-", fmt.ud64(tmp.index),
                            ": \t",    fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                        tmp.links = links;
                        tmp.index += 1;
                    }
                    while (tmp.links.nextPair()) |links| {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "link-",   fmt.ud64(tmp.index),
                            ": \t",    fmt.ux64(tmp.links.prev().?),
                            " <- (",   fmt.ux64(tmp.links.major),
                            ',',       fmt.ux64(tmp.links.minor),
                            ") -> ",   fmt.ux64(tmp.links.next().?),
                            "\ndata-", fmt.ud64(tmp.index),
                            ": \t",    fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                        tmp.links = links;
                        tmp.index += 1;
                    } else {
                        try array.appendAny(mem.fmt_wr_spec, &allocator, .{
                            "sentinel-", fmt.ud64(tmp.index),
                            ":\t",       fmt.ux64(tmp.links.prev().?),
                            " <- (",     fmt.ux64(tmp.links.major),
                            ',',         fmt.ux64(tmp.links.minor),
                            ")\ndata-",  fmt.ud64(tmp.index),
                            ": \t",      fmt.any(Node.Data.read(tmp.links.major)),
                            '\n',
                        });
                    }
                }
                builtin.require(file.write(2, array.readAll()));
            }
        };
    };
}
