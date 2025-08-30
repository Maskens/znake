const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("raylib").Vector2;
const ArrayList = std.ArrayList;
const global = @import("global.zig");
const math = @import("std").math;

// test "apa" {
//
//     try std.testing.expectEqual(math.divFloor(f32, 66.4, 16), 4);
// }

pub const FoodGen = struct {
    foodList: ArrayList(Vector2),
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
        if (rl.getTime() > self.timeToNextFoodInSeconds) {
            return true;
        }

        return false;
    }

    // Generate food and add to list
    pub fn generateFood(self: *FoodGen) !void {
        var x: f32 = @floatFromInt(global.getRandomInt(global.screenWidth));
        var y: f32 = @floatFromInt(global.getRandomInt(global.screenHeight));

        const gridSize: f32 = @floatFromInt(global.gridSize);

        // snap to grid
        x = try math.divFloor(f32, x, gridSize) * gridSize;
        y = try math.divFloor(f32, y, gridSize) * gridSize;

        try self.foodList.append(
            Vector2{
                .x = x,
                .y = y 
            }
        );

        self.timeToNextFoodInSeconds += self.foodRateInSeconds;
    }

    pub fn draw(self: *FoodGen) void {
        for (self.foodList.items) |food| {
            rl.drawRectangleV(food, Vector2{.x = 16, .y = 16}, .green);
        }
    }
    
    // Check food collision
    // Remove food and return true
};
