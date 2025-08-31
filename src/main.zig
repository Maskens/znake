const rl = @import("raylib");
const Direction = @import("global.zig").Direction;
const Player = @import("snake.zig").Player;
const FoodGen = @import("food_gen.zig").FoodGen;
const global = @import("global.zig");

const Vector2 = rl.Vector2;

const std = @import("std");
const lib = @import("mange_lib");

const State = enum {
    playing,
    dead,
    restart,
    quit
};

const GameState = struct {
    player: Player,
    foodGen: FoodGen,
    state: State
};

pub fn main() !void {
    const alloc: std.mem.Allocator = std.heap.page_allocator;

    rl.setConfigFlags(rl.ConfigFlags { 
        .window_resizable = true, 
        .window_highdpi = true, 
        .fullscreen_mode = false // Render bug in dev raylib, we cannot use fullscreen yet
                                 // Our zig bindings for raylib points to latest dev
    });

    rl.initWindow(global.screenWidth, global.screenHeight, "Raylib");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gameState = GameState {
        .player = try Player.init(alloc, Vector2 { .x = 32, .y = 32 }, 8),
        .foodGen = try FoodGen.init(alloc),
        .state = State.playing
    };
    
    defer gameState.player.deInit();
    defer gameState.foodGen.foodList.deinit();

    var quitGame = false;

    while(!rl.windowShouldClose() and !quitGame) {
        var player = &gameState.player;
        var foodGen = &gameState.foodGen;

        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            gameState.state = .restart;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.q)) {
            gameState.state = .quit;
        }

        // Input
        handleInput(player);

        switch (gameState.state) {
            .playing => {
                // Logic
                if (player.shouldMove()) {
                    player.move();
                }

                if(foodGen.shouldGenFood()) {
                    try foodGen.generateFood(gameState.player.bodyAlloc.items);
                }

                if(player.checkCollision(foodGen.foodList.items)) |index| {
                    _ = foodGen.foodList.orderedRemove(index);
                    player.shouldGrow = true;
                }

                if(player.checkCollision(
                        player.bodyAlloc.items[0..player.bodyAlloc.items.len-1])
                ) |_| {
                    gameState.state = .dead;
                }

            },
            .dead => {
            },
            .restart => {
                try player.reset(Vector2 {.x = 16, .y = 16}, 8);
                foodGen.foodList.clearRetainingCapacity();
                gameState.state = .playing;
            },
            .quit => {
                quitGame = true;
            }
        }

        draw(&gameState);
    }
}

fn draw(gameState: *GameState) void {
    // Drawing
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(.black);

    switch (gameState.state) {
        .playing => {
            gameState.player.draw();
            gameState.foodGen.draw();
            rl.drawText("Snake!", global.screenWidth / 3, global.screenHeight / 2, 20, .white);
        },
        .dead => {
            gameState.player.draw();
            gameState.foodGen.draw();
            rl.drawText("Dead! Press R to restart!", global.screenWidth / 3, global.screenHeight / 2, 20, .white);
        },
        else => {}
    }

    return;
}

fn handleInput(player: *Player) void {
    if (rl.isKeyPressed(rl.KeyboardKey.two)) {
        // Cap to something above zero move rate
        player.moveRateInSeconds -= 0.05;
    }

    if (rl.isKeyPressed(rl.KeyboardKey.one)) {
        // Cap to something above zero move rate
        player.moveRateInSeconds += 0.05;
    }

    player.moveRateInSeconds = rl.math.clamp(
        player.moveRateInSeconds, 
        0.05, 
        2
    );

    // Player movement
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

