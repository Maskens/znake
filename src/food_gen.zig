const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("raylib").Vector2;
const ArrayList = std.ArrayList;
const global = @import("global.zig");
const math = @import("std").math;

pub const FoodGen = struct {
    foodList: ArrayList(Vector2),
    maxFoods: u8 = 10,
    timeToNextFoodInSeconds: f64 = 0,
    foodRateInSeconds: f64 = 3,

    pub fn init(allocator: std.mem.Allocator) !FoodGen {
        const foods = ArrayList(Vector2).init(allocator);
        var foodGen = FoodGen {
            .foodList = foods,
        };

        foodGen.timeToNextFoodInSeconds += rl.getTime() + foodGen.foodRateInSeconds;
        return foodGen;
    }

    pub fn shouldGenFood(self: *FoodGen) bool {
        if (self.foodList.items.len > self.maxFoods) {
            return false;
        }

        if (rl.getTime() > self.timeToNextFoodInSeconds) {
            return true;
        }

        return false;
    }

    // Generate food and add to list
    pub fn generateFood(self: *FoodGen, playerBody: []Vector2) !void {
        var pos: ?Vector2 = null;

        while(pos == null) {
            var x: f32 = @floatFromInt(global.getRandomInt(global.screenWidth));
            var y: f32 = @floatFromInt(global.getRandomInt(global.screenHeight));

            const gridSize: f32 = @floatFromInt(global.gridSize);

            // snap to grid
            x = try math.divFloor(f32, x, gridSize) * gridSize;
            y = try math.divFloor(f32, y, gridSize) * gridSize;

            // Check for existing food at that location
            for (self.foodList.items) |food| {
                if (global.checkCollision(food, Vector2 {.x = x, .y = y }, global.gridSize)) {
                    continue;
                }
            }

            // Check for player position
            for (playerBody) |item| {
                if (global.checkCollision(item, Vector2 {.x = x, .y = y }, global.gridSize)) {
                    continue;
                }
            }

            pos = Vector2 {
                .x = x,
                .y = y
            };
        }

        if (pos) |value| {
            try self.foodList.append(
                Vector2{
                    .x = value.x,
                    .y = value.y 
                }
            );
        }

        self.timeToNextFoodInSeconds += self.foodRateInSeconds;
    }

    pub fn draw(self: *FoodGen) void {
        for (self.foodList.items) |food| {
            rl.drawRectangleV(food, Vector2{.x = 16, .y = 16}, .green);
        }
    }
};
