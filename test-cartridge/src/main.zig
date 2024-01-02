const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;
const main = @This();
const system = @import("system.zig");
const crash = @import("crash.zig");
const video = @import("video.zig");

pub const panic = playdate.panic;

comptime {
    _ = playdate;
}

pub fn eventHandler(event: playdate.SystemEvent) void {
    State.current.handleEvent(event);
}

pub const State = enum {
    main,
    system,
    crash,
    video,

    var current: State = .main;

    fn handleEvent(state: State, event: playdate.SystemEvent) void {
        switch (event) {
            inline .simulator_key_pressed, .simulator_key_released => |arg| {
                c.pd.system.logToConsole("%s %s %04x", @tagName(state).ptr, @tagName(event).ptr, @as(c_uint, arg));
            },
            else => {
                c.pd.system.logToConsole("%s %s", @tagName(state).ptr, @tagName(event).ptr);
            },
        }
        switch (state) {
            .main => main.handleEvent(event),
            .system => system.handleEvent(event),
            .crash => crash.handleEvent(event),
            .video => video.handleEvent(event),
        }
    }

    pub fn transition(next: State) void {
        current.handleEvent(.exit);
        current = next;
        current.handleEvent(.init);
    }
};

var title_font: *c.LCDFont = undefined;
var option_title_font: *c.LCDFont = undefined;
var option_desc_font: *c.LCDFont = undefined;

fn handleEvent(event: playdate.SystemEvent) void {
    switch (event) {
        .init => {
            title_font = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-24-Light", null) orelse unreachable;
            option_title_font = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Bold", null) orelse unreachable;
            option_desc_font = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Light", null) orelse unreachable;

            c.pd.system.setMenuImage(null, c.LCD_COLUMNS / 4);

            c.pd.system.setUpdateCallback(update, null);
        },
        .exit => {
            c.pd.system.setUpdateCallback(null, null);

            c.pd.system.setMenuImage(null, 0);

            c.pd.graphics.setFont(null);
            _ = c.pd.system.realloc(option_desc_font, 0);
            _ = c.pd.system.realloc(option_title_font, 0);
            _ = c.pd.system.realloc(title_font, 0);
        },
        else => {},
    }
}

const MainMenuOption = struct {
    state: State,
    title: [:0]const u8,
    desc: [:0]const u8,
};

const options = [_]MainMenuOption{
    .{
        .state = .system,
        .title = "System",
        .desc = "Test misc. 'system' functions",
    },
    .{
        .state = .crash,
        .title = "Panic",
        .desc = "Panic with an error return trace",
    },
    .{
        .state = .video,
        .title = "Video",
        .desc = "Test the video player",
    },
};
var option_index: usize = 0;

fn update(_: ?*anyopaque) callconv(.C) c_int {
    var pressed_btns: c.PDButtons = undefined;
    c.pd.system.getButtonState(null, &pressed_btns, null);

    if (pressed_btns & c.kButtonA != 0) {
        State.transition(options[option_index].state);
        return 1;
    }

    if (pressed_btns & (c.kButtonUp | c.kButtonLeft) != 0) {
        option_index = if (option_index == 0) options.len - 1 else option_index - 1;
    }
    if (pressed_btns & (c.kButtonDown | c.kButtonRight) != 0) {
        option_index = if (option_index == options.len - 1) 0 else option_index + 1;
    }

    c.pd.graphics.clear(c.kColorWhite);

    drawTextCentered(title_font, "Test Cartridge", c.LCD_COLUMNS / 2, c.LCD_ROWS / 4);
    drawTextCentered(option_title_font, options[option_index].title, c.LCD_COLUMNS / 2, c.LCD_ROWS / 8 * 5);
    drawTextCentered(option_desc_font, options[option_index].desc, c.LCD_COLUMNS / 2, c.LCD_ROWS / 4 * 3);

    return 1;
}

fn drawTextCentered(font: *c.LCDFont, text: [:0]const u8, x: c_int, y: c_int) void {
    c.pd.graphics.setFont(font);
    const font_height = c.pd.graphics.getFontHeight(font);
    const text_width = c.pd.graphics.getTextWidth(
        font,
        text.ptr,
        text.len,
        c.kUTF8Encoding,
        c.pd.graphics.getTextTracking(),
    );
    _ = c.pd.graphics.drawText(
        text.ptr,
        text.len,
        c.kUTF8Encoding,
        x - @divTrunc(text_width, 2),
        y - @divTrunc(font_height, 2),
    );
}
