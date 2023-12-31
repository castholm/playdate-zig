const std = @import("std");
const playdate = @import("playdate");
const c = playdate.c;

pub fn handleEvent(_: playdate.SystemEvent) void {
    throw0() catch |err| std.builtin.panic(@errorName(err), @errorReturnTrace(), null);
}

const RandomError = error{ Zero, One, Two, Three };

fn throw0() RandomError!void {
    try throw1();
}

fn throw1() RandomError!void {
    try throw2();
}

fn throw2() RandomError!void {
    try throw3();
}

fn throw3() RandomError!void {
    try throw4();
}

fn throw4() RandomError!void {
    try throw5();
}

fn throw5() RandomError!void {
    try throw6();
}

fn throw6() RandomError!void {
    try throw7();
}

fn throw7() RandomError!void {
    try throw8();
}

fn throw8() RandomError!void {
    try throw9();
}

fn throw9() RandomError!void {
    try throw10();
}

fn throw10() RandomError!void {
    try throw11();
}

fn throw11() RandomError!void {
    try throw12();
}

fn throw12() RandomError!void {
    try throw13();
}

fn throw13() RandomError!void {
    try throw14();
}

fn throw14() RandomError!void {
    try throw15();
}

fn throw15() RandomError!void {
    const x: u2 = @truncate(c.pd.system.getCurrentTimeMilliseconds());
    return switch (x) {
        0 => error.Zero,
        1 => error.One,
        2 => error.Two,
        3 => error.Three,
    };
}
