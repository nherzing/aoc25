const std = @import("std");

fn p1(allocator: std.mem.Allocator, input: []const u8) !void {
    const last_newline = std.mem.lastIndexOf(u8, input, "\n") orelse return error.InvalidInput;
    var operators_it = std.mem.tokenizeScalar(u8, input[last_newline + 1 ..], ' ');
    var operators = try std.ArrayList(u8).initCapacity(allocator, 256);

    while (operators_it.next()) |op| {
        try operators.append(allocator, op[0]);
    }

    var lines = std.mem.tokenizeScalar(u8, input[0..last_newline], '\n');

    var sums = try std.ArrayList(u64).initCapacity(allocator, operators.items.len);
    var first_line = std.mem.tokenizeScalar(u8, lines.next() orelse return error.InvalidInput, ' ');
    while (first_line.next()) |num_s| {
        const num = try std.fmt.parseInt(u62, num_s, 10);
        try sums.append(allocator, num);
    }

    while (lines.next()) |line| {
        var nums = std.mem.tokenizeScalar(u8, line, ' ');
        for (0..operators.items.len) |i| {
            const num_s = nums.next() orelse return error.InvalidInput;
            const num = try std.fmt.parseInt(u62, num_s, 10);
            if (operators.items[i] == '+') {
                sums.items[i] += num;
            } else {
                sums.items[i] *= num;
            }
        }
    }

    var result: u64 = 0;
    for (sums.items) |v| {
        result += v;
    }
    std.debug.print("{d}\n", .{result});
}

fn p2(allocator: std.mem.Allocator, input: []const u8) !void {
    const last_newline = std.mem.lastIndexOf(u8, input, "\n") orelse return error.InvalidInput;
    const operators_line = input[last_newline + 1 ..];

    var lines_it = std.mem.tokenizeScalar(u8, input[0..last_newline], '\n');
    var lines = try std.ArrayList([]const u8).initCapacity(allocator, 256);
    while (lines_it.next()) |line| {
        try lines.append(allocator, line);
    }

    var total_result: u64 = 0;
    var i = lines.items[0].len - 1;
    var nums = try std.ArrayList(u64).initCapacity(allocator, 256);

    while (true) {
        {
            var num: u64 = 0;
            for (0..lines.items.len) |l_i| {
                if (lines.items[l_i][i] != ' ') {
                    num = (num * 10) + (lines.items[l_i][i] - '0');
                }
            }
            try nums.append(allocator, num);
        }

        if (operators_line[i] != ' ') {
            var result = nums.items[0];
            for (nums.items[1..]) |num| {
                if (operators_line[i] == '+') {
                    result += num;
                } else {
                    result *= num;
                }
            }
            total_result += result;
            nums.clearRetainingCapacity();
            if (i == 0) break;
            i -= 1;
        }
        i -= 1;
    }

    std.debug.print("{d}\n", .{total_result});
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "in", std.math.maxInt(usize));

    try p2(allocator, std.mem.trimEnd(u8, input, "\n"));
}
