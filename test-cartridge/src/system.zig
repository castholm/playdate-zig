const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;
const main = @import("main.zig");

var font: *c.LCDFont = undefined;

var menu_image: *c.LCDBitmap = undefined;

var date_time_format_menu_item: *c.PDMenuItem = undefined;
var reset_timer_menu_item: *c.PDMenuItem = undefined;
var accelerometer_menu_item: *c.PDMenuItem = undefined;

const date_time_formats = [_][*:0]const u8{
    "epoch",
    "rfc2616",
    "rfc3339",
};

/// The last moment in time when B+A were NOT down.
var alive_timestamp: c_uint = undefined;

pub fn handleEvent(event: playdate.SystemEvent) void {
    switch (event) {
        .init => {
            font = c.pd.graphics.loadFont("Roobert-11-Mono-Condensed", null) orelse unreachable;

            menu_image = c.pd.graphics.loadBitmap("menuImage", null) orelse unreachable;
            c.pd.system.setMenuImage(menu_image, 0);

            date_time_format_menu_item = c.pd.system.addOptionsMenuItem(
                "dt fmt",
                &date_time_formats,
                date_time_formats.len,
                handleDateTimeFormatMenuItem,
                null,
            ) orelse unreachable;
            reset_timer_menu_item = c.pd.system.addMenuItem(
                "reset timer",
                handleResetTimeMenuItem,
                null,
            ) orelse unreachable;
            accelerometer_menu_item = c.pd.system.addCheckmarkMenuItem(
                "accmtr",
                0,
                handleAccelerometerMenuItem,
                null,
            ) orelse unreachable;

            if (c.pd.system.addMenuItem("four", null, null)) |menu_item_4| {
                c.pd.system.removeMenuItem(menu_item_4);
                c.pd.system.logToConsole("a fourth menu item was added");
            }

            alive_timestamp = c.pd.system.getCurrentTimeMilliseconds();

            _ = c.pd.system.setCrankSoundsDisabled(1);
            c.pd.system.setAutoLockDisabled(1);

            c.pd.system.setUpdateCallback(update, null);
        },
        .exit => {
            c.pd.system.setUpdateCallback(null, null);

            c.pd.system.setAutoLockDisabled(0);
            _ = c.pd.system.setCrankSoundsDisabled(0);

            c.pd.system.setPeripheralsEnabled(c.kNone);
            c.pd.system.removeAllMenuItems();

            c.pd.system.setMenuImage(null, 0);
            c.pd.graphics.freeBitmap(menu_image);

            c.pd.graphics.setFont(null);
            _ = c.pd.system.realloc(font, 0);
        },
        else => {},
    }
}

fn handleDateTimeFormatMenuItem(_: ?*anyopaque) callconv(.C) void {
    c.pd.system.logToConsole("in handleDateTimeFormatMenuItem");
}

fn handleResetTimeMenuItem(_: ?*anyopaque) callconv(.C) void {
    c.pd.system.logToConsole("in handleResetTimer");
    c.pd.system.resetElapsedTime();
}

fn handleAccelerometerMenuItem(_: ?*anyopaque) callconv(.C) void {
    c.pd.system.logToConsole("in handleAccelerometerMenuItem");
    const enabled = c.pd.system.getMenuItemValue(accelerometer_menu_item);
    c.pd.system.setPeripheralsEnabled(if (enabled != 0) c.kAccelerometer else c.kNone);
}

fn update(_: ?*anyopaque) callconv(.C) c_int {
    var current_btns: c.PDButtons = 0;
    var pressed_btns: c.PDButtons = 0;
    var released_btns: c.PDButtons = 0;
    c.pd.system.getButtonState(&current_btns, &pressed_btns, &released_btns);

    c.pd.graphics.clear(c.kColorWhite);
    c.pd.graphics.setFont(font);

    const margin_x = 4;
    const margin_y = 2;

    const x: c_int = margin_x;
    var y: c_int = margin_y;
    const font_height = c.pd.graphics.getFontHeight(font);

    {
        const ms: c_uint = c.pd.system.getCurrentTimeMilliseconds();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Monotonic time: %u", ms);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        var ms: c_uint = undefined;
        const utc_s: c_uint = c.pd.system.getSecondsSinceEpoch(&ms);
        var utc_dt: c.PDDateTime = undefined;
        c.pd.system.convertEpochToDateTime(utc_s, &utc_dt);

        const offset: c_int = c.pd.system.getTimezoneOffset();
        const h_offset: c_int = @divTrunc(offset, 60 * 60);
        const m_offset: c_uint = @abs(@rem(@divTrunc(offset, 60), 60));
        const local_s: c_uint = @bitCast(@as(c_int, @bitCast(utc_s)) + offset);
        var local_dt: c.PDDateTime = undefined;
        c.pd.system.convertEpochToDateTime(local_s, &local_dt);

        var str: [*:0]u8 = undefined;
        _ = switch (c.pd.system.getMenuItemValue(date_time_format_menu_item)) {
            0 => c.pd.system.formatString(&str, "Real time: %u.%03u", utc_s, ms),
            1 => c.pd.system.formatString(
                &str,
                "Real time: %s, %02u %s %04u %02u:%02u:%02u GMT",
                switch (utc_dt.weekday) {
                    1 => "Mon",
                    2 => "Tue",
                    3 => "Wed",
                    4 => "Thu",
                    5 => "Fri",
                    6 => "Sat",
                    else => "Sun",
                }.ptr,
                @as(c_uint, utc_dt.day),
                switch (utc_dt.month) {
                    1 => "Jan",
                    2 => "Feb",
                    3 => "Mar",
                    4 => "Apr",
                    5 => "May",
                    6 => "Jun",
                    7 => "Jul",
                    8 => "Aug",
                    9 => "Sep",
                    10 => "Oct",
                    11 => "Nov",
                    else => "Dec",
                }.ptr,
                @as(c_uint, utc_dt.year),
                @as(c_uint, utc_dt.hour),
                @as(c_uint, utc_dt.minute),
                @as(c_uint, utc_dt.second),
            ),
            else => c.pd.system.formatString(
                &str,
                "Real time: %04u-%02u-%02uT%02u:%02u:%02u.%03u%+03d:%02u",
                @as(c_uint, local_dt.year),
                @as(c_uint, local_dt.month),
                @as(c_uint, local_dt.day),
                @as(c_uint, local_dt.hour),
                @as(c_uint, local_dt.minute),
                @as(c_uint, local_dt.second),
                ms,
                h_offset,
                m_offset,
            ),
        };
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;

        const utc_dt_copy = utc_dt;
        const utc_s_roundtrip = c.pd.system.convertDateTimeToEpoch(&utc_dt);

        if (utc_s_roundtrip != utc_s) {
            c.pd.system.logToConsole("utc_s did not roundtrip");
        }
        if (utc_dt_copy.year != utc_dt.year or
            utc_dt_copy.month != utc_dt.month or
            utc_dt_copy.day != utc_dt.day or
            utc_dt_copy.weekday != utc_dt.weekday or
            utc_dt_copy.hour != utc_dt.hour or
            utc_dt_copy.minute != utc_dt.minute or
            utc_dt_copy.second != utc_dt.second)
        {
            c.pd.system.logToConsole("utc_dt was mutated");
        }
    }

    {
        const elapsed: f32 = c.pd.system.getElapsedTime();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Timer: %.9f", elapsed);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(
            &str,
            "Buttons: %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d",
            @as(c_int, @intFromBool(current_btns & c.kButtonA != 0)),
            @as(c_int, @intFromBool(current_btns & c.kButtonB != 0)),
            @as(c_int, @intFromBool(current_btns & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(current_btns & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(current_btns & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(current_btns & c.kButtonLeft != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonA != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonB != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(pressed_btns & c.kButtonLeft != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonA != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonB != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(released_btns & c.kButtonLeft != 0)),
        );
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const extended: c_int = @intFromBool(c.pd.system.isCrankDocked() == 0);
        const angle: f32 = c.pd.system.getCrankAngle();
        const change: f32 = c.pd.system.getCrankChange();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(
            &str,
            "Crank: %d %07.3f %+08.3f",
            extended,
            angle,
            change,
        );
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        var accel_x = std.math.nan(f32);
        var accel_y = std.math.nan(f32);
        var accel_z = std.math.nan(f32);
        c.pd.system.getAccelerometer(&accel_x, &accel_y, &accel_z);

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(
            &str,
            "Accelerometer: %+06.3f %+06.3f %+06.3f",
            accel_x,
            accel_y,
            accel_z,
        );
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const volts: f32 = c.pd.system.getBatteryVoltage();
        const soc: f32 = c.pd.system.getBatteryPercentage();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Battery: %.3f V, %.3f%% ", volts, soc);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const language = c.pd.system.getLanguage();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Language: %s", switch (language) {
            c.kPDLanguageEnglish => "en",
            c.kPDLanguageJapanese => "ja",
            else => "unknown",
        }.ptr);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const sane_time: c_int = c.pd.system.shouldDisplay24HourTime(); // :^)

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "24-Hour Time: %d", sane_time);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const reduce_flashing: c_int = c.pd.system.getReduceFlashing();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Reduce Flashing: %d", reduce_flashing);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    {
        const upside_down: c_int = c.pd.system.getFlipped();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Upside Down: %d", upside_down);
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;
    }

    y += font_height;

    const exit_instructions = "Hold B+A for 3 seconds to exit";
    _ = c.pd.graphics.drawText(exit_instructions.ptr, exit_instructions.len, c.kUTF8Encoding, x, y);
    y += font_height;

    c.pd.system.drawFPS(c.LCD_COLUMNS - 15 - 3, 3);

    const now = c.pd.system.getCurrentTimeMilliseconds();
    if (current_btns & (c.kButtonB | c.kButtonA) == c.kButtonB | c.kButtonA) {
        if (now - alive_timestamp >= 3000) {
            main.State.transition(.main);
            return 1;
        }
    } else {
        alive_timestamp = now;
    }

    return 1;
}
