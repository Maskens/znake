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

    const stepSize = global.gridSize;

    while(!rl.windowShouldClose()) {
        // Input
        handleInput(&player);

        // Logic
        if (player.shouldMove()) {
            switch (player.direction) {
                .down => player.move(Vector2{.y = stepSize, .x = 0}),
                .up => player.move(Vector2{.y = -stepSize, .x = 0}),
                .right => player.move(Vector2{.x = stepSize, .y = 0}),
                .left => player.move(Vector2{.x = -stepSize, .y = 0})
            }
        }

        if(foodGen.shouldGenFood()) {
            try foodGen.generateFood();
        }

        player.handleFoodCol(&foodGen.foodList);

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
        // Handling input
        if (rl.isKeyDown(rl.KeyboardKey.a)) {
            if (player.direction != Direction.right) {
                player.direction = Direction.left;
            }
            return;
        }

        if (rl.isKeyDown(rl.KeyboardKey.d)) {
            if (player.direction != Direction.left) {
                player.direction = Direction.right;
            }
            return;
        }

        if (rl.isKeyDown(rl.KeyboardKey.w)) {
            if (player.direction != Direction.down) {
                player.direction = Direction.up;
            }
            return;
        }

        if (rl.isKeyDown(rl.KeyboardKey.s)) {
            if (player.direction != Direction.up) {
                player.direction = Direction.down;
            }
            return;
        }
}

