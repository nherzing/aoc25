const std = @import("std");

fn p1(input: []const u8) !void {
    var zeros: u32 = 0;
    var position: i32 = 50;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const dir = line[0];
        const len = try std.fmt.parseInt(i32, line[1..], 10);
        if (dir == 'L') {
            position = @mod(position - len, 100);
        } else {
            position = @mod(position + len, 100);
        }
        if (position == 0) {
            zeros += 1;
        }
    }

    std.debug.print("{d}\n", .{zeros});
}

fn p2(input: []const u8) !void {
    var zeros: u32 = 0;
    var position: i32 = 50;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const dir = line[0];
        const len = try std.fmt.parseInt(i32, line[1..], 10);
        if (len >= 100) {
            zeros += @abs(@divTrunc(len, 100));
        }

        const new_position = if (dir == 'L')
            position - @mod(len, 100)
        else
            position + @mod(len, 100);
        if (position != 0 and (new_position <= 0 or new_position >= 100)) {
            zeros += 1;
        }
        position = @mod(new_position, 100);
    }

    std.debug.print("{d}\n", .{zeros});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(input);
}
