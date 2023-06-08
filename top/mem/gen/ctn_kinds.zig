const ctn_fn = @import("../../ctn_fn.zig");
pub fn read(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readAll,
        .readAllWithSentinel,
        .readOneAt,
        .readCountAt,
        .readManyAt,
        .readCountWithSentinelAt,
        .readManyWithSentinelAt,
        .readOneDefined,
        .readCountDefined,
        .readManyDefined,
        .readCountWithSentinelDefined,
        .readManyWithSentinelDefined,
        .readOneOffsetDefined,
        .readCountOffsetDefined,
        .readManyOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .readOneStreamed,
        .readCountStreamed,
        .readManyStreamed,
        .readCountWithSentinelStreamed,
        .readManyWithSentinelStreamed,
        .readOneOffsetStreamed,
        .readCountOffsetStreamed,
        .readManyOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .readOneUnstreamed,
        .readCountUnstreamed,
        .readManyUnstreamed,
        .readCountWithSentinelUnstreamed,
        .readManyWithSentinelUnstreamed,
        .readOneOffsetUnstreamed,
        .readCountOffsetUnstreamed,
        .readManyOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn refer(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referOneAt,
        .referCountAt,
        .referManyAt,
        .referCountWithSentinelAt,
        .referManyWithSentinelAt,
        .referOneDefined,
        .referCountDefined,
        .referManyDefined,
        .referCountWithSentinelDefined,
        .referManyWithSentinelDefined,
        .referOneOffsetDefined,
        .referCountOffsetDefined,
        .referManyOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .referOneUndefined,
        .referCountUndefined,
        .referManyUndefined,
        .referOneOffsetUndefined,
        .referCountOffsetUndefined,
        .referManyOffsetUndefined,
        .referOneStreamed,
        .referManyStreamed,
        .referCountWithSentinelStreamed,
        .referManyWithSentinelStreamed,
        .referOneOffsetStreamed,
        .referManyOffsetStreamed,
        .referCountWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        .referManyUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn overwrite(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .overwriteOneAt,
        .overwriteCountAt,
        .overwriteManyAt,
        .overwriteOneDefined,
        .overwriteCountDefined,
        .overwriteManyDefined,
        .overwriteOneOffsetDefined,
        .overwriteCountOffsetDefined,
        .overwriteManyOffsetDefined,
        => return true,
        else => return false,
    }
}
pub fn write(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .writeAny,
        .writeOne,
        .writeCount,
        .writeMany,
        .writeFormat,
        .writeFields,
        .writeArgs,
        => return true,
        else => return false,
    }
}
pub fn append(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .appendFields,
        .appendAny,
        .appendArgs,
        .appendFormat,
        .appendOne,
        .appendCount,
        .appendMany,
        => return true,
        else => return false,
    }
}
pub fn helper(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .__undefined,
        .__defined,
        .__unstreamed,
        .__streamed,
        .__avail,
        .__len,
        .__at,
        => return true,
        else => return false,
    }
}
pub fn define(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .defineAll,
        .define,
        => return true,
        else => return false,
    }
}
pub fn undefine(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .undefineAll,
        .undefine,
        => return true,
        else => return false,
    }
}
pub fn stream(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .streamAll,
        .stream,
        => return true,
        else => return false,
    }
}
pub fn unstream(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .unstreamAll,
        .unstream,
        => return true,
        else => return false,
    }
}
pub fn readAll(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readAll,
        .readAllWithSentinel,
        => return true,
        else => return false,
    }
}
pub fn one(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneAt,
        .readOneDefined,
        .readOneOffsetDefined,
        .readOneStreamed,
        .readOneOffsetStreamed,
        .readOneUnstreamed,
        .readOneOffsetUnstreamed,
        .referOneAt,
        .referOneDefined,
        .referOneOffsetDefined,
        .referOneUndefined,
        .referOneOffsetUndefined,
        .referOneStreamed,
        .referOneOffsetStreamed,
        .overwriteOneAt,
        .overwriteOneDefined,
        .overwriteOneOffsetDefined,
        .writeOne,
        .appendOne,
        => return true,
        else => return false,
    }
}
pub fn readOne(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneAt,
        .readOneDefined,
        .readOneOffsetDefined,
        .readOneStreamed,
        .readOneOffsetStreamed,
        .readOneUnstreamed,
        .readOneOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn referOne(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referOneAt,
        .referOneDefined,
        .referOneOffsetDefined,
        .referOneUndefined,
        .referOneOffsetUndefined,
        .referOneStreamed,
        .referOneOffsetStreamed,
        => return true,
        else => return false,
    }
}
pub fn count(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readCountAt,
        .readCountWithSentinelAt,
        .readCountDefined,
        .readCountWithSentinelDefined,
        .readCountOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readCountStreamed,
        .readCountWithSentinelStreamed,
        .readCountOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readCountUnstreamed,
        .readCountWithSentinelUnstreamed,
        .readCountOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .referCountAt,
        .referCountWithSentinelAt,
        .referCountDefined,
        .referCountWithSentinelDefined,
        .referCountOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referCountUndefined,
        .referCountOffsetUndefined,
        .referCountWithSentinelStreamed,
        .referCountWithSentinelOffsetStreamed,
        .overwriteCountAt,
        .overwriteCountDefined,
        .overwriteCountOffsetDefined,
        .writeCount,
        .appendCount,
        => return true,
        else => return false,
    }
}
pub fn readCount(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readCountAt,
        .readCountWithSentinelAt,
        .readCountDefined,
        .readCountWithSentinelDefined,
        .readCountOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readCountStreamed,
        .readCountWithSentinelStreamed,
        .readCountOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readCountUnstreamed,
        .readCountWithSentinelUnstreamed,
        .readCountOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn referCount(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referCountAt,
        .referCountWithSentinelAt,
        .referCountDefined,
        .referCountWithSentinelDefined,
        .referCountOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referCountUndefined,
        .referCountOffsetUndefined,
        .referCountWithSentinelStreamed,
        .referCountWithSentinelOffsetStreamed,
        => return true,
        else => return false,
    }
}
pub fn many(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readManyAt,
        .readManyWithSentinelAt,
        .readManyDefined,
        .readManyWithSentinelDefined,
        .readManyOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .readManyStreamed,
        .readManyWithSentinelStreamed,
        .readManyOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .readManyUnstreamed,
        .readManyWithSentinelUnstreamed,
        .readManyOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyAt,
        .referManyWithSentinelAt,
        .referManyDefined,
        .referManyWithSentinelDefined,
        .referManyOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .referManyUndefined,
        .referManyOffsetUndefined,
        .referManyStreamed,
        .referManyWithSentinelStreamed,
        .referManyOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        .referManyUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        .overwriteManyAt,
        .overwriteManyDefined,
        .overwriteManyOffsetDefined,
        .writeMany,
        .appendMany,
        => return true,
        else => return false,
    }
}
pub fn readMany(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readManyAt,
        .readManyWithSentinelAt,
        .readManyDefined,
        .readManyWithSentinelDefined,
        .readManyOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .readManyStreamed,
        .readManyWithSentinelStreamed,
        .readManyOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .readManyUnstreamed,
        .readManyWithSentinelUnstreamed,
        .readManyOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn referMany(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referManyAt,
        .referManyWithSentinelAt,
        .referManyDefined,
        .referManyWithSentinelDefined,
        .referManyOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .referManyUndefined,
        .referManyOffsetUndefined,
        .referManyStreamed,
        .referManyWithSentinelStreamed,
        .referManyOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        .referManyUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn format(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .writeFormat => return true,
        else => return false,
    }
}
pub fn args(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .writeArgs => return true,
        else => return false,
    }
}
pub fn fields(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .writeFields => return true,
        else => return false,
    }
}
pub fn any(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .writeAny => return true,
        else => return false,
    }
}
pub fn sentinel(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readManyWithSentinelAt,
        .readManyWithSentinelDefined,
        .readManyWithSentinelOffsetDefined,
        .readManyWithSentinelStreamed,
        .readManyWithSentinelOffsetStreamed,
        .readManyWithSentinelUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyWithSentinelAt,
        .referManyWithSentinelDefined,
        .referManyWithSentinelOffsetDefined,
        .referManyWithSentinelStreamed,
        .referManyWithSentinelOffsetStreamed,
        .referManyWithSentinelUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        .readCountWithSentinelAt,
        .readCountWithSentinelDefined,
        .readCountWithSentinelOffsetDefined,
        .readCountWithSentinelStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readCountWithSentinelUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .referCountWithSentinelAt,
        .referCountWithSentinelDefined,
        .referCountWithSentinelOffsetDefined,
        .referCountWithSentinelStreamed,
        .referCountWithSentinelOffsetStreamed,
        => return true,
        else => return false,
    }
}
pub fn at(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneAt,
        .readCountAt,
        .readManyAt,
        .readCountWithSentinelAt,
        .readManyWithSentinelAt,
        .referOneAt,
        .referCountAt,
        .referManyAt,
        .referCountWithSentinelAt,
        .referManyWithSentinelAt,
        .overwriteOneAt,
        .overwriteCountAt,
        .overwriteManyAt,
        => return true,
        else => return false,
    }
}
pub fn defined(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneDefined,
        .readCountDefined,
        .readManyDefined,
        .readCountWithSentinelDefined,
        .readManyWithSentinelDefined,
        .readOneOffsetDefined,
        .readCountOffsetDefined,
        .readManyOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .referOneDefined,
        .referCountDefined,
        .referManyDefined,
        .referCountWithSentinelDefined,
        .referManyWithSentinelDefined,
        .referOneOffsetDefined,
        .referCountOffsetDefined,
        .referManyOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .overwriteOneDefined,
        .overwriteCountDefined,
        .overwriteManyDefined,
        .overwriteOneOffsetDefined,
        .overwriteCountOffsetDefined,
        .overwriteManyOffsetDefined,
        => return true,
        else => return false,
    }
}
pub fn @"undefined"(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referOneUndefined,
        .referCountUndefined,
        .referManyUndefined,
        .referOneOffsetUndefined,
        .referCountOffsetUndefined,
        .referManyOffsetUndefined,
        => return true,
        else => return false,
    }
}
pub fn streamed(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneStreamed,
        .readCountStreamed,
        .readManyStreamed,
        .readCountWithSentinelStreamed,
        .readManyWithSentinelStreamed,
        .readOneOffsetStreamed,
        .readCountOffsetStreamed,
        .readManyOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .referOneStreamed,
        .referManyStreamed,
        .referCountWithSentinelStreamed,
        .referManyWithSentinelStreamed,
        .referOneOffsetStreamed,
        .referManyOffsetStreamed,
        .referCountWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        => return true,
        else => return false,
    }
}
pub fn unstreamed(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneUnstreamed,
        .readCountUnstreamed,
        .readManyUnstreamed,
        .readCountWithSentinelUnstreamed,
        .readManyWithSentinelUnstreamed,
        .readOneOffsetUnstreamed,
        .readCountOffsetUnstreamed,
        .readManyOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn relative_forward(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .referOneUndefined,
        .referCountUndefined,
        .referManyUndefined,
        .referOneOffsetUndefined,
        .referCountOffsetUndefined,
        .referManyOffsetUndefined,
        .readOneUnstreamed,
        .readCountUnstreamed,
        .readManyUnstreamed,
        .readCountWithSentinelUnstreamed,
        .readManyWithSentinelUnstreamed,
        .readOneOffsetUnstreamed,
        .readCountOffsetUnstreamed,
        .readManyOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn relative_reverse(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneDefined,
        .readCountDefined,
        .readManyDefined,
        .readCountWithSentinelDefined,
        .readManyWithSentinelDefined,
        .readOneOffsetDefined,
        .readCountOffsetDefined,
        .readManyOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .referOneDefined,
        .referCountDefined,
        .referManyDefined,
        .referCountWithSentinelDefined,
        .referManyWithSentinelDefined,
        .referOneOffsetDefined,
        .referCountOffsetDefined,
        .referManyOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .overwriteOneDefined,
        .overwriteCountDefined,
        .overwriteManyDefined,
        .overwriteOneOffsetDefined,
        .overwriteCountOffsetDefined,
        .overwriteManyOffsetDefined,
        .readOneStreamed,
        .readCountStreamed,
        .readManyStreamed,
        .readCountWithSentinelStreamed,
        .readManyWithSentinelStreamed,
        .readOneOffsetStreamed,
        .readCountOffsetStreamed,
        .readManyOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .referOneStreamed,
        .referManyStreamed,
        .referCountWithSentinelStreamed,
        .referManyWithSentinelStreamed,
        .referOneOffsetStreamed,
        .referManyOffsetStreamed,
        .referCountWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        => return true,
        else => return false,
    }
}
pub fn offset(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .readOneOffsetDefined,
        .readCountOffsetDefined,
        .readManyOffsetDefined,
        .readCountWithSentinelOffsetDefined,
        .readManyWithSentinelOffsetDefined,
        .referOneOffsetDefined,
        .referCountOffsetDefined,
        .referManyOffsetDefined,
        .referCountWithSentinelOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .overwriteOneOffsetDefined,
        .overwriteCountOffsetDefined,
        .overwriteManyOffsetDefined,
        .referOneOffsetUndefined,
        .referCountOffsetUndefined,
        .referManyOffsetUndefined,
        .readOneOffsetStreamed,
        .readCountOffsetStreamed,
        .readManyOffsetStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readManyWithSentinelOffsetStreamed,
        .referOneOffsetStreamed,
        .referManyOffsetStreamed,
        .referCountWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        .readOneOffsetUnstreamed,
        .readCountOffsetUnstreamed,
        .readManyOffsetUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyOffsetUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => return true,
        else => return false,
    }
}
pub fn special(tag: ctn_fn.Fn) bool {
    switch (tag) {
        .defineAll,
        .undefineAll,
        .streamAll,
        .unstreamAll,
        .len,
        .index,
        .avail,
        .ahead,
        .define,
        .undefine,
        .stream,
        .unstream,
        .init,
        .grow,
        .increment,
        .shrink,
        .decrement,
        .static,
        .dynamic,
        .holder,
        .deinit,
        => return true,
        else => return false,
    }
}
