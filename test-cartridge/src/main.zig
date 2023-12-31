const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;
const main = @This();
const system = @import("system.zig");
const crash = @import("crash.zig");

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
        }
    }

    pub fn transition(next: State) void {
        current.handleEvent(.exit);
        current = next;
        current.handleEvent(.init);
    }
};

var font_title: *c.LCDFont = undefined;
var font_option_title: *c.LCDFont = undefined;
var font_option_description: *c.LCDFont = undefined;

fn handleEvent(event: playdate.SystemEvent) void {
    switch (event) {
        .init => {
            font_title = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-24-Light", null) orelse unreachable;
            font_option_title = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Bold", null) orelse unreachable;
            font_option_description = c.pd.graphics.loadFont("/System/Fonts/Asheville-Sans-14-Light", null) orelse unreachable;

            c.pd.system.setMenuImage(null, c.LCD_COLUMNS / 4);

            c.pd.system.setUpdateCallback(update, null);
        },
        .exit => {
            c.pd.system.setUpdateCallback(null, null);

            c.pd.system.setMenuImage(null, 0);

            c.pd.graphics.setFont(null);
            _ = c.pd.system.realloc(font_option_description, 0);
            _ = c.pd.system.realloc(font_option_title, 0);
            _ = c.pd.system.realloc(font_title, 0);
        },
        else => {},
    }
}

const MainMenuOption = struct {
    state: State,
    title: [:0]const u8,
    description: [:0]const u8,
};

const options = [_]MainMenuOption{
    .{
        .state = .system,
        .title = "System",
        .description = "Test misc. 'system' functions",
    },
    .{
        .state = .crash,
        .title = "Panic",
        .description = "Panic with an error return trace",
    },
};
var selected_index: isize = 0;

fn update(_: ?*anyopaque) callconv(.C) c_int {
    var pressed: c.PDButtons = undefined;
    c.pd.system.getButtonState(null, &pressed, null);

    if (pressed & (c.kButtonUp | c.kButtonLeft) != 0) {
        selected_index -= 1;
    }
    if (pressed & (c.kButtonDown | c.kButtonRight) != 0) {
        selected_index += 1;
    }
    selected_index = @mod(selected_index, options.len);

    const selected_option = options[@intCast(selected_index)];
    if (pressed & c.kButtonA != 0) {
        State.transition(selected_option.state);
        return 1;
    }

    c.pd.graphics.clear(c.kColorWhite);

    drawTextCentered(font_title, "Test Cartridge", c.LCD_COLUMNS / 2, c.LCD_ROWS / 4);
    drawTextCentered(font_option_title, selected_option.title, c.LCD_COLUMNS / 2, c.LCD_ROWS / 8 * 5);
    drawTextCentered(font_option_description, selected_option.description, c.LCD_COLUMNS / 2, c.LCD_ROWS / 4 * 3);

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
