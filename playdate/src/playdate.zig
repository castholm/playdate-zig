const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

pub const c = @import("c.zig");

pub const is_device = c.TARGET_PLAYDATE != 0;

pub const is_simulator = c.TARGET_SIMULATOR != 0;

pub const SystemEvent = union(enum) {
    unknown,
    init,
    init_lua,
    exit,
    lock,
    unlock,
    pause,
    unpause,
    low_power,
    simulator_key_pressed: u32,
    simulator_key_released: u32,

    pub fn fromCEquiv(c_event: c.PDSystemEvent, c_arg: u32) SystemEvent {
        return switch (c_event) {
            c.kEventInit => .init,
            c.kEventInitLua => .init_lua,
            c.kEventLock => .lock,
            c.kEventUnlock => .unlock,
            c.kEventPause => .pause,
            c.kEventResume => .unpause,
            c.kEventTerminate => .exit,
            c.kEventKeyPressed => .{ .simulator_key_pressed = c_arg },
            c.kEventKeyReleased => .{ .simulator_key_released = c_arg },
            c.kEventLowPower => .low_power,
            else => .unknown,
        };
    }
};

export fn eventHandler(pd: *c.PlaydateAPI, event: c.PDSystemEvent, arg: u32) c_int {
    if (event == c.kEventInit) {
        c.pd = pd;
    }
    if (@typeInfo(@TypeOf(root.eventHandler)).Fn.params.len == 3) {
        const result = root.eventHandler(pd, event, arg);
        switch (@typeInfo(@TypeOf(result))) {
            .Int => return result,
            .ErrorUnion => {
                const unwrapped = result catch |err| std.builtin.panic(@errorName(err), @errorReturnTrace(), null);
                switch (@typeInfo(@TypeOf(unwrapped))) {
                    .Int => return unwrapped,
                    else => {},
                }
            },
            else => {},
        }
        @compileError("expected return type of 'root.eventHandler' to be 'c_int' or '!c_int', found '" ++ @typeName(@TypeOf(result)) ++ "'");
    } else {
        const result = root.eventHandler(SystemEvent.fromCEquiv(event, arg));
        switch (@typeInfo(@TypeOf(result))) {
            .Void => return 0,
            .ErrorUnion => {
                const unwrapped = result catch |err| std.builtin.panic(@errorName(err), @errorReturnTrace(), null);
                switch (@typeInfo(@TypeOf(unwrapped))) {
                    .Void => return 0,
                    else => {},
                }
            },
            else => {},
        }
        @compileError("expected return type of 'root.eventHandler' to be 'void' or '!void', found '" ++ @typeName(@TypeOf(result)) ++ "'");
    }
}

/// Crashes the game with a message and error return trace in the following format:
///
/// ```txt
/// panic: your message here
/// 9001cdef 900189ab 90014567 90010123 9000cdef
/// 900089ab 90004567 90000123
/// ```
///
/// To override the default panic handler with this function, add the following lines of code to
/// your root source file:
///
/// ```zig
/// const playdate = @import("playdate");
///
/// pub const panic = playdate.panic;
/// ```
///
pub fn panic(msg: []const u8, error_ret_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    @setCold(true);

    const num_addrs = (if (error_ret_trace) |trace| trace.index else 0) + 1;
    const chars_per_addr = 1 + @bitSizeOf(usize) / 4;
    const buf_len = msg.len + num_addrs * chars_per_addr;
    if (c.pd.system.realloc(null, buf_len + 1)) |ptr| {
        defer _ = c.pd.system.realloc(ptr, 0);

        const buf: [*]u8 = @ptrCast(ptr);
        var buf_i: usize = 0;

        @memcpy(buf, msg);
        buf_i += msg.len;
        var addr_i: usize = 0;
        if (error_ret_trace) |trace| {
            while (addr_i < trace.index) : (addr_i += 1) {
                buf[buf_i] = if (addr_i % 5 == 0) '\n' else ' ';
                buf_i += 1;
                const addr = trace.instruction_addresses[addr_i];
                var shift: std.math.Log2Int(usize) = @bitSizeOf(usize) - 4;
                while (true) : (shift -= 4) {
                    var nybble = addr >> shift & 0xf;
                    nybble += if (nybble < 0xa) '0' else 'a' - 0xa;
                    buf[buf_i] = @truncate(nybble);
                    buf_i += 1;
                    if (shift == 0) break;
                }
            }
        }
        {
            buf[buf_i] = if (addr_i % 5 == 0) '\n' else ' ';
            buf_i += 1;
            const addr = ret_addr orelse @returnAddress();
            var shift: std.math.Log2Int(usize) = @bitSizeOf(usize) - 4;
            while (true) : (shift -= 4) {
                var nybble = addr >> shift & 0xf;
                nybble += if (nybble < 0xa) '0' else 'a' - 0xa;
                buf[buf_i] = @truncate(nybble);
                buf_i += 1;
                if (shift == 0) break;
            }
        }
        buf[buf_i] = 0;

        c.pd.system.@"error"("panic: %s", buf);
    } else {
        c.pd.system.@"error"("panic");
    }

    while (true) {
        @breakpoint();
    }
}

/// Wraps the Playdate memory allocation API. Invokes safety-checked undefined behavior for
/// alignments exceeding 8 bytes.
pub const raw_allocator: std.mem.Allocator = .{
    .ptr = undefined,
    .vtable = &.{
        .alloc = alloc,
        .resize = resize,
        .free = free,
    },
};

fn alloc(_: *anyopaque, len: usize, log2_align: u8, _: usize) ?[*]u8 {
    std.debug.assert(log2_align <= comptime std.math.log2_int(usize, 8));
    return @ptrCast(c.pd.system.realloc(null, len));
}

fn resize(_: *anyopaque, buf: []u8, _: u8, new_len: usize, _: usize) bool {
    return new_len <= buf.len;
}

fn free(_: *anyopaque, buf: []u8, _: u8, _: usize) void {
    _ = c.pd.system.realloc(buf.ptr, 0);
}
