const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;
const main = @import("main.zig");

const update_rate = 50;

var video_player: *c.LCDVideoPlayer = undefined;

var audio: *c.AudioSample = undefined;
var audio_player: *c.SamplePlayer = undefined;

var angle_change_samples: [update_rate / 2]f32 = undefined;
var angle_change_sample_index: usize = undefined;

pub fn handleEvent(event: playdate.SystemEvent) void {
    switch (event) {
        .init => {
            video_player = c.pd.graphics.video.loadVideo("steamboat") orelse unreachable;

            audio = c.pd.sound.sample.load("steamboat") orelse unreachable;
            audio_player = c.pd.sound.sampleplayer.newPlayer() orelse unreachable;
            c.pd.sound.sampleplayer.setSample(audio_player, audio);
            _ = c.pd.sound.sampleplayer.play(audio_player, 0, 0);

            angle_change_samples = [1]f32{0} ** angle_change_samples.len;
            angle_change_sample_index = 0;

            c.pd.display.setRefreshRate(update_rate);
            c.pd.system.setUpdateCallback(update, null);
        },
        .exit => {
            c.pd.system.setUpdateCallback(null, null);
            c.pd.display.setRefreshRate(-1);

            c.pd.sound.sampleplayer.freePlayer(audio_player);
            c.pd.sound.sample.freeSample(audio);

            c.pd.graphics.video.freePlayer(video_player);
        },
        else => {},
    }
}

fn update(_: ?*anyopaque) callconv(.C) c_int {
    var pressed: c.PDButtons = undefined;
    c.pd.system.getButtonState(null, &pressed, null);

    const angle = c.pd.system.getCrankAngle();
    const angle_change = c.pd.system.getCrankChange();

    var should_redraw: c_int = 0;

    var video_length: c_int = undefined;
    var prev_video_index: c_int = undefined;
    c.pd.graphics.video.getInfo(video_player, null, null, null, &video_length, &prev_video_index);
    const video_length_f: f32 = @floatFromInt(video_length);
    const cur_video_index_f = @round(angle / 360 * video_length_f + 0.5);
    const cur_video_index = @mod(@as(c_int, @intFromFloat(cur_video_index_f)), video_length);

    if (cur_video_index != prev_video_index) {
        _ = c.pd.graphics.video.renderFrame(video_player, cur_video_index);
        const ctx = c.pd.graphics.video.getContext(video_player);
        c.pd.graphics.drawBitmap(ctx, 0, 0, c.kBitmapUnflipped);
        should_redraw = 1;
    }

    angle_change_samples[angle_change_sample_index] = angle_change / 360 * update_rate;
    angle_change_sample_index = (angle_change_sample_index + 1) % angle_change_samples.len;
    var rolling_avg: f32 = 0;
    for (angle_change_samples) |sample| rolling_avg += sample;
    rolling_avg /= angle_change_samples.len;

    // Fudge the playback rate near |1| to make it easier to hit the sweet spot.
    const abs_average = @abs(rolling_avg);
    const rate = std.math.copysign(
        std.math.lerp(1, abs_average, @min(@abs(1 - abs_average), 1)),
        rolling_avg,
    );

    c.pd.sound.sampleplayer.setRate(audio_player, rate);

    if (pressed & c.kButtonB != 0) {
        main.State.transition(.main);
        return 0;
    }

    return should_redraw;
}
