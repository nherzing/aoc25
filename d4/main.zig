const std = @import("std");

const Coord = struct { usize, usize };
const Grid = struct {
    data: []u8,
    width: usize,
    height: usize,

    fn init(input: []u8) !Grid {
        const width = std.mem.indexOf(u8, input, "\n") orelse return error.InvalidInput;
        const height = std.mem.count(u8, input, "\n");
        return .{
            .data = input,
            .width = width,
            .height = height,
        };
    }

    fn at(self: *const Grid, x: usize, y: usize) u8 {
        return self.data[y * (self.width + 1) + x];
    }

    fn remove(self: *const Grid, x: usize, y: usize) void {
        self.data[y * (self.width + 1) + x] = '.';
    }

    fn neighbors(
        self: *const Grid,
        x: usize,
        y: usize,
        out: *[8]Coord,
    ) []const Coord {
        var count: usize = 0;

        const x0 = if (x == 0) x else x - 1;
        const x1 = if (x + 1 < self.width) x + 1 else x;

        const y0 = if (y == 0) y else y - 1;
        const y1 = if (y + 1 < self.height) y + 1 else y;

        var yy = y0;
        while (yy <= y1) : (yy += 1) {
            var xx = x0;
            while (xx <= x1) : (xx += 1) {
                if (xx == x and yy == y) continue;

                out[count] = .{ xx, yy };
                count += 1;
            }
        }

        return out[0..count];
    }
};

fn p1(input: []u8) !void {
    const grid = try Grid.init(input);
    var accessible: u32 = 0;

    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            if (grid.at(x, y) != '@') continue;
            var buf: [8]Coord = undefined;
            const neighs = grid.neighbors(x, y, &buf);
            var rolls: u8 = 0;
            for (neighs) |n| {
                if (grid.at(n[0], n[1]) == '@') {
                    rolls += 1;
                }
            }
            if (rolls < 4) {
                accessible += 1;
            }
        }
    }
    std.debug.print("{d}\n", .{accessible});
}

fn scan(grid: *Grid) !u32 {
    var removed: u32 = 0;

    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            if (grid.at(x, y) != '@') continue;
            var buf: [8]Coord = undefined;
            const neighs = grid.neighbors(x, y, &buf);
            var rolls: u8 = 0;
            for (neighs) |n| {
                if (grid.at(n[0], n[1]) == '@') {
                    rolls += 1;
                }
            }
            if (rolls < 4) {
                grid.remove(x, y);
                removed += 1;
            }
        }
    }

    return removed;
}

fn p2(input: []u8) !void {
    var grid = try Grid.init(input);
    var removed: u32 = 0;

    while (true) {
        const new_removed = try scan(&grid);
        if (new_removed == 0) {
            break;
        }
        removed += new_removed;
    }

    std.debug.print("{d}\n", .{removed});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(input);
}
