const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;
const main = @import("main.zig");

var font: *c.LCDFont = undefined;

var menu_image: *c.LCDBitmap = undefined;

var date_time_format_menu_item: *c.PDMenuItem = undefined;
var reset_timer_menu_item: *c.PDMenuItem = undefined;
var accelerometer_enabled_menu_item: *c.PDMenuItem = undefined;

const date_time_formats = [_][*:0]const u8{
    "epoch",
    "rfc2616",
    "rfc3339",
};

var exit_time: c_uint = 0;

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
            accelerometer_enabled_menu_item = c.pd.system.addCheckmarkMenuItem(
                "accmtr",
                0,
                handleAccelerometerMenuItem,
                null,
            ) orelse unreachable;

            if (c.pd.system.addMenuItem("four", null, null)) |menu_item_4| {
                defer c.pd.system.removeMenuItem(menu_item_4);

                c.pd.system.logToConsole("a fourth menu item was added");
            }

            exit_time = c.pd.system.getCurrentTimeMilliseconds();

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
    const enabled = c.pd.system.getMenuItemValue(accelerometer_enabled_menu_item);
    c.pd.system.setPeripheralsEnabled(if (enabled != 0) c.kAccelerometer else c.kNone);
}

fn update(_: ?*anyopaque) callconv(.C) c_int {
    var btn_current: c.PDButtons = 0;
    var btn_pressed: c.PDButtons = 0;
    var btn_released: c.PDButtons = 0;
    c.pd.system.getButtonState(&btn_current, &btn_pressed, &btn_released);

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
        const s_utc: c_uint = c.pd.system.getSecondsSinceEpoch(&ms);
        var dt_utc: c.PDDateTime = undefined;
        c.pd.system.convertEpochToDateTime(s_utc, &dt_utc);

        const offset: c_int = c.pd.system.getTimezoneOffset();
        const offset_h: c_int = @divTrunc(offset, 60 * 60);
        const offset_m: c_uint = @abs(@rem(@divTrunc(offset, 60), 60));
        const s_local: c_uint = @bitCast(@as(c_int, @bitCast(s_utc)) + offset);
        var dt_local: c.PDDateTime = undefined;
        c.pd.system.convertEpochToDateTime(s_local, &dt_local);

        var str: [*:0]u8 = undefined;
        _ = switch (c.pd.system.getMenuItemValue(date_time_format_menu_item)) {
            0 => c.pd.system.formatString(&str, "Real time: %u.%03u", s_utc, ms),
            1 => c.pd.system.formatString(
                &str,
                "Real time: %s, %02u %s %04u %02u:%02u:%02u GMT",
                switch (dt_utc.weekday) {
                    1 => "Mon",
                    2 => "Tue",
                    3 => "Wed",
                    4 => "Thu",
                    5 => "Fri",
                    6 => "Sat",
                    else => "Sun",
                }.ptr,
                @as(c_uint, dt_utc.day),
                switch (dt_utc.month) {
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
                @as(c_uint, dt_utc.year),
                @as(c_uint, dt_utc.hour),
                @as(c_uint, dt_utc.minute),
                @as(c_uint, dt_utc.second),
            ),
            else => c.pd.system.formatString(
                &str,
                "Real time: %04u-%02u-%02uT%02u:%02u:%02u.%03u%+03d:%02u",
                @as(c_uint, dt_local.year),
                @as(c_uint, dt_local.month),
                @as(c_uint, dt_local.day),
                @as(c_uint, dt_local.hour),
                @as(c_uint, dt_local.minute),
                @as(c_uint, dt_local.second),
                ms,
                offset_h,
                offset_m,
            ),
        };
        defer _ = c.pd.system.realloc(str, 0);

        _ = c.pd.graphics.drawText(str, std.mem.len(str), c.kUTF8Encoding, x, y);
        y += font_height;

        const dt_utc_copy = dt_utc;
        const s_utc_roundtrip = c.pd.system.convertDateTimeToEpoch(&dt_utc);

        if (s_utc_roundtrip != s_utc) {
            c.pd.system.logToConsole("real time 's_utc' did not roundtrip");
        }
        if (dt_utc_copy.year != dt_utc.year or
            dt_utc_copy.month != dt_utc.month or
            dt_utc_copy.day != dt_utc.day or
            dt_utc_copy.weekday != dt_utc.weekday or
            dt_utc_copy.hour != dt_utc.hour or
            dt_utc_copy.minute != dt_utc.minute or
            dt_utc_copy.second != dt_utc.second)
        {
            c.pd.system.logToConsole("real time 'dt_utc' was mutated");
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
            @as(c_int, @intFromBool(btn_current & c.kButtonA != 0)),
            @as(c_int, @intFromBool(btn_current & c.kButtonB != 0)),
            @as(c_int, @intFromBool(btn_current & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(btn_current & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(btn_current & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(btn_current & c.kButtonLeft != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonA != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonB != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(btn_pressed & c.kButtonLeft != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonA != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonB != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonDown != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonUp != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonRight != 0)),
            @as(c_int, @intFromBool(btn_released & c.kButtonLeft != 0)),
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
        const voltage: f32 = c.pd.system.getBatteryVoltage();
        const soc: f32 = c.pd.system.getBatteryPercentage();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "Battery: %.3f V, %.3f%% ", voltage, soc);
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
        const display_24_hour_time: c_int = c.pd.system.shouldDisplay24HourTime();

        var str: [*:0]u8 = undefined;
        _ = c.pd.system.formatString(&str, "24-Hour Time: %d", display_24_hour_time);
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

    const exit_instructions = "Hold B+A for 3 seconds to exit.";
    _ = c.pd.graphics.drawText(exit_instructions.ptr, exit_instructions.len, c.kUTF8Encoding, x, y);
    y += font_height;

    c.pd.system.drawFPS(c.LCD_COLUMNS - 15 - 3, 3);

    const now = c.pd.system.getCurrentTimeMilliseconds();
    if (btn_current & (c.kButtonB | c.kButtonA) == c.kButtonB | c.kButtonA) {
        if (now - exit_time >= 3000) {
            main.State.transition(.main);
            return 1;
        }
    } else {
        exit_time = now;
    }

    return 1;
}
