const std = @import("std");
const Rndgen = std.Random.DefaultPrng;

pub const Direction = enum {
    up,
    down,
    right,
    left
};

pub const screenWidth: u32 = 1600;
pub const screenHeight: u32 = 900;

pub const gridSize: i8 = 16;

pub fn getRandomInt(to: u32) u32 {
    var rnd = Rndgen.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    return @mod(rnd.random().int(u32), to);
}


