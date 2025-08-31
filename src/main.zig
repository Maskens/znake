const rl = @import("raylib");
const Direction = @import("global.zig").Direction;
const Player = @import("snake.zig").Player;
const FoodGen = @import("food_gen.zig").FoodGen;
const global = @import("global.zig");

const Vector2 = rl.Vector2;

const std = @import("std");
const lib = @import("mange_lib");

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;

    rl.setConfigFlags(rl.ConfigFlags { 
        .window_resizable = true, 
        .window_highdpi = true, 
        .fullscreen_mode = false // Render bug in dev raylib, we cannot use fullscreen yet
                                 // Our zig bindings for raylib points to latest dev
    });

    var player = try Player.init(alloc);
    var foodGen = try FoodGen.init(alloc);
    defer player.deInit();

    rl.initWindow(global.screenWidth, global.screenHeight, "Raylib");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while(!rl.windowShouldClose()) {
        // Input
        handleInput(&player);

        // Logic
        if (player.shouldMove()) {
            player.move();
        }

        if(foodGen.shouldGenFood()) {
            try foodGen.generateFood();
        }

        if(player.checkCollision(foodGen.foodList.allocatedSlice())) |index| {
            _ = foodGen.foodList.orderedRemove(index);
            player.shouldGrow = true;
        }

        if(player.checkCollision(
                player.bodyAlloc.items[0..player.bodyAlloc.items.len-1])
        ) |index| {
            std.debug.print("Player collision at {}", .{index});
        }

        // Drawing
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        rl.drawText("Snake?!", global.screenWidth / 3, global.screenHeight / 2, 20, .white);

        player.draw();
        foodGen.draw();
    }
}

fn handleInput(player: *Player) void {
    var direction: ?Direction = null;

    if (rl.isKeyDown(rl.KeyboardKey.a)) {
        direction = Direction.left;
    }

    if (rl.isKeyDown(rl.KeyboardKey.d)) {
        direction = Direction.right;
    }

    if (rl.isKeyDown(rl.KeyboardKey.w)) {
        direction = Direction.up;
    }

    if (rl.isKeyDown(rl.KeyboardKey.s)) {
        direction = Direction.down;
    }

    if (direction) |value| {
        player.tryChangeDirection(value);
    }
}

