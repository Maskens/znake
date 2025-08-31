const rl = @import("raylib");
const Vector2 = @import("raylib").Vector2;
const Direction = @import("global.zig").Direction;
const global = @import("global.zig");
const std = @import("std");
const ArrayList = std.ArrayList;

pub const Player = struct {
    currentDirection: Direction = .right,
    nextMoveDirection: Direction = .right,
    bodyAlloc: ArrayList(Vector2),
    shouldGrow: bool = false,
    moveRateInSeconds: f32 = 0.15,
    nextMoveTime: f32 = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        startPos: Vector2,
        length: u8
    ) !Player {
        var player = Player {
            .bodyAlloc = ArrayList(Vector2).init(allocator)
        };

        try initBody(startPos, length, &player);

        player.nextMoveTime = @as(f32, @floatCast(rl.getTime())) + player.moveRateInSeconds;

        return player;
    }

    pub fn deInit(self: *Player) void {
        self.bodyAlloc.deinit();
    }

    pub fn reset(self: *Player, startPos: Vector2, length: u8) !void {
        self.currentDirection = .right;
        self.nextMoveDirection = .right;
        self.nextMoveTime = @as(f32, @floatCast(rl.getTime())) + self.moveRateInSeconds;
        self.bodyAlloc.clearRetainingCapacity();
        try initBody(startPos, length, self);
    }

    pub fn tryChangeDirection(self: *Player, newDirection: Direction) void {
        if (newDirection == Direction.up and self.currentDirection != Direction.down) {
            self.nextMoveDirection = newDirection;
        }
        if (newDirection == Direction.down and self.currentDirection != Direction.up) {
            self.nextMoveDirection = newDirection;
        }
        if (newDirection == Direction.left and self.currentDirection != Direction.right) {
            self.nextMoveDirection = newDirection;
        }
        if (newDirection == Direction.right and self.currentDirection != Direction.left) {
            self.nextMoveDirection = newDirection;
        }
    }

    pub fn shouldMove(self: *Player) bool {
        if(rl.getTime() > self.nextMoveTime) {
            self.nextMoveTime += self.moveRateInSeconds;
            return true;
        }

        return false;
    }

    pub fn move(self: *Player) void {
        self.currentDirection = self.nextMoveDirection;

        const velocity = switch (self.currentDirection) {
            .down => Vector2{.y = global.gridSize, .x = 0},
            .up => Vector2{.y = -global.gridSize, .x = 0},
            .right => Vector2{.x = global.gridSize, .y = 0},
            .left => Vector2{.x = -global.gridSize, .y = 0}
        };

        if (self.shouldGrow) {
            // We just make add a new head part instead of moving all other parts
            const currentHead = self.bodyAlloc.getLast();
            self.bodyAlloc.append(
                Vector2 {
                    .x = currentHead.x + velocity.x,
                    .y = currentHead.y + velocity.y
                }
            ) catch unreachable;
            self.shouldGrow = false;
        } else {
            // Else we move all the body parts
            for (self.bodyAlloc.items, 0..) |*part, i| {
                if (i == self.bodyAlloc.items.len - 1) {
                    const newHeadPos = part.add(velocity);
                    part.x = newHeadPos.x;
                    part.y = newHeadPos.y;
                } else {
                    const nextPart = self.bodyAlloc.items[i + 1];
                    part.x = nextPart.x;
                    part.y = nextPart.y;
                }
            }
        }

        // Wrap any part around screen 
        for (self.bodyAlloc.items) |*part| {
            if (part.x < 0) {
                part.x = global.screenWidth;
            }
            if (part.x > global.screenWidth) {
                part.x = 0;
            }
            if (part.y < 0) {
                part.y = global.screenHeight;
            }
            if (part.y > global.screenHeight) {
                part.y = 0;
            }
            // ******
        }
    }

    pub fn draw(self: *Player) void {
        for(self.bodyAlloc.items) |part| {
            rl.drawRectangleV(
                part, 
                Vector2 {.x = global.gridSize, .y = global.gridSize}, 
                .lime
            );
        }
    }

    // Check for player collision on the list of objects, returns index 
    // for the object collided with or null
    pub fn checkCollision(self: *Player, objects: []Vector2) ?usize {
        const head = self.bodyAlloc.getLast();

        var collision = false;
        for (objects, 0..) |item, index| {
            if (global.checkCollision(
                    item,
                    head,
                    global.gridSize
            )) {
                collision = true;
                return index;
            }
        }

        return null;
    }
};

fn initBody(start: Vector2, length: u8, player: *Player) !void {
    var body = &player.bodyAlloc;

    for (0..length) |i| {
        const iFloat = @as(f32, @floatFromInt(i));
        try body.append(
            Vector2 {
                .x = start.x + @as(f32, @floatCast(global.gridSize * iFloat)),
                .y = start.y 
            }
        );
    }
}
