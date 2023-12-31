const std = @import("std");
const builtin = @import("builtin");

pub const TARGET_EXTENSION = 1;

pub const TARGET_PLAYDATE: comptime_int = @intFromBool(builtin.target.cpu.arch == .thumb and builtin.target.os.tag == .freestanding and builtin.target.abi == .eabihf);

pub const TARGET_SIMULATOR: comptime_int = @intFromBool(TARGET_PLAYDATE == 0);

pub var pd: *PlaydateAPI = undefined;

pub const PlaydateAPI = extern struct {
    system: *const playdate_sys,
    file: *const playdate_file,
    graphics: *const playdate_graphics,
    sprite: *const playdate_sprite,
    display: *const playdate_display,
    sound: *const playdate_sound,
    lua: *const playdate_lua,
    json: *const playdate_json,
    scoreboards: *const playdate_scoreboards,
};

pub const PDSystemEvent = c_uint;
pub const kEventInit = 0;
pub const kEventInitLua = 1;
pub const kEventLock = 2;
pub const kEventUnlock = 3;
pub const kEventPause = 4;
pub const kEventResume = 5;
pub const kEventTerminate = 6;
pub const kEventKeyPressed = 7;
pub const kEventKeyReleased = 8;
pub const kEventLowPower = 9;

//#region System

pub const PDButtons = c_uint;
pub const kButtonLeft = 1 << 0;
pub const kButtonRight = 1 << 1;
pub const kButtonUp = 1 << 2;
pub const kButtonDown = 1 << 3;
pub const kButtonB = 1 << 4;
pub const kButtonA = 1 << 5;

pub const PDLanguage = c_uint;
pub const kPDLanguageEnglish = 0;
pub const kPDLanguageJapanese = 1;
pub const kPDLanguageUnknown = 2;

pub const PDDateTime = extern struct {
    year: u16,
    month: u8,
    day: u8,
    weekday: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

pub const PDMenuItem = opaque {};

pub const PDPeripherals = c_uint;
pub const kNone = 0;
pub const kAccelerometer = 1 << 0;
pub const kAllPeripherals = 0xffff;

pub const PDCallbackFunction = fn (userdata: ?*anyopaque) callconv(.C) c_int;

pub const PDMenuItemCallbackFunction = fn (userdata: ?*anyopaque) callconv(.C) void;

pub const playdate_sys = extern struct {
    realloc: *const fn (ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque,
    formatString: *const fn (ret: *[*:0]u8, fmt: [*:0]const u8, ...) callconv(.C) c_int,
    logToConsole: *const fn (fmt: [*:0]const u8, ...) callconv(.C) void,
    @"error": *const fn (fmt: [*:0]const u8, ...) callconv(.C) void,
    getLanguage: *const fn () callconv(.C) PDLanguage,
    getCurrentTimeMilliseconds: *const fn () callconv(.C) c_uint,
    getSecondsSinceEpoch: *const fn (milliseconds: ?*c_uint) callconv(.C) c_uint,
    drawFPS: *const fn (x: c_int, y: c_int) callconv(.C) void,
    setUpdateCallback: *const fn (update: ?*const PDCallbackFunction, userdata: ?*anyopaque) callconv(.C) void,
    getButtonState: *const fn (current: ?*PDButtons, pushed: ?*PDButtons, released: ?*PDButtons) callconv(.C) void,
    setPeripheralsEnabled: *const fn (mask: PDPeripherals) callconv(.C) void,
    getAccelerometer: *const fn (outx: ?*f32, outy: ?*f32, outz: ?*f32) callconv(.C) void,
    getCrankChange: *const fn () callconv(.C) f32,
    getCrankAngle: *const fn () callconv(.C) f32,
    isCrankDocked: *const fn () callconv(.C) c_int,
    setCrankSoundsDisabled: *const fn (flag: c_int) callconv(.C) c_int,
    getFlipped: *const fn () callconv(.C) c_int,
    setAutoLockDisabled: *const fn (disable: c_int) callconv(.C) void,
    setMenuImage: *const fn (bitmap: ?*LCDBitmap, xOffset: c_int) callconv(.C) void,
    addMenuItem: *const fn (title: [*:0]const u8, callback: ?*const PDMenuItemCallbackFunction, userdata: ?*anyopaque) callconv(.C) ?*PDMenuItem,
    addCheckmarkMenuItem: *const fn (title: [*:0]const u8, value: c_int, callback: ?*const PDMenuItemCallbackFunction, userdata: ?*anyopaque) callconv(.C) ?*PDMenuItem,
    addOptionsMenuItem: *const fn (title: [*:0]const u8, optionTitles: [*]const [*:0]const u8, optionsCount: c_int, f: ?*const PDMenuItemCallbackFunction, userdata: ?*anyopaque) callconv(.C) ?*PDMenuItem,
    removeAllMenuItems: *const fn () callconv(.C) void,
    removeMenuItem: *const fn (menuItem: *PDMenuItem) callconv(.C) void,
    getMenuItemValue: *const fn (menuItem: *PDMenuItem) callconv(.C) c_int,
    setMenuItemValue: *const fn (menuItem: *PDMenuItem, value: c_int) callconv(.C) void,
    getMenuItemTitle: *const fn (menuItem: *PDMenuItem) callconv(.C) [*:0]const u8,
    setMenuItemTitle: *const fn (menuItem: *PDMenuItem, title: [*:0]const u8) callconv(.C) void,
    getMenuItemUserdata: *const fn (menuItem: *PDMenuItem) callconv(.C) ?*anyopaque,
    setMenuItemUserdata: *const fn (menuItem: *PDMenuItem, ud: ?*anyopaque) callconv(.C) void,
    getReduceFlashing: *const fn () callconv(.C) c_int,
    getElapsedTime: *const fn () callconv(.C) f32,
    resetElapsedTime: *const fn () callconv(.C) void,
    getBatteryPercentage: *const fn () callconv(.C) f32,
    getBatteryVoltage: *const fn () callconv(.C) f32,
    getTimezoneOffset: *const fn () callconv(.C) i32,
    shouldDisplay24HourTime: *const fn () callconv(.C) c_int,
    convertEpochToDateTime: *const fn (epoch: u32, datetime: *PDDateTime) callconv(.C) void,
    convertDateTimeToEpoch: *const fn (datetime: *const PDDateTime) callconv(.C) u32,
    clearICache: *const fn () callconv(.C) void,
};

//#endregion System

//#region File

pub const SDFile = anyopaque;

pub const FileOptions = c_uint;
pub const kFileRead = 1 << 0;
pub const kFileReadData = 1 << 1;
pub const kFileWrite = 1 << 2;
pub const kFileAppend = 1 << 3;

pub const FileStat = extern struct {
    isdir: c_int,
    size: c_uint,
    m_year: c_int,
    m_month: c_int,
    m_day: c_int,
    m_hour: c_int,
    m_minute: c_int,
    m_second: c_int,
};

pub const SEEK_SET = 0;

pub const SEEK_CUR = 1;

pub const SEEK_END = 2;

pub const playdate_file = extern struct {
    geterr: *const fn () callconv(.C) ?[*:0]const u8,
    listfiles: *const fn (path: [*:0]const u8, callback: ?*const fn (path: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void, userdata: ?*anyopaque, showhidden: c_int) callconv(.C) c_int,
    stat: *const fn (path: [*:0]const u8, stat: *FileStat) callconv(.C) c_int,
    mkdir: *const fn (path: [*:0]const u8) callconv(.C) c_int,
    unlink: *const fn (name: [*:0]const u8, recursive: c_int) callconv(.C) c_int,
    rename: *const fn (from: [*:0]const u8, to: [*:0]const u8) callconv(.C) c_int,
    open: *const fn (name: [*:0]const u8, mode: FileOptions) callconv(.C) ?*SDFile,
    close: *const fn (file: *SDFile) callconv(.C) c_int,
    read: *const fn (file: *SDFile, buf: *anyopaque, len: c_uint) callconv(.C) c_int,
    write: *const fn (file: *SDFile, buf: *const anyopaque, len: c_uint) callconv(.C) c_int,
    flush: *const fn (file: *SDFile) callconv(.C) c_int,
    tell: *const fn (file: *SDFile) callconv(.C) c_int,
    seek: *const fn (file: *SDFile, pos: c_int, whence: c_int) callconv(.C) c_int,
};

//#endregion File

//#region Graphics

pub const LCDRect = extern struct {
    left: c_int,
    right: c_int,
    top: c_int,
    bottom: c_int,
};

pub fn LCDMakeRect(x: c_int, y: c_int, width: c_int, height: c_int) LCDRect {
    return .{ .left = x, .right = x + width, .top = y, .bottom = y + height };
}

pub fn LCDRect_translate(r: LCDRect, dx: c_int, dy: c_int) LCDRect {
    return .{ .left = r.left + dx, .right = r.right + dx, .top = r.top + dy, .bottom = r.bottom + dy };
}

pub const LCD_COLUMNS = 400;

pub const LCD_ROWS = 240;

pub const LCD_ROWSIZE = 52;

pub const LCD_SCREEN_RECT = LCDMakeRect(0, 0, LCD_COLUMNS, LCD_ROWS);

pub const LCDBitmapDrawMode = c_uint;
pub const kDrawModeCopy = 0;
pub const kDrawModeWhiteTransparent = 1;
pub const kDrawModeBlackTransparent = 2;
pub const kDrawModeFillWhite = 3;
pub const kDrawModeFillBlack = 4;
pub const kDrawModeXOR = 5;
pub const kDrawModeNXOR = 6;
pub const kDrawModeInverted = 7;

pub const LCDBitmapFlip = c_uint;
pub const kBitmapUnflipped = 0;
pub const kBitmapFlippedX = 1;
pub const kBitmapFlippedY = 2;
pub const kBitmapFlippedXY = 3;

pub const LCDSolidColor = c_uint;
pub const kColorBlack = 0;
pub const kColorWhite = 1;
pub const kColorClear = 2;
pub const kColorXOR = 3;

pub const LCDLineCapStyle = c_uint;
pub const kLineCapStyleButt = 0;
pub const kLineCapStyleSquare = 1;
pub const kLineCapStyleRound = 2;

pub const LCDFontLanguage = c_uint;
pub const kLCDFontLanguageEnglish = 0;
pub const kLCDFontLanguageJapanese = 1;
pub const kLCDFontLanguageUnknown = 2;

pub const PDStringEncoding = c_uint;
pub const kASCIIEncoding = 0;
pub const kUTF8Encoding = 1;
pub const k16BitLEEncoding = 2;

pub const LCDPattern = [16]u8;

pub const LCDColor = usize;

pub fn LCDMakePattern(r0: u8, r1: u8, r2: u8, r3: u8, r4: u8, r5: u8, r6: u8, r7: u8, r8: u8, r9: u8, ra: u8, rb: u8, rc: u8, rd: u8, re: u8, rf: u8) LCDPattern {
    return .{ r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, ra, rb, rc, rd, re, rf };
}

pub fn LCDOpaquePattern(r0: u8, r1: u8, r2: u8, r3: u8, r4: u8, r5: u8, r6: u8, r7: u8) LCDPattern {
    return .{ r0, r1, r2, r3, r4, r5, r6, r7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
}

pub const LCDPolygonFillRule = c_uint;
pub const kPolygonFillNonZero = 0;
pub const kPolygonFillEvenOdd = 1;

pub const LCDBitmap = opaque {};

pub const LCDBitmapTable = opaque {};

pub const LCDFont = opaque {};

pub const LCDFontData = opaque {};

pub const LCDFontPage = opaque {};

pub const LCDFontGlyph = opaque {};

pub const LCDVideoPlayer = opaque {};

pub const playdate_video = extern struct {
    loadVideo: *const fn (path: [*:0]const u8) callconv(.C) ?*LCDVideoPlayer,
    freePlayer: *const fn (p: *LCDVideoPlayer) callconv(.C) void,
    setContext: *const fn (p: *LCDVideoPlayer, context: ?*LCDBitmap) callconv(.C) c_int,
    useScreenContext: *const fn (p: *LCDVideoPlayer) callconv(.C) void,
    renderFrame: *const fn (p: *LCDVideoPlayer, n: c_int) callconv(.C) c_int,
    getError: *const fn (p: *LCDVideoPlayer) callconv(.C) ?[*:0]const u8,
    getInfo: *const fn (p: *LCDVideoPlayer, outWidth: ?*c_int, outHeight: ?*c_int, outFrameRate: ?*f32, outFrameCount: ?*c_int, outCurrentFrame: ?*c_int) callconv(.C) void,
    getContext: *const fn (p: *LCDVideoPlayer) callconv(.C) ?*LCDBitmap,
};

pub const playdate_graphics = extern struct {
    video: *const playdate_video,
    clear: *const fn (color: LCDColor) callconv(.C) void,
    setBackgroundColor: *const fn (color: LCDSolidColor) callconv(.C) void,
    setStencil: *const fn (stencil: ?*LCDBitmap) callconv(.C) void,
    setDrawMode: *const fn (mode: LCDBitmapDrawMode) callconv(.C) void,
    setDrawOffset: *const fn (dx: c_int, dy: c_int) callconv(.C) void,
    setClipRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int) callconv(.C) void,
    clearClipRect: *const fn () callconv(.C) void,
    setLineCapStyle: *const fn (endCapStyle: LCDLineCapStyle) callconv(.C) void,
    setFont: *const fn (font: ?*LCDFont) callconv(.C) void,
    setTextTracking: *const fn (tracking: c_int) callconv(.C) void,
    pushContext: *const fn (target: ?*LCDBitmap) callconv(.C) void,
    popContext: *const fn () callconv(.C) void,
    drawBitmap: *const fn (bitmap: *LCDBitmap, x: c_int, y: c_int, flip: LCDBitmapFlip) callconv(.C) void,
    tileBitmap: *const fn (bitmap: *LCDBitmap, x: c_int, y: c_int, width: c_int, height: c_int, flip: LCDBitmapFlip) callconv(.C) void,
    drawLine: *const fn (x1: c_int, y1: c_int, x2: c_int, y2: c_int, width: c_int, color: LCDColor) callconv(.C) void,
    fillTriangle: *const fn (x1: c_int, y1: c_int, x2: c_int, y2: c_int, x3: c_int, y3: c_int, color: LCDColor) callconv(.C) void,
    drawRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int, color: LCDColor) callconv(.C) void,
    fillRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int, color: LCDColor) callconv(.C) void,
    drawEllipse: *const fn (x: c_int, y: c_int, width: c_int, height: c_int, lineWidth: c_int, startAngle: f32, endAngle: f32, color: LCDColor) callconv(.C) void,
    fillEllipse: *const fn (x: c_int, y: c_int, width: c_int, height: c_int, startAngle: f32, endAngle: f32, color: LCDColor) callconv(.C) void,
    drawScaledBitmap: *const fn (bitmap: *LCDBitmap, x: c_int, y: c_int, xscale: f32, yscale: f32) callconv(.C) void,
    drawText: *const fn (text: *const anyopaque, len: usize, encoding: PDStringEncoding, x: c_int, y: c_int) callconv(.C) c_int,
    newBitmap: *const fn (width: c_int, height: c_int, bgcolor: LCDColor) callconv(.C) ?*LCDBitmap,
    freeBitmap: *const fn (bitmap: *LCDBitmap) callconv(.C) void,
    loadBitmap: *const fn (path: [*:0]const u8, outerr: ?*?[*:0]const u8) callconv(.C) ?*LCDBitmap,
    copyBitmap: *const fn (bitmap: *LCDBitmap) callconv(.C) ?*LCDBitmap,
    loadIntoBitmap: *const fn (path: [*:0]const u8, bitmap: *LCDBitmap, outerr: ?*?[*:0]const u8) callconv(.C) void,
    getBitmapData: *const fn (bitmap: *LCDBitmap, width: ?*c_int, height: ?*c_int, rowbytes: ?*c_int, mask: ?*?[*]u8, data: ?*[*]u8) callconv(.C) void,
    clearBitmap: *const fn (bitmap: *LCDBitmap, bgcolor: LCDColor) callconv(.C) void,
    rotatedBitmap: *const fn (bitmap: *LCDBitmap, rotation: f32, xscale: f32, yscale: f32, allocedSize: ?*c_int) callconv(.C) ?*LCDBitmap,
    newBitmapTable: *const fn (count: c_int, width: c_int, height: c_int) callconv(.C) ?*LCDBitmapTable,
    freeBitmapTable: *const fn (table: *LCDBitmapTable) callconv(.C) void,
    loadBitmapTable: *const fn (path: [*:0]const u8, outerr: ?*?[*:0]const u8) callconv(.C) ?*LCDBitmapTable,
    loadIntoBitmapTable: *const fn (path: [*:0]const u8, table: *LCDBitmapTable, outerr: ?*?[*:0]const u8) callconv(.C) void,
    getTableBitmap: *const fn (table: *LCDBitmapTable, idx: c_int) callconv(.C) ?*LCDBitmap,
    loadFont: *const fn (path: [*:0]const u8, outErr: ?*?[*:0]const u8) callconv(.C) ?*LCDFont,
    getFontPage: *const fn (font: *LCDFont, c: u32) callconv(.C) ?*LCDFontPage,
    // TODO bitmap alloc?
    getPageGlyph: *const fn (page: *LCDFontPage, c: u32, bitmap: ?**LCDBitmap, advance: ?*c_int) callconv(.C) ?*LCDFontGlyph,
    getGlyphKerning: *const fn (glyph: *LCDFontGlyph, c1: u32, c2: u32) callconv(.C) c_int,
    getTextWidth: *const fn (font: ?*LCDFont, text: *const anyopaque, len: usize, encoding: PDStringEncoding, tracking: c_int) callconv(.C) c_int,
    getFrame: *const fn () callconv(.C) *[LCD_ROWS * LCD_ROWSIZE]u8,
    getDisplayFrame: *const fn () callconv(.C) *[LCD_ROWS * LCD_ROWSIZE]u8,
    // TODO return alloc? (test if two calls return different bitmaps)
    getDebugBitmap: ?*const fn () callconv(.C) *LCDBitmap,
    copyFrameBufferBitmap: *const fn () callconv(.C) ?*LCDBitmap,
    markUpdatedRows: *const fn (start: c_int, end: c_int) callconv(.C) void,
    display: *const fn () callconv(.C) void,
    // TODO bitmap nullable? (also, does this alloc?)
    setColorToPattern: *const fn (color: *LCDColor, bitmap: *LCDBitmap, x: c_int, y: c_int) callconv(.C) void,
    checkMaskCollision: *const fn (bitmap1: *LCDBitmap, x1: c_int, y1: c_int, flip1: LCDBitmapFlip, bitmap2: *LCDBitmap, x2: c_int, y2: c_int, flip2: LCDBitmapFlip, rect: LCDRect) callconv(.C) c_int,
    setScreenClipRect: *const fn (x: c_int, y: c_int, width: c_int, height: c_int) callconv(.C) void,
    // TODO coords const?
    fillPolygon: *const fn (nPoints: c_int, coords: *c_int, color: LCDColor, fillrule: LCDPolygonFillRule) callconv(.C) void,
    getFontHeight: *const fn (font: *LCDFont) callconv(.C) u8,
    getDisplayBufferBitmap: *const fn () callconv(.C) *LCDBitmap,
    drawRotatedBitmap: *const fn (bitmap: *LCDBitmap, x: c_int, y: c_int, rotation: f32, centerx: f32, centery: f32, xscale: f32, yscale: f32) callconv(.C) void,
    setTextLeading: *const fn (lineHeightAdustment: c_int) callconv(.C) void,
    // TODO mask nullable?
    setBitmapMask: *const fn (bitmap: *LCDBitmap, mask: *LCDBitmap) callconv(.C) c_int,
    getBitmapMask: *const fn (bitmap: *LCDBitmap) callconv(.C) ?*LCDBitmap,
    setStencilImage: *const fn (stencil: ?*LCDBitmap, tile: c_int) callconv(.C) void,
    makeFontFromData: *const fn (data: *LCDFontData, wide: c_int) callconv(.C) *LCDFont,
    getTextTracking: *const fn () callconv(.C) c_int,
};

//#endregion Graphics

//#region Sprite

pub const SpriteCollisionResponseType = c_uint;
pub const kCollisionTypeSlide = 0;
pub const kCollisionTypeFreeze = 1;
pub const kCollisionTypeOverlap = 2;
pub const kCollisionTypeBounce = 3;

pub const PDRect = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

pub fn PDRectMake(x: f32, y: f32, width: f32, height: f32) PDRect {
    return .{ .x = x, .y = y, .width = width, .height = height };
}

pub const CollisionPoint = extern struct {
    x: f32,
    y: f32,
};

pub const CollisionVector = extern struct {
    x: c_int,
    y: c_int,
};

pub const SpriteCollisionInfo = extern struct {
    sprite: *LCDSprite,
    other: *LCDSprite,
    responseType: SpriteCollisionResponseType,
    overlaps: u8,
    ti: f32,
    move: CollisionPoint,
    normal: CollisionVector,
    touch: CollisionPoint,
    spriteRect: PDRect,
    otherRect: PDRect,
};

pub const SpriteQueryInfo = extern struct {
    sprite: *LCDSprite,
    ti1: f32,
    ti2: f32,
    entryPoint: CollisionPoint,
    exitPoint: CollisionPoint,
};

pub const LCDSprite = opaque {};

pub const CWCollisionInfo = opaque {};

pub const CWItemInfo = opaque {};

pub const LCDSpriteDrawFunction = fn (sprite: *LCDSprite, bounds: PDRect, drawrect: PDRect) callconv(.C) void;

pub const LCDSpriteUpdateFunction = fn (sprite: *LCDSprite) callconv(.C) void;

pub const LCDSpriteCollisionFilterProc = fn (sprite: *LCDSprite, other: *LCDSprite) callconv(.C) SpriteCollisionResponseType;

pub const playdate_sprite = extern struct {
    setAlwaysRedraw: *const fn (flag: c_int) callconv(.C) void,
    addDirtyRect: *const fn (dirtyRect: LCDRect) callconv(.C) void,
    drawSprites: *const fn () callconv(.C) void,
    updateAndDrawSprites: *const fn () callconv(.C) void,
    newSprite: *const fn () callconv(.C) ?*LCDSprite,
    freeSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    copy: *const fn (sprite: *LCDSprite) callconv(.C) ?*LCDSprite,
    addSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    removeSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    // TODO sprites const?
    removeSprites: *const fn (sprites: [*]*LCDSprite, count: c_int) callconv(.C) void,
    removeAllSprites: *const fn () callconv(.C) void,
    getSpriteCount: *const fn () callconv(.C) c_int,
    setBounds: *const fn (sprite: *LCDSprite, bounds: PDRect) callconv(.C) void,
    getBounds: *const fn (sprite: *LCDSprite) callconv(.C) PDRect,
    moveTo: *const fn (sprite: *LCDSprite, x: f32, y: f32) callconv(.C) void,
    moveBy: *const fn (sprite: *LCDSprite, dx: f32, dy: f32) callconv(.C) void,
    // TODO image nullable?
    setImage: *const fn (sprite: *LCDSprite, image: *LCDBitmap, flip: LCDBitmapFlip) callconv(.C) void,
    // TODO return nullable?
    getImage: *const fn (sprite: *LCDSprite) callconv(.C) ?*LCDBitmap,
    setSize: *const fn (s: *LCDSprite, width: f32, height: f32) callconv(.C) void,
    setZIndex: *const fn (sprite: *LCDSprite, zIndex: i16) callconv(.C) void,
    getZIndex: *const fn (sprite: *LCDSprite) callconv(.C) i16,
    setDrawMode: *const fn (sprite: *LCDSprite, mode: LCDBitmapDrawMode) callconv(.C) void,
    setImageFlip: *const fn (sprite: *LCDSprite, flip: LCDBitmapFlip) callconv(.C) void,
    getImageFlip: *const fn (sprite: *LCDSprite) callconv(.C) LCDBitmapFlip,
    // TODO stencil nullable?
    setStencil: *const fn (sprite: *LCDSprite, stencil: *LCDBitmap) callconv(.C) void,
    setClipRect: *const fn (sprite: *LCDSprite, clipRect: LCDRect) callconv(.C) void,
    clearClipRect: *const fn (sprite: *LCDSprite) callconv(.C) void,
    setClipRectsInRange: *const fn (clipRect: LCDRect, startZ: c_int, endZ: c_int) callconv(.C) void,
    clearClipRectsInRange: *const fn (startZ: c_int, endZ: c_int) callconv(.C) void,
    setUpdatesEnabled: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    updatesEnabled: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setCollisionsEnabled: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    collisionsEnabled: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setVisible: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    isVisible: *const fn (sprite: *LCDSprite) callconv(.C) c_int,
    setOpaque: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    markDirty: *const fn (sprite: *LCDSprite) callconv(.C) void,
    setTag: *const fn (sprite: *LCDSprite, tag: u8) callconv(.C) void,
    getTag: *const fn (sprite: *LCDSprite) callconv(.C) u8,
    setIgnoresDrawOffset: *const fn (sprite: *LCDSprite, flag: c_int) callconv(.C) void,
    // TODO func nullable?
    setUpdateFunction: *const fn (sprite: *LCDSprite, func: *const LCDSpriteUpdateFunction) callconv(.C) void,
    // TODO func nullable?
    setDrawFunction: *const fn (sprite: *LCDSprite, func: *const LCDSpriteDrawFunction) callconv(.C) void,
    // TODO x, y nullable?
    getPosition: *const fn (sprite: *LCDSprite, x: ?*f32, y: ?*f32) callconv(.C) void,
    resetCollisionWorld: *const fn () callconv(.C) void,
    setCollideRect: *const fn (sprite: *LCDSprite, collideRect: PDRect) callconv(.C) void,
    getCollideRect: *const fn (sprite: *LCDSprite) callconv(.C) PDRect,
    clearCollideRect: *const fn (sprite: *LCDSprite) callconv(.C) void,
    // TODO func nullable?
    setCollisionResponseFunction: *const fn (sprite: *LCDSprite, func: *const LCDSpriteCollisionFilterProc) callconv(.C) void,
    // TODO actualX, actualY nullable?
    checkCollisions: *const fn (sprite: *LCDSprite, goalX: f32, goalY: f32, actualX: ?*f32, actualY: ?*f32, len: *c_int) callconv(.C) [*]SpriteCollisionInfo,
    // TODO actualX, actualY nullable?
    moveWithCollisions: *const fn (sprite: *LCDSprite, goalX: f32, goalY: f32, actualX: ?*f32, actualY: ?*f32, len: *c_int) callconv(.C) [*]SpriteCollisionInfo,
    querySpritesAtPoint: *const fn (x: f32, y: f32, len: *c_int) callconv(.C) [*]*LCDSprite,
    querySpritesInRect: *const fn (x: f32, y: f32, width: f32, height: f32, len: *c_int) callconv(.C) [*]*LCDSprite,
    querySpritesAlongLine: *const fn (x1: f32, y1: f32, x2: f32, y2: f32, len: *c_int) callconv(.C) [*]*LCDSprite,
    querySpriteInfoAlongLine: *const fn (x1: f32, y1: f32, x2: f32, y2: f32, len: *c_int) callconv(.C) [*]SpriteQueryInfo,
    overlappingSprites: *const fn (sprite: *LCDSprite, len: *c_int) callconv(.C) [*]*LCDSprite,
    allOverlappingSprites: *const fn (len: *c_int) callconv(.C) [*]*LCDSprite,
    // TODO pattern const?
    setStencilPattern: *const fn (sprite: *LCDSprite, pattern: *[8]u8) callconv(.C) void,
    clearStencil: *const fn (sprite: *LCDSprite) callconv(.C) void,
    setUserdata: *const fn (sprite: *LCDSprite, userdata: ?*anyopaque) callconv(.C) void,
    getUserdata: *const fn (sprite: *LCDSprite) callconv(.C) ?*anyopaque,
    // TODO stencil nullable?
    setStencilImage: *const fn (sprite: *LCDSprite, stencil: *LCDBitmap, tile: c_int) callconv(.C) void,
    setCenter: *const fn (s: *LCDSprite, x: f32, y: f32) callconv(.C) void,
    // TODO x, y nullable?
    getCenter: *const fn (s: *LCDSprite, x: ?*f32, y: ?*f32) callconv(.C) void,
};

//#endregion Sprite

//#region Display

pub const playdate_display = extern struct {
    getWidth: *const fn () callconv(.C) c_int,
    getHeight: *const fn () callconv(.C) c_int,
    setRefreshRate: *const fn (rate: f32) callconv(.C) void,
    setInverted: *const fn (flag: c_int) callconv(.C) void,
    setScale: *const fn (s: c_uint) callconv(.C) void,
    setMosaic: *const fn (x: c_uint, y: c_uint) callconv(.C) void,
    setFlipped: *const fn (x: c_int, y: c_int) callconv(.C) void,
    setOffset: *const fn (x: c_int, y: c_int) callconv(.C) void,
};

//#endregion Display

//#region Sound

pub const AUDIO_FRAMES_PER_CYCLE = 512;

pub const SoundFormat = c_uint;
pub const kSound8bitMono = 0;
pub const kSound8bitStereo = 1;
pub const kSound16bitMono = 2;
pub const kSound16bitStereo = 3;
pub const kSoundADPCMMono = 4;
pub const kSoundADPCMStereo = 5;

pub fn SoundFormatIsStereo(f: SoundFormat) bool {
    return f & 1 != 0;
}

pub fn SoundFormatIs16bit(f: SoundFormat) bool {
    return f >= kSound16bitMono;
}

pub fn SoundFormat_bytesPerFrame(fmt: SoundFormat) callconv(.C) u32 {
    return @as(u32, if (SoundFormatIsStereo(fmt)) 2 else 1) * @as(u32, if (SoundFormatIs16bit(fmt)) 2 else 1);
}

pub const MIDINote = f32;

pub const NOTE_C4 = 60;

pub fn pd_noteToFrequency(n: MIDINote) callconv(.C) f32 {
    return 440 * std.math.pow(f32, 2, (n - 69) / 12);
}

pub fn pd_frequencyToNote(f: f32) callconv(.C) MIDINote {
    return 12 * @log2(f) - 36.37631607055664;
}

pub const SoundSource = opaque {};

pub const sndCallbackProc = fn (c: *SoundSource) callconv(.C) void;

pub const playdate_sound_source = extern struct {
    setVolume: *const fn (c: *SoundSource, lval: f32, rval: f32) callconv(.C) void,
    // TODO lval, rval nullable?
    getVolume: *const fn (c: *SoundSource, lval: ?*f32, rval: ?*f32) callconv(.C) void,
    isPlaying: *const fn (c: *SoundSource) callconv(.C) c_int,
    // TODO callback nullable?
    setFinishCallback: *const fn (c: *SoundSource, callback: ?*const sndCallbackProc) callconv(.C) void,
};

pub const FilePlayer = opaque {};

pub const playdate_sound_fileplayer = extern struct {
    newPlayer: *const fn () callconv(.C) ?*FilePlayer,
    freePlayer: *const fn (player: *FilePlayer) callconv(.C) void,
    loadIntoPlayer: *const fn (player: *FilePlayer, path: [*:0]const u8) callconv(.C) c_int,
    setBufferLength: *const fn (player: *FilePlayer, bufferLen: f32) callconv(.C) void,
    play: *const fn (player: *FilePlayer, repeat: c_int) callconv(.C) c_int,
    isPlaying: *const fn (player: *FilePlayer) callconv(.C) c_int,
    pause: *const fn (player: *FilePlayer) callconv(.C) void,
    stop: *const fn (player: *FilePlayer) callconv(.C) void,
    setVolume: *const fn (player: *FilePlayer, left: f32, right: f32) callconv(.C) void,
    // TODO left, right nullable?
    getVolume: *const fn (player: *FilePlayer, left: ?*f32, right: ?*f32) callconv(.C) void,
    getLength: *const fn (player: *FilePlayer) callconv(.C) f32,
    setOffset: *const fn (player: *FilePlayer, offset: f32) callconv(.C) void,
    setRate: *const fn (player: *FilePlayer, rate: f32) callconv(.C) void,
    setLoopRange: *const fn (player: *FilePlayer, start: f32, end: f32) callconv(.C) void,
    didUnderrun: *const fn (player: *FilePlayer) callconv(.C) c_int,
    // TODO callback nullable?
    setFinishCallback: *const fn (player: *FilePlayer, callback: ?*const sndCallbackProc) callconv(.C) void,
    // TODO callback nullable?
    setLoopCallback: *const fn (player: *FilePlayer, callback: ?*const sndCallbackProc) callconv(.C) void,
    getOffset: *const fn (player: *FilePlayer) callconv(.C) f32,
    getRate: *const fn (player: *FilePlayer) callconv(.C) f32,
    setStopOnUnderrun: *const fn (player: *FilePlayer, flag: c_int) callconv(.C) void,
    // TODO finishCallback nullable?
    fadeVolume: *const fn (player: *FilePlayer, left: f32, right: f32, len: i32, finishCallback: ?*const sndCallbackProc) callconv(.C) void,
    setMP3StreamSource: *const fn (player: *FilePlayer, dataSource: *const fn (data: [*]u8, bytes: c_int, userdata: ?*anyopaque) callconv(.C) c_int, userdata: ?*anyopaque, bufferLen: f32) callconv(.C) void,
};

pub const AudioSample = opaque {};

pub const SamplePlayer = opaque {};

pub const playdate_sound_sample = extern struct {
    newSampleBuffer: *const fn (byteCount: c_int) callconv(.C) ?*AudioSample,
    loadIntoSample: *const fn (sample: *AudioSample, path: [*:0]const u8) callconv(.C) c_int,
    load: *const fn (path: [*:0]const u8) callconv(.C) ?*AudioSample,
    newSampleFromData: *const fn (data: [*]u8, format: SoundFormat, sampleRate: u32, byteCount: c_int) callconv(.C) ?*AudioSample,
    // TODO data, format, sampleRate, bytelength nullable?
    getData: *const fn (sample: *AudioSample, data: ?*[*]u8, format: ?*SoundFormat, sampleRate: ?*u32, bytelength: ?*u32) callconv(.C) void,
    freeSample: *const fn (sample: *AudioSample) callconv(.C) void,
    getLength: *const fn (sample: *AudioSample) callconv(.C) f32,
};

pub const playdate_sound_sampleplayer = extern struct {
    newPlayer: *const fn () callconv(.C) ?*SamplePlayer,
    freePlayer: *const fn (player: *SamplePlayer) callconv(.C) void,
    // TODO sample nullable?
    setSample: *const fn (player: *SamplePlayer, sample: ?*AudioSample) callconv(.C) void,
    play: *const fn (player: *SamplePlayer, repeat: c_int, rate: f32) callconv(.C) c_int,
    isPlaying: *const fn (player: *SamplePlayer) callconv(.C) c_int,
    stop: *const fn (player: *SamplePlayer) callconv(.C) void,
    setVolume: *const fn (player: *SamplePlayer, left: f32, right: f32) callconv(.C) void,
    // TODO left, right nullable?
    getVolume: *const fn (player: *SamplePlayer, left: ?*f32, right: ?*f32) callconv(.C) void,
    getLength: *const fn (player: *SamplePlayer) callconv(.C) f32,
    setOffset: *const fn (player: *SamplePlayer, offset: f32) callconv(.C) void,
    setRate: *const fn (player: *SamplePlayer, rate: f32) callconv(.C) void,
    setPlayRange: *const fn (player: *SamplePlayer, start: c_int, end: c_int) callconv(.C) void,
    // TODO callback nullable?
    setFinishCallback: *const fn (player: *SamplePlayer, callback: ?*const sndCallbackProc) callconv(.C) void,
    // TODO callback nullable?
    setLoopCallback: *const fn (player: *SamplePlayer, callback: ?*const sndCallbackProc) callconv(.C) void,
    getOffset: *const fn (player: *SamplePlayer) callconv(.C) f32,
    getRate: *const fn (player: *SamplePlayer) callconv(.C) f32,
    setPaused: *const fn (player: *SamplePlayer, flag: c_int) callconv(.C) void,
};

pub const PDSynthSignalValue = opaque {};

pub const PDSynthSignal = opaque {};

pub const signalStepFunc = *const fn (userdata: ?*anyopaque, ioframes: *c_int, ifval: *f32) callconv(.C) f32;

pub const signalNoteOnFunc = *const fn (userdata: ?*anyopaque, note: MIDINote, vel: f32, len: f32) callconv(.C) void;

pub const signalNoteOffFunc = *const fn (userdata: ?*anyopaque, stopped: c_int, offset: c_int) callconv(.C) void;

pub const signalDeallocFunc = *const fn (userdata: ?*anyopaque) callconv(.C) void;

pub const playdate_sound_signal = extern struct {
    newSignal: *const fn (step: signalStepFunc, noteOn: ?signalNoteOnFunc, noteOff: ?signalNoteOffFunc, dealloc: ?signalDeallocFunc, userdata: ?*anyopaque) callconv(.C) ?*PDSynthSignal,
    freeSignal: *const fn (signal: *PDSynthSignal) callconv(.C) void,
    getValue: *const fn (signal: *PDSynthSignal) callconv(.C) f32,
    setValueScale: *const fn (signal: *PDSynthSignal, scale: f32) callconv(.C) void,
    setValueOffset: *const fn (signal: *PDSynthSignal, offset: f32) callconv(.C) void,
};

pub const LFOType = c_uint;
pub const kLFOTypeSquare = 0;
pub const kLFOTypeTriangle = 1;
pub const kLFOTypeSine = 2;
pub const kLFOTypeSampleAndHold = 3;
pub const kLFOTypeSawtoothUp = 4;
pub const kLFOTypeSawtoothDown = 5;
pub const kLFOTypeArpeggiator = 6;
pub const kLFOTypeFunction = 7;

pub const PDSynthLFO = opaque {};

pub const playdate_sound_lfo = extern struct {
    newLFO: *const fn (type: LFOType) callconv(.C) ?*PDSynthLFO,
    freeLFO: *const fn (lfo: *PDSynthLFO) callconv(.C) void,
    setType: *const fn (lfo: *PDSynthLFO, type: LFOType) callconv(.C) void,
    setRate: *const fn (lfo: *PDSynthLFO, rate: f32) callconv(.C) void,
    setPhase: *const fn (lfo: *PDSynthLFO, phase: f32) callconv(.C) void,
    setCenter: *const fn (lfo: *PDSynthLFO, center: f32) callconv(.C) void,
    setDepth: *const fn (lfo: *PDSynthLFO, depth: f32) callconv(.C) void,
    setArpeggiation: *const fn (lfo: *PDSynthLFO, nSteps: c_int, steps: [*]f32) callconv(.C) void,
    // TODO lfoFunc nullable?
    setFunction: *const fn (lfo: *PDSynthLFO, lfoFunc: ?*const fn (lfo: *PDSynthLFO, userdata: ?*anyopaque) callconv(.C) f32, userdata: ?*anyopaque, interpolate: c_int) callconv(.C) void,
    setDelay: *const fn (lfo: *PDSynthLFO, holdoff: f32, ramptime: f32) callconv(.C) void,
    setRetrigger: *const fn (lfo: *PDSynthLFO, flag: c_int) callconv(.C) void,
    getValue: *const fn (lfo: *PDSynthLFO) callconv(.C) f32,
    setGlobal: *const fn (lfo: *PDSynthLFO, global: c_int) callconv(.C) void,
    setStartPhase: *const fn (lfo: *PDSynthLFO, phase: f32) callconv(.C) void,
};

pub const PDSynthEnvelope = opaque {};

pub const playdate_sound_envelope = extern struct {
    newEnvelope: *const fn (attack: f32, decay: f32, sustain: f32, release: f32) callconv(.C) ?*PDSynthEnvelope,
    freeEnvelope: *const fn (env: *PDSynthEnvelope) callconv(.C) void,
    setAttack: *const fn (env: *PDSynthEnvelope, attack: f32) callconv(.C) void,
    setDecay: *const fn (env: *PDSynthEnvelope, decay: f32) callconv(.C) void,
    setSustain: *const fn (env: *PDSynthEnvelope, sustain: f32) callconv(.C) void,
    setRelease: *const fn (env: *PDSynthEnvelope, release: f32) callconv(.C) void,
    setLegato: *const fn (env: *PDSynthEnvelope, flag: c_int) callconv(.C) void,
    setRetrigger: *const fn (env: *PDSynthEnvelope, flag: c_int) callconv(.C) void,
    getValue: *const fn (env: *PDSynthEnvelope) callconv(.C) f32,
    setCurvature: *const fn (env: *PDSynthEnvelope, amount: f32) callconv(.C) void,
    setVelocitySensitivity: *const fn (env: *PDSynthEnvelope, velsens: f32) callconv(.C) void,
    setRateScaling: *const fn (env: *PDSynthEnvelope, scaling: f32, start: MIDINote, end: MIDINote) callconv(.C) void,
};

pub const SoundWaveform = c_uint;
pub const kWaveformSquare = 0;
pub const kWaveformTriangle = 1;
pub const kWaveformSine = 2;
pub const kWaveformNoise = 3;
pub const kWaveformSawtooth = 4;
pub const kWaveformPOPhase = 5;
pub const kWaveformPODigital = 6;
pub const kWaveformPOVosim = 7;

pub const synthRenderFunc = *const fn (userdata: ?*anyopaque, left: [*]i32, right: [*]i32, nsamples: c_int, rate: u32, drate: i32) callconv(.C) c_int;

pub const synthNoteOnFunc = *const fn (userdata: ?*anyopaque, note: MIDINote, velocity: f32, len: f32) callconv(.C) void;

pub const synthReleaseFunc = *const fn (userdata: ?*anyopaque, stop: c_int) callconv(.C) void;

pub const synthSetParameterFunc = *const fn (userdata: ?*anyopaque, parameter: c_int, value: f32) callconv(.C) c_int;

pub const synthDeallocFunc = *const fn (userdata: ?*anyopaque) callconv(.C) void;

pub const PDSynth = opaque {};

pub const playdate_sound_synth = extern struct {
    newSynth: *const fn () callconv(.C) ?*PDSynth,
    freeSynth: *const fn (synth: *PDSynth) callconv(.C) void,
    setWaveform: *const fn (synth: *PDSynth, wave: SoundWaveform) callconv(.C) void,
    setGenerator: *const fn (synth: *PDSynth, stereo: c_int, render: synthRenderFunc, noteOn: ?synthNoteOnFunc, release: ?synthReleaseFunc, setparam: ?synthSetParameterFunc, dealloc: ?synthDeallocFunc, userdata: ?*anyopaque) callconv(.C) void,
    // TODO sample nullable?
    setSample: *const fn (synth: *PDSynth, sample: ?*AudioSample, sustainStart: u32, sustainEnd: u32) callconv(.C) void,
    setAttackTime: *const fn (synth: *PDSynth, attack: f32) callconv(.C) void,
    setDecayTime: *const fn (synth: *PDSynth, decay: f32) callconv(.C) void,
    setSustainLevel: *const fn (synth: *PDSynth, sustain: f32) callconv(.C) void,
    setReleaseTime: *const fn (synth: *PDSynth, release: f32) callconv(.C) void,
    setTranspose: *const fn (synth: *PDSynth, halfSteps: f32) callconv(.C) void,
    // TODO mod nullable?
    setFrequencyModulator: *const fn (synth: *PDSynth, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getFrequencyModulator: *const fn (synth: *PDSynth) callconv(.C) ?*PDSynthSignalValue,
    // TODO mod nullable?
    setAmplitudeModulator: *const fn (synth: *PDSynth, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getAmplitudeModulator: *const fn (synth: *PDSynth) callconv(.C) ?*PDSynthSignalValue,
    getParameterCount: *const fn (synth: *PDSynth) callconv(.C) c_int,
    setParameter: *const fn (synth: *PDSynth, parameter: c_int, value: f32) callconv(.C) c_int,
    // TODO mod nullable?
    setParameterModulator: *const fn (synth: *PDSynth, parameter: c_int, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getParameterModulator: *const fn (synth: *PDSynth, parameter: c_int) callconv(.C) ?*PDSynthSignalValue,
    playNote: *const fn (synth: *PDSynth, freq: f32, vel: f32, len: f32, when: u32) callconv(.C) void,
    playMIDINote: *const fn (synth: *PDSynth, note: MIDINote, vel: f32, len: f32, when: u32) callconv(.C) void,
    noteOff: *const fn (synth: *PDSynth, when: u32) callconv(.C) void,
    stop: *const fn (synth: *PDSynth) callconv(.C) void,
    setVolume: *const fn (synth: *PDSynth, left: f32, right: f32) callconv(.C) void,
    // TODO left, right nullable?
    getVolume: *const fn (synth: *PDSynth, left: *f32, right: *f32) callconv(.C) void,
    isPlaying: *const fn (synth: *PDSynth) callconv(.C) c_int,
    // TODO return nullable? (docs strongly imply not)
    getEnvelope: *const fn (synth: *PDSynth) callconv(.C) *PDSynthEnvelope,
    // TODO sample nullable?
    setWavetable: *const fn (synth: *PDSynth, sample: ?*AudioSample, log2size: c_int, columns: c_int, rows: c_int) callconv(.C) c_int,
};

pub const ControlSignal = opaque {};

pub const playdate_control_signal = extern struct {
    newSignal: *const fn () callconv(.C) ?*ControlSignal,
    freeSignal: *const fn (signal: *ControlSignal) callconv(.C) void,
    clearEvents: *const fn (control: *ControlSignal) callconv(.C) void,
    addEvent: *const fn (control: *ControlSignal, step: c_int, value: f32, interpolate: c_int) callconv(.C) void,
    removeEvent: *const fn (control: *ControlSignal, step: c_int) callconv(.C) void,
    getMIDIControllerNumber: *const fn (control: *ControlSignal) callconv(.C) c_int,
};

pub const PDSynthInstrument = opaque {};

pub const playdate_sound_instrument = extern struct {
    newInstrument: *const fn () callconv(.C) ?*PDSynthInstrument,
    freeInstrument: *const fn (inst: *PDSynthInstrument) callconv(.C) void,
    addVoice: *const fn (inst: *PDSynthInstrument, synth: *PDSynth, rangeStart: MIDINote, rangeEnd: MIDINote, transpose: f32) callconv(.C) c_int,
    playNote: *const fn (inst: *PDSynthInstrument, frequency: f32, vel: f32, len: f32, when: u32) callconv(.C) ?*PDSynth,
    playMIDINote: *const fn (inst: *PDSynthInstrument, frequency: MIDINote, vel: f32, len: f32, when: u32) callconv(.C) ?*PDSynth,
    setPitchBend: *const fn (inst: *PDSynthInstrument, bend: f32) callconv(.C) void,
    setPitchBendRange: *const fn (inst: *PDSynthInstrument, halfSteps: f32) callconv(.C) void,
    setTranspose: *const fn (inst: *PDSynthInstrument, halfSteps: f32) callconv(.C) void,
    noteOff: *const fn (inst: *PDSynthInstrument, note: MIDINote, when: u32) callconv(.C) void,
    allNotesOff: *const fn (inst: *PDSynthInstrument, when: u32) callconv(.C) void,
    setVolume: *const fn (inst: *PDSynthInstrument, left: f32, right: f32) callconv(.C) void,
    // TODO left, right nullable?
    getVolume: *const fn (inst: *PDSynthInstrument, left: ?*f32, right: ?*f32) callconv(.C) void,
    activeVoiceCount: *const fn (inst: *PDSynthInstrument) callconv(.C) c_int,
};

pub const SequenceTrack = opaque {};

pub const playdate_sound_track = extern struct {
    newTrack: *const fn () callconv(.C) ?*SequenceTrack,
    freeTrack: *const fn (track: *SequenceTrack) callconv(.C) void,
    // TODO inst nullable?
    setInstrument: *const fn (track: *SequenceTrack, inst: ?*PDSynthInstrument) callconv(.C) void,
    // TODO return nullable?
    getInstrument: *const fn (track: *SequenceTrack) callconv(.C) ?*PDSynthInstrument,
    addNoteEvent: *const fn (track: *SequenceTrack, step: u32, len: u32, note: MIDINote, velocity: f32) callconv(.C) void,
    removeNoteEvent: *const fn (track: *SequenceTrack, step: u32, note: MIDINote) callconv(.C) void,
    clearNotes: *const fn (track: *SequenceTrack) callconv(.C) void,
    getControlSignalCount: *const fn (track: *SequenceTrack) callconv(.C) c_int,
    getControlSignal: *const fn (track: *SequenceTrack, idx: c_int) callconv(.C) ?*ControlSignal,
    clearControlEvents: *const fn (track: *SequenceTrack) callconv(.C) void,
    getPolyphony: *const fn (track: *SequenceTrack) callconv(.C) c_int,
    activeVoiceCount: *const fn (track: *SequenceTrack) callconv(.C) c_int,
    setMuted: *const fn (track: *SequenceTrack, mute: c_int) callconv(.C) void,
    getLength: *const fn (track: *SequenceTrack) callconv(.C) u32,
    getIndexForStep: *const fn (track: *SequenceTrack, step: u32) callconv(.C) c_int,
    // TODO outStep, outLen, outNote, outVelocity nullable?
    getNoteAtIndex: *const fn (track: *SequenceTrack, index: c_int, outStep: ?*u32, outLen: ?*u32, outNote: ?*MIDINote, outVelocity: ?*f32) callconv(.C) c_int,
    getSignalForController: *const fn (track: *SequenceTrack, controller: c_int, create: c_int) callconv(.C) ?*ControlSignal,
};

pub const SoundSequence = opaque {};

pub const SequenceFinishedCallback = *const fn (seq: *SoundSequence, userdata: ?*anyopaque) callconv(.C) void;

pub const playdate_sound_sequence = extern struct {
    newSequence: *const fn () callconv(.C) ?*SoundSequence,
    freeSequence: *const fn (sequence: *SoundSequence) callconv(.C) void,
    loadMidiFile: *const fn (seq: *SoundSequence, path: [*:0]const u8) callconv(.C) c_int,
    getTime: *const fn (seq: *SoundSequence) callconv(.C) u32,
    setTime: *const fn (seq: *SoundSequence, time: u32) callconv(.C) void,
    setLoops: *const fn (seq: *SoundSequence, loopstart: c_int, loopend: c_int, loops: c_int) callconv(.C) void,
    getTempo: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    setTempo: *const fn (seq: *SoundSequence, stepsPerSecond: f32) callconv(.C) void,
    getTrackCount: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    addTrack: *const fn (seq: *SoundSequence) callconv(.C) ?*SequenceTrack,
    // TODO return nullable?
    getTrackAtIndex: *const fn (seq: *SoundSequence, idx: c_uint) callconv(.C) ?*SequenceTrack,
    // TODO track nullable?
    setTrackAtIndex: *const fn (seq: *SoundSequence, track: ?*SequenceTrack, idx: c_uint) callconv(.C) void,
    allNotesOff: *const fn (seq: *SoundSequence) callconv(.C) void,
    isPlaying: *const fn (seq: *SoundSequence) callconv(.C) c_int,
    getLength: *const fn (seq: *SoundSequence) callconv(.C) u32,
    play: *const fn (seq: *SoundSequence, finishCallback: ?SequenceFinishedCallback, userdata: ?*anyopaque) callconv(.C) void,
    stop: *const fn (seq: *SoundSequence) callconv(.C) void,
    getCurrentStep: *const fn (seq: *SoundSequence, timeOffset: ?*c_int) callconv(.C) c_int,
    setCurrentStep: *const fn (seq: *SoundSequence, step: c_int, timeOffset: c_int, playNotes: c_int) callconv(.C) void,
};

pub const TwoPoleFilter = opaque {};

pub const TwoPoleFilterType = c_uint;
pub const kFilterTypeLowPass = 0;
pub const kFilterTypeHighPass = 1;
pub const kFilterTypeBandPass = 2;
pub const kFilterTypeNotch = 3;
pub const kFilterTypePEQ = 4;
pub const kFilterTypeLowShelf = 5;
pub const kFilterTypeHighShelf = 6;

pub const playdate_sound_effect_twopolefilter = extern struct {
    newFilter: *const fn () callconv(.C) ?*TwoPoleFilter,
    freeFilter: *const fn (filter: *TwoPoleFilter) callconv(.C) void,
    setType: *const fn (filter: *TwoPoleFilter, type: TwoPoleFilterType) callconv(.C) void,
    setFrequency: *const fn (filter: *TwoPoleFilter, frequency: f32) callconv(.C) void,
    // TODO signal nullable?
    setFrequencyModulator: *const fn (filter: *TwoPoleFilter, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getFrequencyModulator: *const fn (filter: *TwoPoleFilter) callconv(.C) ?*PDSynthSignalValue,
    setGain: *const fn (filter: *TwoPoleFilter, gain: f32) callconv(.C) void,
    setResonance: *const fn (filter: *TwoPoleFilter, resonance: f32) callconv(.C) void,
    // TODO signal nullable?
    setResonanceModulator: *const fn (filter: *TwoPoleFilter, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getResonanceModulator: *const fn (filter: *TwoPoleFilter) callconv(.C) ?*PDSynthSignalValue,
};

pub const OnePoleFilter = opaque {};

pub const playdate_sound_effect_onepolefilter = extern struct {
    newFilter: *const fn () callconv(.C) ?*OnePoleFilter,
    freeFilter: *const fn (filter: *OnePoleFilter) callconv(.C) void,
    setParameter: *const fn (filter: *OnePoleFilter, parameter: f32) callconv(.C) void,
    // TODO signal nullable?
    setParameterModulator: *const fn (filter: *OnePoleFilter, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getParameterModulator: *const fn (filter: *OnePoleFilter) callconv(.C) ?*PDSynthSignalValue,
};

pub const BitCrusher = opaque {};

pub const playdate_sound_effect_bitcrusher = extern struct {
    newBitCrusher: *const fn () callconv(.C) ?*BitCrusher,
    freeBitCrusher: *const fn (filter: *BitCrusher) callconv(.C) void,
    setAmount: *const fn (filter: *BitCrusher, amount: f32) callconv(.C) void,
    // TODO signal nullable?
    setAmountModulator: *const fn (filter: *BitCrusher, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getAmountModulator: *const fn (filter: *BitCrusher) callconv(.C) ?*PDSynthSignalValue,
    setUndersampling: *const fn (filter: *BitCrusher, undersampling: f32) callconv(.C) void,
    // TODO signal nullable?
    setUndersampleModulator: *const fn (filter: *BitCrusher, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getUndersampleModulator: *const fn (filter: *BitCrusher) callconv(.C) ?*PDSynthSignalValue,
};

pub const RingModulator = opaque {};

pub const playdate_sound_effect_ringmodulator = extern struct {
    newRingmod: *const fn () callconv(.C) ?*RingModulator,
    freeRingmod: *const fn (filter: *RingModulator) callconv(.C) void,
    setFrequency: *const fn (filter: *RingModulator, frequency: f32) callconv(.C) void,
    // TODO signal nullable?
    setFrequencyModulator: *const fn (filter: *RingModulator, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getFrequencyModulator: *const fn (filter: *RingModulator) callconv(.C) ?*PDSynthSignalValue,
};

pub const DelayLine = opaque {};

pub const DelayLineTap = opaque {};

pub const playdate_sound_effect_delayline = extern struct {
    newDelayLine: *const fn (length: c_int, stereo: c_int) callconv(.C) ?*DelayLine,
    freeDelayLine: *const fn (filter: *DelayLine) callconv(.C) void,
    setLength: *const fn (d: *DelayLine, frames: c_int) callconv(.C) void,
    setFeedback: *const fn (d: *DelayLine, fb: f32) callconv(.C) void,
    addTap: *const fn (d: *DelayLine, delay: c_int) callconv(.C) ?*DelayLineTap,
    freeTap: *const fn (tap: *DelayLineTap) callconv(.C) void,
    setTapDelay: *const fn (t: *DelayLineTap, frames: c_int) callconv(.C) void,
    // TODO mod nullable?
    setTapDelayModulator: *const fn (t: *DelayLineTap, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getTapDelayModulator: *const fn (t: *DelayLineTap) callconv(.C) ?*PDSynthSignalValue,
    setTapChannelsFlipped: *const fn (t: *DelayLineTap, flip: c_int) callconv(.C) void,
};

pub const Overdrive = opaque {};

pub const playdate_sound_effect_overdrive = extern struct {
    newOverdrive: *const fn () callconv(.C) ?*Overdrive,
    freeOverdrive: *const fn (filter: *Overdrive) callconv(.C) void,
    setGain: *const fn (o: *Overdrive, gain: f32) callconv(.C) void,
    setLimit: *const fn (o: *Overdrive, limit: f32) callconv(.C) void,
    // TODO mod nullable?
    setLimitModulator: *const fn (o: *Overdrive, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getLimitModulator: *const fn (o: *Overdrive) callconv(.C) ?*PDSynthSignalValue,
    setOffset: *const fn (o: *Overdrive, offset: f32) callconv(.C) void,
    // TODO mod nullable?
    setOffsetModulator: *const fn (o: *Overdrive, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getOffsetModulator: *const fn (o: *Overdrive) callconv(.C) ?*PDSynthSignalValue,
};

pub const SoundEffect = opaque {};

pub const effectProc = fn (e: *SoundEffect, left: [*]i32, right: [*]i32, nsamples: c_int, bufactive: c_int) callconv(.C) c_int;

pub const playdate_sound_effect = extern struct {
    newEffect: *const fn (proc: *const effectProc, userdata: ?*anyopaque) callconv(.C) ?*SoundEffect,
    freeEffect: *const fn (effect: *SoundEffect) callconv(.C) void,
    setMix: *const fn (effect: *SoundEffect, level: f32) callconv(.C) void,
    // TODO signal nullable?
    setMixModulator: *const fn (effect: *SoundEffect, signal: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getMixModulator: *const fn (effect: *SoundEffect) callconv(.C) ?*PDSynthSignalValue,
    setUserdata: *const fn (effect: *SoundEffect, userdata: ?*anyopaque) callconv(.C) void,
    getUserdata: *const fn (effect: *SoundEffect) callconv(.C) ?*anyopaque,
    twopolefilter: *const playdate_sound_effect_twopolefilter,
    onepolefilter: *const playdate_sound_effect_onepolefilter,
    bitcrusher: *const playdate_sound_effect_bitcrusher,
    ringmodulator: *const playdate_sound_effect_ringmodulator,
    delayline: *const playdate_sound_effect_delayline,
    overdrive: *const playdate_sound_effect_overdrive,
};

pub const SoundChannel = opaque {};

// TODO right nullable? (when stereo == 0)
pub const AudioSourceFunction = fn (context: ?*anyopaque, left: [*]i16, right: ?[*]i16, len: c_int) callconv(.C) c_int;

pub const playdate_sound_channel = extern struct {
    newChannel: *const fn () callconv(.C) ?*SoundChannel,
    freeChannel: *const fn (channel: *SoundChannel) callconv(.C) void,
    addSource: *const fn (channel: *SoundChannel, source: *SoundSource) callconv(.C) c_int,
    removeSource: *const fn (channel: *SoundChannel, source: *SoundSource) callconv(.C) c_int,
    addCallbackSource: *const fn (channel: *SoundChannel, callback: *const AudioSourceFunction, context: ?*anyopaque, stereo: c_int) callconv(.C) ?*SoundSource,
    addEffect: *const fn (channel: *SoundChannel, effect: *SoundEffect) callconv(.C) void,
    removeEffect: *const fn (channel: *SoundChannel, effect: *SoundEffect) callconv(.C) void,
    setVolume: *const fn (channel: *SoundChannel, volume: f32) callconv(.C) void,
    getVolume: *const fn (channel: *SoundChannel) callconv(.C) f32,
    // TODO mod nullable?
    setVolumeModulator: *const fn (channel: *SoundChannel, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getVolumeModulator: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    setPan: *const fn (channel: *SoundChannel, pan: f32) callconv(.C) void,
    // TODO mod nullable?
    setPanModulator: *const fn (channel: *SoundChannel, mod: ?*PDSynthSignalValue) callconv(.C) void,
    // TODO return nullable?
    getPanModulator: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    // TODO return nullable?
    getDryLevelSignal: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
    // TODO return nullable?
    getWetLevelSignal: *const fn (channel: *SoundChannel) callconv(.C) ?*PDSynthSignalValue,
};

pub const RecordCallback = fn (context: ?*anyopaque, buffer: [*]i16, length: c_int) callconv(.C) c_int;

pub const playdate_sound = extern struct {
    channel: *const playdate_sound_channel,
    fileplayer: *const playdate_sound_fileplayer,
    sample: *const playdate_sound_sample,
    sampleplayer: *const playdate_sound_sampleplayer,
    synth: *const playdate_sound_synth,
    sequence: *const playdate_sound_sequence,
    effect: *const playdate_sound_effect,
    lfo: *const playdate_sound_lfo,
    envelope: *const playdate_sound_envelope,
    source: *const playdate_sound_source,
    controlsignal: *const playdate_control_signal,
    track: *const playdate_sound_track,
    instrument: *const playdate_sound_instrument,
    getCurrentTime: *const fn () callconv(.C) u32,
    addSource: *const fn (callback: *const AudioSourceFunction, context: ?*anyopaque, stereo: c_int) callconv(.C) ?*SoundSource,
    getDefaultChannel: *const fn () callconv(.C) *SoundChannel,
    addChannel: *const fn (channel: *SoundChannel) callconv(.C) c_int,
    removeChannel: *const fn (channel: *SoundChannel) callconv(.C) c_int,
    // TODO callback nullable?
    setMicCallback: *const fn (callback: ?*const RecordCallback, context: ?*anyopaque, forceInternal: c_int) callconv(.C) void,
    // TODO changeCallback nullable?
    getHeadphoneState: *const fn (headphone: ?*c_int, headsetmic: ?*c_int, changeCallback: ?*const fn (headphone: c_int, mic: c_int) callconv(.C) void) callconv(.C) void,
    setOutputsActive: *const fn (headphone: c_int, speaker: c_int) callconv(.C) void,
    removeSource: *const fn (source: *SoundSource) callconv(.C) c_int,
    signal: *const playdate_sound_signal,
    getError: *const fn () callconv(.C) ?[*:0]const u8,
};

//#endregion Sound

//#region Lua

pub const lua_State = ?*anyopaque;

pub const lua_CFunction = *const fn (L: *lua_State) callconv(.C) c_int;

pub const LuaUDObject = opaque {};

pub const l_valtype = c_uint;
pub const kInt = 0;
pub const kFloat = 1;
pub const kStr = 2;

pub const lua_reg = extern struct {
    name: [*:0]const u8,
    func: lua_CFunction,
};

pub const enum_LuaType = c_uint;
pub const kTypeNil = 0;
pub const kTypeBool = 1;
pub const kTypeInt = 2;
pub const kTypeFloat = 3;
pub const kTypeString = 4;
pub const kTypeTable = 5;
pub const kTypeFunction = 6;
pub const kTypeThread = 7;
pub const kTypeObject = 8;

pub const lua_val = extern struct {
    name: [*:0]const u8,
    type: l_valtype,
    v: extern union {
        intval: c_uint,
        floatval: f32,
        strval: [*:0]const u8,
    },
};

pub const playdate_lua = extern struct {
    addFunction: *const fn (f: lua_CFunction, name: [*:0]const u8, outerr: ?*?[*:0]const u8) callconv(.C) c_int,
    registerClass: *const fn (name: [*:0]const u8, reg: [*]const lua_reg, vals: [*]const lua_val, isstatic: c_int, outErr: ?*?[*:0]const u8) callconv(.C) c_int,
    pushFunction: *const fn (f: lua_CFunction) callconv(.C) void,
    indexMetatable: *const fn () callconv(.C) c_int,
    stop: *const fn () callconv(.C) void,
    start: *const fn () callconv(.C) void,
    getArgCount: *const fn () callconv(.C) c_int,
    // TODO outClass (element) nullable?
    getArgType: *const fn (pos: c_int, outClass: ?*?[*:0]const u8) callconv(.C) enum_LuaType,
    argIsNil: *const fn (pos: c_int) callconv(.C) c_int,
    getArgBool: *const fn (pos: c_int) callconv(.C) c_int,
    getArgInt: *const fn (pos: c_int) callconv(.C) c_int,
    getArgFloat: *const fn (pos: c_int) callconv(.C) f32,
    // TODO return nullable?
    getArgString: *const fn (pos: c_int) callconv(.C) ?[*:0]const u8,
    // TODO return nullable?
    getArgBytes: *const fn (pos: c_int, outlen: *usize) callconv(.C) ?[*]const u8,
    // TODO return, outud (element) nullable?
    getArgObject: *const fn (pos: c_int, type: [*:0]const u8, outud: ?*?*LuaUDObject) callconv(.C) ?*anyopaque,
    // TODO return nullable?
    getBitmap: *const fn (pos: c_int) callconv(.C) ?*LCDBitmap,
    // TODO return nullable?
    getSprite: *const fn (pos: c_int) callconv(.C) ?*LCDSprite,
    pushNil: *const fn () callconv(.C) void,
    pushBool: *const fn (val: c_int) callconv(.C) void,
    pushInt: *const fn (val: c_int) callconv(.C) void,
    pushFloat: *const fn (val: f32) callconv(.C) void,
    pushString: *const fn (str: [*:0]const u8) callconv(.C) void,
    pushBytes: *const fn (str: [*]const u8, len: usize) callconv(.C) void,
    pushBitmap: *const fn (bitmap: *LCDBitmap) callconv(.C) void,
    pushSprite: *const fn (sprite: *LCDSprite) callconv(.C) void,
    // TODO return nulable?
    pushObject: *const fn (obj: *anyopaque, type: [*:0]const u8, nValues: c_int) callconv(.C) ?*LuaUDObject,
    // TODO return nullable?
    retainObject: *const fn (obj: *LuaUDObject) callconv(.C) ?*LuaUDObject,
    releaseObject: *const fn (obj: *LuaUDObject) callconv(.C) void,
    setUserValue: *const fn (obj: *LuaUDObject, slot: c_uint) callconv(.C) void,
    getUserValue: *const fn (obj: *LuaUDObject, slot: c_uint) callconv(.C) c_int,
    callFunction_deprecated: *const fn (name: [*:0]const u8, nargs: c_int) callconv(.C) void,
    callFunction: *const fn (name: [*:0]const u8, nargs: c_int, outerr: ?*?[*:0]const u8) callconv(.C) c_int,
};

//#endregion Lua

//#region JSON

pub const json_value_type = c_uint;
pub const kJSONNull = 0;
pub const kJSONTrue = 1;
pub const kJSONFalse = 2;
pub const kJSONInteger = 3;
pub const kJSONFloat = 4;
pub const kJSONString = 5;
pub const kJSONArray = 6;
pub const kJSONTable = 7;

pub const json_value = extern struct {
    type: u8,
    data: extern union {
        intval: c_int,
        floatval: f32,
        stringval: [*:0]u8,
        arrayval: ?*anyopaque,
        tableval: ?*anyopaque,
    },
};

pub fn json_intValue(value: json_value) callconv(.C) c_int {
    return switch (value.type) {
        kJSONInteger => value.data.intval,
        kJSONFloat => @intFromFloat(value.data.floatval),
        kJSONString => 0, // TODO implement newlib strtol(value.data.stringval, null, 10)
        kJSONTrue => 1,
        else => 0,
    };
}

pub fn json_floatValue(value: json_value) callconv(.C) f32 {
    return switch (value.type) {
        kJSONInteger => @floatFromInt(value.data.intval),
        kJSONFloat => value.data.floatval,
        kJSONString => 0, // TODO implement newlib strtof(value.data.stringval, null)
        kJSONTrue => 1,
        else => 0,
    };
}

pub fn json_boolValue(value: json_value) callconv(.C) c_int {
    return if (value.type == kJSONString) @intFromBool(value.data.stringval[0] == 0) else json_intValue(value);
}

pub fn json_stringValue(value: json_value) callconv(.C) ?[*:0]u8 {
    return if (value.type == kJSONString) value.data.stringval else null;
}

pub const json_decoder = extern struct {
    decodeError: *const fn (decoder: *json_decoder, @"error": ?[*:0]const u8, linenum: c_int) callconv(.C) void,
    willDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) void,
    shouldDecodeTableValueForKey: ?*const fn (decoder: *json_decoder, key: ?[*:0]const u8) callconv(.C) c_int,
    didDecodeTableValue: ?*const fn (decoder: *json_decoder, key: [*:0]const u8, value: json_value) callconv(.C) void,
    shouldDecodeArrayValueAtIndex: ?*const fn (decoder: *json_decoder, pos: c_int) callconv(.C) c_int,
    didDecodeArrayValue: ?*const fn (decoder: *json_decoder, pos: c_int, value: json_value) callconv(.C) void,
    didDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) ?*anyopaque,
    userdata: ?*anyopaque,
    returnString: c_int,
    path: ?[*:0]const u8,
};

pub fn json_setTableDecode(
    decoder: *json_decoder,
    willDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) void,
    didDecodeTableValue: ?*const fn (decoder: *json_decoder, key: [*:0]const u8, value: json_value) callconv(.C) void,
    didDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) ?*anyopaque,
) callconv(.C) void {
    decoder.didDecodeTableValue = didDecodeTableValue;
    decoder.didDecodeArrayValue = null;
    decoder.willDecodeSublist = willDecodeSublist;
    decoder.didDecodeSublist = didDecodeSublist;
}

pub fn json_setArrayDecode(
    decoder: *json_decoder,
    willDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) void,
    didDecodeArrayValue: ?*const fn (decoder: *json_decoder, pos: c_int, value: json_value) callconv(.C) void,
    didDecodeSublist: ?*const fn (decoder: *json_decoder, name: ?[*:0]const u8, type: json_value_type) callconv(.C) ?*anyopaque,
) callconv(.C) void {
    decoder.didDecodeTableValue = null;
    decoder.didDecodeArrayValue = didDecodeArrayValue;
    decoder.willDecodeSublist = willDecodeSublist;
    decoder.didDecodeSublist = didDecodeSublist;
}

pub const json_reader = extern struct {
    read: *const fn (userdata: ?*anyopaque, buf: [*]u8, bufsize: c_int) callconv(.C) c_int,
    userdata: ?*anyopaque,
};

pub const writeFunc = fn (userdata: ?*anyopaque, str: [*]const u8, len: c_int) callconv(.C) void;

pub const json_encoder = extern struct {
    writeStringFunc: *const writeFunc,
    userdata: ?*anyopaque,

    /// This field encompasses the following C bit-fields, which can not yet be represented in Zig.
    /// ```c
    /// int pretty : 1;
    /// int startedTable : 1;
    /// int startedArray : 1;
    /// int depth : 29;
    /// ```
    pretty_startedTable_startedArray_depth: c_uint,

    startArray: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    addArrayMember: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    endArray: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    startTable: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    addTableMember: ?*const fn (encoder: *json_encoder, name: [*]const u8, len: c_int) callconv(.C) void,
    endTable: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    writeNull: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    writeFalse: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    writeTrue: ?*const fn (encoder: *json_encoder) callconv(.C) void,
    writeInt: ?*const fn (encoder: *json_encoder, num: c_int) callconv(.C) void,
    writeDouble: ?*const fn (encoder: *json_encoder, num: f64) callconv(.C) void,
    writeString: ?*const fn (encoder: *json_encoder, str: [*]const u8, len: c_int) callconv(.C) void,
};

pub const playdate_json = extern struct {
    initEncoder: *const fn (encoder: *json_encoder, write: *const writeFunc, userdata: ?*anyopaque, pretty: c_int) callconv(.C) void,
    decode: *const fn (functions: *json_decoder, reader: json_reader, outval: ?*json_value) callconv(.C) c_int,
    decodeString: *const fn (functions: *json_decoder, jsonString: [*:0]const u8, outval: ?*json_value) callconv(.C) c_int,
};

//#endregion JSON

//#region Scoreboards

pub const PDScore = extern struct {
    rank: u32,
    value: u32,
    player: [*:0]u8,
};

pub const PDScoresList = extern struct {
    boardID: [*:0]u8,
    count: c_uint,
    lastUpdated: u32,
    playerIncluded: c_int,
    limit: c_uint,
    scores: [*]PDScore,
};

pub const PDBoard = extern struct {
    boardID: [*:0]u8,
    name: [*:0]u8,
};

pub const PDBoardsList = extern struct {
    count: c_uint,
    lastUpdated: u32,
    boards: [*]PDBoard,
};

pub const AddScoreCallback = *const fn (score: *PDScore, errorMessage: ?[*:0]const u8) callconv(.C) void;

pub const PersonalBestCallback = *const fn (score: *PDScore, errorMessage: ?[*:0]const u8) callconv(.C) void;

pub const BoardsListCallback = *const fn (boards: *PDBoardsList, errorMessage: ?[*:0]const u8) callconv(.C) void;

pub const ScoresCallback = *const fn (boards: *PDScoresList, errorMessage: ?[*:0]const u8) callconv(.C) void;

pub const playdate_scoreboards = extern struct {
    addScore: *const fn (boardId: [*:0]const u8, value: u32, callback: AddScoreCallback) callconv(.C) c_int,
    getPersonalBest: *const fn (boardId: [*:0]const u8, callback: PersonalBestCallback) callconv(.C) c_int,
    freeScore: *const fn (score: *PDScore) callconv(.C) void,
    getScoreboards: *const fn (callback: BoardsListCallback) callconv(.C) c_int,
    freeBoardsList: *const fn (boardsList: *PDBoardsList) callconv(.C) void,
    getScores: *const fn (boardId: [*:0]const u8, callback: ScoresCallback) callconv(.C) c_int,
    freeScoresList: *const fn (scoresList: *PDScoresList) callconv(.C) void,
};

//#endregion Scoreboards

test {
    std.testing.refAllDeclsRecursive(@This());
}
