const std = @import("std");
const rl = @import("raylib");
const Rndgen = std.Random.DefaultPrng;

pub const Direction = enum {
    up,
    down,
    right,
    left
};

pub const screenWidth: u32 = 800;
pub const screenHeight: u32 = 448;

pub const gridSize: i8 = 16;

pub fn getRandomInt(to: u32) u32 {
    var rnd = Rndgen.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    return @mod(rnd.random().int(u32), to);
}

pub fn checkCollision(vec1: rl.Vector2, vec2: rl.Vector2, size: f32) bool {
    return rl.checkCollisionRecs(
        rl.Rectangle {
            .x = vec1.x,
            .y = vec1.y,
            .width = size,
            .height = size 
        },
        rl.Rectangle {
            .x = vec2.x,
            .y = vec2.y,
            .width = size,
            .height = size
        }
    );
}


