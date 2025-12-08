const std = @import("std");

const Diagram = struct {
    grid: []u8,
    start_x: usize,
    width: usize,
    height: usize,

    fn init(input: []u8) !Diagram {
        const width = std.mem.indexOf(u8, input, "\n") orelse return error.InvalidInput;
        const height = std.mem.count(u8, input, "\n");
        var start_x: usize = undefined;

        for (0..width) |i| {
            if (input[i] == 'S') {
                start_x = i;
                input[i] = '|';
            }
        }
        return .{
            .grid = input,
            .start_x = start_x,
            .width = width,
            .height = height,
        };
    }

    fn at(self: *const Diagram, x: usize, y: usize) u8 {
        return self.grid[y * (self.width + 1) + x];
    }

    fn set(self: *const Diagram, x: usize, y: usize, v: u8) void {
        self.grid[y * (self.width + 1) + x] = v;
    }
};

fn p1(input: []u8) !void {
    const diagram = try Diagram.init(input);

    var splits: u64 = 0;
    for (0..diagram.height - 1) |y| {
        for (0..diagram.width) |x| {
            if (diagram.at(x, y) == '|') {
                if (diagram.at(x, y + 1) == '^') {
                    splits += 1;
                    diagram.set(x - 1, y + 1, '|');
                    diagram.set(x + 1, y + 1, '|');
                } else {
                    diagram.set(x, y + 1, '|');
                }
            }
        }
    }

    std.debug.print("{d}\n", .{splits});
}

fn p2(allocator: std.mem.Allocator, input: []u8) !void {
    const diagram = try Diagram.init(input);
    var timelines = try allocator.alloc(u64, diagram.width * diagram.height);
    @memset(timelines, 0);
    timelines[diagram.start_x] = 1;

    for (0..diagram.height - 1) |y| {
        for (0..diagram.width) |x| {
            if (timelines[y * diagram.width + x] > 0) {
                if (diagram.at(x, y + 1) == '^') {
                    timelines[(y + 1) * diagram.width + x - 1] += timelines[y * diagram.width + x];
                    timelines[(y + 1) * diagram.width + x + 1] += timelines[y * diagram.width + x];
                } else {
                    timelines[(y + 1) * diagram.width + x] += timelines[y * diagram.width + x];
                }
            }
        }
    }

    var count: u64 = 0;
    for (timelines[timelines.len - diagram.width ..]) |v| {
        count += v;
    }

    std.debug.print("{d}\n", .{count});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(allocator, input);
}
