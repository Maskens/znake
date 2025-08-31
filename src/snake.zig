const rl = @import("raylib");
const Vector2 = @import("raylib").Vector2;
const Direction = @import("global.zig").Direction;
const global = @import("global.zig");
const std = @import("std");
const ArrayList = std.ArrayList;

pub const Part = struct {
    position: Vector2,
};

pub const Player = struct {
    direction: Direction = .right,
    bodyAlloc: ArrayList(Part),
    shouldGrow: bool = false,
    moveRateInSeconds: f64 = 0.2,
    nextMoveTime: f64 = undefined,

    pub fn init(allocator: std.mem.Allocator) !Player {
        var body = ArrayList(Part).init(allocator);
        try initBody(&body);
        var player = Player {
            .bodyAlloc = body
        };

        player.nextMoveTime = rl.getTime() + player.moveRateInSeconds;

        return player;
    }

    pub fn deInit(self: *Player) void {
        self.bodyAlloc.deinit();
    }

    pub fn shouldMove(self: *Player) bool {
        if(rl.getTime() > self.nextMoveTime) {
            self.nextMoveTime += self.moveRateInSeconds;
            return true;
        }

        return false;
    }

    pub fn move(self: *Player, velocity: Vector2) void {

        if (self.shouldGrow) {
            // We just make add a new body part instead of moving all other parts
            const currentHead = self.bodyAlloc.getLast();
            self.bodyAlloc.append(
                Part {
                    .position = Vector2 {
                        .x = currentHead.position.x + velocity.x,
                        .y = currentHead.position.y + velocity.y
                    }
                }
            ) catch unreachable;
            self.shouldGrow = false;

            return;
        }

        // Else we move all the body parts

        for (self.bodyAlloc.items, 0..) |*part, i| {
            if (i == self.bodyAlloc.items.len - 1) {
                part.position = part.position.add(velocity); // head
            } else {
                part.position = self.bodyAlloc.items[i + 1].position;
            }

            // Wrap player around screen 
            if (part.position.x < 0) {
                part.position.x = global.screenWidth;
            }
            if (part.position.x > global.screenWidth) {
                part.position.x = 0;
            }
            if (part.position.y < 0) {
                part.position.y = global.screenHeight;
            }
            if (part.position.y > global.screenHeight) {
                part.position.y = 0;
            }
            // ******
        }
    }

    pub fn draw(self: *Player) void {
        for(self.bodyAlloc.items) |part| {
            rl.drawRectangleV(
                part.position, 
                Vector2 {.x = global.gridSize, .y = global.gridSize}, 
                .lime
            );
        }
    }

    pub fn handleFoodCol(self: *Player, foods: *ArrayList(Vector2)) void {
        const head = self.bodyAlloc.getLast();

        var collision = false;
        for (foods.items, 0..) |food, index| {
            if (rl.checkCollisionRecs(
                    rl.Rectangle {
                        .x = food.x,
                        .y = food.y,
                        .width = global.gridSize,
                        .height = global.gridSize
                    },
                    rl.Rectangle {
                        .x = head.position.x,
                        .y = head.position.y,
                        .width = global.gridSize,
                        .height = global.gridSize
                    }
            )) {
                collision = true;
                _ = foods.orderedRemove(index);
                break;
            }
        }

        if (collision) {
            self.shouldGrow = true;
        }
    }
};

fn initBody(body: *ArrayList(Part)) !void {
    try body.append(Part {
        .position = Vector2 {
            .x = global.gridSize,
            .y = global.gridSize
        }
    });
    try body.append(Part {
        .position = Vector2 {
            .x = global.gridSize * 2,
            .y = global.gridSize
        }
    });
    try body.append(Part {
        .position = Vector2 {
            .x = global.gridSize * 3,
            .y = global.gridSize
        }
    });
    try body.append(Part {
        .position = Vector2 {
            .x = global.gridSize * 4,
            .y = global.gridSize
        }
    });
}
