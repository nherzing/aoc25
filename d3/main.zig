const std = @import("std");

fn maxJoltage(batteries: []const u8, len: usize) u64 {
    var joltage: u64 = 0;
    var rest = batteries;
    for (0..len) |i| {
        const b_i = std.mem.indexOfMax(u8, rest[0 .. rest.len - (len - 1 - i)]);
        joltage *= 10;
        joltage += rest[b_i] - '0';
        rest = rest[b_i + 1 ..];
    }
    return joltage;
}

fn p1(input: []const u8) !void {
    var joltage: u64 = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        joltage += maxJoltage(line, 12);
    }

    std.debug.print("{d}\n", .{joltage});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p1(input);
}
